#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"
#include "shaders/honeycombMath.glsl"

uniform bool inverse=false; // when false, a ball of CELL_SHELL_DIST radius is cut out from solid honeycomb; when true, only the ball is solid
uniform float time=0.0;

uniform mat4 cam_mat4; // combined rotation and boost matrix

uniform float SHELL_RATIO = 0.5; // 0.38 for small gap at edge
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
    for (int step = 0; step < 96; ++step) {
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

vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time) {
    float distanceToCenter = acosh1(max(pos.w, 1.0));
    if (!inverse && distanceToCenter < CELL_SHELL_DIST-0.001 || inverse && distanceToCenter > CELL_SHELL_DIST+0.001){
        return vec3(0.08, 0.09, 0.14) * exp(-0.2*travel);
    }
    vec3 normalxyz = pos.xyz / sinh(distanceToCenter) * cosh(distanceToCenter);
    vec4 normal = vec4(normalxyz, sinh(distanceToCenter));
    float light = dot(dir, normal);
    if (inverse) light = -light;
    float edgeGlow = 0.5*(1.0 + light);
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

    vec4 final_cam_pos_H = cam_mat4 * cam_pos_H0;
    vec4 final_ray_dir_H = cam_mat4 * rd_T0;

    bool terrain_was_hit;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, terrain_was_hit);

    return vec4(fragment_color, 1.0) * color;
}
