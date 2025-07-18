
#define HYPERBOLIC_MODEL_UHP 0
#define HYPERBOLIC_MODEL_P_DISK 1
#define HYPERBOLIC_MODEL_K_DISK 2

#ifndef HYPERBOLIC_EPS
#define HYPERBOLIC_EPS 1e-5f // A small epsilon for float comparisons
#endif
// Helper function for complex number multiplication: (a.x + i*a.y) * (b.x + i*b.y)
vec2 complex_mul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

// 1. rotate point around another point in uhp. used to handle player's natural direction rotation
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

// 2. Transform the uhp position to make the player at aim position (usually center of the screen)
vec2 Transform2MakePlayerAtAimPos(vec2 pos, vec2 player_pos, vec2 aim_pos, float axisY) {
    // Transform the position to make the player at aim position
    vec2 screen_size = love_ScreenSize.xy; 
    pos.y -= axisY;
    float zoom = (aim_pos.y - axisY) / (player_pos.y - axisY);
    pos.y *= zoom;
    pos.y += axisY;
    pos.x = (pos.x - player_pos.x) * zoom + aim_pos.x;
    return pos;
}

// 3. Convert the position to the other hyperbolic model (UHP, P-Disk, K-Disk)
vec2 Convert2OtherModel(vec2 pos, float axisY, float rFactor, int hyperbolic_model) {
    if (hyperbolic_model == HYPERBOLIC_MODEL_UHP) {
        return pos; // No conversion needed for UHP
    }
    vec2 screen_size = love_ScreenSize.xy; 
    vec2 z_prime = vec2(pos.x, pos.y - axisY);
    vec2 z0_prime = vec2(screen_size.x/2, screen_size.y/2 - axisY);

    vec2 z0_prime_conj = vec2(z0_prime.x, -z0_prime.y);
    vec2 numerator = z_prime - z0_prime;
    vec2 denominator = z_prime - z0_prime_conj;
    // map to disk coordinates
    float denominator_sq = dot(denominator, denominator);
    vec2 w = vec2((numerator.x * denominator.x + numerator.y * denominator.y) / denominator_sq,
                    (numerator.y * denominator.x - numerator.x * denominator.y) / denominator_sq);
    w=vec2(-w.y,w.x); // i dunno why a 90 degrees rotation is needed
    if(hyperbolic_model==HYPERBOLIC_MODEL_K_DISK){
        float ww = dot(w, w);
        ww = (2)/(1.0 + ww); // Klein model projection
        w = w * ww;
    }
    float r= 0.5 * min(screen_size.x, screen_size.y) * rFactor;
    vec2 screen_pos = vec2(screen_size.x / 2 + w.x * r, screen_size.y/2 + w.y * r);
    return screen_pos;
}


// anti 3. Convert position in the other hyperbolic model to UHP
vec2 ConvertFromOtherModel(vec2 pos, float axisY, float rFactor, int hyperbolic_model) {
    if (hyperbolic_model == HYPERBOLIC_MODEL_UHP) {
        return pos; // No conversion needed for UHP
    }
    vec2 screen_size = love_ScreenSize.xy; 
    float r= 0.5 * min(screen_size.x, screen_size.y) * rFactor;
    vec2 w = vec2((pos.x - screen_size.x / 2) / r, (pos.y - screen_size.y / 2) / r);

    float ww = dot(w, w);
    if(ww>1.0) {
        return vec2(0, 1e20); // Return a point at "infinity" if outside the disk
    }
    if(hyperbolic_model==HYPERBOLIC_MODEL_K_DISK){
        ww = (1.0-sqrt(1.0-ww))/ww;
        w = w * ww;
    }
    w=vec2(w.y,-w.x); // i dunno why a 90 degrees rotation is needed
    
    vec2 z0_prime = vec2(screen_size.x / 2, screen_size.y / 2 - axisY);
    vec2 z0_prime_conj = vec2(z0_prime.x, -z0_prime.y);

    // Calculate the numerator: z0_prime - w * z0_prime_conj
    // (Complex multiplication: (a+bi)(c+di) = (ac-bd) + (ad+bc)i)
    vec2 w_times_z0_conj = vec2(w.x * z0_prime_conj.x - w.y * z0_prime_conj.y,
                                w.x * z0_prime_conj.y + w.y * z0_prime_conj.x);
    vec2 numerator = z0_prime - w_times_z0_conj;

    // Calculate the denominator: 1 - w
    vec2 denominator = vec2(1.0 - w.x, -w.y);

    // Perform the complex division: z' = numerator / denominator
    // (Complex division: n/d = (n * conj(d)) / |d|^2)
    float denominator_sq = dot(denominator, denominator);

    // Handle the singularity at w = (1,0), which maps to infinity in the UHP.
    if (denominator_sq < 1e-9) { // Use a small epsilon for floating point comparison
        return vec2(pos.x, 1e20); // Return a point with a very large Y value (at "infinity")
    }

    vec2 z_prime = vec2((numerator.x * denominator.x + numerator.y * denominator.y) / denominator_sq,
                      (numerator.y * denominator.x - numerator.x * denominator.y) / denominator_sq);

    // 5. Undo the initial translation to get the final UHP coordinates
    // The forward step was z' = pos_uhp - (0, axisY). The inverse is pos_uhp = z' + (0, axisY).
    vec2 uhp_pos = vec2(z_prime.x, z_prime.y + axisY);
    
    return uhp_pos;
}