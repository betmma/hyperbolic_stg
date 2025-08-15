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

// --- Added: road width and travel speed ---
uniform float path_half_width = 0.5;      // Half-width of straight path along x=0
uniform float cam_travel_speed = 0.35;    // Forward speed along +X

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
    // Flatten a straight path along x=0
    if (abs(pos_xy_embedding.x) < path_half_width) {
        return -0.02; // Slightly below zero to make the road visible
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

// --- Hyperbolic helpers and tree SDFs ---
float mdot4(vec4 a, vec4 b) { return -dot(a.xyz, b.xyz) + a.w*b.w; }
float acosh1(float x) { return log(x + sqrt(max(0.0, x*x - 1.0))); }
float hdist(vec4 a, vec4 b) { return acosh1(max(1.0, mdot4(a,b))); }
vec4 lift_to_H(vec3 xyz) { return vec4(xyz, sqrt(1.0 + dot(xyz, xyz))); }
vec4 spacelike_up(vec4 p_H) {
    // Build a spacelike unit vector orthogonal to p_H, roughly pointing +Z
    vec4 ez = vec4(0.0, 0.0, 1.0, 0.0);
    float alpha = mdot4(ez, p_H); // since mdot4(p_H,p_H)=1
    vec4 v = ez - alpha * p_H;
    float n2 = -mdot4(v,v);
    return v / sqrt(max(n2, 1e-8));
}
// Added: asinh and a generic spacelike direction from a Cartesian axis
float asinh1(float x) { return log(x + sqrt(x*x + 1.0)); }
vec4 spacelike_from_axis(vec4 p_H, vec3 axis) {
    vec4 e = vec4(axis, 0.0);
    float alpha = mdot4(e, p_H);
    vec4 v = e - alpha * p_H;
    float n2 = -mdot4(v,v);
    return v / sqrt(max(n2, 1e-8));
}

float treeSDF_H(vec4 p_H, float time, out float nearestRadiusH) {
    // Trees: go from origin along +Y by varying hyperbolic distances (axis),
    // then from each axis point go along ±X by a fixed hyperbolic offset.
    const float spacingH       = 1.1;  // hyperbolic spacing along +Y axis
    const float lateralOffsetH = 0.55; // fixed hyperbolic offset to left/right from axis

    float bestD = 1e9;
    nearestRadiusH = 0.0;

    // Axis origin anchored near the path center (x=0). Use terrain at (0,0) for base height.
    float baseZ = terrainFunc(vec2(0.0, 0.0), time);
    vec4 p_axis0 = lift_to_H(vec3(0.0, 0.0, baseZ));
    vec4 v_axis  = spacelike_from_axis(p_axis0, vec3(0.0, 1.0, 0.0)); // +Y direction on the axis

    // Project sample to axis coordinate (s satisfies mdot(p_H, v_axis) = sinh(s))
    float s0 = asinh1(mdot4(p_H, v_axis));
    int k0 = int(floor(s0 / spacingH));

    // Check a few neighbors around k0
    for (int dk = -5; dk <= 1; ++dk) {
        float s = float(k0 + dk) * spacingH + mod(time*0.1,spacingH); // slight upward drift over time
        vec4 c_axis = p_axis0 * cosh(s) + v_axis * sinh(s);

        // Lateral ±X direction at this axis point
        vec4 v_lat = spacelike_from_axis(c_axis, vec3(1.0, 0.0, 0.0));

        // Two sides: left (-) and right (+) along v_lat by fixed hyperbolic distance
        for (int side = -1; side <= 1; side += 2) {
            float sign = float(side);
            vec4 c_side = c_axis * cosh(lateralOffsetH) + (sign * v_lat) * sinh(lateralOffsetH);

            // Stack three spheres upward from this lateral point via hyperbolic "up"
            vec4 v_up = spacelike_up(c_side);
            float rH = 0.30;     // base hyperbolic radius
            float scale = 0.82;  // shrink per layer
            float s_up = rH;     // offset to first center so it rests on c_side

            for (int i = 0; i < 3; ++i) {
                vec4 c_H = c_side * cosh(s_up) + v_up * sinh(s_up);
                float d = hdist(p_H, c_H) - rH;
                if (d < bestD) { bestD = d; nearestRadiusH = rH; }
                float rH_next = rH * scale;
                s_up += rH + rH_next; // make adjacent spheres touch in H^3
                rH = rH_next;
            }
        }
    }
    return bestD;
}

float treeSDF_H_only(vec4 p_H, float time) {
    float r; return treeSDF_H(p_H, time, r);
}

vec3 treeNormal_H(vec4 p_H, float time) {
    float e = 0.002;
    vec4 px1 = lift_to_H(p_H.xyz + vec3(e,0,0));
    vec4 px2 = lift_to_H(p_H.xyz - vec3(e,0,0));
    vec4 py1 = lift_to_H(p_H.xyz + vec3(0,e,0));
    vec4 py2 = lift_to_H(p_H.xyz - vec3(0,e,0));
    vec4 pz1 = lift_to_H(p_H.xyz + vec3(0,0,e));
    vec4 pz2 = lift_to_H(p_H.xyz - vec3(0,0,e));
    float rTmp;
    float dx = treeSDF_H(px1, time, rTmp) - treeSDF_H(px2, time, rTmp);
    float dy = treeSDF_H(py1, time, rTmp) - treeSDF_H(py2, time, rTmp);
    float dz = treeSDF_H(pz1, time, rTmp) - treeSDF_H(pz2, time, rTmp);
    return normalize(vec3(dx,dy,dz));
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

    const int MAX_STEPS = 32;
    const float MAX_DIST_HYPERBOLIC = 5.0; // Max hyperbolic distance
    float step_coeff=0.6;

    // Cache previous step's probe SDFs to halve calls
    bool hasCache = false;
    float cachedDistTerrain = 0.0;
    float cachedDistTree = 0.0;
    float cachedTreeRadius = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec4 current_pos_H = cam_pos_H * cosh(t) + ray_dir_H * sinh(t);

        if (current_pos_H.w <= 0.005) {
            break; 
        }

        // Distances to terrain (embedding-z SDF) and trees (hyperbolic SDF)
        float dist_terrain;
        float dist_tree;
        float nearestRadiusH;
        if (hasCache) {
            dist_terrain = cachedDistTerrain;
            dist_tree = cachedDistTree;
            nearestRadiusH = cachedTreeRadius;
            hasCache = false; // consume cache
        } else {
            dist_terrain = sceneSDF(current_pos_H, time);
            dist_tree = treeSDF_H(current_pos_H, time, nearestRadiusH);
        }

        // Decide step based on closest SDF
        float dist_to_scene = min(dist_terrain, dist_tree);
        float dt = abs(dist_to_scene) * step_coeff / max(1.0, current_pos_H.w);
        step_coeff = step_coeff * 1.06; // for far away terrain, increase step size to let ray reach further
        dt = max(0.005, dt);

        // Probe forward using the same dt we plan to advance (enables caching next loop)
        float dt_probe = dt;
        vec4 probe_pos_H = cam_pos_H * cosh(t + dt_probe) + ray_dir_H * sinh(t + dt_probe);
        float dist_terrain_probe = sceneSDF(probe_pos_H, time);
        float probeTreeRadius;
        float dist_tree_probe = treeSDF_H(probe_pos_H, time, probeTreeRadius);

        // Hit thresholds (tuned to avoid sky tinting)
        float eps_terrain = 0.01;
        float eps_tree    = 0.03;

        bool approaching_terrain = dist_terrain_probe < dist_terrain;
        bool approaching_tree    = dist_tree_probe    < dist_tree;

        bool terrain_candidate = (t > 0.02) && approaching_terrain && (dist_terrain < eps_terrain);
        bool tree_candidate    = (t > 0.02) && approaching_tree    && (dist_tree    < eps_tree);

        if (terrain_candidate || tree_candidate) {
            bool hit_tree = tree_candidate && (!terrain_candidate || dist_tree <= dist_terrain);
            hit_terrain = !hit_tree;
            
            // --- Base color ---
            vec3 base_color;
            if (hit_tree) {
                // Brown-to-green based on sphere hyperbolic radius (smaller -> greener)
                float leafness = clamp((0.35 - nearestRadiusH) * 3.0, 0.0, 1.0);
                base_color = mix(vec3(0.35, 0.25, 0.12), vec3(0.15, 0.50, 0.18), leafness);
            } else {
                vec2 shifted_pos_tex = shift_pos(current_pos_H.xy, time);
                base_color = colorFunc(shifted_pos_tex, time).rgb;
                base_color *= (0.9 + 0.1 * sin(shifted_pos_tex.x*5.0 + shifted_pos_tex.y*3.0));
            }

            // --- Normal ---
            vec3 normal_emb;
            if (hit_tree) {
                normal_emb = treeNormal_H(current_pos_H, time);
            } else {
                float normal_calc_eps = 0.001;
                normal_emb = getTerrainNormal(current_pos_H, time, normal_calc_eps);
            }

            // --- Lighting ---
            vec3 ambient_light_color = vec3(0.25, 0.25, 0.10);
            vec3 directional_light_color = vec3(0.9, 0.85, 0.75);
            vec3 light_dir_emb = normalize(vec3(0.5, 0.5, 0.707));
            float shininess = 48.0;
            float specular_strength = 0.45;

            // Tangent vector of the geodesic ray at the hit point current_pos_H
            vec4 ray_tangent_at_hit_H = cam_pos_H * sinh(t) + ray_dir_H * cosh(t);
            vec3 view_dir_emb = -normalize(ray_tangent_at_hit_H.xyz);

            vec3 ambient = ambient_light_color * base_color;
            float NdotL = max(0.0, dot(normal_emb, light_dir_emb));
            vec3 diffuse = directional_light_color * base_color * NdotL;
            vec3 halfway_dir = normalize(light_dir_emb + view_dir_emb);
            float NdotH = max(0.0, dot(normal_emb, halfway_dir));
            vec3 specular = directional_light_color * specular_strength * pow(NdotH, shininess);
            if (NdotL <= 0.0) specular = vec3(0.0);

            vec3 lit_color = ambient + diffuse + specular;

            // Fog effect based on hyperbolic distance t
            float fog_density = 0.25; 
            float fog_factor = exp(-t * fog_density);
            return mix(sky_color, lit_color, fog_factor);
        }

        // No hit: cache probe distances for next iteration and march forward
        cachedDistTerrain = dist_terrain_probe;
        cachedDistTree    = dist_tree_probe;
        cachedTreeRadius  = probeTreeRadius;
        hasCache = true;

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

