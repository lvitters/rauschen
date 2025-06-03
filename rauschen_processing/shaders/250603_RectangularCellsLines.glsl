#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// --- Constants for Internal Parameter Generation ---
// Base values
const float BASE_PULSE_TIME_SPEED = 1.0;
const float BASE_DRIFT_TIME_SPEED = 1.0;
const float BASE_PULSE_SPATIAL_FREQ = 0.25;
const float BASE_PULSE_DIR_CHANGE_SPEED = 0.06; // Avg. angular speed (A) for commonAngle

// Amplitudes of variation
const float AMP_PULSE_TIME_SPEED = 0.4;
const float AMP_DRIFT_TIME_SPEED = 0.4;
const float AMP_PULSE_SPATIAL_FREQ = 0.15;
const float AMP_PULSE_DIR_CHANGE_SPEED = 0.03;

// Frequencies of variation (how fast the parameters themselves change)
const float FREQ_PULSE_TIME_SPEED = 0.011;
const float FREQ_DRIFT_TIME_SPEED = 0.013;
const float FREQ_PULSE_SPATIAL_FREQ = 0.015;
const float FREQ_PULSE_DIR_CHANGE_SPEED = 0.017;

// Phase offsets for variety
const float PHASE_PTS = 0.0;
const float PHASE_DTS = 1.1;
const float PHASE_PSF = 2.2;
const float PHASE_A_COMMON = 3.3; // For commonAngle's rate of change

// NEW: Constants for Pulse Direction Distortion
const float BASE_DIR_DIST_AMOUNT = 0.3; // Max angle offset in radians
const float AMP_DIR_DIST_AMOUNT = 0.2;   // Distortion amount will vary (e.g., 0.1 to 0.5 rad)
const float FREQ_DIR_DIST_AMOUNT_PARAM = 0.016; // How fast the amount itself changes
const float PHASE_DIR_DIST_AMOUNT = 4.4;

const float BASE_DIR_DIST_FREQ = 0.08; // Spatial frequency of the angle noise
const float AMP_DIR_DIST_FREQ = 0.04;
const float FREQ_DIR_DIST_FREQ_PARAM = 0.018;
const float PHASE_DIR_DIST_FREQ = 5.5;

const float BASE_DIR_DIST_SPEED = 0.15; // Temporal speed of the angle noise pattern
const float AMP_DIR_DIST_SPEED = 0.1;
const float FREQ_DIR_DIST_SPEED_PARAM = 0.022;
const float PHASE_DIR_DIST_SPEED = 6.6;

const vec2 DIR_DIST_SPATIAL_VEC = vec2(0.53, 0.81); // Fixed vector for spatial variation of distortion

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float cellSize = 16.0;
    vec2 cell = floor(uv * u_resolution / cellSize);
    // vec2 cellUV = fract(uv * u_resolution / cellSize); // Not used directly in this version for main effect

    vec2 cellCoord = (cell + vec2(0.5)) * cellSize / u_resolution;
    vec4 cellColor = texture2D(u_texture, cellCoord);
    float cellValue = (cellColor.r + cellColor.g + cellColor.b) / 3.0;

    // --- Generate Internal "Parameters" from u_time ---
    float g_pulseTimeSpeed = BASE_PULSE_TIME_SPEED + AMP_PULSE_TIME_SPEED * sin(u_time * FREQ_PULSE_TIME_SPEED + PHASE_PTS);
    g_pulseTimeSpeed = max(0.1, g_pulseTimeSpeed); 

    float g_driftTimeSpeed = BASE_DRIFT_TIME_SPEED + AMP_DRIFT_TIME_SPEED * sin(u_time * FREQ_DRIFT_TIME_SPEED + PHASE_DTS);
    g_driftTimeSpeed = max(0.1, g_driftTimeSpeed);

    float g_pulseSpatialFrequency = BASE_PULSE_SPATIAL_FREQ + AMP_PULSE_SPATIAL_FREQ * sin(u_time * FREQ_PULSE_SPATIAL_FREQ + PHASE_PSF);
    g_pulseSpatialFrequency = max(0.05, g_pulseSpatialFrequency);

    float g_A_inst = BASE_PULSE_DIR_CHANGE_SPEED + AMP_PULSE_DIR_CHANGE_SPEED * sin(u_time * FREQ_PULSE_DIR_CHANGE_SPEED + PHASE_A_COMMON);
    g_A_inst = max(0.01, g_A_inst); 

    float commonAngle = BASE_PULSE_DIR_CHANGE_SPEED * u_time - (AMP_PULSE_DIR_CHANGE_SPEED / FREQ_PULSE_DIR_CHANGE_SPEED) * cos(u_time * FREQ_PULSE_DIR_CHANGE_SPEED + PHASE_A_COMMON);
    commonAngle += (AMP_PULSE_DIR_CHANGE_SPEED / FREQ_PULSE_DIR_CHANGE_SPEED) * cos(PHASE_A_COMMON);
    
    // NEW: Generate parameters for pulse direction distortion
    float g_dirDistAmount = BASE_DIR_DIST_AMOUNT + AMP_DIR_DIST_AMOUNT * sin(u_time * FREQ_DIR_DIST_AMOUNT_PARAM + PHASE_DIR_DIST_AMOUNT);
    g_dirDistAmount = max(0.0, g_dirDistAmount);

    float g_dirDistFreq = BASE_DIR_DIST_FREQ + AMP_DIR_DIST_FREQ * sin(u_time * FREQ_DIR_DIST_FREQ_PARAM + PHASE_DIR_DIST_FREQ);
    g_dirDistFreq = max(0.01, g_dirDistFreq);

    float g_dirDistSpeed = BASE_DIR_DIST_SPEED + AMP_DIR_DIST_SPEED * sin(u_time * FREQ_DIR_DIST_SPEED_PARAM + PHASE_DIR_DIST_SPEED);

    // --- PULSE Effect Calculation with Distorted Direction ---
    float distortionPhase = dot(cell, DIR_DIST_SPATIAL_VEC) * g_dirDistFreq + u_time * g_dirDistSpeed;
    float localAngleNoise = sin(distortionPhase) * g_dirDistAmount;
    float finalAngleForPulse = commonAngle + localAngleNoise;
    vec2 directionForPulse = vec2(cos(finalAngleForPulse), sin(finalAngleForPulse));

    float pulsePhaseSpatial = dot(cell, directionForPulse) * g_pulseSpatialFrequency;
    float pulsePhaseTime = u_time * g_pulseTimeSpeed;
    float pulse = sin(pulsePhaseTime + pulsePhaseSpatial) * 0.5 + 0.5;

    // --- Edge and Color Cycling ---
    // (Using cellUV here, which was commented out earlier but is needed for 'edge')
    vec2 cellUV = fract(uv * u_resolution / cellSize); 
    float edgeThreshold = 0.2 + 0.1 * sin(u_time * 0.2); 
    float edge = step(edgeThreshold, cellUV.x) * step(edgeThreshold, cellUV.y) *
                 step(edgeThreshold, 1.0 - cellUV.x) * step(edgeThreshold, 1.0 - cellUV.y);
    float hue_time_factor = 0.1; 
    float hue = cellValue * 2.0 + u_time * hue_time_factor;
    vec3 cycleColor;
    hue = fract(hue);
    if (hue < 1.0/6.0) { cycleColor = vec3(1.0, hue*6.0, 0.0); }
    else if (hue < 2.0/6.0) { cycleColor = vec3(2.0-hue*6.0, 1.0, 0.0); }
    else if (hue < 3.0/6.0) { cycleColor = vec3(0.0, 1.0, (hue-2.0/6.0)*6.0); }
    else if (hue < 4.0/6.0) { cycleColor = vec3(0.0, 4.0-hue*6.0, 1.0); }
    else if (hue < 5.0/6.0) { cycleColor = vec3((hue-4.0/6.0)*6.0, 0.0, 1.0); }
    else { cycleColor = vec3(1.0, 0.0, 6.0-hue*6.0); }

    float cycleColorMix = 0.15; 
    vec3 finalColor = mix(cellColor.rgb, cycleColor, cycleColorMix); 
    
    float edgeEffectStrength = 0.3; 
    finalColor = mix(finalColor, vec3(1.0) - finalColor, edge * pulse * edgeEffectStrength); 

    // --- DRIFT Effect Calculation (uses unperturbed commonAngle via g_A_inst) ---
    float driftStrength = 0.02; 
    if (driftStrength > 0.0) {
        vec2 base_drift_coeffs = vec2(1.0, 0.5); 
        float accumulatedPhaseOffsetX;
        float accumulatedPhaseOffsetY;
        float current_A_for_drift = g_A_inst; // Use the instantaneous rate of change of commonAngle
        
        float invA = 1.0 / current_A_for_drift;
        float sinA_t = sin(current_A_for_drift * u_time); 
        float cosA_t = cos(current_A_for_drift * u_time); 

        accumulatedPhaseOffsetX = g_driftTimeSpeed * invA * (sinA_t * base_drift_coeffs.x + cosA_t * base_drift_coeffs.y - base_drift_coeffs.y);
        accumulatedPhaseOffsetY = g_driftTimeSpeed * invA * (-cosA_t * base_drift_coeffs.x + sinA_t * base_drift_coeffs.y + base_drift_coeffs.x);
        
        float drift = sin(cell.x + accumulatedPhaseOffsetX) * cos(cell.y + accumulatedPhaseOffsetY) * driftStrength;
        finalColor += vec3(drift);
    }

    gl_FragColor = vec4(finalColor, 1.0);
}