precision mediump float; // Or highp for better quality if needed

// Uniforms: These are values passed into the shader from your program
uniform vec2 u_resolution;  // The dimensions of the canvas (e.g., width, height)
uniform sampler2D u_texture; // The input texture (previous frame's output)
uniform float u_time;       // Current time in seconds, used for animation

// --- Configurable Parameters ---
// You can tweak these values to change the behavior of the flow field
const float FLOW_SPEED = 2.0;         // Overall speed of the flow (pixels per frame/step)
const float NOISE_STRENGTH = 0.4;     // How much noise distorts the main flow (0.0 = no distortion, 1.0 = strong)
const float NOISE_SPATIAL_SCALE = 4.0;// Scale of the noise features (larger = smaller, more detailed noise)
const float NOISE_TIME_SCALE = 0.1;   // How fast the noise pattern evolves over time

// --- Helper Functions ---

// Simple hash function to generate a pseudo-random float from a float
float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Simple hash function to generate a pseudo-random float from a 2D vector
float hash2(vec2 p) {
    // Simple dot product based hash
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Simple 2D value noise function
float snoise(vec2 p) {
    vec2 i = floor(p); // Integer part of p
    vec2 f = fract(p); // Fractional part of p

    // Smoothstep interpolation factor (hermite interpolation: 3f^2 - 2f^3)
    f = f * f * (3.0 - 2.0 * f);

    // Hash values for the 4 corners of the grid cell
    float v00 = hash2(i + vec2(0.0, 0.0));
    float v10 = hash2(i + vec2(1.0, 0.0));
    float v01 = hash2(i + vec2(0.0, 1.0));
    float v11 = hash2(i + vec2(1.0, 1.0));

    // Bilinear interpolation
    return mix(mix(v00, v10, f.x), mix(v01, v11, f.x), f.y);
}

// --- Main Shader Logic ---
void main() {
    // Calculate UV coordinates for the current pixel (ranging from 0.0 to 1.0)
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // 1. Determine the main flow direction
    // This creates a base direction that slowly rotates over time.
    // The 'hash1' provides a fixed "random" starting offset for the angle.
    float base_random_angle_offset = hash1(1.2345) * 6.2831853; // Approx 0 to 2*PI
    float time_based_angle_change = u_time * 0.02; // Controls how fast the main direction rotates
    vec2 main_direction = vec2(
        cos(base_random_angle_offset + time_based_angle_change),
        sin(base_random_angle_offset + time_based_angle_change)
    );

    // 2. Generate spatial noise for flow perturbation
    // Noise coordinates are scaled spatially and evolve over time
    vec2 noise_uv_spatial = uv * NOISE_SPATIAL_SCALE;
    vec2 noise_uv_temporal_offset = vec2(u_time * NOISE_TIME_SCALE, -u_time * NOISE_TIME_SCALE * 0.7);

    // Generate two noise values (for x and y components of the noise vector)
    // snoise returns a value between 0.0 and 1.0. We map it to -1.0 to 1.0.
    float noise_x = (snoise(noise_uv_spatial + noise_uv_temporal_offset) - 0.5) * 2.0;
    // Offset the noise input for the y-component to get a different noise pattern
    float noise_y = (snoise(noise_uv_spatial + noise_uv_temporal_offset + vec2(5.2, 1.3)) - 0.5) * 2.0;

    vec2 noise_vector = vec2(noise_x, noise_y);

    // 3. Combine main direction and noise
    // The flow direction is a combination of the main direction and the scaled noise vector.
    // Normalizing ensures consistent speed if NOISE_STRENGTH is high, otherwise noise can also affect speed.
    vec2 combined_flow_direction = normalize(main_direction + noise_vector * NOISE_STRENGTH);

    // 4. Calculate displacement for texture sampling
    // FLOW_SPEED determines how many pixels the texture moves per frame/step in the flow direction.
    vec2 flow_offset_pixels = combined_flow_direction * FLOW_SPEED;

    // Convert the pixel offset to UV offset (UV space is 0.0 to 1.0)
    vec2 displacement_uv = flow_offset_pixels / u_resolution;

    // 5. Calculate source UV for sampling (advection)
    // We subtract the displacement because we're asking:
    // "For the current pixel 'uv', where did its color come FROM in the previous frame?"
    vec2 sample_uv = uv - displacement_uv;

    // 6. Ensure stability: Wrap coordinates using fract()
    // fract() keeps the UV coordinates within the 0.0 to 1.0 range.
    // This makes pixels flowing off one edge reappear on the opposite edge.
    sample_uv = fract(sample_uv);

    // 7. Sample the input texture (previous frame) at the calculated source UV
    vec4 final_color = texture2D(u_texture, sample_uv);

    // Output the final color for the current pixel
    gl_FragColor = final_color;
}