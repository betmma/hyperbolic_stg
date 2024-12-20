extern vec2 center;   // The center of the circle
extern float radius;  // The radius of the circle

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
    // Get the distance from the pixel to the center of the circle
    float dist = distance(pixel_coords, center);
    
    // If the pixel is within the circle, invert the colors
    if (dist <= radius) {
        // Get the original color from the texture
        vec4 texColor = Texel(texture, texture_coords);
        
        // Invert the colors by subtracting from 1
        texColor.rgb = vec3(1.0) - texColor.rgb;
        
        return texColor;
    } else {
        // Else, return the original color
        return Texel(texture, texture_coords);
    }
}