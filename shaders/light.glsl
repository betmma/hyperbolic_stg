#include "shaders/modelsTrans.glsl"
// GLSL (Pixel Shader - e.g., light.frag)
float shapeDistanceVec(vec2 p1, vec2 p2, float curvature, float axisY) {
    // Calculate the two distances needed for the formula
    float dist1 = distance(p1, p2);
    float dist2 = distance(p1, vec2(p2.x, 2.0 * axisY - p2.y));
    
    // Calculate the denominator, protecting against division by zero
    float denominator = 2.0 * sqrt(max(0.0001, (p1.y - axisY) * (p2.y - axisY)));
    
    // Calculate the final hyperbolic distance
    return 2.0 * curvature * log((dist1 + dist2) / denominator);
}

float sinh(float x) {
    return (exp(x) - exp(-x)) / 2.0;
}

uniform vec2 lightPositions[16]; // MAX_LIGHTS = 16
uniform vec3 lightColors[16];    // MAX_LIGHTS = 16
uniform float lightIntensities[16]; // MAX_LIGHTS = 16
uniform int numLights; // Actual number of lights to use (0 to MAX_LIGHTS)
uniform float backgroundLightIntensity; // Background light intensity

uniform vec2 player_pos;       // Center of rotation
uniform vec2 aim_pos;         // Aim position for the player
uniform float rotation_angle;   // Angle of rotation in radians
uniform int hyperbolic_model; // 0 for UHP, 1 for P_DISK, 2 for K_DISK
uniform float r_factor; // Radius factor for disk models

const float constantAttenuation = 1.0;
const float linearAttenuation = 5.0;
const float curvature = 100;
const float axisY = -100;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 originalColor = Texel(texture, texture_coords);
    vec3 totalLightContribution = vec3(0.0); // Start with no light

    // World position (adjust if your screen_coords are not world coords)
    // For simplicity, let's assume screen_coords roughly map to world for now.
    // You might need camera transformations here!
    vec2 pos=ConvertFromOtherModel(screen_coords, axisY, r_factor, hyperbolic_model);
    pos=Transform2MakePlayerAtAimPos(pos, aim_pos, player_pos, axisY);
    pos=hyperbolically_rotate_point_mobius(pos, player_pos, -rotation_angle, axisY);
    vec2 pixelWorldPos = pos;

    for (int i = 0; i < numLights; ++i) {
        // Calculate distance from pixel to the current light
        float dist = shapeDistanceVec(pixelWorldPos, lightPositions[i], curvature, axisY);

        // Calculate attenuation (how light fades with distance)
        // 1.0 / (Kc + Kl * d + Kq * d^2)
        float attenuation = 1.0 / (constantAttenuation + sinh(dist / curvature) * linearAttenuation);

        // Prevent overly bright spots very close to the light
        attenuation = clamp(attenuation, 0.0, 1.0); 

        // Add this light's contribution (color * intensity * attenuation)
        totalLightContribution += lightColors[i] * lightIntensities[i] * attenuation;
    }

    // Normalize the total light contribution to avoid overflow
    totalLightContribution = clamp(totalLightContribution, 0.0, 1.0); // Ensure values are between 0 and 1

    // ambient light 
    vec3 ambientLight = vec3(backgroundLightIntensity, backgroundLightIntensity, backgroundLightIntensity); 

    vec3 colorCoeff = max(totalLightContribution, ambientLight);

    // Apply the light
    vec3 finalColor = originalColor.rgb * (colorCoeff);

    // Apply setColor to the final color
    vec4 finalColorv4 = vec4(finalColor, originalColor.a) * color; // Apply the color multiplier

    return finalColorv4; // Return the final color
}