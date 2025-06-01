//Copyright (c) 2021 Butadiene
//Released under the MIT license
//https://opensource.org/licenses/mit-license.php

extern number iTime;      // Provided by Lua: love.timer.getTime()
extern vec2 iResolution;  // Provided by Lua: vec2(love.graphics.getWidth(), love.graphics.getHeight())

const float PI = 3.14159265359; // acos(-1.0) also works

mat2 rot(float r){
    vec2 s = vec2(cos(r), sin(r));
    return mat2(s.x, s.y, -s.y, s.x);
}

float cube(vec3 p, vec3 s){
    vec3 q = abs(p);
    vec3 m = max(s-q, vec3(0.0)); // Ensure second arg is vec3 for max(vec3, vec3)
    return length(max(q-s, vec3(0.0))) - min(min(m.x,m.y),m.z); // Ensure second arg is vec3
}

// Parameter 'col' in tetcol renamed to 'col_in' to avoid ambiguity if used elsewhere
vec4 tetcol(vec3 p_in, vec3 offset_val, float scale_val, vec3 col_in){
    vec4 z = vec4(p_in, 1.0);
    vec3 color_acc = col_in; // Use a local copy to modify

    for(int i = 0; i < 20; i++){ // Loop count 20
        if(z.x + z.y < 0.0) { z.xy = -z.yx; color_acc.z += 1.0; }
        if(z.x + z.z < 0.0) { z.xz = -z.zx; color_acc.y += 1.0; }
        if(z.z + z.y < 0.0) { z.zy = -z.yz; color_acc.x += 1.0; }
        
        z *= scale_val; // This scales all components of z, including z.w
        z.xyz += offset_val * (1.0 - scale_val); // Corrected multiplication
    }
    return vec4(color_acc, (cube(z.xyz, vec3(1.5))) / z.w);
}

// float bpm = 120.0; // This variable is not used in the dist function

// Parameter 't' in dist renamed to 'time_param' as 't' is used for raymarching
vec4 dist(vec3 p_ray, float time_param){ // time_param is actually unused in this function's logic
    p_ray.xy *= rot(PI);
    p_ray.x -= 5.1;

    p_ray.yz *= rot(iTime * 0.25);

    float s = 1.0;
    p_ray.z = abs(p_ray.z) - 3.0;
    p_ray = abs(p_ray) - s * 8.0; // Applies to all components
    p_ray = abs(p_ray) - s * 4.0;
    p_ray = abs(p_ray) - s * 2.0;
    p_ray = abs(p_ray) - s * 1.0;

    vec4 sd = tetcol(p_ray, vec3(1.0), 1.8, vec3(0.0));
    float d_surf = sd.w;
    vec3 col_surf = vec3(1.0) - 0.1 * sd.xyz - vec3(0.3); // Ensure vec3 arithmetic
    col_surf *= exp(-2.5 * d_surf) * 2.0;
    return vec4(col_surf, d_surf);
}
vec3 get_normal(vec3 p_norm, float time_for_dist) {
    // The time_for_dist parameter is for consistency with the dist function's signature,
    // even if dist doesn't use its second float parameter in this specific shader.
    // We use iTime for animations within dist, so that's implicitly handled.
    float eps_norm = 0.001; // Small epsilon for normal calculation
    vec2 hx = vec2(eps_norm, 0.0);
    vec2 hy = vec2(0.0, eps_norm); // For clarity, though hx.yx could be used
    
    // Using central differences for better accuracy
    return normalize(vec3(
        dist(p_norm + hx.xyy, time_for_dist).w - dist(p_norm - hx.xyy, time_for_dist).w,
        dist(p_norm + hx.yxy, time_for_dist).w - dist(p_norm - hx.yxy, time_for_dist).w,
        dist(p_norm + hx.yyx, time_for_dist).w - dist(p_norm - hx.yyx, time_for_dist).w
    ));
}
const float NEAR_CLIP = 0.01; // Adjust this value as needed

vec4 effect(vec4 v_color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords / iResolution.xy;
    // uv.y = 1.0 - uv.y; // Optional: if image is Y-flipped compared to Shadertoy
    
    vec2 p_ndc = (uv - 0.5) * 2.0;
    // p_ndc.y *= -1.0; // Optional: if NDC Y-axis needs flipping

    float rsa = 0.1 + mod(iTime * 0.0005, 32.0);
    float rkt = iTime * 0.2 + 0.5 * PI + 1.05;
    vec3 of = vec3(0.0, 0.0, 0.0);
    vec3 ro = of + vec3(rsa * cos(rkt), -1.2, rsa * sin(rkt));

    vec3 ta = of + vec3(1.0 + cos(iTime) * 0.2, -1.3, 1.0 + sin(iTime) * 0.2);
    
    ro.yx *= rot(iTime * 0.2); 
    ro.zx *= rot(iTime * 0.2);

    vec3 cdir = normalize(ta - ro);
    vec3 side = normalize(cross(cdir, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(side, cdir));
    
    vec3 rd = normalize(p_ndc.x * side + p_ndc.y * up + 0.4 * cdir);

    float d_march;
    // Initialize t_march to the NEAR_CLIP distance instead of 0.0
    float t_march = NEAR_CLIP; 
    vec3 ac = vec3(0.0);
    float ep = 0.0001;

    for(int i = 0; i < 66; i++){
        // The point sampled is ro + rd * t_march, so it starts NEAR_CLIP away
        vec4 rsd = dist(ro + rd * t_march, t_march); 
        d_march = rsd.w;
        
        // Check if the march step would take us behind the near clip plane
        // This is a safeguard, but typically d_march should be positive if outside objects.
        // If d_march is very small AND t_march is near NEAR_CLIP, it means we're close to a surface
        // right at the near clip.
        if (t_march + d_march < NEAR_CLIP && d_march < ep) {
            // Potentially hit something "behind" or exactly at the near clip start.
            // You might want to break or handle this specially.
            // For simplicity, the standard march continues.
            // If d_march is negative (inside an object), t_march could decrease.
        }

        t_march += d_march;
        ac += rsd.xyz;
        
        if(d_march < ep) break;
        if(t_march > 100.0) break; // Max ray distance
    }

    vec3 final_col = 0.04 * ac;

    if(final_col.r < 0.1 && final_col.g < 0.1 && final_col.b < 0.1) {
        final_col = vec3(0.0);
    }
    
    return vec4(final_col*0.2, 1.0);
}