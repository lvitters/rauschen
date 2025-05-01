#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// --- Hardcoded CA Parameters (Tune these!) ---
// Adjusted for potentially more activity and less decay
const float GROWTH_PEAK = 0.35;  // Center of optimal neighbor brightness for growth
const float GROWTH_WIDTH = 0.15; // Wider growth range (try 0.1 - 0.2)
const float GROWTH_RATE = 0.25; // Slightly faster growth (try 0.15 - 0.35)
const float DECAY_RATE = 0.025; // Slower decay (try 0.01 - 0.04)
const float DT = 1.0;            // Time step influence (usually 1.0)

// --- Time Modulation & Noise ---
const float PARAM_WIGGLE = 0.05; // Keep range of oscillation
const float TIME_SPEED = 0.15;   // Keep speed of oscillation
const float PERTURB_STRENGTH = 0.01; // Strength of random perturbation

// --- Color Dynamics ---
// Changed RATE to AMOUNT as we use sin() for oscillation
const float HUE_ROTATION_AMOUNT = 0.04; // How much hue *can* shift (try 0.01 - 0.05)

// --- Simple Pseudo-Random Number Generator ---
float rand(vec2 co){
    // Seed with time to ensure frame-to-frame difference
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453 + u_time);
}

// --- RGB <-> HSV Conversion Functions (Standard) ---
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// --- Helper Functions for CA ---
float averageNeighborsBrightness(sampler2D tex, vec2 uv, vec2 pixelSize) {
    float sum = 0.0;
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
             // If including center pixel average:
            vec4 neighbor = texture2D(tex, uv + vec2(x, y) * pixelSize);
            sum += dot(neighbor.rgb, vec3(0.299, 0.587, 0.114));
             // If excluding center pixel average:
             // if (x != 0.0 || y != 0.0) { // Don't sample center pixel for average
             //    vec4 neighbor = texture2D(tex, uv + vec2(x, y) * pixelSize);
             //    sum += dot(neighbor.rgb, vec3(0.299, 0.587, 0.114));
             // }
        }
    }
     return sum / 9.0; // Divide by 9 if including center, 8 if excluding
    // return sum / 8.0; // If excluding center
}

float growthFactor(float avg_neighbors, float peak, float width) {
    width = max(width, 0.001);
    float dist_sq = (avg_neighbors - peak) * (avg_neighbors - peak);
    return exp(-dist_sq / (2.0 * width * width));
}

// --- Main Shader Logic ---
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 pixelSize = 1.0 / u_resolution;

    vec4 prevState = texture2D(u_texture, uv);
    vec3 prevColor = prevState.rgb;
    float currentStateBrightness = dot(prevColor, vec3(0.299, 0.587, 0.114));

    float avgN = averageNeighborsBrightness(u_texture, uv, pixelSize);

    // Calculate time-modulated parameters
    float timeWiggle = sin(u_time * TIME_SPEED) * PARAM_WIGGLE;
    float currentGrowthPeak = GROWTH_PEAK + timeWiggle;
    float currentGrowthWidth = max(GROWTH_WIDTH + cos(u_time * TIME_SPEED * 0.7 + 2.0) * PARAM_WIGGLE * 0.5, 0.02); // Ensure width > 0

    float growth = growthFactor(avgN, currentGrowthPeak, currentGrowthWidth);

    // --- Modify Change Calculation with Survival Term ---
    // Reduce decay significantly if the cell is already bright (alive)
    float survivalFactor = smoothstep(0.1, 0.3, currentStateBrightness); // Increase survival boost range

    float growTerm = growth * GROWTH_RATE * (1.0 - currentStateBrightness);
    // Decay is reduced by survivalFactor
    float decayTerm = (1.0 - growth) * (1.0 - survivalFactor) * DECAY_RATE * currentStateBrightness;

    float change = growTerm - decayTerm;

    // Add perturbation
    float perturb = (rand(uv) - 0.5) * PERTURB_STRENGTH;
    float nextStateBrightness = currentStateBrightness + change * DT + perturb;

    nextStateBrightness = clamp(nextStateBrightness, 0.05, 1.0);

    // --- Color Handling ---
    vec3 hsv = rgb2hsv(prevColor);
    float prevSaturation = hsv.y;
    float prevHue = hsv.x;

    if (currentStateBrightness < 0.02) { // Was black
        if (nextStateBrightness >= 0.02) { // Coming alive
            // Assign random hue
            hsv.x = rand(uv + vec2(0.1,0.0)); // Use rand based only on uv for stable revival color? Or keep time? Let's try rand(uv).
            // hsv.x = rand(uv + u_time * 0.01); // Slower time variation for revival hue
            hsv.y = 0.85; // Start saturated
            hsv.z = nextStateBrightness;
        } else { // Stay black
            hsv = vec3(prevHue, 0.0, 0.0); // Keep hue, but black
        }
    } else { // Already had color
        // 1. Rotate Hue using sin() based on change speed
        hsv.x = fract(prevHue + sin(change * 10.0) * HUE_ROTATION_AMOUNT); // Oscillating shift

        // 2. Modulate Saturation
        hsv.y = clamp(prevSaturation * 0.7 + nextStateBrightness * 0.5, 0.2, 1.0); // Adjusted formula, ensure min sat

        // 3. Set Value (Brightness)
        hsv.z = nextStateBrightness;
    }

    vec3 finalColorRGB = hsv2rgb(hsv);

    gl_FragColor = vec4(finalColorRGB, 1.0);
}