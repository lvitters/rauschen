#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;    // Input texture (previous frame's output)
uniform vec2 u_resolution;      // Resolution of the canvas (must be accurate)
uniform float u_time;           // Time for animation
uniform int u_cells_x;          // Desired number of cells in X (will be capped at 100)
uniform int u_cells_y;          // Desired number of cells in Y (will be capped at 100)

// --- Base Configuration (can still be adjusted) ---
const float ORBIT_RADIUS_FACTOR = 0.4;
const float TIME_ANIMATION_SPEED = 0.25;

// PI constants for readability
const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

// Max cells cap
const int MAX_CELLS_PER_DIMENSION = 20;

// --- Pseudo-Random Function ---
float rand(vec2 seed) {
    return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // --- Apply Cell Count Cap ---
    // Use the user-provided cell count, but cap it at MAX_CELLS_PER_DIMENSION
    int actual_cells_x = min(u_cells_x, MAX_CELLS_PER_DIMENSION);
    int actual_cells_y = min(u_cells_y, MAX_CELLS_PER_DIMENSION);

    float min_dist_sq = 10000.0;
    vec3 final_cell_color = vec3(0.0);

    // Ensure cell counts are at least 1 for float calculations.
    float num_cells_x_float = max(1.0, float(actual_cells_x));
    float num_cells_y_float = max(1.0, float(actual_cells_y));

    float base_cell_width = 1.0 / num_cells_x_float;
    float base_cell_height = 1.0 / num_cells_y_float;

    // Loop through the capped number of cells
    for (int i = 0; i < actual_cells_x; i++) {
        for (int j = 0; j < actual_cells_y; j++) {

            vec2 uv_base_grid_point = vec2( (float(i) + 0.5) * base_cell_width,
                                            (float(j) + 0.5) * base_cell_height );

            vec3 cell_color_seed = texture2D(u_texture, uv_base_grid_point).rgb;

            float norm_i = (num_cells_x_float == 1.0) ? 0.0 : float(i) / (num_cells_x_float - 1.0);
            float norm_j = (num_cells_y_float == 1.0) ? 0.0 : float(j) / (num_cells_y_float - 1.0);

            vec2 random_seed = vec2(float(i), float(j));
            float rand_val1 = rand(random_seed);
            float rand_val2 = rand(random_seed + vec2(10.3, -5.7));
            float rand_val3 = rand(random_seed - vec2(3.1, 12.9));
            float rand_val4 = rand(random_seed + vec2(1.73, 4.56));
            float rand_val5 = rand(random_seed - vec2(2.14, 3.71));

            float cell_specific_time_speed_factor = 0.75 + rand_val1 * 0.5;
            float time_factor = u_time * TIME_ANIMATION_SPEED * cell_specific_time_speed_factor;

            float base_freq_x_contrib = 1.0 + norm_i * 1.5;
            float base_freq_y_contrib = 1.0 + norm_j * 1.5;
            
            float base_phase_offset_x = norm_i * TWO_PI;
            float base_phase_offset_y = norm_j * TWO_PI * 1.3;

            float time_freq_mod_x = 0.1 + (rand_val2 - 0.5) * 0.08;
            float time_freq_mod_y = 0.15 + (rand_val3 - 0.5) * 0.1;

            float amp_mod_x = 0.5 + (rand_val2 - 0.5) * 0.3;
            float amp_mod_y = 0.5 + (rand_val3 - 0.5) * 0.3;

            float freq_x = base_freq_x_contrib + sin(norm_j * PI + time_factor * time_freq_mod_x) * amp_mod_x;
            float freq_y = base_freq_y_contrib + cos(norm_i * PI + time_factor * time_freq_mod_y) * amp_mod_y;
            
            float phase_offset_x = base_phase_offset_x + (rand_val4 - 0.5) * (PI / 2.0);
            float phase_offset_y = base_phase_offset_y + (rand_val5 - 0.5) * (PI / 2.0) * 1.3;

            float radius_x = base_cell_width * ORBIT_RADIUS_FACTOR;
            float radius_y = base_cell_height * ORBIT_RADIUS_FACTOR;

            vec2 offset_from_base;
            offset_from_base.x = radius_x * sin(freq_x * time_factor + phase_offset_x);
            offset_from_base.y = radius_y * cos(freq_y * time_factor + phase_offset_y + norm_i * (PI / 2.0));

            vec2 uv_dynamic_feature_point = uv_base_grid_point + offset_from_base;
            uv_dynamic_feature_point = clamp(uv_dynamic_feature_point, 0.001, 0.999);
            
            vec2 diff_to_feature = uv - uv_dynamic_feature_point;
            float dist_sq = dot(diff_to_feature, diff_to_feature);

            if (dist_sq < min_dist_sq) {
                min_dist_sq = dist_sq;
                final_cell_color = cell_color_seed;
            }
        }
    }

    gl_FragColor = vec4(final_cell_color, 1.0);
}