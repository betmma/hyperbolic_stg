#include "shaders/H2math.glsl"

uniform float shape_axis_y;

uniform vec2 V0; 
uniform vec2 V1;
uniform vec2 V2;

// Texture UVs corresponding to each vertex of the fundamental triangle
uniform vec2 tex_uv_V0;
uniform vec2 tex_uv_V1;
uniform vec2 tex_uv_V2;

// --- Constants ---
const int MAX_REFLECTIONS = 40; 

// --- Main Shader Function (Love2D pixel shader) ---
// `Texel(texture, uv)` is Love2D's equivalent of `texture2D(texture, uv)`
// `texture_coords` (from Love2D `effect` signature) are screen UVs [0,1] for a full-screen pass.
vec4 effect(vec4 pixel_color, Image input_texture, vec2 texture_coords, vec2 pixel_coords_px) {
    // 1. expect the texture be same size as screen and drawn at (0,0) position (so full cover)
    vec2 p;
    p.x = (texture_coords.x) * love_ScreenSize.x;
    p.y = (texture_coords.y) * love_ScreenSize.y - shape_axis_y; 

    vec2 V0m = V0 - vec2(0.0, shape_axis_y); // translation so axis_y is 0 for code below
    vec2 V1m = V1 - vec2(0.0, shape_axis_y);
    vec2 V2m = V2 - vec2(0.0, shape_axis_y);

    // 2. Define fundamental triangle geodesics from its vertices
    UHPGeodesic G01 = make_geodesic_segment(V0m, V1m);
    UHPGeodesic G12 = make_geodesic_segment(V1m, V2m);
    UHPGeodesic G20 = make_geodesic_segment(V2m, V0m);

    // 3. Reflection loop
    vec2 p_in_fundamental = p;
    for (int i = 0; i < MAX_REFLECTIONS; ++i) {
        bool reflected_in_iter = false;
        if (!is_on_correct_side_of_edge(p_in_fundamental, G01, V2m)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G01);
            reflected_in_iter = true;
        }
        if (!is_on_correct_side_of_edge(p_in_fundamental, G12, V0m)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G12);
            reflected_in_iter = true;
        }
        if (!is_on_correct_side_of_edge(p_in_fundamental, G20, V1m)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G20);
            reflected_in_iter = true;
        }

        if (p_in_fundamental.y <= EPSILON * 0.1) { // Point escaped far below
             return vec4(0.0, 0.0, 0.0, 1.0); 
        }
        if (p_in_fundamental.y <= EPSILON && p_in_fundamental.y > EPSILON * 0.1) { // Point very close to boundary
             p_in_fundamental.y = EPSILON; // clamp it
        }
        
        if (!reflected_in_iter) {
            break; 
        }
        if (i == MAX_REFLECTIONS - 1) { 
            return vec4(1.0, 0.0, 1.0, 1.0); // Magenta for non-convergence
        }
    }
    if (p_in_fundamental.y <= EPSILON) { return vec4(0.05, 0.0, 0.0, 1.0); }


    // 4. Calculate barycentric coordinates
    vec3 bary_coords = get_hyperbolic_barycentric_coords(p_in_fundamental, V0m, V1m, V2m);

    bary_coords = clamp(bary_coords, 0.0, 1.0);
    float sum_bary = bary_coords.x + bary_coords.y + bary_coords.z;
    if (sum_bary > EPSILON) {
        bary_coords /= sum_bary;
    } else { 
        if (distance(p_in_fundamental, V0m) < EPSILON) bary_coords = vec3(1,0,0);
        else if (distance(p_in_fundamental, V1m) < EPSILON) bary_coords = vec3(0,1,0);
        else if (distance(p_in_fundamental, V2m) < EPSILON) bary_coords = vec3(0,0,1);
        else bary_coords = vec3(1.0/3.0, 1.0/3.0, 1.0/3.0);
    }

    // 5. Interpolate texture UVs
    vec2 final_texture_uv = bary_coords.x * tex_uv_V0 +
                            bary_coords.y * tex_uv_V1 +
                            bary_coords.z * tex_uv_V2;

    // 6. Sample the input texture
    return Texel(input_texture, final_texture_uv) * pixel_color;
}

