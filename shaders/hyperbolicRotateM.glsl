#include "shaders/modelsTrans.glsl"

// hyperbolic rotation using Mobius transformation
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifndef HYPERBOLIC_EPS
#define HYPERBOLIC_EPS 1e-5f // A small epsilon for float comparisons
#endif

// Uniforms that will be used by the new 'position' function:
uniform vec2 player_pos;       // Center of rotation
uniform vec2 aim_pos;         // Aim position for the player
uniform float rotation_angle;   // Angle of rotation in radians
uniform float shape_axis_y;     // Y-coordinate of the hyperbolic plane's boundary axis
uniform int hyperbolic_model; // 0 for UHP, 1 for DISK
uniform float r_factor; // Radius factor for disk models
#define HYPERBOLIC_MODEL_UHP 0
#define HYPERBOLIC_MODEL_P_DISK 1
#define HYPERBOLIC_MODEL_K_DISK 2


// The main 'position' function, updated to use the Mobius transformation method.
// It expects 'player_pos', 'rotation_angle', and 'shape_axis_y' as uniforms.
vec4 position(mat4 transform_projection, vec4 vertex_pos) {
    vec2 screen_size = love_ScreenSize.xy; 
    vec2 current_pos_euclidean = vec2(vertex_pos.x, vertex_pos.y);
    
    // Call the new rotation function.
    // player_pos, rotation_angle, shape_axis_y must be provided as uniforms.
    vec2 rotated_pos_euclidean = hyperbolically_rotate_point_mobius(
        current_pos_euclidean, 
        player_pos,         // uniform vec2 player_pos;
        rotation_angle,     // uniform float rotation_angle;
        shape_axis_y        // uniform float shape_axis_y;
    );

    rotated_pos_euclidean=Transform2MakePlayerAtAimPos(rotated_pos_euclidean, player_pos,aim_pos, shape_axis_y);

    vec2 screen_pos= Convert2OtherModel(rotated_pos_euclidean, shape_axis_y, r_factor, hyperbolic_model);

    return transform_projection * vec4(screen_pos, 0.0, 1.0);
}