#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform float u_time;
uniform vec2 u_resolution;
uniform int u_cells_x;  // Number of cells in x direction
uniform int u_cells_y;  // Number of cells in y direction

// Simple hash function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D rotation matrix
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Use uniforms if they're under 40, otherwise cap at 40
    vec2 numCells = vec2(
        u_cells_x < 40 ? float(u_cells_x) : 40.0,
        u_cells_y < 40 ? float(u_cells_y) : 40.0
    );
    
    // Get which cell we're in (with slight overlap for propagation)
    vec2 cellID = floor(uv * numCells * 0.9); // 0.9 creates 10% overlap
    
    // Get cell center
    vec2 cellCenter = (cellID + 0.5) / (numCells * 0.9);
    
    // Create variable rotation for each cell
    float cellSeed = hash(cellID);
    float cellSeed2 = hash(cellID + vec2(123.45, 67.89));
    
    // Variable rotation speed and direction
    float rotationSpeed = 0.1 + cellSeed * 0.6; // Speed varies from 0.1 to 0.7
    float direction = cellSeed > 0.5 ? 1.0 : -1.0; // Random direction
    float angle = u_time * 0.001 * rotationSpeed * direction;
    
    // Variable rotation center (cell center, corner, or edge)
    vec2 rotationCenter;
    float centerType = cellSeed2;
    vec2 cellSize = 1.0 / (numCells * 0.9);
    
    if (centerType < 0.4) {
        // Cell center (40% chance)
        rotationCenter = cellCenter;
    } else if (centerType < 0.7) {
        // Cell corner (30% chance)
        vec2 cornerOffset = vec2(
            hash(cellID + vec2(234.56, 0.0)) > 0.5 ? 0.5 : -0.5,
            hash(cellID + vec2(0.0, 345.67)) > 0.5 ? 0.5 : -0.5
        );
        rotationCenter = cellCenter + cornerOffset * cellSize;
    } else {
        // Cell edge (30% chance)
        float edgeChoice = hash(cellID + vec2(456.78, 789.01));
        if (edgeChoice < 0.25) {
            rotationCenter = cellCenter + vec2(0.0, 0.5 * cellSize.y); // Top edge
        } else if (edgeChoice < 0.5) {
            rotationCenter = cellCenter + vec2(0.0, -0.5 * cellSize.y); // Bottom edge
        } else if (edgeChoice < 0.75) {
            rotationCenter = cellCenter + vec2(0.5 * cellSize.x, 0.0); // Right edge
        } else {
            rotationCenter = cellCenter + vec2(-0.5 * cellSize.x, 0.0); // Left edge
        }
    }
    
    // Position relative to rotation center
    vec2 localPos = uv - rotationCenter;
    
    // Apply rotation
    vec2 rotatedPos = rotate2D(angle) * localPos;
    
    // Final UV coordinate
    vec2 finalUV = rotationCenter + rotatedPos;
    
    // Keep within bounds
    finalUV = clamp(finalUV, 0.0, 1.0);
    
    // Sample texture
    vec4 color = texture2D(u_texture, finalUV);
    
    gl_FragColor = color;
}