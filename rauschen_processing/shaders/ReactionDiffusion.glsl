#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// constants for the Gray-Scott reaction-diffusion model
const float dA = 1.0;     // diffusion rate for chemical A
const float dB = 0.5;     // diffusion rate for chemical B
const float dt = 0.8;     // time step size

// helper function for random number generation
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, uv);
    
    // Use time to create evolving parameters
    // This makes the simulation change behavior over time
    float timeCycle = sin(u_time * 0.1) * 0.5 + 0.5; // oscillates between 0 and 1
    
    // Parameters that change over time
    float feed = 0.035 + 0.01 * timeCycle;
    float kill = 0.062 - 0.01 * timeCycle;
    
    // Create moving feed/kill zones using time
    float xWave = sin(uv.x * 10.0 + u_time * 0.2) * 0.5 + 0.5;
    float yWave = cos(uv.y * 8.0 - u_time * 0.15) * 0.5 + 0.5;
    
    // Local parameter variations based on time and position
    float localFeed = feed * (1.0 + 0.5 * xWave);
    float localKill = kill * (1.0 + 0.5 * yWave);
    
    // sample the neighborhood for diffusion calculation
    float dx = 1.0 / u_resolution.x;
    float dy = 1.0 / u_resolution.y;
    
    vec4 center = texColor;
    vec4 left = texture2D(u_texture, uv + vec2(-dx, 0.0));
    vec4 right = texture2D(u_texture, uv + vec2(dx, 0.0));
    vec4 top = texture2D(u_texture, uv + vec2(0.0, -dy));
    vec4 bottom = texture2D(u_texture, uv + vec2(0.0, dy));
    vec4 topLeft = texture2D(u_texture, uv + vec2(-dx, -dy));
    vec4 topRight = texture2D(u_texture, uv + vec2(dx, -dy));
    vec4 bottomLeft = texture2D(u_texture, uv + vec2(-dx, dy));
    vec4 bottomRight = texture2D(u_texture, uv + vec2(dx, dy));
    
    // use red channel as chemical A and blue channel as chemical B
    float a = center.r;
    float b = center.b;
    
    // compute Laplacian for A and B 
    float laplaceA = (left.r + right.r + top.r + bottom.r + 
                      0.5 * (topLeft.r + topRight.r + bottomLeft.r + bottomRight.r)) / 6.0 - center.r;
    
    float laplaceB = (left.b + right.b + top.b + bottom.b + 
                      0.5 * (topLeft.b + topRight.b + bottomLeft.b + bottomRight.b)) / 6.0 - center.b;
    
    // reaction-diffusion equations with time-varying parameters
    float reaction = a * b * b;
    
    // update a and b
    float nextA = a + dt * (dA * laplaceA - reaction + localFeed * (1.0 - a));
    float nextB = b + dt * (dB * laplaceB + reaction - (localKill) * b);
    
    // clamp values to valid range
    nextA = clamp(nextA, 0.0, 1.0);
    nextB = clamp(nextB, 0.0, 1.0);
    
    // Use original texture to seed the system
    float brightness = (texColor.r + texColor.g + texColor.b) / 3.0;
    
    // Continuously inject new patterns over time
    float timePhase = mod(u_time, 20.0);
    if (timePhase < 0.5) {
        // Every 20 time units, inject new pattern seeds
        float seedPattern = step(0.85, random(uv + vec2(floor(u_time * 0.05))));
        nextB = mix(nextB, 1.0, seedPattern * 0.5);
    }
    
    // Add moving seed points that drop chemical B
    vec2 seedPos1 = vec2(0.5 + 0.4 * sin(u_time * 0.2), 0.5 + 0.4 * cos(u_time * 0.17));
    vec2 seedPos2 = vec2(0.5 + 0.4 * sin(u_time * 0.11 + 2.0), 0.5 + 0.4 * cos(u_time * 0.13));
    
    float seedDist1 = length(uv - seedPos1);
    float seedDist2 = length(uv - seedPos2);
    
    if (seedDist1 < 0.02 || seedDist2 < 0.02) {
        nextB = mix(nextB, 1.0, 0.2);
    }
    
    // Initial condition
    if (u_time < 0.5) {
        // Start with a field of A with some B seeds
        nextA = 1.0;
        nextB = step(0.7, sin(uv.x * 20.0) * sin(uv.y * 20.0)) * 0.5;
        
        // Use original texture to influence initial pattern
        nextB = mix(nextB, brightness * 0.8, 0.5);
    }
    
    // Dynamic color mapping that changes with time
    vec3 color1 = vec3(0.1, 0.0, 0.4 + 0.2 * sin(u_time * 0.1));
    vec3 color2 = vec3(0.8 - 0.2 * sin(u_time * 0.13), 0.8, 0.1);
    vec3 color3 = vec3(1.0, 0.4 + 0.2 * sin(u_time * 0.07), 0.0);
    
    float value = nextA - nextB * 1.2;
    
    vec3 finalColor;
    if (value < 0.3) {
        finalColor = color1;
    } else if (value < 0.6) {
        float t = (value - 0.3) / 0.3;
        finalColor = mix(color1, color2, t);
    } else {
        float t = (value - 0.6) / 0.4;
        finalColor = mix(color2, color3, t);
    }
    
    //// Store the reaction-diffusion state for the next frame
    gl_FragColor = vec4(nextA, 0.5, nextB, 1.0);
    
    // Alternative: Visualize the reaction-diffusion state
    gl_FragColor = vec4(finalColor, 1.0);
}