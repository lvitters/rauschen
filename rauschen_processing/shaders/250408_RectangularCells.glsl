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

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    // vec4 texColor = texture2D(u_texture, uv); // texColor wasn't used, can be removed if not needed elsewhere

    // create a grid effect by discretizing the coordinates
    float cellSize = 16.0; // Adjust for larger/smaller cells
    vec2 cell = floor(uv * u_resolution / cellSize);
    vec2 cellUV = fract(uv * u_resolution / cellSize);

    // sample the current cell's color
    vec2 cellCoord = (cell + vec2(0.5)) * cellSize / u_resolution;
    vec4 cellColor = texture2D(u_texture, cellCoord); // This is the original color we want to preserve

    // calculate cell "value" based on brightness
    float cellValue = (cellColor.r + cellColor.g + cellColor.b) / 3.0;

    // create a pulsing effect based on time and cell value
    float pulse = sin(u_time + cellValue * 10.0) * 0.5 + 0.5; // Pulse ranges 0.0 to 1.0

    // create different effects per cell based on original color
    float edgeThreshold = 0.2 + 0.1 * sin(u_time * 0.2);
    float edge = step(edgeThreshold, cellUV.x) * step(edgeThreshold, cellUV.y) *
                 step(edgeThreshold, 1.0 - cellUV.x) * step(edgeThreshold, 1.0 - cellUV.y);

    // create a time-based color cycle (this is the color that was overpowering the original)
    float hue = cellValue * 2.0 + u_time * 0.1;
    vec3 cycleColor;

    // simple HSV to RGB conversion for the hue cycle
    hue = fract(hue);
    if (hue < 1.0/6.0) {
        cycleColor = vec3(1.0, hue*6.0, 0.0);
    } else if (hue < 2.0/6.0) {
        cycleColor = vec3(2.0-hue*6.0, 1.0, 0.0);
    } else if (hue < 3.0/6.0) {
        cycleColor = vec3(0.0, 1.0, (hue-2.0/6.0)*6.0);
    } else if (hue < 4.0/6.0) {
        cycleColor = vec3(0.0, 4.0-hue*6.0, 1.0);
    } else if (hue < 5.0/6.0) {
        cycleColor = vec3((hue-4.0/6.0)*6.0, 0.0, 1.0);
    } else {
        cycleColor = vec3(1.0, 0.0, 6.0-hue*6.0);
    }

    // final color is a mix of the cell color and the cycle color
    // MODIFICATION: Reduced the influence of cycleColor from 0.7 to 0.2
    // This means finalColor will be 80% cellColor.rgb and 20% cycleColor.
    // Adjust 0.2 to your liking (0.0 means only cellColor, 1.0 means only cycleColor)
    vec3 finalColor = mix(cellColor.rgb, cycleColor, 0.15); // <<<< MODIFIED HERE

    // apply edge effect and pulse
    // MODIFICATION: Reduced the intensity of the edge/pulse effect by multiplying by 0.3
    // Adjust 0.3 to your liking (0.0 means no inversion effect, 1.0 is full original effect)
    float edgeEffectStrength = 0.3; // <<<< ADDED PARAMETER FOR CLARITY
    finalColor = mix(finalColor, vec3(1.0) - finalColor, edge * pulse * edgeEffectStrength); // <<<< MODIFIED HERE

    // add some subtle motion to the cells
    // MODIFICATION: Reduced the drift amount from 0.1 to 0.02
    // Adjust 0.02 to your liking (0.0 means no drift coloration)
    float driftStrength = 0.02; // <<<< ADDED PARAMETER FOR CLARITY
    float drift = sin(cell.x + u_time) * cos(cell.y + u_time * 0.5) * driftStrength; // <<<< MODIFIED HERE
    finalColor += vec3(drift);

    gl_FragColor = vec4(finalColor, 1.0);
}