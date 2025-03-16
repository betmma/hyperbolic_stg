extern float progress; // The progress of the transition (0.0 to 1.0)

// Simple hash function for randomness
float hash(float n) {
    return fract(sin(n) * 43758.5453 + sin(n * (n + 9898)) * 16931.161);
}

// Function to check if point is inside a triangle
bool pointInTriangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    // Calculate edge vectors
    vec2 e0 = b - a;
    vec2 e1 = c - b;
    vec2 e2 = a - c;
    
    // Calculate vectors from vertices to point
    vec2 v0 = p - a;
    vec2 v1 = p - b;
    vec2 v2 = p - c;
    
    // Calculate cross products
    float c0 = e0.x * v0.y - e0.y * v0.x;
    float c1 = e1.x * v1.y - e1.y * v1.x;
    float c2 = e2.x * v2.y - e2.y * v2.x;
    
    // Point is inside if all cross products have the same sign
    return (c0 <= 0.0 && c1 <= 0.0 && c2 <= 0.0) || (c0 >= 0.0 && c1 >= 0.0 && c2 >= 0.0);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    // Get normalized screen coordinates (0.0 to 1.0)
    vec2 uv = screen_coords / love_ScreenSize.xy;
    
    // Number of spikes from each corner
    const int NUM_SPIKES = 20;
    
    // Default alpha is 0 (transparent)
    float alpha = 0.0;
    
    // Create spikes from top-left corner
    for (int i = 0; i < NUM_SPIKES; i++) {
        // Calculate angle for this spike (distribute across a range)
        float angle = 0.02 + (float(i) / float(NUM_SPIKES - 1)) * 1.1;
        
        // Calculate spike length with variation
        float length = progress * 0.95 * (0.7 + hash(float(i) * 31.23) * 3.6);
        
        // Make spikes longer at the top
        length *= 1.0 + (1.0 - uv.y) * 0.7;
        
        // Calculate spike tip position
        vec2 tip = vec2(0.0, 0.0) + length * vec2(cos(angle), sin(angle));
        
        // Calculate spike width at tip (triangular shape)
        float width = 0.1 * length;
        
        // Calculate perpendicular direction at tip
        vec2 perp = width * vec2(-sin(angle), cos(angle));
        
        // Define triangle vertices
        vec2 a = vec2(0.0, 0.0);  // Origin (top-left)
        vec2 b = tip + perp;      // One corner of spike
        vec2 c = tip - perp;      // Other corner of spike
        
        // Check if current pixel is inside this spike
        if (pointInTriangle(uv, a, b, c)) {
            alpha = alpha * 0.2 + 0.8;
        }
    }
    
    // Create spikes from top-right corner
    for (int i = 0; i < NUM_SPIKES; i++) {
        // Calculate angle for this spike (distribute across a range)
        float angle = 3.14159 - 0.02 - (float(i) / float(NUM_SPIKES - 1)) * 1.1;
        
        // Calculate spike length with variation
        float length = progress * 0.95 * (0.7 + hash(float(i + 100) * 173.31) * 3.6);
        
        // Make spikes longer at the top
        length *= 1.0 + (1.0 - uv.y) * 0.7;
        
        // Calculate spike tip position
        vec2 tip = vec2(1.0, 0.0) + length * vec2(cos(angle), sin(angle));
        
        // Calculate spike width at tip (triangular shape)
        float width = 0.1 * length;
        
        // Calculate perpendicular direction at tip
        vec2 perp = width * vec2(-sin(angle), cos(angle));
        
        // Define triangle vertices
        vec2 a = vec2(1.0, 0.0);  // Origin (top-right)
        vec2 b = tip + perp;      // One corner of spike
        vec2 c = tip - perp;      // Other corner of spike
        
        // Check if current pixel is inside this spike
        if (pointInTriangle(uv, a, b, c)) {
            alpha = alpha * 0.2 + 0.8;
        }
    }
    
    // Ensure full coverage when progress is 1.0
    if (progress >= 0.99) {
        alpha = 1.0;
    }
    
    // Apply the alpha value to the texture
    return vec4(texcolor.rgb, texcolor.a * alpha);
}