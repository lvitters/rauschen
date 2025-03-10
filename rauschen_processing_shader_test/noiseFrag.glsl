#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(float seed) {
    return fract(sin(seed) * 10000.0);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy; // Normalize coordinates (0-1)
    
    float seed = uv.x * 123.4 + uv.y * 456.7; // Unique seed per pixel
    float r = noise(time + seed);
    float g = noise(time + seed + 1000.0);
    float b = noise(time + seed + 2000.0);

    gl_FragColor = vec4(r, g, b, 1.0); // Output color
}