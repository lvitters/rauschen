#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform float u_time;
uniform int u_cells_x;
uniform int u_cells_y;

const float ORBIT_RADIUS_FACTOR = 0.4;
const float TIME_ANIMATION_SPEED = 0.25;
const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const int MAX_CELLS_PER_DIMENSION = 100; // Keep the cap for safety

// --- Optimization: Local Search Radius ---
// Determines the neighborhood size.
// 1 = 3x3 neighborhood (9 cells checked max)
// 2 = 5x5 neighborhood (25 cells checked max)
// Adjust this value to balance performance and visual quality.
const int SEARCH_RADIUS = 1; // Start with 1 for a 3x3 search

float rand(vec2 seed) {
    return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    int actual_cells_x = min(u_cells_x, MAX_CELLS_PER_DIMENSION);
    int actual_cells_y = min(u_cells_y, MAX_CELLS_PER_DIMENSION);

    float min_dist_sq = 10000.0;
    vec3 final_cell_color = vec3(0.0);

    float num_cells_x_float = max(1.0, float(actual_cells_x));
    float num_cells_y_float = max(1.0, float(actual_cells_y));

    float base_cell_width = 1.0 / num_cells_x_float;
    float base_cell_height = 1.0 / num_cells_y_float;

    // Determine the "home" cell for the current UV coordinate
    int home_cell_x = int(floor(uv.x * num_cells_x_float));
    int home_cell_y = int(floor(uv.y * num_cells_y_float));

    // Loop through a smaller neighborhood around the home cell
    for (int di = -SEARCH_RADIUS; di <= SEARCH_RADIUS; di++) {
        for (int dj = -SEARCH_RADIUS; dj <= SEARCH_RADIUS; dj++) {
            
            int i = home_cell_x + di;
            int j = home_cell_y + dj;

            // Check if the neighboring cell (i,j) is within grid bounds
            if (i >= 0 && i < actual_cells_x && j >= 0 && j < actual_cells_y) {
                
                // --- All the original cell logic from here ---
                // This part is the same as before, just executed for fewer (i,j) pairs.

                vec2 uv_base_grid_point = vec2( (float(i) + 0.5) * base_cell_width,
                                                (float(j) + 0.5) * base_cell_height );

                vec3 cell_color_seed = texture2D(u_texture, uv_base_grid_point).rgb;

                float norm_i = (num_cells_x_float == 1.0) ? 0.0 : float(i) / (num_cells_x_float - 1.0);
                float norm_j = (num_cells_y_float == 1.0) ? 0.0 : float(j) / (num_cells_y_float - 1.0);

                vec2 random_seed = vec2(float(i), float(j)); // Seed based on absolute cell index
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
                // --- End of original cell logic ---
            }
        }
    }

    gl_FragColor = vec4(final_cell_color, 1.0);
}