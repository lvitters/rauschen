#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform float u_time;
uniform vec2 u_resolution;
uniform int u_cells_x;
uniform int u_cells_y;

// Hash function for pseudo-random values
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Get cell coordinates
vec2 getCellCoord(vec2 uv) {
    return floor(uv * vec2(float(u_cells_x), float(u_cells_y)));
}

// Get normalized cell center
vec2 getCellCenter(vec2 cellCoord) {
    return (cellCoord + 0.5) / vec2(float(u_cells_x), float(u_cells_y));
}

// Sample a cell's color
vec3 sampleCell(vec2 cellCoord) {
    vec2 cellUV = getCellCenter(cellCoord);
    return texture2D(u_texture, cellUV).rgb;
}

// Count live neighbors based on brightness threshold
int countNeighbors(vec2 cellCoord, float threshold) {
    int count = 0;
    
    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue; // Skip center cell
            
            vec2 neighborCoord = cellCoord + vec2(float(dx), float(dy));
            
            // Wrap around edges for toroidal topology
            neighborCoord.x = mod(neighborCoord.x, float(u_cells_x));
            neighborCoord.y = mod(neighborCoord.y, float(u_cells_y));
            
            vec3 neighborColor = sampleCell(neighborCoord);
            float brightness = dot(neighborColor, vec3(0.299, 0.587, 0.114));
            
            if (brightness > threshold) {
                count++;
            }
        }
    }
    
    return count;
}

// Apply cellular automaton rules with color evolution
vec3 evolveCell(vec2 cellCoord, vec3 currentColor) {
    float brightness = dot(currentColor, vec3(0.299, 0.587, 0.114));
    float threshold = 0.3 + 0.2 * sin(u_time * 0.1);
    
    int neighbors = countNeighbors(cellCoord, threshold);
    
    // Create time-based variation that cycles predictably
    float timePhase = fract(u_time * 0.05);
    float cellHash = hash(cellCoord * 0.1);
    float localTime = timePhase + cellHash;
    
    vec3 newColor = currentColor;
    
    // Ensure minimum brightness to avoid black background
    float minBrightness = 0.4;
    
    // Modified cellular automaton rules with diverse color evolution
    if (brightness > threshold) {
        // Cell is "alive"
        if (neighbors < 2) {
            // Underpopulation - transform color instead of just fading
            vec3 baseColor = vec3(
                hash(cellCoord * 3.7 + vec2(u_time * 0.02)),
                hash(cellCoord * 5.1 + vec2(u_time * 0.03)),
                hash(cellCoord * 7.3 + vec2(u_time * 0.04))
            );
            newColor = mix(currentColor, baseColor, 0.6);
        } else if (neighbors > 3) {
            // Overpopulation - diverse color mutations
            vec3 mutationColor = vec3(
                0.5 + 0.5 * sin(cellHash * 17.0 + u_time * 0.08),
                0.5 + 0.5 * sin(cellHash * 23.0 + u_time * 0.06),
                0.5 + 0.5 * sin(cellHash * 31.0 + u_time * 0.07)
            );
            newColor = mix(currentColor, mutationColor, 0.4);
        } else {
            // Survival - unique color evolution per cell
            vec3 evolutionVector = vec3(
                sin(localTime * 4.0 + cellHash * 13.0),
                sin(localTime * 5.0 + cellHash * 17.0),
                sin(localTime * 6.0 + cellHash * 19.0)
            ) * 0.15;
            
            newColor = mix(currentColor, currentColor + evolutionVector, 0.3);
        }
    } else {
        // Cell is "dead" or dim
        if (neighbors == 3) {
            // Birth - create diverse new cells
            vec3 neighborSum = vec3(0.0);
            int liveNeighbors = 0;
            
            for (int dx = -1; dx <= 1; dx++) {
                for (int dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue;
                    
                    vec2 neighborCoord = cellCoord + vec2(float(dx), float(dy));
                    neighborCoord.x = mod(neighborCoord.x, float(u_cells_x));
                    neighborCoord.y = mod(neighborCoord.y, float(u_cells_y));
                    
                    vec3 neighborColor = sampleCell(neighborCoord);
                    float neighborBrightness = dot(neighborColor, vec3(0.299, 0.587, 0.114));
                    
                    if (neighborBrightness > threshold) {
                        neighborSum += neighborColor;
                        liveNeighbors++;
                    }
                }
            }
            
            if (liveNeighbors > 0) {
                vec3 avgColor = neighborSum / float(liveNeighbors);
                
                // Create unique birth colors instead of similar gradients
                vec3 birthVariation = vec3(
                    hash(cellCoord * 2.3 + vec2(u_time * 0.05, 17.0)),
                    hash(cellCoord * 3.7 + vec2(u_time * 0.07, 29.0)),
                    hash(cellCoord * 5.1 + vec2(u_time * 0.06, 43.0))
                );
                
                // Mix averaged neighbor color with unique variation
                newColor = mix(avgColor, birthVariation, 0.7);
            }
        } else {
            // Transform dim cells instead of letting them stay black/dark
            vec3 transformColor = vec3(
                0.2 + 0.3 * hash(cellCoord * 1.7 + vec2(u_time * 0.03)),
                0.2 + 0.3 * hash(cellCoord * 2.9 + vec2(u_time * 0.04)),
                0.2 + 0.3 * hash(cellCoord * 4.1 + vec2(u_time * 0.05))
            );
            newColor = mix(currentColor, transformColor, 0.05);
        }
    }
    
    // Ensure minimum brightness to prevent black areas
    float currentBrightness = dot(newColor, vec3(0.299, 0.587, 0.114));
    if (currentBrightness < minBrightness) {
        vec3 boostColor = vec3(
            minBrightness + hash(cellCoord * 6.7) * 0.5,
            minBrightness + hash(cellCoord * 8.3) * 0.5,
            minBrightness + hash(cellCoord * 9.1) * 0.5
        );
        newColor = mix(newColor, boostColor, 0.7);
    }
    
    return clamp(newColor, 0.0, 1.0);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 cellCoord = getCellCoord(uv);
    vec3 currentColor = sampleCell(cellCoord);
    
    vec3 newColor = evolveCell(cellCoord, currentColor);
    
    // Create chaotic gradient by blending neighboring cell gradients with varying overlap
    vec2 cellUV = fract(uv * vec2(float(u_cells_x), float(u_cells_y)));
    vec2 centeredUV = cellUV - 0.5;
    
    // Start with current cell's gradient properties
    float baseGradientAngle = hash(cellCoord * 0.7) * 6.28;
    float baseGradientStrength = 0.2 + 0.2 * hash(cellCoord * 1.1);
    
    // Each cell has its own gradient overlap intensity
    float gradientOverlapAmount = 0.1 + 0.8 * hash(cellCoord * 6.1); // 0.1 to 0.9
    
    // Accumulate gradient influences from nearby cells
    float totalGradientValue = 0.0;
    float totalInfluence = 1.0; // Start with self-influence
    
    // Sample gradient influences from neighboring cells
    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            vec2 neighborOffset = vec2(float(dx), float(dy));
            vec2 neighborCoord = cellCoord + neighborOffset;
            neighborCoord.x = mod(neighborCoord.x, float(u_cells_x));
            neighborCoord.y = mod(neighborCoord.y, float(u_cells_y));
            
            // Get neighbor's gradient properties
            float neighborGradientAngle = hash(neighborCoord * 0.7) * 6.28;
            float neighborGradientStrength = 0.2 + 0.2 * hash(neighborCoord * 1.1);
            
            // Calculate influence based on distance and this cell's overlap settings
            float distance = length(neighborOffset);
            float baseInfluenceStrength = 0.3 + 0.4 * hash(neighborCoord * 2.3 + cellCoord * 4.7);
            
            // Scale influence by this cell's gradient overlap amount
            float influenceStrength = baseInfluenceStrength * gradientOverlapAmount;
            
            // Distance-based falloff with some randomness
            float influence = influenceStrength / (1.0 + distance * distance);
            
            // Calculate gradient contribution from this neighbor
            vec2 neighborGradientDir = vec2(cos(neighborGradientAngle), sin(neighborGradientAngle));
            float neighborGradientValue = dot(centeredUV, neighborGradientDir) * neighborGradientStrength;
            
            // Accumulate the gradient effect
            totalGradientValue += neighborGradientValue * influence;
            totalInfluence += influence;
        }
    }
    
    // Also add the base cell's own gradient
    vec2 baseGradientDir = vec2(cos(baseGradientAngle), sin(baseGradientAngle));
    float baseGradientValue = dot(centeredUV, baseGradientDir) * baseGradientStrength;
    totalGradientValue += baseGradientValue;
    
    // Normalize and apply the chaotic gradient
    float normalizedGradient = totalGradientValue / totalInfluence;
    float cellMask = 0.85 + normalizedGradient;
    cellMask = clamp(cellMask, 0.7, 1.0);
    
    // Apply gradient to color
    newColor *= cellMask;
    
    // Add cell overlap effect with individual variation
    vec2 cellBorder = abs(cellUV - 0.5); // Distance from cell center
    float overlapChance = hash(cellCoord * 3.3);
    
    // Some cells extend beyond their boundaries
    if (overlapChance > 0.5) {
        // Each cell has its own unique overlap distance
        float cellOverlapDistance = 0.05 + 0.4 * hash(cellCoord * 7.7);
        float edgeDistance = max(cellBorder.x, cellBorder.y);
        
        if (edgeDistance > cellOverlapDistance) {
            // Sample neighboring cells for overlap
            vec3 blendedColor = newColor;
            
            // Check immediate neighbors only to avoid complexity
            for (int dx = -1; dx <= 1; dx++) {
                for (int dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue; // Skip current cell
                    
                    vec2 neighborCoord = cellCoord + vec2(float(dx), float(dy));
                    neighborCoord.x = mod(neighborCoord.x, float(u_cells_x));
                    neighborCoord.y = mod(neighborCoord.y, float(u_cells_y));
                    
                    // Check if this neighbor also wants to overlap
                    float neighborOverlapChance = hash(neighborCoord * 3.3);
                    if (neighborOverlapChance > 0.5) {
                        vec3 neighborColor = sampleCell(neighborCoord);
                        vec3 evolvedNeighborColor = evolveCell(neighborCoord, neighborColor);
                        
                        // Apply simple gradient to neighbor
                        float neighborGradientAngle = hash(neighborCoord * 0.7) * 6.28;
                        float neighborGradientStrength = 0.2 + 0.2 * hash(neighborCoord * 1.1);
                        vec2 neighborGradientDir = vec2(cos(neighborGradientAngle), sin(neighborGradientAngle));
                        float neighborGradientValue = dot(centeredUV, neighborGradientDir) * neighborGradientStrength;
                        float neighborCellMask = 0.85 + neighborGradientValue;
                        neighborCellMask = clamp(neighborCellMask, 0.7, 1.0);
                        evolvedNeighborColor *= neighborCellMask;
                        
                        // Calculate blend factor
                        float neighborDistance = length(vec2(float(dx), float(dy)));
                        float neighborOverlapDistance = 0.05 + 0.4 * hash(neighborCoord * 7.7);
                        float blendStart = max(cellOverlapDistance, neighborOverlapDistance);
                        float maxBlendFactor = 0.3 + 0.3 * hash(cellCoord * 9.1 + neighborCoord * 11.3);
                        
                        float blendFactor = smoothstep(blendStart, 0.5, edgeDistance) * maxBlendFactor / neighborDistance;
                        blendFactor = clamp(blendFactor, 0.0, 0.5);
                        
                        if (blendFactor > 0.05) {
                            blendedColor = mix(blendedColor, evolvedNeighborColor, blendFactor);
                        }
                    }
                }
            }
            
            newColor = blendedColor;
        }
    }
    
    gl_FragColor = vec4(newColor, 1.0);
}