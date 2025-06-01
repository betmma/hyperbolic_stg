

// Minkowski metric g(A,B) = A.w*B.w - A.x*B.x - A.y*B.y - A.z*B.z
// For the hyperboloid model with R=1: w^2 - x^2 - y^2 - z^2 = 1
float minkowski_dot(vec4 a, vec4 b) {
    return a.w*b.w - dot(a.xyz, b.xyz);
}

// Helper: Creates a Lorentz rotation matrix (rotation about origin)
mat4 create_rotation_lorentz_matrix(vec3 axis, float angle) {
    if (length(axis) < 0.0001 || abs(angle) < 0.00001) { // Check for zero axis or angle
        return mat4(1.0); // Identity matrix
    }
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float t = 1.0 - c; // 1 - cosine

    // Standard axis-angle rotation matrix elements (R_ij)
    float r00 = t*a.x*a.x + c;
    float r01 = t*a.x*a.y - s*a.z;
    float r02 = t*a.x*a.z + s*a.y;

    float r10 = t*a.x*a.y + s*a.z;
    float r11 = t*a.y*a.y + c;
    float r12 = t*a.y*a.z - s*a.x;

    float r20 = t*a.x*a.z - s*a.y;
    float r21 = t*a.y*a.z + s*a.x;
    float r22 = t*a.z*a.z + c;

    // GLSL mat4 is column-major: mat4(col0, col1, col2, col3)
    return mat4(
        vec4(r00, r10, r20, 0.0), // Column 0
        vec4(r01, r11, r21, 0.0), // Column 1
        vec4(r02, r12, r22, 0.0), // Column 2
        vec4(0.0, 0.0, 0.0, 1.0)  // Column 3
    );
}

// Helper: Creates a Lorentz boost matrix (translation from origin)
mat4 create_boost_lorentz_matrix(vec3 n_spatial_dir, float b) {
    if (abs(b) < 0.00001) { // Check for zero boost distance
        return mat4(1.0); // Identity matrix
    }
    if (length(n_spatial_dir) < 0.0001) { // Check for zero direction
         // Default to Z-axis boost if direction is zero but distance is not,
         // or return identity. For safety, returning identity.
        // Alternatively, could pick a default like vec3(0,0,1)
        return mat4(1.0); 
    }
    vec3 n = normalize(n_spatial_dir);
    float ch = cosh(b);
    float sh = sinh(b);

    mat4 L; // Column-major by default
    L[0][0] = 1.0 + (ch - 1.0) * n.x * n.x;
    L[1][0] = (ch - 1.0) * n.x * n.y; // L_10
    L[2][0] = (ch - 1.0) * n.x * n.z; // L_20
    L[3][0] = sh * n.x;               // L_30

    L[0][1] = (ch - 1.0) * n.y * n.x; // L_01
    L[1][1] = 1.0 + (ch - 1.0) * n.y * n.y;
    L[2][1] = (ch - 1.0) * n.y * n.z; // L_21
    L[3][1] = sh * n.y;               // L_31

    L[0][2] = (ch - 1.0) * n.z * n.x; // L_02
    L[1][2] = (ch - 1.0) * n.z * n.y; // L_12
    L[2][2] = 1.0 + (ch - 1.0) * n.z * n.z;
    L[3][2] = sh * n.z;               // L_32

    L[0][3] = sh * n.x;               // L_03
    L[1][3] = sh * n.y;               // L_13
    L[2][3] = sh * n.z;               // L_23
    L[3][3] = ch;
    return L;
}
