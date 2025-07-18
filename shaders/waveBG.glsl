#include "shaders/modelsTrans.glsl"

// Vector version if you prefer working with vec2
float shapeDistanceVec(vec2 p1, vec2 p2, float curvature, float axisY) {
    // Calculate the two distances needed for the formula
    float dist1 = distance(p1, p2);
    float dist2 = distance(p1, vec2(p2.x, 2.0 * axisY - p2.y));
    
    // Calculate the denominator, protecting against division by zero
    float denominator = 2.0 * sqrt(max(0.0001, (p1.y - axisY) * (p2.y - axisY)));
    
    // Calculate the final hyperbolic distance
    return 2.0 * curvature * log((dist1 + dist2) / denominator);
}

// this shader is used in scene 6-6

uniform float curvature;
uniform float axisY;
uniform float time;
uniform float thershold;
uniform vec2 source1;
uniform float amplitude1;
uniform float frequency1;
uniform vec2 source2;
uniform float amplitude2;
uniform float frequency2;
uniform vec3 colorMix;


uniform vec2 player_pos;       // Center of rotation
uniform vec2 aim_pos;         // Aim position for the player
uniform float rotation_angle;   // Angle of rotation in radians
uniform int hyperbolic_model; // 0 for UHP, 1 for DISK
uniform float r_factor; // Radius factor for disk models

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pos=ConvertFromOtherModel(screen_coords, axisY, r_factor, hyperbolic_model);
    pos=Transform2MakePlayerAtAimPos(pos, aim_pos, player_pos, axisY);
    pos=hyperbolically_rotate_point_mobius(pos, player_pos, -rotation_angle, axisY);
    // Get distance from current pixel to some reference point
    float dist1 = shapeDistanceVec(pos, source1, curvature, axisY);
    float dist2 = shapeDistanceVec(pos, source2, curvature, axisY);
    float phase1 = dist1 * frequency1 - time;
    float phase2 = dist2 * frequency2 - time;
    float sum = amplitude1 * sin(phase1) + amplitude2 * sin(phase2);
    sum = sum / (amplitude1 + amplitude2) * 0.5 + 0.5; // Normalize to [0, 1]
    float c = sum;
    if (c < thershold) c = c * 0.8; // Create a boundary effect
    float brightness = 1 / dist1 / dist1 + 1 / dist2 / dist2;
    if (brightness > 1) brightness = 1;
    float r = c * colorMix.x + brightness * (1 - colorMix.x);
    float g = c * colorMix.y + brightness * (1 - colorMix.y);
    float b = c * colorMix.z + brightness * (1 - colorMix.z);
    if (time < 3){
        r = r * (time/3);
        g = g * (time/3);
        b = b * (time/3);
    }
    return vec4(r,g,b, 1.0);
}
