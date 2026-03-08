#define FACE_COUNT 12
vec4 getFaceNormal(int index) {
    if (index == 0) return vec4(0.0, -1.144122805635, -0.707106781187, 0.899453719974);
    if (index == 1) return vec4(-0.707106781187, 0.0, -1.144122805635, 0.899453719974);
    if (index == 2) return vec4(-1.144122805635, -0.707106781187, 0.0, 0.899453719974);
    if (index == 3) return vec4(0.0, -1.144122805635, 0.707106781187, 0.899453719974);
    if (index == 4) return vec4(-0.707106781187, 0.0, 1.144122805635, 0.899453719974);
    if (index == 5) return vec4(-1.144122805635, 0.707106781187, 0.0, 0.899453719974);
    if (index == 6) return vec4(0.0, 1.144122805635, -0.707106781187, 0.899453719974);
    if (index == 7) return vec4(0.0, 1.144122805635, 0.707106781187, 0.899453719974);
    if (index == 8) return vec4(0.707106781187, 0.0, -1.144122805635, 0.899453719974);
    if (index == 9) return vec4(1.144122805635, -0.707106781187, 0.0, 0.899453719974);
    if (index == 10) return vec4(0.707106781187, 0.0, 1.144122805635, 0.899453719974);
    return vec4(1.144122805635, 0.707106781187, 0.0, 0.899453719974);
}
int getOppositeFace(int index) {
    if (index == 0) return 7;
    if (index == 1) return 10;
    if (index == 2) return 11;
    if (index == 3) return 6;
    if (index == 4) return 8;
    if (index == 5) return 9;
    if (index == 6) return 3;
    if (index == 7) return 0;
    if (index == 8) return 4;
    if (index == 9) return 5;
    if (index == 10) return 1;
    return 2;
}
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
            if (plane_signed(pos, getFaceNormal(i)) <= 0.0) {
                pos = reflect_plane(pos, getFaceNormal(i));
                dir = reflect_plane(dir, getFaceNormal(i));
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
