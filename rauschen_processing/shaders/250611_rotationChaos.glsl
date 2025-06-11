#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform float u_time;
uniform vec2 u_resolution;

// Hash function for pseudo-random numbers (from your original code)
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D rotation matrix (from your original code)
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

// MODIFIED: Added a 2D Simplex Noise function.
// This function will generate our smooth, random values.
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                       -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m;
    m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    vec3 originalColor = texture2D(u_texture, uv).rgb;
    
    vec3 quantized = floor(originalColor * 4.0) / 4.0;
    float regionID = hash(quantized.rg);
    
    // --- MODIFICATIONS START HERE ---
    
    // 1. DYNAMIC ROTATION SPEED AND DIRECTION (SLOWER)
    float rotationSpeedNoise = snoise(vec2(regionID * 5.0, u_time * 0.1));
    float rotationAngle = u_time * 0.05 * rotationSpeedNoise;

    // 2. DYNAMIC ROTATION CENTER
    float offsetX = snoise(vec2(regionID * 12.34, u_time * 0.05));
    float offsetY = snoise(vec2(regionID * 56.78, u_time * 0.05));
    
    // MODIFIED: Added a new noise calculation to control the MAGNITUDE of the center's movement.
    // I'm using a very slow time multiplier (0.02) so this effect changes gradually.
    float variationMagnitudeNoise = (snoise(vec2(u_time * 0.02, regionID * 7.0)) + 1.0) * 0.5; // Map noise to [0, 1]
    
    // Now, map the [0, 1] noise value to our desired [0.25, 0.45] range.
    float dynamicVariationMagnitude = 0.2 + variationMagnitudeNoise * 0.10; // 0.20 is the range (0.35 - 0.25)

    // Apply the new dynamic magnitude instead of a fixed number.
    vec2 centerOffset = vec2(offsetX, offsetY) * dynamicVariationMagnitude; 
    vec2 rotationCenter = vec2(0.5) + centerOffset;
    
    // 3. DYNAMIC RADIUS (Unchanged)
    float radiusNoise = (snoise(vec2(regionID * 3.0, u_time * 0.08)) + 1.0) * 0.5;
    float dynamicRadius = 0.05 + radiusNoise * 0.2;

    // --- MODIFICATIONS END HERE ---

    vec2 toCenter = uv - rotationCenter;
    float distanceToCenter = length(toCenter);
    
    if (distanceToCenter < dynamicRadius) {
        vec2 rotated = rotate2D(rotationAngle) * toCenter;
        vec2 newUV = rotationCenter + rotated;
        newUV = clamp(newUV, 0.0, 1.0);
        gl_FragColor = vec4(texture2D(u_texture, newUV).rgb, 1.0);
    } else {
        gl_FragColor = vec4(originalColor, 1.0);
    }
}