#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

uniform float time = 0.0;
uniform mat4 cam_mat4;
uniform vec2 V0;
uniform vec2 V1;
uniform vec2 V2;

uniform float holeSize;
uniform bool holeIsHorizon;

const float STAGE_HEIGHT = 0;
const float STAGE_RADIUS = 1.60;
const float STAGE_THICKNESS = 0.18;
const float STAGE_EDGE_WIDTH = 0.25;

const int MAX_REFLECTIONS = 10;
const int EDGE_LIGHT_COUNT = 14;
const int SPOT_COUNT = 3;

const float STEP_MIN = 0.01;
const float STEP_MAX = 0.1;
const float STEP_SCALE = 0.82;
const float MAX_HYP_DIST = 6.5;
const float HIT_EPS = 0.0025;

UHPGeodesic G01 = make_geodesic_segment(V0, V1);
UHPGeodesic G12 = make_geodesic_segment(V1, V2);
UHPGeodesic G20 = make_geodesic_segment(V2, V0);

struct flipData {
    vec2 p_in_fundamental;
    int flipCount;
};

float mdot4(vec4 a, vec4 b) { return -dot(a.xyz, b.xyz) + a.w * b.w; }
float acosh1(float x) { return log(x + sqrt(max(0.0, x * x - 1.0))); }
float asinh1(float x) { return log(x + sqrt(x * x + 1.0)); }
vec4 lift_to_H(vec3 xyz) { return vec4(xyz, sqrt(1.0 + dot(xyz, xyz))); }

flipData flip(vec2 pos_xy_embedding) {
    vec2 p_in_fundamental = hyperboloid_to_uhp(pos_xy_embedding);
    int flipCount = 0;
    for (int i = 0; i < MAX_REFLECTIONS; ++i) {
        bool reflected = false;
        if (!is_on_correct_side_of_edge(p_in_fundamental, G01, V2)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G01);
            reflected = true;
            flipCount++;
        }
        if (!is_on_correct_side_of_edge(p_in_fundamental, G12, V0)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G12);
            reflected = true;
            flipCount++;
        }
        if (!is_on_correct_side_of_edge(p_in_fundamental, G20, V1)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G20);
            reflected = true;
            flipCount++;
        }
        if (p_in_fundamental.y <= EPSILON * 0.1) {
            return flipData(vec2(0.0), -1);
        }
        if (p_in_fundamental.y <= EPSILON && p_in_fundamental.y > EPSILON * 0.1) {
            p_in_fundamental.y = EPSILON;
        }
        if (!reflected) {
            break;
        }
        if (i == MAX_REFLECTIONS - 1) {
            return flipData(vec2(0.0), -1);
        }
    }
    return flipData(p_in_fundamental, flipCount);
}

vec3 stage_local(vec4 p_H) {
    return vec3(p_H.x, p_H.y, p_H.z - STAGE_HEIGHT);
}

vec4 normalize_spacelike(vec4 v) {
    float n2 = -mdot4(v, v);
    return v / sqrt(max(n2, 1e-6));
}

vec4 project_to_tangent(vec4 p, vec4 v) {
    return v - mdot4(p, v) * p;
}

float stageSDF(vec4 p_H) {
    vec3 local = stage_local(p_H);
    float radial = length(local.xy);
    float radialDist = radial - STAGE_RADIUS;
    float verticalDist = local.z;
    return max(verticalDist, radialDist);
}

vec3 stageNormal(vec4 p_H) {
    float e = 0.0025;
    vec4 px1 = lift_to_H(p_H.xyz + vec3(e, 0.0, 0.0));
    vec4 px2 = lift_to_H(p_H.xyz - vec3(e, 0.0, 0.0));
    vec4 py1 = lift_to_H(p_H.xyz + vec3(0.0, e, 0.0));
    vec4 py2 = lift_to_H(p_H.xyz - vec3(0.0, e, 0.0));
    vec4 pz1 = lift_to_H(p_H.xyz + vec3(0.0, 0.0, e));
    vec4 pz2 = lift_to_H(p_H.xyz - vec3(0.0, 0.0, e));

    float dx = stageSDF(px1) - stageSDF(px2);
    float dy = stageSDF(py1) - stageSDF(py2);
    float dz = stageSDF(pz1) - stageSDF(pz2);
    return normalize(vec3(dx, dy, dz));
}

float angularDifference(float a, float b) {
    float diff = a - b;
    diff = mod(diff + 3.14159265358979323846, 6.28318530717958647692) - 3.14159265358979323846;
    return abs(diff);
}

vec3 spotBase(int idx) {
    if (idx == 0) {
        return vec3(1.55, -0.25, 1.35);
    } else if (idx == 1) {
        return vec3(-1.55, 0.30, 1.28);
    }
    return vec3(0.0, 0.7, 2.42);
}

void getSpotInfo(int idx, float time, out vec3 origin, out vec3 direction, out vec3 color, out float coneAngle, out vec3 target) {
    origin = spotBase(idx);
    float phase = float(idx);
    vec3 stageCenter = vec3(0.0, 0.0, STAGE_HEIGHT);

    float heading = phase * 2.094395102393195 + 0.75 * sin(time * 0.35 + phase * 1.137);
    float sweepRadius = STAGE_RADIUS * (0.35 + 0.28 * (0.6 + 0.4 * sin(time * 0.42 + phase * 2.17)));
    target = stageCenter + vec3(cos(heading) * sweepRadius, sin(heading) * sweepRadius, 0.06 * sin(time * 0.8 + phase));

    direction = normalize(target - origin);
    color = mix(vec3(0.92, 0.86, 0.74), vec3(0.58, 0.78, 1.05), 0.45 + 0.25 * sin(time * 0.9 + phase * 1.73));
    coneAngle = 0.21 + 0.03 * sin(time * 0.6 + phase * 0.97);
}

vec3 accumulateSpotlightFog(vec4 pos_H, float stepLen, float time) {
    vec3 fog = vec3(0.0);
    for (int i = 0; i < SPOT_COUNT; ++i) {
        vec3 origin; vec3 dir; vec3 color; float coneAngle; vec3 target;
        getSpotInfo(i, time, origin, dir, color, coneAngle, target);

        vec4 originH = lift_to_H(origin);
        vec4 targetH = lift_to_H(target);
        vec4 axisDir = normalize_spacelike(project_to_tangent(originH, targetH));

        float axialCos = mdot4(originH, pos_H);
        if (axialCos <= 1.0) {
            continue;
        }
        float axisProj = mdot4(axisDir, pos_H);
        float axialUnsigned = acosh1(max(axialCos, 1.0));
        float axialSign = axisProj <= 0.0 ? 1.0 : -1.0;
        float axial = axialUnsigned * axialSign;
        if (axial <= 0.0) {
            continue;
        }

        float b = -axisProj;
        vec4 planePoint = originH * axialCos + axisDir * b;
        vec4 perp = pos_H - planePoint;
        float perpNorm = sqrt(max(-mdot4(perp, perp), 0.0));
        float radialDist = asinh1(perpNorm);

        float spread = tan(coneAngle * 0.48);
        float axialScale = max(sinh(axial), 0.0);
        float beamRadius = max(axialScale * spread, 0.009);
        float radialFalloff = exp(-pow(radialDist / (beamRadius + 4e-5), 4.0));
        float depthFalloff = exp(-axial * 1.05);
        float flutter = 0.92 + 0.08 * sin(time * 1.35 + float(i) * 2.51);
        fog += color * radialFalloff * depthFalloff * flutter;
    }
    return fog * stepLen * 0.9;
}

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0,2,1)/3.0)*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p-1.0, 0.0, 1.0), c.y);
}

vec3 tessellationColor(vec2 pos_xy_embedding, float time) {
    flipData fd = flip(pos_xy_embedding);
    if (fd.flipCount < 0) {
        return vec3(0.35, 0.05, 0.35);
    }
    vec3 bary = get_hyperbolic_barycentric_coords(fd.p_in_fundamental, V0, V1, V2);
    float parity = float(mod(fd.flipCount,2));
    vec3 paletteA = vec3(0.45, 0.26, 0.72);
    vec3 paletteB = vec3(0.17, 0.32, 0.68);
    vec3 base = mix(paletteA, paletteB, parity);
    vec3 edgeHighlight = hsv2rgb(vec3(0.75 + 0.15 * parity + time * 0.1 + 0.2 * sin(time * 0.5 + float(fd.flipCount)), 0.6, 0.9));
    float edgeFactor = smoothstep(0.0, 0.12, min(min(bary.x, bary.y), bary.z));
    base = mix(edgeHighlight, base, edgeFactor);
    vec3 accent = normalize(vec3(0.6, 0.35, 0.9));
    float shimmer = 0.32 * sin(time * 0.9 + dot(bary, vec3(5.3, 3.7, 4.1)) + float(fd.flipCount));
    base += accent * shimmer;
    base += vec3(bary.x * 0.08, bary.y * 0.05, bary.z * 0.06);
    return clamp(base, 0.0, 1.0);
}
float smin_poly(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
vec3 computeEdgeLights(vec3 local, float time) {
    float radial = length(local.xy);
    float edgeMask = smoothstep(STAGE_RADIUS - STAGE_EDGE_WIDTH, STAGE_RADIUS - STAGE_EDGE_WIDTH * 0.25, radial);
    if (edgeMask <= 0.0) {
        return vec3(0.0);
    }
    float angle = atan(local.y, local.x);
    float lights = 0.0;
    for (int i = 0; i < EDGE_LIGHT_COUNT; ++i) {
        float wobble = 0.7 + 0.3 * sin(time * 0.25 + i);
        float target = 6.283185307179586 * (float(i) / float(EDGE_LIGHT_COUNT)) + time * 0.35;
        float diff = angularDifference(angle, target);
        float width = 0.1 + 0.04 * sin(time * 0.7 + float(i) * 1.37);
        lights += exp(-pow(diff / width, 2.0)) * wobble;
    }
    lights *= 0.45 * edgeMask * exp(smin_poly(local.z+0.05,0,0.1)*10.0);
    vec3 hue = vec3(1.25, 1.05, 0.75);
    return hue * lights;
}

vec3 computeSpotlightLighting(vec3 worldPos, vec3 normal, vec3 viewDir, vec3 baseAlbedo, float time) {
    vec3 total = vec3(0.0);
    for (int i = 0; i < SPOT_COUNT; ++i) {
        vec3 origin; vec3 dir; vec3 lightColor; float coneAngle; vec3 target;
        getSpotInfo(i, time, origin, dir, lightColor, coneAngle, target);

        vec3 toLight = origin - worldPos;
        float dist2 = max(dot(toLight, toLight), 1e-4);
        vec3 L = normalize(toLight);
        vec3 lightToPoint = -L;

        float alignment = dot(lightToPoint, dir);
        float outer = cos(coneAngle * 0.58);
        if (alignment <= outer) {
            continue;
        }
        float inner = cos(coneAngle * 0.38);
        float cone = smoothstep(outer, inner, alignment);

        float diffuse = max(dot(normal, L), 0.0);
        vec3 halfway = normalize(L + viewDir);
        float spec = pow(max(dot(normal, halfway), 0.0), 52.0);

        float distance = sqrt(dist2);
        float attenuation = cone * exp(-distance * 0.82) / (1.0 + dist2 * 0.14);
        float pulse = 0.92 + 0.15 * sin(time * 0.6 + float(i) * 2.1);

        vec3 contribution = lightColor * (baseAlbedo * diffuse + spec * 0.7);
        total += contribution * attenuation * pulse * 2.6;
    }
    return total;
}

vec3 computeStageShading(vec4 hitPos_H, vec3 normal, vec3 viewDir, float travel, float time) {
    vec3 local = stage_local(hitPos_H);
    vec3 baseAlbedo = tessellationColor(hitPos_H.xy, time);
    vec3 ambient = baseAlbedo * (0.22 + 0.08 * sin(time * 0.2));
    vec3 fill = vec3(0.08, 0.09, 0.12);
    vec3 lighting = ambient + fill * 0.6;

    vec3 spot = computeSpotlightLighting(hitPos_H.xyz, normal, viewDir, baseAlbedo, time);
    lighting += spot * 1.8;

    vec3 edge = computeEdgeLights(local, time);
    lighting += edge;

    float centerFalloff = smoothstep(0.0, STAGE_RADIUS * 0.7, length(local.xy));
    lighting *= mix(1.35, 0.95, centerFalloff);

    float rim = pow(1.0 - max(dot(normal, viewDir), 0.0), 2.5);
    lighting += vec3(0.28, 0.3, 0.42) * rim;

    float fog = exp(-travel * 0.18);
    lighting *= fog;
    return clamp(lighting, 0.0, 2.4);
}

vec3 getHoleColor(vec3 dir, float time) {
    vec3 holeCenter = normalize(vec3(0.0, -1.7, 0.3));
    float cosTheta = dot(dir, holeCenter);
    
    vec3 w = holeCenter;
    vec3 u = normalize(cross(vec3(1.0, 0.0, 0.0), w));
    vec3 v = cross(w, u);
    float angle = atan(dot(dir, v), dot(dir, u));
    
    float spike1 = 0.05 * abs(sin(angle * 4.0)); 
    float spike2 = 0.03 * abs(sin(angle * 8.5 + 1.0));
    float grit  = 0.01 * sin(angle * 30.0); // Add regular noise for texture

    float irregularity = -(spike1 + spike2) + grit;
    float currentRadius = (holeSize + irregularity);
    
    if (acos(clamp(cosTheta, -1.0, 1.0)) < currentRadius) {
        if (holeIsHorizon) {
            vec3 sky = vec3(0.05, 0.05, 0.4);
            vec3 horizon = vec3(1.0, 0.6, 0.45);
            vec3 ground = vec3(0.1, 0.0, 0.3);
            if (dir.z < holeCenter.z) return mix(ground, horizon, smoothstep(holeCenter.z-0.3, holeCenter.z, dir.z));
            return mix(horizon, sky, smoothstep(holeCenter.z, holeCenter.z+0.3, dir.z));
        } else {
             float flash = sin(dir.x * 20.0 + time * 5.0) * sin(dir.y * 20.0 - time * 5.0);
             vec3 col = 0.5 + 0.5 * cos(time + dir.xyx * 10.0 + vec3(0,2,4));
             return col + flash * 0.5;
        }
    }
    return vec3(-1.0);
}

vec3 backgroundColor(vec4 p, vec4 v, float time) {
    vec4 L = p + v;
    vec3 dir = normalize(L.xyz);
    if (holeSize > 0.001) {
        vec3 hole = getHoleColor(dir, time);
        if (hole.x > -0.5) return hole;
    }

    vec3 base = vec3(0.02, 0.03, 0.055);
    vec3 beams = vec3(0.0);
    dir = normalize(v.xyz);
    for (int i = 0; i < SPOT_COUNT; ++i) {
        vec3 origin; vec3 spotlightDir; vec3 color; float coneAngle; vec3 target;
        getSpotInfo(i, time, origin, spotlightDir, color, coneAngle, target);
        float tight = pow(max(dot(dir, spotlightDir), 0.0), 32.0);
        vec3 beamColor = mix(vec3(0.3, 0.28, 0.54), color, 0.42);
        beams += beamColor * tight * (1.05 + 0.55 * sin(time * 0.7 + float(i)));
    }
    return base + beams;
}

vec3 rayMarch(vec4 cam_pos_H, vec4 ray_dir_H, float time, out bool hit_stage) {
    float t = 0.0;
    hit_stage = false;
    vec3 bg = backgroundColor(cam_pos_H, ray_dir_H, time);
    vec3 beamAccum = vec3(0.0);

    for (int i = 0; i < 48; ++i) {
        vec4 current_pos_H = cam_pos_H * cosh(t) + ray_dir_H * sinh(t);
        if (current_pos_H.w <= 0.01) break;

        float dist = stageSDF(current_pos_H);
        float dt = clamp(dist * STEP_SCALE / max(1.0, current_pos_H.w), STEP_MIN, STEP_MAX);
        vec3 fogStep = accumulateSpotlightFog(current_pos_H, dt, time);
        if (dist < HIT_EPS) {
            hit_stage = true;
            vec3 normal = stageNormal(current_pos_H);
            vec4 ray_tangent = cam_pos_H * sinh(t) + ray_dir_H * cosh(t);
            vec3 viewDir = -normalize(ray_tangent.xyz);
            return clamp(computeStageShading(current_pos_H, normal, viewDir, t, time) + beamAccum * 1.35 + fogStep * 3.0, 0.0, 2.6);
        }
        beamAccum += fogStep;
        t += dt;
        if (t > MAX_HYP_DIST) break;
    }
    float fade = exp(-t * 0.2);
    return clamp(bg * fade + beamAccum * 3.2, 0.0, 2.2);
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
    final_ray_dir_H = normalize_spacelike(project_to_tangent(final_cam_pos_H, final_ray_dir_H));

    bool hit_stage;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, hit_stage);
    fragment_color = clamp(fragment_color, 0.0, 1.0);

    return vec4(fragment_color, 1.0) * color;
}
