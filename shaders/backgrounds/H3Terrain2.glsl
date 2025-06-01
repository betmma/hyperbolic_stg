#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

uniform bool flat_=false; // if true, terrainFunc returns 0 and drastically increases performance
uniform vec2 V0; 
uniform vec2 V1;
uniform vec2 V2;
uniform float time=0.0;

uniform vec3 cam_rotation_axis1 = vec3(1.0, 0.0, 0.0); // Default: X-axis for pitch
uniform float cam_pitch = 0.0;              // Default: No pitch
uniform vec3 cam_rotation_axis2 = vec3(0.0, 1.0, 0.0); // Default: Y-axis for yaw
uniform float cam_yaw = 0.0;              // Default: No yaw
uniform vec3 cam_rotation_axis3 = vec3(0.0, 0.0, 1.0); // Optional: Z-axis for roll
uniform float cam_roll = 0.0;              // Optional: No roll

uniform vec3 cam_translation = vec3(0.0, 0.0, 1.0); // Default: Boost along Z-axis

UHPGeodesic G01 = make_geodesic_segment(V0, V1);
UHPGeodesic G12 = make_geodesic_segment(V1, V2);
UHPGeodesic G20 = make_geodesic_segment(V2, V0);
const int MAX_REFLECTIONS = 10; 


vec2 shift_pos(vec2 pos, float time) {
    // Shift coordinates based on time for movement. this is in embedding space so not actually hyperbolic
    return pos + vec2(cos(time) * 0.0+0.001, -time * 0.0);
}

struct flipData {
    vec2 p_in_fundamental;
    int flipCount;
};
flipData flip(vec2 pos_xy_embedding) {
    vec2 p_in_fundamental= hyperboloid_to_uhp(pos_xy_embedding);
    int flipCount=0;
    for (int i = 0; i < MAX_REFLECTIONS; ++i) {
        bool reflected_in_iter = false;
        if (!is_on_correct_side_of_edge(p_in_fundamental, G01, V2)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G01);
            reflected_in_iter = true;
            flipCount++;
        }
        if (!is_on_correct_side_of_edge(p_in_fundamental, G12, V0)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G12);
            reflected_in_iter = true;
            // flipCount++; // intended to make colored shape become quadrilateral
        }
        if (!is_on_correct_side_of_edge(p_in_fundamental, G20, V1)) {
            p_in_fundamental = reflect_point(p_in_fundamental, G20);
            reflected_in_iter = true;
            flipCount++;
        }

        if (p_in_fundamental.y <= EPSILON * 0.1) { // Point escaped far below
             return flipData(vec2(0.0, 0.0), -1);
        }
        if (p_in_fundamental.y <= EPSILON && p_in_fundamental.y > EPSILON * 0.1) { // Point very close to boundary
             p_in_fundamental.y = EPSILON; // clamp it
        }
        
        if (!reflected_in_iter) {
            break; 
        }
        if (i == MAX_REFLECTIONS - 1) { 
            return flipData(vec2(0.0, 0.0), -1); // Indicate non-convergence
        }
    }
    return flipData(p_in_fundamental, flipCount);
}

vec4 colorFunc(vec2 pos_xy_embedding, float time) {
    flipData fd = flip(pos_xy_embedding);
    int flipCount = fd.flipCount;
    if (flipCount < 0) { 
        return vec4(1.0, 0.0, 1.0, 1.0); // Magenta for non-convergence
    }
    if (mod(flipCount,2)==0) { 
        return vec4(0.8, 0.2, 0.2, 1.0);
    }
    return vec4(0.2, 0.2, 0.8, 1.0);
}

// returns embedding z. not perfectly hyperbolic, so value should be close to 0 and small 
float terrainFunc(vec2 pos_xy_embedding, float time) {
    if (flat_) {
        return 0.0; // If flat_, return 0 for performance
    }
    vec2 shifted_pos = shift_pos(pos_xy_embedding, time);
    flipData fd = flip(shifted_pos);
    if (fd.flipCount < 0) { 
        return 0.0; // Indicate non-convergence
    }
    vec2 p_in_fundamental = fd.p_in_fundamental;
    vec3 bary_coords = get_hyperbolic_barycentric_coords(p_in_fundamental, V0, V1, V2);
    float bx= bary_coords.x;
    return (bx*bx*bx) * 0.6; 
}

// deprecated
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

float terrainFunc_(vec2 pos_xy_embedding, float time) {
    return 0;

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

    const int MAX_STEPS = 64;
    const float MAX_DIST_HYPERBOLIC = 30.0; // Max hyperbolic distance
    float step_coeff=0.6;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec4 current_pos_H = cam_pos_H * cosh(t) + ray_dir_H * sinh(t);

        if (current_pos_H.w <= 0.005) {
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

            terrain_color_base=colorFunc(shifted_pos_tex, time).rgb; // Use the colorFunc to get the terrain color

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

        float dt = abs(dist_to_surface_approx) * step_coeff / max(1.0, current_pos_H.w);
        step_coeff=step_coeff*1.06; // for far away terrain, increase step size to let ray reach further
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
    float field_of_view_factor = -1.3; 

    // 1. Initial camera state at H^3 origin
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0); 
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, field_of_view_factor));
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0); // Tangent vector at origin

    // 2. Build combined rotation matrix
    // Order of multiplication matters: M_new = M_next_op * M_current_op
    // To apply Rot1 then Rot2: M_combined_rot = Rot2 * Rot1
    mat4 M_rotation_component = mat4(1.0);
    // Example: Apply first rotation (e.g. pitch), then second rotation (e.g. yaw)
    // The axes are in the initial, unrotated frame.
    M_rotation_component = create_rotation_lorentz_matrix(cam_rotation_axis2, cam_yaw) * M_rotation_component; // e.g., Yaw
    M_rotation_component = create_rotation_lorentz_matrix(cam_rotation_axis1, cam_pitch) * M_rotation_component; // e.g., Pitch
    M_rotation_component = create_rotation_lorentz_matrix(cam_rotation_axis3, cam_roll) * M_rotation_component; // e.g., Roll

    // 3. Build boost matrix
    mat4 M_boost_component = create_boost_lorentz_matrix(vec3(1,0,0), cam_translation.x)
        * create_boost_lorentz_matrix(vec3(0,1,0), cam_translation.y)
        * create_boost_lorentz_matrix(vec3(0,0,1), cam_translation.z);

    // 4. Combine transformations: Rotations first (orient at origin), then boost (translate)
    // M_total transforms from the canonical camera frame to the world frame.
    mat4 M_total = M_boost_component * M_rotation_component;

    // 5. Apply total transformation to canonical camera position and ray direction
    vec4 final_cam_pos_H = M_total * cam_pos_H0;
    vec4 final_ray_dir_H = M_total * rd_T0;
    
    // Ensure ray direction is properly normalized in Minkowski sense if necessary,
    // though Lorentz transforms should preserve it if rd_T0 was correct.
    // minkowski_dot(rd_T0, rd_T0) is -1.
    // minkowski_dot(final_ray_dir_H, final_ray_dir_H) should also be -1.
    // minkowski_dot(final_cam_pos_H, final_ray_dir_H) should be 0.

    bool terrain_was_hit;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, terrain_was_hit);

    return vec4(fragment_color, 1.0);
}

