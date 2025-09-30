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
