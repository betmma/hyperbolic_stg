#include "shaders/math.glsl"

uniform float time;
uniform float cam_height=1.0;
uniform float cam_pitch=0.0; // Camera pitch angle in radians, negative to look down

// Minkowski metric g(A,B) = A.w*B.w - A.x*B.x - A.y*B.y - A.z*B.z
// For the hyperboloid model with R=1: w^2 - x^2 - y^2 - z^2 = 1
float minkowski_dot(vec4 a, vec4 b) {
    return a.w*b.w - dot(a.xyz, b.xyz);
}

float random(vec2 st) { return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123); }
float noise2D(vec2 st) { vec2 i=floor(st); vec2 f=fract(st); float a=random(i); float b=random(i+vec2(1,0)); float c=random(i+vec2(0,1)); float d=random(i+vec2(1,1)); vec2 u=f*f*(3.0-2.0*f); return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.y*u.x; }
// Fractional Brownian Motion (fBm) for more natural terrain
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.8;
    float frequency = 0.6;
    const int octaves = 5; // Number of noise layers

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise2D(frequency * st);
        frequency *= 2.0; // Lacunarity: how much detail is added each octave
        amplitude *= 0.5; // Persistence/Gain: how much each octave contributes
    }
    return value;
}

vec2 shift_pos(vec2 pos, float time) {
    // Shift coordinates based on time for movement
    return pos + vec2(time * 0.0 + 0.001, -time * 0.2);
}

// Terrain height function
// Input: pos_xy_embedding are x,y coordinates in the Minkowski embedding space.
// Output: z-coordinate in the Minkowski embedding space for the terrain surface.
float terrainFunc(vec2 pos_xy_embedding, float time) {
    // Shift coordinates based on time for movement
    vec2 shifted_pos = shift_pos(pos_xy_embedding, time);
    
    float height_val = fbm(shifted_pos) * 0.8; // Base height variation
    
    // Lower the average terrain height so camera is above it
    height_val -= 0.6; 
    return height_val;
}

vec3 getTerrainNormal(vec4 p_H, float time, float epsilon_normal) {
    // Central differences for terrainFunc derivatives w.r.t. p_H.xy
    // Note: terrainFunc is defined based on embedding x,y coordinates
    float terrain_dx = (terrainFunc(p_H.xy + vec2(epsilon_normal, 0.0), time) - terrainFunc(p_H.xy - vec2(epsilon_normal, 0.0), time)) / (2.0 * epsilon_normal);
    float terrain_dy = (terrainFunc(p_H.xy + vec2(0.0, epsilon_normal), time) - terrainFunc(p_H.xy - vec2(0.0, epsilon_normal), time)) / (2.0 * epsilon_normal);

    // The terrain surface is implicitly p_H.z - terrainFunc(p_H.xy, time) = 0.
    // The gradient vector (-d(terrainFunc)/dx, -d(terrainFunc)/dy, 1) is normal to this surface.
    // This vector points "outwards" from the terrain, towards positive SDF values.
    vec3 normal_emb = normalize(vec3(-terrain_dx, -terrain_dy, 1.0));
    return normal_emb;
}

// Scene Distance Estimator (SDF-like function)
// p_H: A point on the hyperboloid (x,y,z,w with w > 0).
// Returns an approximate signed distance (along embedding z-axis) to the terrain surface.
// Positive if p_H.z is "above" the terrain, negative if "below".
float sceneSDF(vec4 p_H, float time) {
    float terrain_z_at_p_xy = terrainFunc(p_H.xy, time);
    return p_H.z - terrain_z_at_p_xy; 
}

// Raymarching core function
// cam_pos_H: Camera position on the hyperboloid.
// ray_dir_H: Initial ray direction (normalized space-like tangent vector at cam_pos_H, g(ray_dir_H, ray_dir_H) = -1).
// hit_terrain: Output parameter indicating if the terrain was hit.
vec3 rayMarch(vec4 cam_pos_H, vec4 ray_dir_H, float time, out bool hit_terrain) {
    float t = 0.0; // Hyperbolic distance along the geodesic
    hit_terrain = false;
    vec3 sky_color = vec3(0.35, 0.55, 0.85); // Sky color

    const int MAX_STEPS = 128;
    const float MAX_DIST_HYPERBOLIC = 30.0; // Max hyperbolic distance

    for (int i = 0; i < MAX_STEPS; i++) {
        vec4 current_pos_H = cam_pos_H * cosh(t) + ray_dir_H * sinh(t);

        if (current_pos_H.w <= 0.001) {
            break; 
        }

        float dist_to_surface_approx = sceneSDF(current_pos_H, time);
        float epsilon = 0.01 * max(1.0, current_pos_H.w * 0.5); 

        if (dist_to_surface_approx < epsilon) {
            hit_terrain = true;
            
            // --- Terrain Base Color ---
            vec3 terrain_color_base = vec3(0.45, 0.35, 0.25); 
            float height_factor = smoothstep(-0.8, 0.2, current_pos_H.z); 
            terrain_color_base = mix(vec3(0.2, 0.15, 0.1), vec3(0.7, 0.65, 0.55), height_factor);
            
            vec2 shifted_pos_tex = shift_pos(current_pos_H.xy, time); // Use a different name for clarity
            terrain_color_base *= (0.9 + 0.1 * sin(shifted_pos_tex.x*5.0 + shifted_pos_tex.y*3.0));

            // --- Enhanced Lighting Calculation ---
            float normal_calc_eps = 0.001; // Epsilon for normal calculation finite differences
            vec3 normal_emb = getTerrainNormal(current_pos_H, time, normal_calc_eps);

            // Lighting parameters
            vec3 ambient_light_color = vec3(0.25, 0.25, 0.10);    // Cool ambient light
            vec3 directional_light_color = vec3(0.9, 0.85, 0.75); // Warm sunlight color
            vec3 light_dir_emb = normalize(vec3(0.5, 0.5, 0.707)); // Light from top-right-ish (normalize for direction)
            float shininess = 48.0;                              // Shininess for specular highlights
            float specular_strength = 0.45;                      // Strength of specular highlights

            // View direction calculation
            // Tangent vector of the geodesic ray at the hit point current_pos_H
            vec4 ray_tangent_at_hit_H = cam_pos_H * sinh(t) + ray_dir_H * cosh(t);
            // View direction is opposite to the ray's propagation direction (spatial part)
            vec3 view_dir_emb = -normalize(ray_tangent_at_hit_H.xyz);

            // Ambient component
            vec3 ambient = ambient_light_color * terrain_color_base;

            // Diffuse component
            float NdotL = max(0.0, dot(normal_emb, light_dir_emb));
            vec3 diffuse = directional_light_color * terrain_color_base * NdotL;

            // Specular component (Blinn-Phong)
            vec3 halfway_dir = normalize(light_dir_emb + view_dir_emb);
            float NdotH = max(0.0, dot(normal_emb, halfway_dir));
            vec3 specular = directional_light_color * specular_strength * pow(NdotH, shininess);
            
            // Ensure specular is not applied if the surface is facing away from the light
            if (NdotL <= 0.0) {
                specular = vec3(0.0);
            }

            vec3 lit_terrain_color = ambient + diffuse + specular;
            // --- End of Lighting Calculation ---

            // Fog effect based on hyperbolic distance t
            float fog_density = 0.18; 
            float fog_factor = exp(-t * fog_density);
            return mix(sky_color, lit_terrain_color, fog_factor);
        }

        float dt = abs(dist_to_surface_approx) * 0.6 / max(1.0, current_pos_H.w);
        dt = max(0.005, dt); 
        
        t += dt;

        if (t > MAX_DIST_HYPERBOLIC) {
            break;
        }
    }
    return sky_color;
}


// Main fragment shader function for Love2D
// color: The vertex color (usually white).
// texture: The texture (if one is used with love.graphics.draw).
// texture_coords: UV coordinates for the texture.
// screen_coords: Pixel coordinates on the screen (gl_FragCoord.xy equivalent).
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Normalize screen coordinates and set up UVs for ray direction generation
    // screen_coords origin is usually bottom-left (like gl_FragCoord)
    vec2 uv = screen_coords.xy / love_ScreenSize.xy; // Range [0,1] x [0,1]
    uv = uv * 2.0 - 1.0;                             // Range [-1,1] x [-1,1], Y points up
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;   // Correct for aspect ratio

    // --- Camera Setup ---
    float cam_hyperbolic_height = cam_height; // Hyperbolic distance for camera "up" translation from origin (0,0,0,1)
    float cam_pitch_angle = cam_pitch;     // Radians, negative to look down towards terrain
    float field_of_view_factor = -1.3; // Determines FOV; smaller magnitude = wider FOV

    // 1. Initial camera state at H^3 origin (embedding: (0,0,0,1))
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0); // (x,y,z,w)
    
    // Initial ray direction in the tangent space of cam_pos_H0.
    // This is a normalized space-like vector (g(V,V) = -1).
    // Its w-component is 0 because cam_pos_H0.xyz is (0,0,0).
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, field_of_view_factor)); 
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0);

    // 2. Apply pitch rotation to the ray direction (rotation around X-axis of embedding space)
    // This affects the YZ components of rd_T0.
    float cos_p = cos(cam_pitch_angle);
    float sin_p = sin(cam_pitch_angle);
    // Standard 2D rotation matrix for (y,z) components
    vec2 yz_original = rd_T0.yz;
    vec2 yz_rotated = vec2(
        yz_original.x * cos_p - yz_original.y * sin_p,
        yz_original.x * sin_p + yz_original.y * cos_p
    );
    vec4 rd_T_pitched = vec4(rd_T0.x, yz_rotated.x, yz_rotated.y, rd_T0.w); // rd_T0.w is still 0

    // 3. Apply boost transformation (hyperbolic translation along Z_embedding axis)
    // This moves the camera "up" and transforms the pitched ray direction.
    float b_cam_translation = cam_hyperbolic_height;
    float ch_b = cosh(b_cam_translation);
    float sh_b = sinh(b_cam_translation);

    // Calculate final camera position on the hyperboloid
    vec4 final_cam_pos_H;
    final_cam_pos_H.x = cam_pos_H0.x; // Stays 0
    final_cam_pos_H.y = cam_pos_H0.y; // Stays 0
    final_cam_pos_H.z = cam_pos_H0.z * ch_b + cam_pos_H0.w * sh_b; // Becomes sinh(b_cam_translation)
    final_cam_pos_H.w = cam_pos_H0.z * sh_b + cam_pos_H0.w * ch_b; // Becomes cosh(b_cam_translation)
    // So, final_cam_pos_H = (0.0, 0.0, sinh(b_cam_translation), cosh(b_cam_translation))

    // Transform the pitched ray direction vector to be tangent at final_cam_pos_H
    vec4 final_ray_dir_H;
    final_ray_dir_H.x = rd_T_pitched.x;
    final_ray_dir_H.y = rd_T_pitched.y;
    // Z and W components are transformed by the boost
    final_ray_dir_H.z = rd_T_pitched.z * ch_b + rd_T_pitched.w * sh_b; // rd_T_pitched.w is 0
    final_ray_dir_H.w = rd_T_pitched.z * sh_b + rd_T_pitched.w * ch_b; // rd_T_pitched.w is 0, so final_ray_dir_H.w = rd_T_pitched.z * sh_b
    // This transformation ensures final_ray_dir_H is tangent to final_cam_pos_H and g(final_ray_dir_H, final_ray_dir_H) = -1.
    
    bool terrain_was_hit;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, terrain_was_hit);

    return vec4(fragment_color, 1.0);
}

