#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// --- Hardcoded Flow/Displacement Parameters ---
const float NOISE_FREQ = 5.0;    // Spatial frequency of the flow noise
const float FLOW_SPEED = 0.005;   // How fast things move (adjust dt equivalent)
const float DISPLACE_STRENGTH = 0.01; // How much the texture displaces itself

// --- Simple Pseudo-Random Number Generator ---
// Necessary because we don't have built-in noise functions
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// --- Simple 2D Value Noise ---
// Uses rand() to create smooth noise for the flow field
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u); // Smooth interpolation (smoothstep)

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
        u.y);
    return res;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 pixelSize = 1.0 / u_resolution; // For potential neighbor sampling in displacement

    // --- 1. Calculate Flow Field Vector ---
    // Use noise based on position and time to get an angle
    float angle = noise(uv * NOISE_FREQ + u_time * 0.1) * 2.0 * 3.14159; // Angle from 0 to 2*PI
    vec2 flow = vec2(cos(angle), sin(angle));

    // --- 2. Calculate Displacement Offset ---
    // Read previous state at current pixel
    vec4 prevState = texture2D(u_texture, uv);

    // Simple displacement based on R and G channels
    vec2 displaceOffset = (prevState.rg - 0.5) * 2.0 * DISPLACE_STRENGTH;

    /* // Alternative: Displacement based on brightness gradient (more complex)
    float centerBrightness = dot(prevState.rgb, vec3(0.333));
    float rightBrightness = dot(texture2D(u_texture, uv + vec2(pixelSize.x, 0.0)).rgb, vec3(0.333));
    float upBrightness    = dot(texture2D(u_texture, uv + vec2(0.0, pixelSize.y)).rgb, vec3(0.333));
    vec2 brightnessGradient = vec2(rightBrightness - centerBrightness, upBrightness - centerBrightness);
    vec2 displaceOffset = normalize(brightnessGradient) * DISPLACE_STRENGTH; // Use gradient direction
    if (length(brightnessGradient) == 0.0) displaceOffset = vec2(0.0); // Avoid NaN
    */


    // --- 3. Calculate Advection (where pixel came from) ---
    vec2 source_uv = uv - flow * FLOW_SPEED;

    // --- 4. Sample Previous Frame at Advected + Displaced UV ---
    // Add the displacement to the source UV
    vec2 final_sample_uv = source_uv + displaceOffset;

    // Handle texture wrapping/clamping if needed (default is often clamp)
    // final_sample_uv = fract(final_sample_uv); // Optional: wrap around edges

    vec4 newColor = texture2D(u_texture, final_sample_uv);

    // Output the advected/displaced color
    gl_FragColor = newColor;
}