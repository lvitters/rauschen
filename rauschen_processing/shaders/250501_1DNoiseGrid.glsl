#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture; // Input texture from the previous frame (ping-pong)
uniform float u_time;

// --- Helper Functions (Unchanged) ---
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float rand(vec2 co) {
    // Using fract(sin()) for pseudo-randomness based on position
    // Consider alternatives if patterns emerge
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(float p) {
    float fl = floor(p);
    float fc = fract(p);
    // Cubic interpolation (smoothstep)
    float u = fc * fc * (3.0 - 2.0 * fc);
    // Interpolate between random values at integer points
    return mix(rand(vec2(fl, fl)), rand(vec2(fl + 1.0, fl + 1.0)), u);
}

// --- Main Shader Logic ---
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, uv); // Get color from PREVIOUS frame

    // --- Calculate Noise Signals ---
    // Get a unique offset per pixel based on its position.
    // floor(uv * 100.0) creates 10x10 blocks with the same offset.
    // Use uv directly or scale differently for smoother/finer grain variation.
    float pixelOffset = rand(floor(uv * 100.0));
    // float pixelOffset = rand(uv * 50.0); // Example: smaller blocks or no floor

    // Looping time value
    float timeLoop = mod(u_time * 0.2, 20.0);

    // Calculate separate noise values for R, G, B channels
    // These values are in the range [0, 1]
    float noiseR = noise(timeLoop * 0.9 + pixelOffset * 5.0);
    float noiseG = noise(timeLoop * 0.7 + pixelOffset * 7.0);
    float noiseB = noise(timeLoop * 1.1 + pixelOffset * 3.0);

    // --- Modify the Input Color using Noise ---

    // Define how strongly the noise affects the color. Adjust this value!
    // Smaller values mean subtle changes, larger values mean more drastic changes.
    float modificationStrength = 0.1; // Example: Adjust between ~0.01 and 1.0+

    // Method 1: Additive Offset
    // Center noise around 0 (range becomes [-0.5, +0.5]) and scale by strength
    float r_offset = (noiseR - 0.5) * modificationStrength;
    float g_offset = (noiseG - 0.5) * modificationStrength;
    float b_offset = (noiseB - 0.5) * modificationStrength;

    // Apply the offset to the input color components
    float finalR = texColor.r + r_offset;
    float finalG = texColor.g + g_offset;
    float finalB = texColor.b + b_offset;

    // --- (Optional) Remove the explicit Sine wave addition ---
    // These add regular wave patterns, which might not be desired if you want pure noise modification.
    /*
    finalR += 0.05 * sin(timeLoop * 2.0 + uv.x * 10.0) * modificationStrength;
    finalG += 0.05 * sin(timeLoop * 3.0 + uv.y * 8.0) * modificationStrength;
    finalB += 0.05 * sin(timeLoop * 4.0 + (uv.x + uv.y) * 6.0) * modificationStrength;
    */

    // Clamp the final results to ensure they stay within the valid [0, 1] range
    finalR = clamp(finalR, 0.0, 1.0);
    finalG = clamp(finalG, 0.0, 1.0);
    finalB = clamp(finalB, 0.0, 1.0);

    // Set the final fragment color, preserving the original alpha
    gl_FragColor = vec4(finalR, finalG, finalB, texColor.a);
}