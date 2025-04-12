#ifdef GL_ES
precision mediump float;
#endif

// claude.ai vibe coding

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

// random function based on pixel position
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// improved 1D noise function with better smoothing
float noise(float p) {
    float fl = floor(p);
    float fc = fract(p);
    
    // smoother transition using cubic interpolation
    float u = fc * fc * (3.0 - 2.0 * fc);
    
    return mix(rand(vec2(fl, fl)), rand(vec2(fl + 1.0, fl + 1.0)), u);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy; 	// normalize pixel coords
    vec4 texColor = texture2D(u_texture, uv); 		// get original buffer color
    
    // use pixel coordinates to create unique offsets
    float pixelOffset = rand(floor(uv * 100.0));
    
    // create continuously changing colors that don't settle
    // by using modulo on time to create cycling behavior
    float timeLoop = mod(u_time * 0.2, 20.0); 
    
    // different speeds for each channel
    float r = noise(timeLoop * 0.9 + pixelOffset * 5.0);
    float g = noise(timeLoop * 0.7 + pixelOffset * 7.0);
    float b = noise(timeLoop * 1.1 + pixelOffset * 3.0);
    
    // map to desired range
    r = map(r, 0.0, 1.0, 0.2, 0.8);
    g = map(g, 0.0, 1.0, 0.2, 0.8);
    b = map(b, 0.0, 1.0, 0.2, 0.8);
    
    // add slight oscillation to prevent values from becoming static
    r += 0.05 * sin(timeLoop * 2.0 + uv.x * 10.0);
    g += 0.05 * sin(timeLoop * 3.0 + uv.y * 8.0);
    b += 0.05 * sin(timeLoop * 4.0 + (uv.x + uv.y) * 6.0);
    
    // ensure values stay in valid range
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);
    
    // use a fixed blend factor instead of one that increases with time
    // this ensures the effect remains active without settling
    vec4 noiseColor = vec4(r, g, b, 1.0);
    vec4 finalColor = mix(texColor, noiseColor, 0.5);
    
    gl_FragColor = finalColor;
}