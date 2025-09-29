#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

uniform bool flat_=false;
uniform vec2 V0;
uniform vec2 V1;
uniform vec2 V2;
uniform float time=0.0;

uniform vec3 cam_rotation_axis1 = vec3(1.0, 0.0, 0.0);
uniform float cam_pitch = 0.0;
uniform vec3 cam_rotation_axis2 = vec3(0.0, 1.0, 0.0);
uniform float cam_yaw = 0.0;
uniform vec3 cam_rotation_axis3 = vec3(0.0, 0.0, 1.0);
uniform float cam_roll = 0.0;
uniform vec3 cam_translation = vec3(0.0, 0.0, 1.0);

const int FACE_COUNT = 12;
const vec4 FACE_NORMALS[FACE_COUNT] = vec4[](
    vec4(0.0, -1.144122805635, -0.707106781187, 0.899453719974),
    vec4(-0.707106781187, 0.0, -1.144122805635, 0.899453719974),
    vec4(-1.144122805635, -0.707106781187, 0.0, 0.899453719974),
    vec4(0.0, -1.144122805635, 0.707106781187, 0.899453719974),
    vec4(-0.707106781187, 0.0, 1.144122805635, 0.899453719974),
    vec4(-1.144122805635, 0.707106781187, 0.0, 0.899453719974),
    vec4(0.0, 1.144122805635, -0.707106781187, 0.899453719974),
    vec4(0.0, 1.144122805635, 0.707106781187, 0.899453719974),
    vec4(0.707106781187, 0.0, -1.144122805635, 0.899453719974),
    vec4(1.144122805635, -0.707106781187, 0.0, 0.899453719974),
    vec4(0.707106781187, 0.0, 1.144122805635, 0.899453719974),
    vec4(1.144122805635, 0.707106781187, 0.0, 0.899453719974)
);
const int OPPOSITE_FACE[FACE_COUNT] = int[](7, 10, 11, 6, 8, 9, 3, 0, 4, 5, 1, 2);
const float CELL_INRADIUS = 0.808460833756;
const float CELL_CIRCUMRADIUS = 1.226456871000;
const float CELL_SHELL_DIST = 0.5 * (CELL_INRADIUS + CELL_CIRCUMRADIUS);
const float MAX_HYP_DIST = 9.5;
const float STEP_MIN = 0.02;
const float STEP_MAX = 0.9;
const float STEP_FACTOR = 0.72;

float mdot4(vec4 a, vec4 b) {
    return -dot(a.xyz, b.xyz) + a.w*b.w;
}

float acosh1(float x) { return log(x + sqrt(max(0.0, x*x - 1.0))); }
float asinh1(float x) { return log(x + sqrt(x*x + 1.0)); }

vec4 normalize_spacelike(vec4 v) {
    float n2 = -mdot4(v, v);
    return v / sqrt(max(n2, 1e-6));
}

vec4 project_to_tangent(vec4 p, vec4 v) {
    return v - mdot4(p, v) * p;
}

void geodesic_step(vec4 pos, vec4 dir, float t, out vec4 pos_out, out vec4 dir_out) {
    float ch = cosh(t);
    float sh = sinh(t);
    pos_out = ch * pos + sh * dir;
    dir_out = sh * pos + ch * dir;
}

float plane_signed(vec4 pos, vec4 plane) {
    return mdot4(pos, plane);
}

vec4 reflect_plane(vec4 v, vec4 plane) {
    float m = mdot4(v, plane);
    return v + 2.0 * m * plane;
}

void renormalize_state(inout vec4 pos, inout vec4 dir) {
    float pos_norm = sqrt(max(mdot4(pos, pos), 1e-6));
    pos /= pos_norm;
    dir = project_to_tangent(pos, dir);
    dir = normalize_spacelike(dir);
}

void wrap_inside_cell(inout vec4 pos, inout vec4 dir) {
    for (int iteration = 0; iteration < 4; ++iteration) {
        bool adjusted = false;
        for (int i = 0; i < FACE_COUNT; ++i) {
            if (plane_signed(pos, FACE_NORMALS[i]) <= 0.0) {
                pos = reflect_plane(pos, FACE_NORMALS[i]);
                dir = reflect_plane(dir, FACE_NORMALS[i]);
                adjusted = true;
            }
        }
        dir = project_to_tangent(pos, dir);
        dir = normalize_spacelike(dir);
        if (!adjusted) {
            break;
        }
    }
}

vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time);

vec3 rayMarch(vec4 cam_pos_H, vec4 ray_dir_H, float time, out bool hit_terrain) {
    hit_terrain = false;
    vec4 pos = cam_pos_H;
    vec4 dir = normalize_spacelike(project_to_tangent(pos, ray_dir_H));
    wrap_inside_cell(pos, dir);

    vec3 accum = vec3(0.08, 0.09, 0.14);
    float travel = 0.0;
    for (int step = 0; step < 72; ++step) {
        float shellDist = acosh1(max(pos.w, 1.0));
        if (shellDist > CELL_SHELL_DIST) {
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
        dt = min(dt, CELL_SHELL_DIST - shellDist);
        if (dt <= 0.000005) break;

        vec3 sampleColor = honeycomb_shade(pos, dir, travel, time);
        accum = sampleColor;

        float remaining = dt;
        for (int guard = 0; guard < 4 && remaining > 0.0005; ++guard) {
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
                    for (int iter = 0; iter < 5; ++iter) {
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
    }
    return accum;
}

vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time) {
    float distanceToCenter = acosh1(max(pos.w, 1.0));
    vec3 normalxyz = pos.xyz / sinh(distanceToCenter) * cosh(distanceToCenter);
    vec4 normal = vec4(normalxyz, sinh(distanceToCenter));
    float edgeGlow = 0.5*(1.0 + dot(dir, normal));
    float wave = 0.5 + 0.5 * sin(time * 0.45 + travel * 1.2 + pos.w * 0.6);
    vec3 base = mix(vec3(0.05, 0.09, 0.15), vec3(0.82, 0.68, 0.44), edgeGlow);
    base += 0.15 * wave * vec3(0.2, 0.35, 0.6);
    return base*exp(-0.45*travel);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords.xy / love_ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float field_of_view_factor = -1.3;
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, field_of_view_factor));
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0);

    mat4 M_rotation_component = mat4(1.0);
    M_rotation_component = create_rotation_lorentz_matrix(cam_rotation_axis2, cam_yaw) * M_rotation_component;
    M_rotation_component = create_rotation_lorentz_matrix(cam_rotation_axis1, cam_pitch) * M_rotation_component;
    M_rotation_component = create_rotation_lorentz_matrix(cam_rotation_axis3, cam_roll) * M_rotation_component;

    mat4 M_boost_component = create_boost_lorentz_matrix(vec3(1,0,0), cam_translation.x)
        * create_boost_lorentz_matrix(vec3(0,1,0), cam_translation.y)
        * create_boost_lorentz_matrix(vec3(0,0,1), cam_translation.z);

    mat4 M_total = M_boost_component * M_rotation_component;
    vec4 final_cam_pos_H = M_total * cam_pos_H0;
    vec4 final_ray_dir_H = M_total * rd_T0;

    bool terrain_was_hit;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, terrain_was_hit);

    return vec4(fragment_color, 1.0) * color;
}
