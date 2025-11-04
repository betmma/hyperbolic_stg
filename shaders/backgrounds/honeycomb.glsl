#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"
#include "shaders/honeycombMath.glsl"

uniform bool inverse=false; // when false, a ball of CELL_SHELL_DIST radius is cut out from solid honeycomb; when true, only the ball is solid
uniform float time=0.0;

uniform mat4 cam_mat4; // combined rotation and boost matrix

uniform float SHELL_RATIO = 0.5; // 0.38 for small gap at edge
uniform int reflect_count = 0; // times of camera reflection. flip coords in shade to keep continuity
float CELL_SHELL_DIST = SHELL_RATIO * CELL_INRADIUS + (1-SHELL_RATIO) * CELL_CIRCUMRADIUS;
const float MAX_HYP_DIST = 9.5;
const float STEP_MIN = 0.02;
const float STEP_MAX = 0.9;
const float STEP_FACTOR = 0.99;


vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time);

vec3 rayMarch(vec4 cam_pos_H, vec4 ray_dir_H, float time, out bool hit_terrain) {
    hit_terrain = false;
    vec4 pos = cam_pos_H;
    vec4 dir = normalize_spacelike(project_to_tangent(pos, ray_dir_H));
    wrap_inside_cell(pos, dir);

    vec3 accum = vec3(0.08, 0.09, 0.14);
    float travel = 0.0;
    for (int step = 0; step < 64; ++step) {
        float shellDist = acosh1(max(pos.w, 1.0));
        if (!inverse && shellDist >= CELL_SHELL_DIST || inverse && shellDist <= CELL_SHELL_DIST) {
            break;
        }

        float nearest = 1e9;
        for (int i = 0; i < FACE_COUNT; ++i) {
            nearest = min(nearest, plane_signed(pos, FACE_NORMALS[i]));
        }
        nearest = max(nearest, 0.0);
        float nearestDist = asinh1(nearest);
        float dt = clamp(max(nearestDist * STEP_FACTOR, STEP_MIN), STEP_MIN, STEP_MAX);
        dt = min(dt, MAX_HYP_DIST - travel);
        dt = min(dt, abs(CELL_SHELL_DIST - shellDist));


        float remaining = dt;
        for (int guard = 0; guard < 1 && remaining > 0.0005; ++guard) {
            vec4 trialPos;
            vec4 trialDir;
            geodesic_step(pos, dir, remaining, trialPos, trialDir);
            int hitFace = -1;
            float hitT = remaining;
            for (int i = 0; i < FACE_COUNT; ++i) {
                float s0 = plane_signed(pos, FACE_NORMALS[i]);
                float s1 = plane_signed(trialPos, FACE_NORMALS[i]);
                if (s1 < 0.0) {
                    float low = 0.0;
                    float high = remaining;
                    for (int iter = 0; iter < 2; ++iter) {
                        float mid = 0.5 * (low + high);
                        vec4 midPos;
                        vec4 midDir;
                        geodesic_step(pos, dir, mid, midPos, midDir);
                        float smid = plane_signed(midPos, FACE_NORMALS[i]);
                        if (smid > 0.0) {
                            low = mid;
                        } else {
                            high = mid;
                        }
                    }
                    if (high < hitT) {
                        hitT = high;
                        hitFace = i;
                    }
                }
            }
            if (hitFace != -1) {
                vec4 hitPos;
                vec4 hitDir;
                geodesic_step(pos, dir, hitT, hitPos, hitDir);
                pos = reflect_plane(hitPos, FACE_NORMALS[hitFace]);
                dir = reflect_plane(hitDir, FACE_NORMALS[hitFace]);
                renormalize_state(pos, dir);
                remaining -= hitT;
            } else {
                pos = trialPos;
                dir = trialDir;
                renormalize_state(pos, dir);
                remaining = 0.0;
            }
        }
        travel += dt;
        if (travel >= MAX_HYP_DIST) break;
        // if (dt <= 0.00001) {
        //     break;
        // }
    }
    vec3 sampleColor = honeycomb_shade(pos, dir, travel, time);
    accum = sampleColor;
    return accum;
}
// ---------------- Disco helpers ----------------

float hash11(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+34.56);
    return fract(p.x*p.y);
}

// HSV to RGB for animated beams
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0,2,1)/3.0)*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p-1.0, 0.0, 1.0), c.y);
}

// Unit vector from latitude theta in [-pi/2, pi/2], longitude phi in [-pi, pi]
vec3 sphDir(float theta, float phi) {
    float ct = cos(theta), st = sin(theta);
    float cp = cos(phi),   sp = sin(phi);
    return vec3(ct*cp, st, ct*sp);
}

// Environment “lights”: a few colored beams sweeping direction space
vec3 envLights(vec3 r, float time){
    vec3 col = vec3(0.0); 
    for(int i=0;i<6;i++){
        float ph = time*0.65 + float(i)*2.13;
        vec3 L = normalize(vec3(cos(ph+5.1*i), sin(ph*1.3+1.7*i), cos(ph*0.7-2.3*i)));
        float tight = pow(max(dot(r, L), 0.0), 18.0); // sharp specular lobe
        vec3 hue = hsv2rgb(vec3(fract(0.2*float(i) + time*0.11), 0.85, 1.0));
        col += hue * tight * 6.0;
    }
    return col;
}

// Longitude/latitude faceting with AA grout lines
// N: unit direction on sphere
// meridians: number of φ bins (vertical slices)
// parallels: number of θ bins (horizontal bands)
// grout: edge half-width in cell units (0..0.5)
void geoFacet(vec3 N, float meridians, float parallels, float grout,
              out vec3 facetN, out vec2 tileUV, out float edgeMask)
{
    // spherical coordinates
    float phi   = atan(N.z, N.x);                       // [-pi, pi]
    float theta = asin(clamp(N.y, -1.0, 1.0));          // [-pi/2, pi/2]

    // normalized [0,1] for hashing / color animation
    float u = (phi + PI) / (2.0*PI);
    float v = (theta + 0.5*PI) / PI;
    tileUV = vec2(u, v);

    // facet center angles
    float iu = floor(u * meridians);
    float iv = floor(v * parallels);
    float uc = (iu + 0.5) / meridians;
    float vc = (iv + 0.5) / parallels;
    float phi_c   = uc * (2.0*PI) - PI;
    float theta_c = vc * PI - 0.5*PI;

    // flat facet normal is the center direction
    facetN = sphDir(theta_c, phi_c);

    // AA edge mask along nearest meridian/parallel
    vec2 cell = vec2(u*meridians, v*parallels);
    vec2 frac = fract(cell);
    vec2 distToEdge = min(frac, 1.0 - frac);
    vec2 aa = 0.5 * fwidth(cell);                       // derivative-based AA
    float edgeU = 1.0 - smoothstep(grout - aa.x, grout + aa.x, distToEdge.x);
    float edgeV = 1.0 - smoothstep(grout - aa.y, grout + aa.y, distToEdge.y);
    edgeMask = max(edgeU, edgeV);                       // 1 at edges, 0 in tile interior
}

// -------------------- Disco-ball shading replacement ----------------------

vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time) {
    if (mod(reflect_count, 2) == 1){ 
        pos.xy = -pos.xy;
        dir.xy = -dir.xy;
    }
    float decay = inverse ? 0.18 : 0.38;
    // Hyperbolic distance to origin on the hyperboloid
    float d = acosh1(max(pos.w, 1.0));

    // Keep your shell logic but don’t blackout the interior
    bool outsideShell = (!inverse && d < CELL_SHELL_DIST - 0.001) ||
                        ( inverse && d > CELL_SHELL_DIST + 0.001);
    if (outsideShell) {
        return vec3(0.1, 0.1, 0.1) * exp(-decay*travel);
    }

    // Euclidean normal of the shell from your hyperbolic embedding
    float sh = max(sinh(d), 1e-5);
    float ch = cosh(d);
    vec3 N_euclid = normalize(pos.xyz / sh * ch);

    // Optional signed lighting like your original
    float Lsigned = dot(dir, vec4(N_euclid, sh));
    if (inverse) Lsigned = -Lsigned;

    // Spherical faceting parameters
    const float MERIDIANS = 64.0;   // vertical lines (φ)
    const float PARALLELS = 32.0;   // horizontal lines (θ)
    const float GROUT     = 0.05;   // AA half-width in cell units

    // Compute facet normal and edge mask
    vec3 facetN; vec2 tileUV; float edgeMask;
    geoFacet(N_euclid, MERIDIANS, PARALLELS, GROUT, facetN, tileUV, edgeMask);

    // View and reflection for mirror tiles
    vec3 V = normalize(-dir.xyz);
    vec3 R = reflect(-V, facetN);

    // Mirror env with Fresnel for spicy glints
    vec3 env = envLights(R, time);
    float F = pow(1.0 - max(dot(V, facetN), 0.0), 5.0);
    vec3 mirrorCol = env * (1.2*(0.08 + 0.92*F));

    // Base tile visibility + subtle hue wobble so it never dies in darkness
    vec3 tileBase = vec3(0.10)*0.5*(1+Lsigned);
    float hueShift = 0.08*sin(time*0.7) + 0.04*sin(3.0*time + tileUV.x*2.0);
    vec3 wobble = hsv2rgb(vec3(hueShift, 0.12, 1.0));

    // Sparkles: random tiles twinkle
    float sparkleSeed = hash11(tileUV*vec2(37.3, 91.7));
    float sparkleHit  = step(0.08, sparkleSeed);
    float sparkle = sparkleHit *
                    pow(max(dot(R, normalize(vec3(0.3,0.8,0.5))), 0.0), 80.0) *
                    (0.7 + 0.3*sin(time*22.0 + sparkleSeed*6.2831853));
    vec3 sparkleCol = vec3(1.6) * sparkle;

    // Grout color and mixing along edges (edgeMask=1 at lines)
    vec3 groutCol = vec3(0.20, 0.18, 0.16);

    // Final tile color
    vec3 tileCol = (tileBase + mirrorCol + sparkleCol) * wobble;

    vec3 color = mix(tileCol, groutCol, edgeMask);

    // Gentle rim so the silhouette always reads
    float rim = pow(1.0 - max(dot(facetN, V), 0.0), 2.0);
    color += vec3(0.25) * rim;

    // Modest attenuation so it doesn’t vanish with long travel
    color *= exp(-decay * travel);

    return color;
}




vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords.xy / love_ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float field_of_view_factor = -1.3;
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, field_of_view_factor));
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0);

    vec4 final_cam_pos_H = cam_mat4 * cam_pos_H0;
    vec4 final_ray_dir_H = cam_mat4 * rd_T0;

    bool terrain_was_hit;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, terrain_was_hit);
    fragment_color = clamp(fragment_color, 0.0, 1.0);
    return vec4(fragment_color, 1.0) * color;
}
