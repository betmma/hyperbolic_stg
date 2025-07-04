// hyperbolic rotation using Mobius transformation
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifndef HYPERBOLIC_EPS
#define HYPERBOLIC_EPS 1e-5f // A small epsilon for float comparisons
#endif

// Uniforms that will be used by the new 'position' function:
uniform vec2 player_pos;       // Center of rotation
uniform float rotation_angle;   // Angle of rotation in radians
uniform float shape_axis_y;     // Y-coordinate of the hyperbolic plane's boundary axis

// Helper function for complex number multiplication: (a.x + i*a.y) * (b.x + i*b.y)
vec2 complex_mul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

// New function for hyperbolic rotation using Mobius transformation
vec2 hyperbolically_rotate_point_mobius(vec2 point_to_rotate, vec2 center_of_rotation, float angle_rad, float axisY) {
    // 1. Shift coordinates so the boundary axis (y=axisY) becomes y'=0.
    //    pt' = point_to_rotate - vec2(0.0, axisY)
    //    p_center' = center_of_rotation - vec2(0.0, axisY)
    vec2 pt_prime = vec2(point_to_rotate.x, point_to_rotate.y - axisY);
    vec2 p_center_prime = vec2(center_of_rotation.x, center_of_rotation.y - axisY);

    // --- Validity Checks ---
    // Center of rotation must be strictly in the upper half-plane (p_center_prime.y > 0).
    if (p_center_prime.y <= HYPERBOLIC_EPS) {
        // Rotation around a point on or below the axis is ill-defined for an elliptic isometry.
        // Return the original point as a safe fallback.
        return point_to_rotate;
    }
    // The point to be rotated should also ideally be in the upper half-plane.
    if (pt_prime.y <= HYPERBOLIC_EPS) {
        // If the point is on or below the boundary, its rotation within the UHP model is problematic.
        return point_to_rotate;
    }

    // --- Handle Zero Rotation ---
    // If angle_rad is very close to a multiple of 2*PI, it's effectively no rotation.
    float cos_a = cos(angle_rad);
    float sin_a = sin(angle_rad);
    if (abs(sin_a) < HYPERBOLIC_EPS && abs(cos_a - 1.0) < HYPERBOLIC_EPS) {
        return point_to_rotate; // No rotation
    }
    vec2 rot_complex = vec2(cos_a, sin_a); // R = e^(i * angle_rad)

    // --- Mobius Transformation Coefficients ---
    // T(z') = (a_coeff*z' + b_coeff) / (c_coeff*z' + d_coeff)
    // p' is p_center_prime (complex number)
    // q' is reflection of p' across y'=0 axis: (p_center_prime.x, -p_center_prime.y)
    vec2 q_center_prime = vec2(p_center_prime.x, -p_center_prime.y);

    // a_coeff = R*q' - p'
    vec2 a_coeff = complex_mul(rot_complex, q_center_prime) - p_center_prime;
    
    // b_coeff = (1-R)*p'*q'
    // Note: p'*q' = (x_p', y_p')*(x_p', -y_p') = (x_p'^2 + y_p'^2, 0) = (dot(p',p'), 0)
    vec2 one_complex = vec2(1.0, 0.0);
    vec2 one_minus_R = one_complex - rot_complex;
    vec2 p_prime_times_q_prime = vec2(dot(p_center_prime, p_center_prime), 0.0);
    vec2 b_coeff = complex_mul(one_minus_R, p_prime_times_q_prime);

    // c_coeff = R - 1
    vec2 c_coeff = rot_complex - one_complex;
    
    // d_coeff = q' - R*p'
    vec2 d_coeff = q_center_prime - complex_mul(rot_complex, p_center_prime);

    // --- Apply Transformation ---
    // Numerator: a_coeff * pt_prime + b_coeff
    vec2 num = complex_mul(a_coeff, pt_prime) + b_coeff;
    // Denominator: c_coeff * pt_prime + d_coeff
    vec2 den = complex_mul(c_coeff, pt_prime) + d_coeff;

    float den_sq_mag = dot(den, den); // Squared magnitude of the denominator

    if (den_sq_mag < HYPERBOLIC_EPS * HYPERBOLIC_EPS) { // Compare with EPS^2
        // This case implies pt_prime is at or very near the pole of the Mobius transformation.
        // For a valid elliptic isometry (rotation) with center in UHP, the pole is not in UHP.
        // Hitting this might be due to extreme coordinates or floating-point precision issues.
        // Fallback to the original point is a safe option.
        return point_to_rotate;
    }

    // Perform complex division: num / den
    // (num * conjugate(den)) / |den|^2
    vec2 rotated_pt_prime = vec2(num.x * den.x + num.y * den.y,   // Real part
                                 num.y * den.x - num.x * den.y) / den_sq_mag; // Imaginary part

    // 5. Shift coordinates back to the original system: result_prime + vec2(0.0, axisY)
    return vec2(rotated_pt_prime.x, rotated_pt_prime.y + axisY);
}

// The main 'position' function, updated to use the Mobius transformation method.
// It expects 'player_pos', 'rotation_angle', and 'shape_axis_y' as uniforms.
vec4 position(mat4 transform_projection, vec4 vertex_pos) {
    vec2 current_pos_euclidean = vec2(vertex_pos.x, vertex_pos.y);
    
    // Call the new rotation function.
    // player_pos, rotation_angle, shape_axis_y must be provided as uniforms.
    vec2 rotated_pos_euclidean = hyperbolically_rotate_point_mobius(
        current_pos_euclidean, 
        player_pos,         // uniform vec2 player_pos;
        rotation_angle,     // uniform float rotation_angle;
        shape_axis_y        // uniform float shape_axis_y;
    );
    
    return transform_projection * vec4(rotated_pos_euclidean.x, rotated_pos_euclidean.y, 0.0, 1.0);

    // vec2 z_prime = vec2(rotated_pos_euclidean.x, rotated_pos_euclidean.y - shape_axis_y);
    // vec2 z0_prime = vec2(player_pos.x, player_pos.y - shape_axis_y);

    // vec2 z0_prime_conj = vec2(z0_prime.x, -z0_prime.y);
    // vec2 numerator = z_prime - z0_prime;
    // vec2 denominator = z_prime - z0_prime_conj;
    // // map to disk coordinates
    // float denominator_sq = dot(denominator, denominator);
    // vec2 w = vec2((numerator.x * denominator.x + numerator.y * denominator.y) / denominator_sq,
    //                 (numerator.y * denominator.x - numerator.x * denominator.y) / denominator_sq);
    // // Convert to screen coordinates
    // vec2 screen_size = vec2(800.0, 600.0); // Example screen size, replace with actual uniform if needed
    // float r= 0.5 * min(screen_size.x, screen_size.y);
    // vec2 screen_pos = vec2(screen_size.x / 2 + w.x * r, screen_size.y/2 + w.y * r);

    // return transform_projection * vec4(screen_pos, 0.0, 1.0);
}