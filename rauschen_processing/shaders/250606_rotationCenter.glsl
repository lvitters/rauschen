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

// Simple 2D noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal noise (multiple octaves)
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// 2D rotation matrix
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Sample the original texture
    vec3 originalColor = texture2D(u_texture, uv).rgb;
    
    // Create a region ID based on quantized color
    vec3 quantized = floor(originalColor * 4.0) / 4.0;
    float regionID = hash(quantized.rg);
    
    // Time-varying rotation parameters using noise
    float timeScale = u_time * 0.0005;
    vec2 noiseInput = vec2(regionID * 10.0, timeScale);
    
    // Dynamic rotation speed and direction
    float rotationNoise = fbm(noiseInput) * 2.0 - 1.0; // Range: -1 to 1
    float rotationDirection = sign(rotationNoise); // -1 or 1 for direction
    float rotationSpeed = abs(rotationNoise) * 2.0 + 0.1; // Always positive, varies intensity
    float rotationAngle = timeScale * rotationSpeed * rotationDirection * (0.5 + regionID);
    
    // Dynamic rotation radius using different noise
    vec2 radiusNoiseInput = vec2(regionID * 15.0 + 100.0, timeScale * 0.8);
    float radiusNoise = fbm(radiusNoiseInput);
    float baseRadius = 0.15; // Base rotation radius
    float radiusVariation = 0.12; // How much the radius can vary
    float dynamicRadius = baseRadius + radiusVariation * radiusNoise;
    
    // Keep rotation center at screen center
    vec2 rotationCenter = vec2(0.5);
    
    // Calculate distance from center
    vec2 toCenter = uv - rotationCenter;
    float distanceToCenter = length(toCenter);
    
    // Apply rotation with smooth falloff
    if (distanceToCenter < dynamicRadius) {
        // Smooth falloff at the edges
        float falloff = smoothstep(dynamicRadius, dynamicRadius * 0.7, distanceToCenter);
        
        // Apply rotation with falloff
        vec2 rotated = rotate2D(rotationAngle * falloff) * toCenter;
        vec2 newUV = rotationCenter + rotated;
        newUV = clamp(newUV, 0.0, 1.0);
        
        vec3 rotatedColor = texture2D(u_texture, newUV).rgb;
        
        // Blend between original and rotated based on falloff
        vec3 finalColor = mix(originalColor, rotatedColor, falloff);
        gl_FragColor = vec4(finalColor, 1.0);
    } else {
        // Use original color for pixels outside rotation area
        gl_FragColor = vec4(originalColor, 1.0);
    }
}