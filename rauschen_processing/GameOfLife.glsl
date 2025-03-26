#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// helper function to map values from one range to another
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

// random function based on pixel position
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// check if a color has dominant red
bool isDominantRed(vec4 color) {
    float maxC = max(max(color.r, color.g), color.b);
    if (maxC <= 0.0) return false;
    vec3 norm = color.rgb / maxC;
    return norm.r > 0.7 && norm.g < 0.5 && norm.b < 0.5;
}

// check if a color has dominant green
bool isDominantGreen(vec4 color) {
    float maxC = max(max(color.r, color.g), color.b);
    if (maxC <= 0.0) return false;
    vec3 norm = color.rgb / maxC;
    return norm.g > 0.7 && norm.r < 0.5 && norm.b < 0.5;
}

// check if a color has dominant blue
bool isDominantBlue(vec4 color) {
    float maxC = max(max(color.r, color.g), color.b);
    if (maxC <= 0.0) return false;
    vec3 norm = color.rgb / maxC;
    return norm.b > 0.7 && norm.r < 0.5 && norm.g < 0.5;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, uv);
    
    // simplify by using a 3x3 neighborhood
    float dx = 1.0 / u_resolution.x;
    float dy = 1.0 / u_resolution.y;
    
    vec4 n1 = texture2D(u_texture, uv + vec2(-dx, -dy));
    vec4 n2 = texture2D(u_texture, uv + vec2(0.0, -dy));
    vec4 n3 = texture2D(u_texture, uv + vec2(dx, -dy));
    vec4 n4 = texture2D(u_texture, uv + vec2(-dx, 0.0));
    vec4 n5 = texture2D(u_texture, uv + vec2(dx, 0.0));
    vec4 n6 = texture2D(u_texture, uv + vec2(-dx, dy));
    vec4 n7 = texture2D(u_texture, uv + vec2(0.0, dy));
    vec4 n8 = texture2D(u_texture, uv + vec2(dx, dy));
    
    // count neighbors by dominant color
    int rNeighbors = 0;
    int gNeighbors = 0;
    int bNeighbors = 0;
    
    if (isDominantRed(n1)) rNeighbors++;
    if (isDominantRed(n2)) rNeighbors++;
    if (isDominantRed(n3)) rNeighbors++;
    if (isDominantRed(n4)) rNeighbors++;
    if (isDominantRed(n5)) rNeighbors++;
    if (isDominantRed(n6)) rNeighbors++;
    if (isDominantRed(n7)) rNeighbors++;
    if (isDominantRed(n8)) rNeighbors++;
    
    if (isDominantGreen(n1)) gNeighbors++;
    if (isDominantGreen(n2)) gNeighbors++;
    if (isDominantGreen(n3)) gNeighbors++;
    if (isDominantGreen(n4)) gNeighbors++;
    if (isDominantGreen(n5)) gNeighbors++;
    if (isDominantGreen(n6)) gNeighbors++;
    if (isDominantGreen(n7)) gNeighbors++;
    if (isDominantGreen(n8)) gNeighbors++;
    
    if (isDominantBlue(n1)) bNeighbors++;
    if (isDominantBlue(n2)) bNeighbors++;
    if (isDominantBlue(n3)) bNeighbors++;
    if (isDominantBlue(n4)) bNeighbors++;
    if (isDominantBlue(n5)) bNeighbors++;
    if (isDominantBlue(n6)) bNeighbors++;
    if (isDominantBlue(n7)) bNeighbors++;
    if (isDominantBlue(n8)) bNeighbors++;
    
    // check current cell state
    bool isRAlive = isDominantRed(texColor);
    bool isGAlive = isDominantGreen(texColor);
    bool isBAlive = isDominantBlue(texColor);
    
    // start with neutral color
    vec3 newColor = vec3(0.2);
    
    // Apply Conway's Game of Life rules to each channel independently
    
    // red channel rules
    if (isRAlive) {
        if (rNeighbors == 2 || rNeighbors == 3) {
            newColor.r = 0.9; // Red cell survives
        }
    } else {
        if (rNeighbors == 3) {
            newColor.r = 0.9; // Red cell born
        }
    }
    
    // green channel rules
    if (isGAlive) {
        if (gNeighbors == 2 || gNeighbors == 3) {
            newColor.g = 0.9; // Green cell survives
        }
    } else {
        if (gNeighbors == 3) {
            newColor.g = 0.9; // Green cell born
        }
    }
    
    // blue channel rules
    if (isBAlive) {
        if (bNeighbors == 2 || bNeighbors == 3) {
            newColor.b = 0.9; // Blue cell survives
        }
    } else {
        if (bNeighbors == 3) {
            newColor.b = 0.9; // Blue cell born
        }
    }
    
    // initial pattern to seed the simulation
    if (u_time < 1.0) {
        float cellSize = 20.0;
        float patternX = mod(floor(uv.x * cellSize), 3.0);
        float patternY = mod(floor(uv.y * cellSize), 3.0);
        float pattern = mod(patternX + patternY, 3.0);
        
        if (pattern < 1.0) {
            newColor = vec3(0.9, 0.2, 0.2); // Red
        } else if (pattern < 2.0) {
            newColor = vec3(0.2, 0.9, 0.2); // Green
        } else {
            newColor = vec3(0.2, 0.2, 0.9); // Blue
        }
    }
    
    // blend with original texture
    vec3 finalColor = mix(texColor.rgb, newColor, 0.8);
    
    // occasional randomness to prevent stagnation
    if (rand(uv + vec2(u_time * 0.01)) > 0.995) {
        finalColor = mix(finalColor, vec3(rand(uv + vec2(u_time))), 0.3);
    }
    
    gl_FragColor = vec4(finalColor, 1.0);
}