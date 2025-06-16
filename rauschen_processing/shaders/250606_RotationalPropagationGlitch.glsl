#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform float u_time;
uniform vec2 u_resolution;

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

// Fast region ID based on current pixel color only
float getRegionID(vec2 uv) {
    vec3 color = texture2D(u_texture, uv).rgb;
    // Quantize color to create regions
    vec3 quantized = floor(color * 6.0) / 6.0;
    return hash(quantized.xy + quantized.z * 0.1);
}

// Estimate region center using a simple grid-based approach
vec2 getRegionCenter(vec2 uv, float regionID) {
    vec2 gridSize = vec2(32.0); // Divide screen into 32x32 grid
    vec2 gridPos = floor(uv * gridSize) / gridSize;
    
    // Use grid position and region ID to create pseudo-center
    vec2 offset = vec2(hash(vec2(regionID * 12.34, gridPos.x)), 
                       hash(vec2(regionID * 56.78, gridPos.y)));
    offset = (offset - 0.5) * 0.1; // Small random offset within grid cell
    
    return gridPos + vec2(1.0 / gridSize) * 0.5 + offset;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Get region ID for current pixel (single texture sample)
    float regionID = getRegionID(uv);
    
    // Create stable rotation parameters based on region ID
    float rotationSeed = hash(vec2(regionID * 123.45, regionID * 67.89));
    float rotationSpeed = 0.3 + rotationSeed * 1.0;
    float rotationAngle = u_time * 0.008 * rotationSpeed;
    
    // Get estimated region center (no additional texture samples)
    vec2 regionCenter = getRegionCenter(uv, regionID);
    
    // Apply rotation around region center
    vec2 relativePos = uv - regionCenter;
    
    // Scale rotation effect based on distance from center
    float dist = length(relativePos);
    float rotationStrength = smoothstep(0.15, 0.05, dist);
    
    vec2 rotatedPos = mix(relativePos, rotate2D(rotationAngle) * relativePos, rotationStrength);
    vec2 finalUV = regionCenter + rotatedPos;
    
    // Clamp to texture bounds
    finalUV = clamp(finalUV, 0.0, 1.0);
    
    // Sample the texture at the rotated position
    vec4 color = texture2D(u_texture, finalUV);
    
    // Subtle color shift for visual feedback
    float rotationPhase = sin(rotationAngle + regionID * 6.28) * 0.03;
    color.rgb += rotationPhase * vec3(rotationSeed, 1.0 - rotationSeed, rotationSeed * 0.5);
    
    gl_FragColor = color;
}