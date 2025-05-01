#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Simple pseudo-random number generator
float random (vec2 st) {
    vec2 seed = st + vec2(sin(u_time * 0.1), cos(u_time * 0.1)) * 0.01;
    return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// --- Dominant color checks (Y/C/M checks relaxed) ---
float C_THRESH = 0.2; // Base brightness threshold
float C_DIFF = 0.1;   // Required difference for primaries

bool isDominantRed(vec4 c) { return c.r > c.g + C_DIFF && c.r > c.b + C_DIFF && c.r > C_THRESH; }
bool isDominantGreen(vec4 c) { return c.g > c.r + C_DIFF && c.g > c.b + C_DIFF && c.g > C_THRESH; }
bool isDominantBlue(vec4 c) { return c.b > c.r + C_DIFF && c.b > c.g + C_DIFF && c.b > C_THRESH; }

// --- CHANGE: Relaxed Y/C/M checks ---
// Yellow = R and G are high, B is low
bool isDominantYellow(vec4 c) { return c.r > C_THRESH && c.g > C_THRESH && c.b < C_THRESH; }
// Cyan = G and B are high, R is low
bool isDominantCyan(vec4 c) { return c.g > C_THRESH && c.b > C_THRESH && c.r < C_THRESH; }
// Magenta = R and B are high, G is low
bool isDominantMagenta(vec4 c) { return c.r > C_THRESH && c.b > C_THRESH && c.g < C_THRESH; }


// Helper to map values
float mapValue(float value, float min1, float max1, float min2, float max2) {
  return min2 + clamp((value - min1) * (max2 - min2) / (max1 - min1), 0.0, 1.0) * (max2 - min2);
}


void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, uv);

    float dx = 1.0 / u_resolution.x;
    float dy = 1.0 / u_resolution.y;

    // Neighbor sampling (as before)
    vec4 n[8];
    n[0] = texture2D(u_texture, uv + vec2(-dx, -dy));
    n[1] = texture2D(u_texture, uv + vec2(0.0, -dy));
    n[2] = texture2D(u_texture, uv + vec2(dx, -dy));
    n[3] = texture2D(u_texture, uv + vec2(-dx, 0.0));
    n[4] = texture2D(u_texture, uv + vec2(dx, 0.0));
    n[5] = texture2D(u_texture, uv + vec2(-dx, dy));
    n[6] = texture2D(u_texture, uv + vec2(0.0, dy));
    n[7] = texture2D(u_texture, uv + vec2(dx, dy));

    // Count neighbors by dominant color (Expanded)
    float rN=0.0, gN=0.0, bN=0.0, yN=0.0, cN=0.0, mN=0.0;
    for(int i = 0; i < 8; i++) {
        // Important: Check primaries FIRST, then secondaries if primary fails
        // This avoids double-counting (e.g., a Yellow pixel shouldn't count as R *and* G neighbor)
        if (isDominantRed(n[i])) rN++;
        else if (isDominantGreen(n[i])) gN++;
        else if (isDominantBlue(n[i])) bN++;
        else if (isDominantYellow(n[i])) yN++;
        else if (isDominantCyan(n[i])) cN++;
        else if (isDominantMagenta(n[i])) mN++;
    }

    // Check current cell state (Expanded) - Use same priority logic
    bool isR = false, isG = false, isB = false, isY = false, isC = false, isM = false;
    if (isDominantRed(texColor)) isR = true;
    else if (isDominantGreen(texColor)) isG = true;
    else if (isDominantBlue(texColor)) isB = true;
    else if (isDominantYellow(texColor)) isY = true;
    else if (isDominantCyan(texColor)) isC = true;
    else if (isDominantMagenta(texColor)) isM = true;
    bool isDead = !isR && !isG && !isB && !isY && !isC && !isM;


    // Define base "dead" color (as before)
    float deadHue = 0.6 + sin(u_time * 0.05 + uv.x * 2.0) * 0.1;
    float deadSaturation = 0.5;
    float deadValue = 0.08 + random(uv + vec2(0.5, 0.5)) * 0.05;
    vec3 deadColor = hsv2rgb(vec3(deadHue, deadSaturation, deadValue));

    // Determine next state using HighLife (B36/S23) & Simplified Inhibition (as before)
    bool nextR=false, nextG=false, nextB=false, nextY=false, nextC=false, nextM=false;
    float inhibitionThreshold = 4.0; // Tune this
    float otherN;

    // Red B36/S23
    otherN = gN+bN+yN+cN+mN;
    if (isR) { if ((rN == 2.0 || rN == 3.0) && otherN <= inhibitionThreshold) nextR = true; }
    else { if ((rN == 3.0 || rN == 6.0) && otherN <= inhibitionThreshold) nextR = true; }
    // Green B36/S23
    otherN = rN+bN+yN+cN+mN;
    if (isG) { if ((gN == 2.0 || gN == 3.0) && otherN <= inhibitionThreshold) nextG = true; }
    else { if ((gN == 3.0 || gN == 6.0) && otherN <= inhibitionThreshold) nextG = true; }
    // Blue B36/S23
    otherN = rN+gN+yN+cN+mN;
    if (isB) { if ((bN == 2.0 || bN == 3.0) && otherN <= inhibitionThreshold) nextB = true; }
    else { if ((bN == 3.0 || bN == 6.0) && otherN <= inhibitionThreshold) nextB = true; }
    // Yellow B36/S23
    otherN = rN+gN+bN+cN+mN;
    if (isY) { if ((yN == 2.0 || yN == 3.0) && otherN <= inhibitionThreshold) nextY = true; }
    else { if ((yN == 3.0 || yN == 6.0) && otherN <= inhibitionThreshold) nextY = true; }
    // Cyan B36/S23
    otherN = rN+gN+bN+yN+mN;
    if (isC) { if ((cN == 2.0 || cN == 3.0) && otherN <= inhibitionThreshold) nextC = true; }
    else { if ((cN == 3.0 || cN == 6.0) && otherN <= inhibitionThreshold) nextC = true; }
    // Magenta B36/S23
    otherN = rN+gN+bN+yN+cN;
    if (isM) { if ((mN == 2.0 || mN == 3.0) && otherN <= inhibitionThreshold) nextM = true; }
    else { if ((mN == 3.0 || mN == 6.0) && otherN <= inhibitionThreshold) nextM = true; }


    // --- Calculate Color Based on New State (No Averaging) ---
    vec3 calculatedColor = vec3(0.0); // Start black
    int aliveCount = 0; // Still count for logic, but not averaging
    float totalNeighbors = rN+gN+bN+yN+cN+mN; // Use for saturation mapping

    // Define base hues for 6 colors
    float baseHueR=0.0/6.0, baseHueY=1.0/6.0, baseHueG=2.0/6.0;
    float baseHueC=3.0/6.0, baseHueB=4.0/6.0, baseHueM=5.0/6.0;

    // --- CHANGE: Simply ADD colors, no division later ---
    if (nextR) {
        float rSat = mapValue(totalNeighbors, 1.0, 8.0, 0.7, 1.0);
        calculatedColor += hsv2rgb(vec3(baseHueR, rSat, 0.9)); aliveCount++;
    }
    if (nextG) {
        float gSat = mapValue(totalNeighbors, 1.0, 8.0, 0.7, 1.0);
        calculatedColor += hsv2rgb(vec3(baseHueG, gSat, 0.9)); aliveCount++;
    }
     if (nextB) {
        float bSat = mapValue(totalNeighbors, 1.0, 8.0, 0.7, 1.0);
        calculatedColor += hsv2rgb(vec3(baseHueB, bSat, 0.9)); aliveCount++;
    }
    if (nextY) {
        float ySat = mapValue(totalNeighbors, 1.0, 8.0, 0.7, 1.0);
        calculatedColor += hsv2rgb(vec3(baseHueY, ySat, 0.9)); aliveCount++;
    }
    if (nextC) {
        float cSat = mapValue(totalNeighbors, 1.0, 8.0, 0.7, 1.0);
        calculatedColor += hsv2rgb(vec3(baseHueC, cSat, 0.9)); aliveCount++;
    }
    if (nextM) {
        float mSat = mapValue(totalNeighbors, 1.0, 8.0, 0.7, 1.0);
        calculatedColor += hsv2rgb(vec3(baseHueM, mSat, 0.9)); aliveCount++;
    }

    // Final color assignment
    if (aliveCount > 0) {
        // --- CHANGE: Removed averaging ---
        // Clamp ensures additive color doesn't exceed 1.0
        calculatedColor = clamp(calculatedColor, 0.0, 1.0);
    } else {
        calculatedColor = deadColor; // Assign dead color if no channels active
    }


    // --- Seeding (Unchanged) ---
     if (u_time < 1.5) {
        float cellSize = 10.0;
        float pattern = mod(floor(uv.x * cellSize) + floor(uv.y * cellSize), 6.0);
         if (pattern < 1.0) calculatedColor = hsv2rgb(vec3(baseHueR, 0.9, 0.9));
         else if (pattern < 2.0) calculatedColor = hsv2rgb(vec3(baseHueY, 0.9, 0.9));
         else if (pattern < 3.0) calculatedColor = hsv2rgb(vec3(baseHueG, 0.9, 0.9));
         else if (pattern < 4.0) calculatedColor = hsv2rgb(vec3(baseHueC, 0.9, 0.9));
         else if (pattern < 5.0) calculatedColor = hsv2rgb(vec3(baseHueB, 0.9, 0.9));
         else calculatedColor = hsv2rgb(vec3(baseHueM, 0.9, 0.9));
    }

    // --- Assign final color (NO MIX) ---
    vec3 finalColor = calculatedColor;

    // --- Anti-Stagnation Randomness (Keep low for now) ---
    if (random(uv) > 0.995) { // 0.5% chance
       float randHue = random(uv + vec2(0.1, 0.1));
       float randSat = 0.5 + random(uv + vec2(0.2, 0.2)) * 0.5;
       float randVal = 0.1 + random(uv + vec2(0.3, 0.3)) * 0.8;
       finalColor = hsv2rgb(vec3(randHue, randSat, randVal));
    }

    gl_FragColor = vec4(finalColor, 1.0);
}