uniform float shape_axis_y;

uniform vec2 V0; 
uniform vec2 V1;
uniform vec2 V2;

// Texture UVs corresponding to each vertex of the fundamental triangle
uniform vec2 tex_uv_V0;
uniform vec2 tex_uv_V1;
uniform vec2 tex_uv_V2;

// --- Constants ---
const float PI = 3.1415926535;
const int MAX_REFLECTIONS = 40; 
const float EPSILON = 1e-7;     // Small number for float comparisons & boundary checks

// --- Struct for UHP Geodesic ---
struct UHPGeodesic {
    bool is_vertical_line;
    float x_coord;     // x-coordinate if vertical line
    float center_x;    // x-coordinate of circle center if semicircle
    float radius_sq;   // radius squared if semicircle
};

// --- Helper Functions (identical to previous shader) ---

UHPGeodesic make_geodesic_segment(vec2 z1, vec2 z2) {
    UHPGeodesic g;
    if (abs(z1.x - z2.x) < EPSILON) {
        g.is_vertical_line = true;
        g.x_coord = z1.x;
        g.center_x = 0.0; 
        g.radius_sq = 0.0;
    } else { 
        g.is_vertical_line = false;
        g.center_x = ( (z2.x*z2.x + z2.y*z2.y) - (z1.x*z1.x + z1.y*z1.y) ) / (2.0 * (z2.x - z1.x));
        g.x_coord = 0.0; 
        g.radius_sq = (z1.x - g.center_x)*(z1.x - g.center_x) + z1.y*z1.y;
        if (g.radius_sq < 0.0) g.radius_sq = 0.0; 
    }
    return g;
}

float signed_dist_to_geodesic(vec2 p, UHPGeodesic g) {
    if (g.is_vertical_line) {
        return p.x - g.x_coord;
    } else {
        return (p.x - g.center_x)*(p.x - g.center_x) + p.y*p.y - g.radius_sq;
    }
}

bool is_on_correct_side_of_edge(vec2 p, UHPGeodesic edge_geodesic, vec2 third_vertex_of_triangle) {
    float p_signed_dist = signed_dist_to_geodesic(p, edge_geodesic);
    float ref_signed_dist = signed_dist_to_geodesic(third_vertex_of_triangle, edge_geodesic);
    
    if (abs(ref_signed_dist) < EPSILON) { 
        return true; 
    }
    return p_signed_dist * sign(ref_signed_dist) >= -EPSILON;
}

vec2 reflect_point(vec2 p, UHPGeodesic g) {
    if (p.y <= EPSILON) return p; 

    if (g.is_vertical_line) {
        return vec2(2.0 * g.x_coord - p.x, p.y);
    } else { 
        float dx = p.x - g.center_x;
        float dy = p.y;
        float norm_sq = dx*dx + dy*dy; 

        if (norm_sq < EPSILON*EPSILON || g.radius_sq < EPSILON*EPSILON) { 
            return p; 
        }
        float factor = g.radius_sq / norm_sq;
        vec2 reflected_p = vec2(g.center_x + dx * factor, dy * factor);
        if (reflected_p.y <= EPSILON) return p;
        return reflected_p;
    }
}

vec2 mobius_transform_vertex_to_i(vec2 z_other, vec2 P_vertex) {
    // P_vertex.y is assumed to be > EPSILON.
    // This is generally true for points in UHP and after clamping in the main loop.
    return vec2((z_other.x - P_vertex.x) / P_vertex.y, z_other.y / P_vertex.y);
}

// Calculates the hyperbolic angle at P_angle_vertex for triangle (P_angle_vertex, P_other1, P_other2).
// Assumes P_angle_vertex, P_other1, P_other2 are distinct and form a non-degenerate triangle in UHP.
float calculate_hyperbolic_angle_at_vertex(vec2 P_angle_vertex, vec2 P_other1, vec2 P_other2) {
    // Transform P_other1 and P_other2 such that P_angle_vertex maps to i (0,1).
    vec2 Q_prime = mobius_transform_vertex_to_i(P_other1, P_angle_vertex);
    vec2 R_prime = mobius_transform_vertex_to_i(P_other2, P_angle_vertex);

    vec2 tangent_at_i_to_Q_prime; // Normalized tangent vector at i for geodesic i-Q'
    vec2 tangent_at_i_to_R_prime; // Normalized tangent vector at i for geodesic i-R'

    // --- Calculate tangent for geodesic i-Q' ---
    // This geodesic connects (0,1) to Q_prime.
    // Since P_angle_vertex, P_other1, P_other2 are distinct, Q_prime is not (0,1).

    // Case 1: Q_prime is on the transformed imaginary axis (Q_prime.x is zero).
    if (abs(Q_prime.x) < EPSILON) {
        // Geodesic is the imaginary axis. Tangent at i is vertical.
        // Direction depends on whether Q_prime.y is above or below 1.0 (y-coord of i).
        tangent_at_i_to_Q_prime = vec2(0.0, sign(Q_prime.y - 1.0));
    }
    // Case 2: Q_prime is not on the transformed imaginary axis.
    else {
        // Geodesic is a semicircle centered on the real axis.
        // The slope of the tangent to this semicircle at i=(0,1) is c_slope.
        float c_slope = (Q_prime.x*Q_prime.x + Q_prime.y*Q_prime.y - 1.0) / (2.0 * Q_prime.x);
        
        // The unnormalized tangent vector can be represented as (1.0, c_slope).
        // To ensure it points towards the side where Q_prime.x lies:
        // if Q_prime.x > 0, use (1.0, c_slope)
        // if Q_prime.x < 0, use (-1.0, -c_slope)
        vec2 unnormalized_tangent = vec2(1.0, c_slope);
        if (Q_prime.x < 0.0) {
            unnormalized_tangent = -unnormalized_tangent; // equivalent to vec2(-1.0, -c_slope)
        }
        tangent_at_i_to_Q_prime = normalize(unnormalized_tangent);
    }

    // --- Calculate tangent for geodesic i-R' (similar logic) ---
    if (abs(R_prime.x) < EPSILON) {
        tangent_at_i_to_R_prime = vec2(0.0, sign(R_prime.y - 1.0));
    } else {
        float c_slope = (R_prime.x*R_prime.x + R_prime.y*R_prime.y - 1.0) / (2.0 * R_prime.x);
        vec2 unnormalized_tangent = vec2(1.0, c_slope);
        if (R_prime.x < 0.0) {
            unnormalized_tangent = -unnormalized_tangent;
        }
        tangent_at_i_to_R_prime = normalize(unnormalized_tangent);
    }
    
    // The angle is acos of the dot product of the normalized tangent vectors.
    float dot_product = dot(tangent_at_i_to_Q_prime, tangent_at_i_to_R_prime);
    // Clamp dot_product to avoid acos domain errors due to floating point inaccuracies.
    return acos(clamp(dot_product, -1.0, 1.0));
}

// Calculates the hyperbolic area of triangle (P1, P2, P3).
// All points are vec2 in UHP.
float get_hyperbolic_triangle_area(vec2 P1, vec2 P2, vec2 P3) {
    // Handle degenerate triangles (coincident vertices) by returning 0 area.
    // Uses squared Euclidean distance for the coincidence check.
    float dist_sq_P1P2 = dot(P1-P2, P1-P2);
    float dist_sq_P2P3 = dot(P2-P3, P2-P3);
    float dist_sq_P3P1 = dot(P3-P1, P3-P1);

    // If any two points are effectively coincident, the area is 0.
    if (dist_sq_P1P2 < EPSILON*EPSILON || dist_sq_P2P3 < EPSILON*EPSILON || dist_sq_P3P1 < EPSILON*EPSILON) {
        return 0.0;
    }

    // Calculate the three interior angles of the hyperbolic triangle.
    float angle1 = calculate_hyperbolic_angle_at_vertex(P1, P2, P3);
    float angle2 = calculate_hyperbolic_angle_at_vertex(P2, P3, P1);
    float angle3 = calculate_hyperbolic_angle_at_vertex(P3, P1, P2);

    // Hyperbolic area by Gauss-Bonnet theorem: Area = PI - (sum of interior angles).
    float sum_angles = angle1 + angle2 + angle3;
    float area = PI - sum_angles;

    // Area must be non-negative. Hyperbolic triangles always have sum_angles < PI.
    // If area is slightly negative due to precision errors, clamp it to 0.
    return max(area, 0.0);
}

// Calculates hyperbolic barycentric coordinates of point P w.r.t. triangle (V0, V1, V2).
// P is assumed to be inside or on the boundary of the triangle V0V1V2.
// All points are vec2 in UHP.
vec3 get_hyperbolic_barycentric_coords(vec2 P, vec2 V0, vec2 V1, vec2 V2) {
    // Barycentric coordinates (w0, w1, w2) are ratios of hyperbolic areas:
    // w0 = Area_h(P, V1, V2) / Area_h(V0, V1, V2) for vertex V0
    // w1 = Area_h(P, V0, V2) / Area_h(V0, V1, V2) for vertex V1
    // w2 = Area_h(P, V0, V1) / Area_h(V0, V1, V2) for vertex V2

    // Calculate areas of the three sub-triangles formed by P and pairs of vertices.
    float area_PV1V2 = get_hyperbolic_triangle_area(P, V1, V2); // Sub-triangle opposite V0
    float area_PV0V2 = get_hyperbolic_triangle_area(P, V0, V2); // Sub-triangle opposite V1
    float area_PV0V1 = get_hyperbolic_triangle_area(P, V0, V1); // Sub-triangle opposite V2

    // Calculate the total area of the fundamental triangle V0V1V2.
    // OPTIMIZATION: This area is constant for all pixels if V0,V1,V2 are uniforms.
    // It can be pre-calculated (e.g., on CPU or once in a vertex shader)
    // and passed as a uniform: `uniform float inv_total_hyperbolic_area_V0V1V2;`
    // Then: w0 = area_PV1V2 * inv_total_hyperbolic_area_V0V1V2; etc.
    float total_area_V0V1V2 = get_hyperbolic_triangle_area(V0, V1, V2);

    // If the fundamental triangle is degenerate (e.g., collinear vertices, very small area),
    // hyperbolic barycentric coordinates are ill-defined or unstable.
    if (total_area_V0V1V2 < EPSILON * EPSILON) { // Using a small threshold for area
        // Fallback to Euclidean barycentric coordinates (requires original `get_barycentric_coords` to exist).
        // Alternatively, return a default like (1/3, 1/3, 1/3) or signal an error.
        return vec3(1/3, 1/3, 1/3); // Original Euclidean function
    }

    float w0 = area_PV1V2 / total_area_V0V1V2;
    float w1 = area_PV0V2 / total_area_V0V1V2;
    float w2 = area_PV0V1 / total_area_V0V1V2;
    
    // The sum w0+w1+w2 should ideally be 1.0.
    // The main shader body (effect function) already has robust normalization and clamping
    // for the final bary_coords, which will handle any minor deviations.
    return vec3(w0, w1, w2);
}

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

