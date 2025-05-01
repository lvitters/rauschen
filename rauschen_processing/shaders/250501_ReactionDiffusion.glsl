#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture; // Input from previous frame
uniform float u_time;      // Available uniform

// --- Hardcoded Reaction-Diffusion Parameters ---
// !! Tune these values directly in the code !!

// Base diffusion rates for R, G, B
const vec3 baseDiffRate = vec3(1.0, 0.5, 0.6); // Example: R diffuses fastest, G slowest

// Base feed rates (f) for R, G, B
const vec3 baseFeedRate = vec3(0.055, 0.060, 0.065);

// Base kill rates (k) for R, G, B
const vec3 baseKillRate = vec3(0.062, 0.068, 0.072); // Often k > f

// Time step for simulation
const float dt = 1.0;

// --- Optional Time Modulation ---
// Use u_time to slightly vary parameters, preventing static patterns
const float feedModulation = 0.004; // How much feed rate varies over time
const float killModulation = 0.003; // How much kill rate varies over time
const float timeSpeed = 0.1;       // How fast parameters oscillate


// Helper function to calculate Laplacian
vec3 laplacian(sampler2D tex, vec2 uv, vec2 pixelSize) {
    vec3 sum = vec3(0.0);

    // Von Neumann neighborhood (Center Weight: -1.0, Orthogonal Neighbors: 0.25 each -> Sum = 0)
    // Using direct texture lookups for simplicity
    sum += texture2D(tex, uv + vec2(0.0, pixelSize.y)).rgb;  // Up
    sum += texture2D(tex, uv - vec2(0.0, pixelSize.y)).rgb;  // Down
    sum += texture2D(tex, uv + vec2(pixelSize.x, 0.0)).rgb;  // Right
    sum += texture2D(tex, uv - vec2(pixelSize.x, 0.0)).rgb;  // Left

    // Weighted average (approximation of continuous Laplacian)
    sum *= 0.25; // Average of neighbors

    // Subtract center pixel's value: Average(Neighbors) - Center
    sum -= texture2D(tex, uv).rgb;

    return sum;

    /* Alternative: Moore neighborhood (8 neighbors) - might give smoother results
    vec3 center = texture2D(tex, uv).rgb;
    sum += texture2D(tex, uv + vec2(-pixelSize.x, -pixelSize.y)).rgb; // TL
    sum += texture2D(tex, uv + vec2( 0.0,        -pixelSize.y)).rgb; // T
    sum += texture2D(tex, uv + vec2( pixelSize.x, -pixelSize.y)).rgb; // TR
    sum += texture2D(tex, uv + vec2(-pixelSize.x,  0.0)).rgb;        // L
    sum += texture2D(tex, uv + vec2( pixelSize.x,  0.0)).rgb;        // R
    sum += texture2D(tex, uv + vec2(-pixelSize.x,  pixelSize.y)).rgb; // BL
    sum += texture2D(tex, uv + vec2( 0.0,         pixelSize.y)).rgb; // B
    sum += texture2D(tex, uv + vec2( pixelSize.x,  pixelSize.y)).rgb; // BR
    // Simple average - center (different weights can be used)
    sum /= 8.0;
    sum -= center;
    return sum;
    */
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 pixelSize = 1.0 / u_resolution;

    // Get previous state (R, G, B concentrations)
    vec4 prevState = texture2D(u_texture, uv);
    float R = prevState.r;
    float G = prevState.g;
    float B = prevState.b;

    // Calculate Laplacian (diffusion term)
    vec3 lap = laplacian(u_texture, uv, pixelSize);

    // --- Calculate potentially time-varying parameters ---
    // Oscillate feed/kill rates slightly around their base values using time
    float timeFactorR = (sin(u_time * timeSpeed * 1.1) + 1.0) * 0.5; // 0..1 range
    float timeFactorG = (cos(u_time * timeSpeed * 0.9) + 1.0) * 0.5; // 0..1 range, different phase
    float timeFactorB = (sin(u_time * timeSpeed * 1.3 + 1.5) + 1.0) * 0.5; // 0..1 range, different phase

    vec3 currentFeed = baseFeedRate + vec3(timeFactorR, timeFactorG, timeFactorB) * feedModulation - (feedModulation / 2.0);
    vec3 currentKill = baseKillRate + vec3(timeFactorG, timeFactorB, timeFactorR) * killModulation - (killModulation / 2.0); // Use different time factors

    // Ensure feed/kill rates don't go below zero (or some small epsilon)
    currentFeed = max(currentFeed, vec3(0.001));
    currentKill = max(currentKill, vec3(0.001));


    // --- Reaction Terms (Cyclic Adaptation of Gray-Scott) ---
    // R consumes G, G consumes B, B consumes R
    float RGR = R * G * G;
    float GBR = G * B * B;
    float BRR = B * R * R;

    // --- Apply Reaction-Diffusion Equation ---
    float newR = R + (baseDiffRate.r * lap.r - RGR + currentFeed.r * (1.0 - R) - currentKill.r * R) * dt;
    float newG = G + (baseDiffRate.g * lap.g + RGR - GBR + currentFeed.g * (1.0 - G) - currentKill.g * G) * dt;
    float newB = B + (baseDiffRate.b * lap.b + GBR - BRR + currentFeed.b * (1.0 - B) - currentKill.b * B) * dt;

    // --- Clamp values ---
    vec3 finalColor = clamp(vec3(newR, newG, newB), 0.0, 1.0);

    // --- Output the new state ---
    gl_FragColor = vec4(finalColor, 1.0); // Keep alpha at 1.0
}