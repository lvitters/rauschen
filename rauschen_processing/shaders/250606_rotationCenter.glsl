#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_cells_x;
uniform float u_cells_y;

// Hash function for pseudo-random numbers
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D rotation matrix
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // First, just sample the original texture
    vec3 originalColor = texture2D(u_texture, uv).rgb;
    
    // Create a simple region ID based on quantized color
    vec3 quantized = floor(originalColor * 4.0) / 4.0;
    float regionID = hash(quantized.rg);
    
    // Very slow rotation based on region
    float rotationAngle = u_time * 0.001 * (0.5 + regionID);
    
    // Create a rotation center - use a simple approach
    vec2 centerOffset = vec2(hash(vec2(regionID * 12.34)), hash(vec2(regionID * 56.78))) - 0.5;
    centerOffset *= 0.1; // Small offset from UV center
    vec2 rotationCenter = vec2(0.5) + centerOffset;
    
    // Calculate distance from center - only rotate nearby pixels  
    vec2 toCenter = uv - rotationCenter;
    float distanceToCenter = length(toCenter);
    
    // Only apply rotation if we're within a reasonable distance
    if (distanceToCenter < 0.2) {
        vec2 rotated = rotate2D(rotationAngle) * toCenter;
        vec2 newUV = rotationCenter + rotated;
        newUV = clamp(newUV, 0.0, 1.0);
        gl_FragColor = vec4(texture2D(u_texture, newUV).rgb, 1.0);
    } else {
        // Just use original color for pixels far from rotation centers
        gl_FragColor = vec4(originalColor, 1.0);
    }
}