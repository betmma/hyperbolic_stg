#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

uniform float time = 0.0;
uniform mat4 cam_mat4;

const float MOVE_SPEED = 0.1;

// Constants for raymarching
const int MAX_STEPS = 96;
const float MAX_DIST = 5.0;
const float SURF_DIST = 0.005; // Decreased slightly for sharper water contact
const float STEP_SCALE = 0.5;

// Terrain constants
const float SIDE_HEIGHT = 1.9;
const float MOUNTAIN_DIST = 1.0;
const float NOISE_SCALE = 2.0;
const float NOISE_AMP = 0.5;
const float RIVER_WIDTH = 0.6;

// ----------------------------------------------------------------------------
// Noise Functions
// ----------------------------------------------------------------------------

float hash(vec3 p) {
    p = fract(p * 0.3183099 + .1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) { // Reduced octaves for performance
        f += amp * noise(p);
        p *= 2.01;
        amp *= 0.5;
    }
    return f;
}

// ----------------------------------------------------------------------------
// Water Specific Functions
// ----------------------------------------------------------------------------

// Generates a height value for water surface detail (used for normal mapping)
float waterHeightMap(vec2 uv) {
    // Layer 1: Base flow
    vec3 p1 = vec3(uv.x * 8.0, uv.y * 4.0 + time * 1.0, time * 0.2);
    float n1 = noise(p1);
    
    // Layer 2: Crossing choppiness
    vec3 p2 = vec3(uv.x * 12.0 + time * 0.5, uv.y * 12.0, time * 0.3);
    float n2 = noise(p2);
    
    return mix(n1, n2, 0.5);
}

// Perturbs the surface normal based on water height map
vec3 applyWaterNormal(vec3 norm, vec2 uv, float strength) {
    vec2 e = vec2(0.01, 0.0);
    float h = waterHeightMap(uv);
    float hx = waterHeightMap(uv + e.xy) - h;
    float hy = waterHeightMap(uv + e.yx) - h;
    
    // Build a tangent space normal perturbation
    vec3 perturbation = normalize(vec3(-hx * strength, -hy * strength, e.x));
    
    // Very rough approximation of tangent space to world space rotation:
    // Just adding to the existing normal is often visually sufficient for water
    // provided the surface is mostly flat/upwards.
    return normalize(norm + vec3(perturbation.x, perturbation.y, 0.0) * 0.5);
}

// ----------------------------------------------------------------------------
// Hyperbolic Terrain Logic
// ----------------------------------------------------------------------------

float getTerrainHeight(vec4 p_base) {
    float x = p_base.x;
    float y = p_base.y;
    
    float v = asinh(x); 
    float u = asinh(y / sqrt(1.0 + x * x)); 

    float bank_width = 0.4;
    float river_depth = -0.3;
    
    float abs_v = abs(v);
    float bank_factor = smoothstep(RIVER_WIDTH, RIVER_WIDTH + bank_width, abs_v);
    
    // Remove geometric ripples - let the normal map handle water detail.
    // It's cheaper and looks better (less jelly-like).
    float h_base = mix(river_depth, abs_v * 0.5, bank_factor);
    
    vec3 noise_pos = vec3(x, y, 0.0) * NOISE_SCALE;
    
    // Offset noise along U to make terrain feel like we are moving past it
    vec3 p_noise = vec3(u - time * MOVE_SPEED, v, 0.0) * 3.0;
    float h_noise = fbm(p_noise) * NOISE_AMP;
    
    float mountain_scale = smoothstep(RIVER_WIDTH, RIVER_WIDTH + MOUNTAIN_DIST, abs_v);
    h_noise *= (0.2 + SIDE_HEIGHT * mountain_scale);
    
    return h_base + h_noise * bank_factor; 
}

float map(vec4 p) {
    float h_p = asinh(p.z);
    float ch = sqrt(1.0 + p.z * p.z);
    vec4 p_base = vec4(p.x / ch, p.y / ch, 0.0, p.w / ch);
    float h_terrain = getTerrainHeight(p_base);
    return (h_p - h_terrain) * 0.5;
}

vec3 calcNormal(vec4 p) {
    float e = 0.005; // Slightly wider epsilon for smoother terrain normals
    // Re-normalizing w inside the fetch isn't strictly necessary for tiny epsilons 
    // if we assume locally Euclidean, but good for correctness.
    
    // Gradient approximation
    float d = map(p);
    vec3 n = vec3(
        map(p + vec4(e, 0, 0, 0)) - d,
        map(p + vec4(0, e, 0, 0)) - d,
        map(p + vec4(0, 0, e, 0)) - d
    );
    return normalize(n);
}

// ----------------------------------------------------------------------------
// Raymarching & Shading
// ----------------------------------------------------------------------------

vec3 rayMarch(vec4 ro, vec4 rd, out bool hit) {
    float t = 0.0;
    hit = false;
    
    // Define Sky Color here so we can use it for reflection
    vec3 skyTop = vec3(0.1, 0.4, 0.8);
    vec3 skyHorizon = vec3(0.7, 0.8, 0.9);
    vec3 skyCol = mix(skyTop, skyHorizon, pow(1.0 - abs(rd.z), 2.0));
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec4 p = ro * cosh(t) + rd * sinh(t);
        if (t > MAX_DIST) break;
        
        float d = map(p);
        
        if (d < SURF_DIST) {
            hit = true;
            vec3 n = calcNormal(p);
            vec3 lightDir = normalize(vec3(0.5, -0.5, 1.0));
            
            // --- Calculate Coordinates ---
            float ch = sqrt(1.0 + p.z * p.z);
            vec4 p_base = vec4(p.x / ch, p.y / ch, 0.0, p.w / ch);
            float v = asinh(p_base.x);
            float u = asinh(p_base.y / sqrt(1.0 + p_base.x * p_base.x));
            
            // Move water coordinates with time
            float flowU = u - time * MOVE_SPEED;
            
            float abs_v = abs(v);
            vec3 col;
            
            // --- WATER SHADING ---
            if (abs_v < RIVER_WIDTH) {
                // 1. Water Normal Mapping
                // Use Fermi coords (flowU, v) for texture mapping
                // Multiplied by constants to tile the noise nicely
                vec3 waterN = applyWaterNormal(n, vec2(flowU, v), 20.0);
                
                // 2. Basic Colors
                vec3 deepWater = vec3(0.02, 0.05, 0.15);
                vec3 shallowWater = vec3(0.0, 0.3, 0.4);
                
                // 3. Fresnel Effect
                // Calculates how much light reflects off the surface based on view angle
                vec3 viewDir = -normalize(rd.xyz); // Approximate view direction in tangent space
                float fresnel = pow(clamp(1.0 - dot(waterN, viewDir), 0.0, 1.0), 4.0);
                fresnel = clamp(fresnel, 0.0, 0.9); // Don't let it go pure white
                
                // 4. Specular Highlight (Sun)
                vec3 halfVec = normalize(lightDir + viewDir);
                float spec = pow(max(dot(waterN, halfVec), 0.0), 200.0); // Sharp highlight
                
                // 5. Edge Foam
                // Determine how close we are to the river bank
                float edgeDist = RIVER_WIDTH - abs_v;
                float foam = smoothstep(0.1, 0.0, edgeDist); // 1.0 at edge, 0.0 inside
                // Add noise to foam edge
                foam *= step(0.4, noise(vec3(flowU*10.0, v*20.0, time)));
                
                // --- Combine Water Components ---
                
                // Mix deep and shallow based on distance to center (fake depth)
                vec3 baseWater = mix(deepWater, shallowWater, abs_v / RIVER_WIDTH);
                
                // Mix base water with Sky reflection based on Fresnel
                col = mix(baseWater, skyCol * 1.2, fresnel);
                
                // Add Sun Specular
                col += vec3(1.0, 0.9, 0.8) * spec;
                
                // Add Foam
                col += vec3(0.9) * foam;
                
            } 
            // --- TERRAIN SHADING ---
            else {
                float diff = max(dot(n, lightDir), 0.0);
                float amb = 0.2;
                
                float h = asinh(p.z);
                // Terrain coloring logic
                if (h > 1.0) {
                    col = vec3(0.9, 0.95, 1.0); // Snow
                } else if (h > -0.1) {
                    col = mix(vec3(0.2, 0.35, 0.1), vec3(0.4, 0.35, 0.3), (h - 0.2) * 2.0); 
                } else {
                    col = vec3(0.35, 0.3, 0.2); // Mud/Bank
                }
                
                // Texture noise
                float tex = fbm(vec3(u - time*MOVE_SPEED, v, h)*5.0);
                col *= (0.6 + 0.6 * tex);
                
                col = col * (diff + amb);
            }
            
            // Fog
            float fogDist = t;
            // Hyperbolic space volume grows exponentially, make fog denser faster?
            // Or keep linear for visibility.
            float fogFactor = 1.0 - exp(-fogDist * 0.1);
            return mix(col, skyCol, fogFactor);
        }
        
        t += d * STEP_SCALE;
    }
    
    return skyCol - rd.z * 0.2;
}

// ----------------------------------------------------------------------------
// Main Effect
// ----------------------------------------------------------------------------

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords.xy / love_ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float field_of_view_factor = -1.3;
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, field_of_view_factor));
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0);

    vec4 final_cam_pos_H = cam_mat4 * cam_pos_H0;
    vec4 final_ray_dir_H = cam_mat4 * rd_T0;
    
    bool hit;
    vec3 col = rayMarch(final_cam_pos_H, final_ray_dir_H, hit);
    
    // Gamma correction
    col = pow(col, vec3(0.4545));
    
    return vec4(col, 1.0) * color;
}