#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

// ---------- Controls ----------
uniform float time = 0.0;
uniform bool flat_=false; // kept from H3Terrain2.glsl to reuse its send function in lua

// Fundamental triangle for the H^2 tessellation
uniform vec2 V0;
uniform vec2 V1;
uniform vec2 V2;

// Camera orientation (same semantics as your existing shader)
uniform vec3  cam_rotation_axis1 = vec3(1.0, 0.0, 0.0);
uniform float cam_pitch          = 0.0;
uniform vec3  cam_rotation_axis2 = vec3(0.0, 1.0, 0.0);
uniform float cam_yaw            = 0.0;
uniform vec3  cam_rotation_axis3 = vec3(0.0, 0.0, 1.0);
uniform float cam_roll           = 0.0;
uniform vec3  cam_translation    = vec3(0.0, 0.0, 1.0);

// Three dream layers defined by boosts along -Z (rapidity values)
uniform vec3 plane_eta = vec3(-0.1, -0.4, -0.9); // larger => visually “deeper” below camera

// Line look
uniform float line_width   = 0.1;    // thickness of tessellation lines in barycentric units
uniform float line_glow    = 2.5;    // edge glow exponent
uniform float line_wobble  = 0.005;  // subtle temporal wobble in the lines

// Mist & starfield
uniform vec3  mist_color      = vec3(0.15, 0.08, 0.35);
// Strength of additive mist
uniform float mist_strength   = 0.65;
// Pixel scale for noise domain
uniform float mist_scale_px   = 30.0;
// Flow speed of the Brownian field
uniform float mist_speed      = 0.3;
// How strongly mist prefers the bottom of screen (0=no bias, 1=strong)
uniform float mist_bottom_bias = 0.85;
uniform float star_density     = 0.06; // probability per screen cell
uniform float star_brightness  = 0.8;
// screen-space star controls (2D)
uniform float star_cell_px     = 8.0;   // approximate pixel cell size for star placement
uniform float star_core_px     = 0.4;    // core radius in pixels
uniform float star_halo_px     = 1.5;    // halo radius in pixels

// ---------- Geodesics for reflections ----------
UHPGeodesic G01 = make_geodesic_segment(V0, V1);
UHPGeodesic G12 = make_geodesic_segment(V1, V2);
UHPGeodesic G20 = make_geodesic_segment(V2, V0);
const int MAX_REFLECTIONS = 10;

// ---------- Small helpers ----------
float mdot4(vec4 a, vec4 b) { return -dot(a.xyz, b.xyz) + a.w*b.w; }

// Solve for t such that z(t) = target for p(t) = p0*cosh(t) + v*sinh(t)
float solve_t_for_z_target(float a, float b, float target) {
    // Quadratic in u = e^t: (a+b)*0.5*u^2 - target*u + (a-b)*0.5 = 0
    float A = 0.5*(a+b);
    float B = 0.5*(a-b);
    float Z = target;

    // Handle nearly-zero A robustly
    if (abs(A) < 1e-6) {
        if (abs(Z) < 1e-6) return -1.0;
        float u = B / Z;
        if (u <= 0.0) return -1.0;
        float t = log(u);
        return (t >= 0.0) ? t : -1.0;
    }

    float disc = Z*Z - 4.0*A*B;
    if (disc < 0.0) return -1.0;
    float sdisc = sqrt(disc);

    float u1 = (Z + sdisc) / (2.0*A);
    float u2 = (Z - sdisc) / (2.0*A);
    float t  = 1e9;
    if (u1 > 0.0) t = min(t, log(u1));
    if (u2 > 0.0) t = min(t, log(u2));
    return (t == 1e9 || t < 0.0) ? -1.0 : t;
}

// Cheap 2D hash
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

// ---------------- flip(): reuse your reflection to fundamental ----------------
struct flipData { vec2 p_in_fundamental; int flipCount; };

flipData flip(vec2 pos_xy_embedding) {
    vec2 p = hyperboloid_to_uhp(pos_xy_embedding);
    int flipCount = 0;
    for (int i = 0; i < MAX_REFLECTIONS; ++i) {
        bool reflected = false;

        if (!is_on_correct_side_of_edge(p, G01, V2)) {
            p = reflect_point(p, G01);
            reflected = true;
            flipCount++;
        }
        if (!is_on_correct_side_of_edge(p, G12, V0)) {
            p = reflect_point(p, G12);
            reflected = true;
            // flipCount++; // keep parity tweak optional
        }
        if (!is_on_correct_side_of_edge(p, G20, V1)) {
            p = reflect_point(p, G20);
            reflected = true;
            flipCount++;
        }

        if (p.y <= EPSILON * 0.1) {
            return flipData(vec2(0.0), -1);
        }
        if (p.y <= EPSILON && p.y > EPSILON * 0.1) {
            p.y = EPSILON;
        }
        if (!reflected) break;
        if (i == MAX_REFLECTIONS - 1) {
            return flipData(vec2(0.0), -1);
        }
    }
    return flipData(p, flipCount);
}

// Glowing line intensity from barycentric coords in fundamental triangle
float tess_line_intensity(vec2 pos_xy_embedding, float wobble, float width, float glowPow, float tDepth, float eta) {
    // tiny layer decorrelation by boosting the sample before flip
    mat4 B = create_boost_lorentz_matrix(vec3(1,1,0), eta);
    vec4 pH = B * vec4(pos_xy_embedding, 0.0, sqrt(1.0 + dot(pos_xy_embedding, pos_xy_embedding)));
    flipData fd = flip(pH.xy);
    if (fd.flipCount < 0) return 0.0;

    vec3 bary = get_hyperbolic_barycentric_coords(fd.p_in_fundamental, V0, V1, V2);

    // subtle dream-wobble of edges
    float jitter = sin(time*0.7 + dot(pH.xy, vec2(0.9, 1.3))*4.5 + tDepth) * wobble;
    vec3 b = max(bary + jitter, 0.0);

    // choose which edges to show (here: only x-edge; un-comment others to add)
    float m = min(b.x, min(b.y*0.0+1.0, b.z*0.0+1.0));

    float edge = smoothstep(width, 0.0, m);
    edge = pow(edge, glowPow);

    // distance attenuation with hyperbolic geodesic t
    float att = 1.0 / (1.0 + 0.6*tDepth*tDepth);
    return edge * att;
}

// Intersect with z′=0 in a frame boosted by -eta along +Z.
vec3 shade_plane_boostedZ0(vec4 cam_pos_H, vec4 ray_dir_H,
                           float eta, float scale, float wobble, float width, float glowPow,
                           out float tHitOut)
{
    // Boost by -eta along +Z: camera & direction into the plane’s local frame
    mat4 B = create_boost_lorentz_matrix(vec3(0,0,1), -eta);
    vec4 p0p = B * cam_pos_H;
    vec4 v0p = B * ray_dir_H;

    // Solve for z′(t) = 0
    float t = solve_t_for_z_target(p0p.z, v0p.z, 0.0);
    tHitOut = t;
    if (t < 0.0) return vec3(0.0);

    // Evaluate hit point in the boosted frame (z′ ≈ 0)
    vec4 hitp = p0p * cosh(t) + v0p * sinh(t);
    if (hitp.w <= 0.0) return vec3(0.0);

    // Use x′y′ inside that H^2 (z′=0) to drive the tessellation
    vec2 xy_local = hitp.xy * scale;

    float lineI = tess_line_intensity(xy_local, wobble, width, glowPow, t, eta);
    vec3 redDream = mix(vec3(1.6, 0.1, 0.2), vec3(1.1, 0.05, 0.25), clamp(t*0.18, 0.0, 1.0));

    return redDream * lineI; // additive
}

vec3 stars_screen2D(vec2 fragPx) {
    // Grid the screen in pixel cells, place at most one star per cell
    vec2 grid = fragPx / star_cell_px;
    vec2 cell = floor(grid);
    vec2 f    = fract(grid);

    float h   = hash21(cell);

    // Decide if this cell has a star (probability = star_density)
    float hasStar = step(1.0 - star_density, h);

    // Random sub-cell center (stable per cell)
    float hx = fract(h * 17.0);
    float hy = fract(h * 29.0);
    vec2  c  = vec2(hx, hy);

    // Pixel-space distances for anti-aliased core + halo
    // Convert normalized cell coords back to pixels
    vec2  fpix = (f - c) * star_cell_px;
    float d    = length(fpix);

    // Temporal twinkle
    float tw = 0.3 + 0.3*sin(time*0.5*(1+0.5*sin(h*99)) + h*8.0 + 99);

    // Smooth core and softer halo
    float aa    = fwidth(d) + 1e-4;
    float core  = smoothstep(star_core_px + aa, star_core_px - aa, d);
    float halo  = smoothstep(star_halo_px + aa, star_halo_px - aa, d) * 0.35;

    float intensity = (core + halo) * tw * star_brightness;

    return hasStar * intensity * vec3(1.0);
}

// ---------- 2D Mist via Brownian motion (fBM) ----------
// Value noise (hashed corners + smooth bilinear)
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0 - 2.0*f); // smoothstep
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    // Classic Brownian motion: sum of octaves with halving amplitude & doubling freq
    float amp = 0.5;
    float sum = 0.0;
    mat2 R = mat2( cos(0.5), -sin(0.5),
                   sin(0.5),  cos(0.5));
    for (int i = 0; i < 5; ++i) {
        sum += amp * valueNoise(p);
        p = R * p * 2.0;
        amp *= 0.5;
    }
    return sum;
}

// Domain-warped fBM for organic, drifting mist
float mistField(vec2 p_px, vec2 uv_ndc) {
    // Normalize to a grid in "pixels per cell"
    vec2 p = p_px / mist_scale_px;

    // Base advection (Brownian drift)
    vec2 flow = vec2(0.2, -0.5) * mist_speed * time;

    // First layer
    float q  = fbm(p + flow);
    // Domain warp (curl-like look using perpendicular mix)
    vec2  w1 = vec2(fbm(p + vec2( 1.7, 9.2) + flow),
                    fbm(p + vec2(-8.3, 2.8) - flow));
    float r  = fbm(p + 2.0*w1 + flow*0.5 + vec2(q, -q));

    // Shape it: emphasize soft wisps, bias to screen bottom if requested
    float bottomMask = mix(1.0, smoothstep(0.9, -0.2, uv_ndc.y), mist_bottom_bias);
    float m = pow(smoothstep(0.2, 0.95, r), 2.0) * bottomMask;

    // Tiny flutter so it doesn't feel static
    m *= 0.98 + 0.02*sin(time*0.6 + r*20.0);

    return clamp(m, 0.0, 1.0);
}

vec3 mist_screen2D(vec2 fragPx, vec2 uv_ndc) {
    float m = mistField(fragPx, uv_ndc);
    return mist_color * (m * mist_strength);
}

// ---------- Main (Love2D effect) ----------
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Screen -> NDC
    vec2 uv = screen_coords.xy / love_ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    // Camera & ray (same pipeline as your terrain shader)
    float fov = -1.3;
    if (flat_) {
        fov = fov + 0.00001; // avoid flat_ be optimized
    }
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 rd_screen  = normalize(vec3(uv.x, uv.y, fov));
    vec4 rd_T0      = vec4(rd_screen, 0.0);

    mat4 M_rot = mat4(1.0);
    M_rot = create_rotation_lorentz_matrix(cam_rotation_axis2, cam_yaw)   * M_rot;
    M_rot = create_rotation_lorentz_matrix(cam_rotation_axis1, cam_pitch) * M_rot;
    M_rot = create_rotation_lorentz_matrix(cam_rotation_axis3, cam_roll)  * M_rot;

    mat4 M_boost = create_boost_lorentz_matrix(vec3(1,0,0), cam_translation.x)
                 * create_boost_lorentz_matrix(vec3(0,1,0), cam_translation.y)
                 * create_boost_lorentz_matrix(vec3(0,0,1), cam_translation.z);

    mat4 M_total = M_boost * M_rot;

    vec4 cam_pos_H = M_total * cam_pos_H0;
    vec4 ray_dir_H = M_total * rd_T0;

    // Dreamy “sky” backdrop (we fog toward this)
    vec3 base = mix(vec3(0.06, 0.05, 0.10), vec3(0.12, 0.10, 0.18), uv.y*0.5+0.5);

    // Three boosted planes (z′=0 in their own -Z-boosted frames)
    float t1; vec3 c1 = shade_plane_boostedZ0(cam_pos_H, ray_dir_H,
                    plane_eta.x,
                    1.00,
                    line_wobble*1.00, line_width*1.00, line_glow, t1);

    float t2; vec3 c2 = shade_plane_boostedZ0(cam_pos_H, ray_dir_H,
                    plane_eta.y,
                    1.00,
                    line_wobble*0.85, line_width*0.85, line_glow*1.1, t2);

    float t3; vec3 c3 = shade_plane_boostedZ0(cam_pos_H, ray_dir_H,
                    plane_eta.z,
                    1.00,
                    line_wobble*0.70, line_width*0.75, line_glow*1.2, t3);

    // Additive accumulation of red dream-lines
    vec3 accum = base + c1 + c2 + c3;


    // screen-space stars (2D)
    vec3 starCol = stars_screen2D(screen_coords.xy);
    accum += starCol;

    // blue mist (2D)
    accum += mist_screen2D(screen_coords.xy, uv);

    // Gentle vignette
    // float r2 = dot(uv, uv);
    // accum *= smoothstep(1.4, 0.2, r2);

    return vec4(accum, 1.0) * color;
}
