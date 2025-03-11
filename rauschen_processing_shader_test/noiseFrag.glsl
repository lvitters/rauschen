#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

// Random function based on pixel position
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Basic 1D noise function
float noise(float p){
    float fl = floor(p);
    float fc = fract(p);
    return mix(rand(vec2(fl, fl)), rand(vec2(fl + 1.0, fl + 1.0)), fc);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy; // normalize pixel coords

    // Use pixel position to get different randomness per pixel
    float r = noise(u_time + rand(uv));
    float g = noise(u_time + rand(uv) + rand(uv));
    float b = noise(u_time + rand(uv) + rand(uv) + rand(uv));

    r = map(r, 0.0, 1.0, 0.2, 0.8);
    g = map(g, 0.0, 1.0, 0.2, 0.8);
    b = map(b, 0.0, 1.0, 0.2, 0.8);

    gl_FragColor = vec4(r, g, b, 1.0);
}