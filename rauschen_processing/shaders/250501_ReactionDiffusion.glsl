#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture; // Input texture (previous frame's state: R=A, B=B)
uniform float u_time;

// == Gray-Scott Reaction-Diffusion Parameters ==

// Diffusion rates
const float dA = 1.0; 
const float dB = 0.5; 

// Time step (larger steps can be faster but less stable)
const float dt = 1.0; // Increased slightly from original for potentially faster evolution

// Feed/Kill Rates - These determine the pattern!
// Choose ONE pair by uncommenting it.
// float feed = 0.0545; float kill = 0.062;  // Mitosis / Coral Growth (U-Skate World)
// float feed = 0.026; float kill = 0.051;  // Solitons / Spots
float feed = 0.0367; float kill = 0.0649; // Defaulting to a known stable pattern
// float feed = 0.078; float kill = 0.061;  // Worms / Stripes
// float feed = 0.03; float kill = 0.057;  // Chaos / Bubbles

// --- Optional: Time/Space Varying Feed/Kill ---
// You can uncomment these lines *instead* of the fixed feed/kill above
// to restore the original dynamic behavior (may need careful tuning).
// float timeCycle = sin(u_time * 0.1) * 0.5 + 0.5; 
// float dynamicFeed = 0.035 + 0.01 * timeCycle;
// float dynamicKill = 0.062 - 0.01 * timeCycle;
// float xWave = sin(uv.x * 10.0 + u_time * 0.2) * 0.5 + 0.5;
// float yWave = cos(uv.y * 8.0 - u_time * 0.15) * 0.5 + 0.5;
// feed = dynamicFeed * (1.0 + 0.5 * xWave); // Assign to the 'feed' variable
// kill = dynamicKill * (1.0 + 0.5 * yWave); // Assign to the 'kill' variable
// --- End Optional ---


// Helper function for random number generation (used in optional perturbations)
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 center = texture2D(u_texture, uv); // Read previous state: R=A, B=B

    float a = center.r;
    float b = center.b;
    
    float nextA;
    float nextB;

    // == Initial Conditions (only runs for the first few frames) ==
    if (u_time < 0.5) { 
        // Start with A=1 everywhere, B=0 mostly
        nextA = 1.0;
        nextB = 0.0;
        
        // Seed B in a small central area
        vec2 centerDist = abs(uv - vec2(0.5)); 
        if (max(centerDist.x, centerDist.y) < 0.05) { // e.g., 10% wide square
            nextB = 1.0; // High concentration of B
        }
        
        // --- Alternative Initial Condition: Use input texture brightness ---
        // Uncomment this section INSTEAD of the central square seed if desired
        // float brightness = (center.r + center.g + center.b) / 3.0; 
        // // You might still want A=1 initially regardless of texture
        // nextA = 1.0; 
        // nextB = step(0.7, sin(uv.x * 20.0) * sin(uv.y * 20.0)) * 0.5; // Original sin pattern
        // nextB = mix(nextB, brightness * 0.8, 0.5); // Mix with brightness
        // --- End Alternative Initial Condition ---

    } else {
        // == Reaction-Diffusion Calculation (for u_time >= 0.5) ==
        
        // Sample the neighborhood 
        float dx = 1.0 / u_resolution.x;
        float dy = 1.0 / u_resolution.y;
        
        vec4 left   = texture2D(u_texture, uv + vec2(-dx, 0.0));
        vec4 right  = texture2D(u_texture, uv + vec2(dx, 0.0));
        vec4 top    = texture2D(u_texture, uv + vec2(0.0, -dy));
        vec4 bottom = texture2D(u_texture, uv + vec2(0.0, dy));
        vec4 tl     = texture2D(u_texture, uv + vec2(-dx, -dy));
        vec4 tr     = texture2D(u_texture, uv + vec2(dx, -dy));
        vec4 bl     = texture2D(u_texture, uv + vec2(-dx, dy));
        vec4 br     = texture2D(u_texture, uv + vec2(dx, dy));
        
        // Compute Laplacian using a common weighted kernel
        // (Weights: Center=-1, Adjacent=0.2, Diagonal=0.05)
        float laplaceA = (a * -1.0) + 
                         (left.r + right.r + top.r + bottom.r) * 0.2 + 
                         (tl.r + tr.r + bl.r + br.r) * 0.05;
        
        float laplaceB = (b * -1.0) +
                         (left.b + right.b + top.b + bottom.b) * 0.2 +
                         (tl.b + tr.b + bl.b + br.b) * 0.05;

        // --- Original Laplacian Calculation (commented out) ---                 
        // float laplaceA = (left.r + right.r + top.r + bottom.r + 
        //                   0.5 * (tl.r + tr.r + bl.r + br.r)) / 6.0 - a;
        // float laplaceB = (left.b + right.b + top.b + bottom.b + 
        //                   0.5 * (tl.b + tr.b + bl.b + br.b)) / 6.0 - b;
        // --- End Original Laplacian ---

        // Gray-Scott reaction term
        float reaction = a * b * b;
        
        // Update A and B using the chosen feed/kill rates
        nextA = a + dt * (dA * laplaceA - reaction + feed * (1.0 - a));
        nextB = b + dt * (dB * laplaceB + reaction - (kill + feed) * b); // Standard kill term
        // nextB = b + dt * (dB * laplaceB + reaction - (kill) * b); // Original kill term (might also work)
    }

    // Clamp values BEFORE applying perturbations (if any)
    nextA = clamp(nextA, 0.0, 1.0);
    nextB = clamp(nextB, 0.0, 1.0);

    // == Optional Perturbations (Uncomment to enable) ==
    // These add extra B chemical to the system in different ways

    // // 1. Periodic random seeding
    // float timePhase = mod(u_time, 30.0); // Every 30 seconds
    // if (timePhase < 0.1) { // For a short duration
    //     // Seed only in areas where B is already low, helps prevent oversaturation
    //     if (random(uv + floor(u_time)) > 0.99 && nextB < 0.1) { 
    //         nextB = 0.5; // Add a significant amount of B
    //     }
    // }
    
    // // 2. Moving seed points
    // vec2 seedPos1 = vec2(0.5 + 0.4 * sin(u_time * 0.20), 0.5 + 0.4 * cos(u_time * 0.17));
    // vec2 seedPos2 = vec2(0.5 + 0.4 * sin(u_time * -0.11 + 2.0), 0.5 + 0.4 * cos(u_time * 0.13));
    // float seedRadius = 0.015;
    // if (length(uv - seedPos1) < seedRadius || length(uv - seedPos2) < seedRadius) {
    //     nextB = mix(nextB, 1.0, 0.5); // Strongly add B near moving points
    // }

    // // Clamp values AGAIN after perturbations if they are enabled
    // nextA = clamp(nextA, 0.0, 1.0);
    // nextB = clamp(nextB, 0.0, 1.0);
    // == End Optional Perturbations ==


    // == Output ==
    // Store the calculated state (A in Red, B in Blue) for the next frame's calculation.
    // Green channel is unused (set to 0). Alpha is 1.
    gl_FragColor = vec4(nextA, 0.0, nextB, 1.0); 


    // == Optional Visualization (Commented Out) ==
    // To see colors, you would typically use a second shader pass or draw this texture 
    // in Processing using a custom color mapping based on the R (A) and B (B) channels.
    // Example color mapping from original shader:
    // vec3 color1 = vec3(0.1, 0.0, 0.4 + 0.2 * sin(u_time * 0.1));
    // vec3 color2 = vec3(0.8 - 0.2 * sin(u_time * 0.13), 0.8, 0.1);
    // vec3 color3 = vec3(1.0, 0.4 + 0.2 * sin(u_time * 0.07), 0.0);
    // float value = nextA - nextB * 1.2;
    // vec3 finalColor;
    // if (value < 0.3) { finalColor = color1; } 
    // else if (value < 0.6) { finalColor = mix(color1, color2, (value - 0.3) / 0.3); } 
    // else { finalColor = mix(color2, color3, (value - 0.6) / 0.4); }
    // // gl_FragColor = vec4(finalColor, 1.0); // This line would VISUALIZE, not store state
    // == End Optional Visualization ==
}