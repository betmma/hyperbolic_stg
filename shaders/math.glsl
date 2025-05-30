float cosh(float x) { return (exp(x) + exp(-x)) / 2.0; }
float sinh(float x) { return (exp(x) - exp(-x)) / 2.0; }
float acosh(float x) { if (x < 1.0) return 0.0; return log(x + sqrt(x * x - 1.0)); } 
const float PI = 3.1415926535;
const float EPSILON = 1e-7;

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

vec2 hyperboloid_to_uhp(vec2 pos_xy_embedding) {
    float x_H = pos_xy_embedding.x;
    float y_H = pos_xy_embedding.y;

    // 1. Calculate w_H0 for the point (x_H, y_H) on the z_H=0 sheet
    // w_H0^2 - x_H^2 - y_H^2 = 1  => w_H0 = sqrt(1 + x_H^2 + y_H^2)
    float w_H0 = sqrt(1.0 + x_H*x_H + y_H*y_H);

    // 2. Convert to Poincaré disk coordinates (x_d, y_d)
    // (1.0 + w_H0) is always >= 2.0 since w_H0 >= 1.0, so no division by zero.
    float inv_denom_disk = 1.0 / (1.0 + w_H0);
    float x_d = x_H * inv_denom_disk;
    float y_d = y_H * inv_denom_disk;

    // 3. Convert from Poincaré disk (x_d, y_d) to UHP (u,v)
    // Denominator for UHP mapping: D_uhp = (1-x_d)^2 + y_d^2
    float D_uhp_denom = (1.0-x_d)*(1.0-x_d) + y_d*y_d;

    float u, v;
    if (D_uhp_denom < EPSILON) {
        // This case corresponds to x_d approx 1 and y_d approx 0 (rightmost point of disk boundary),
        // which maps to complex infinity.
        // Handle this by returning a point far away or a default value.
        // For terrain, this might mean an "undefined" or very distant UHP coordinate.
        // A large v value could work if your tessellation handles distant points gracefully.
        u = 0.0; // Arbitrary, as v will dominate
        v = 1.0 / EPSILON; // Very large v
    } else {
        u = -2.0 * y_d / D_uhp_denom;
        v = (1.0 - x_d*x_d - y_d*y_d) / D_uhp_denom;
    }

    // Ensure v is strictly positive for UHP, clamping if it's too close to zero
    // (e.g., due to floating point inaccuracies for points near the disk boundary).
    v = max(v, EPSILON);

    return vec2(u, v);
}
