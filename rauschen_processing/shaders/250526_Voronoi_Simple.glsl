#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D u_texture;    // Input texture (previous frame's output)
uniform vec2 u_resolution;   // Resolution of the canvas (must be accurate)
uniform float u_time;         // Time for animation

// NOTE: No 'varying vec2 vTexCoord;' declaration.
// We will use gl_FragCoord.xy / u_resolution.xy for UVs.

// --- Configuration ---
// Drastically reduced cell count to simplify observation of behavior
const int NUM_CELLS_X = 8; // e.g., 4x4 = 16 cells total
const int NUM_CELLS_Y = 8;

// ORBIT_RADIUS_FACTOR: Max orbital distance from base point, as factor of cell size.
// With fewer cells, each cell's base area is larger. 0.4 allows significant, visible movement.
const float ORBIT_RADIUS_FACTOR = 0.4; 

// TIME_ANIMATION_SPEED: Controls the speed of the orbital animations.
const float TIME_ANIMATION_SPEED = 0.25; 

void main() {
    // Calculate UV coordinates using gl_FragCoord (pixel coordinate) and u_resolution.
    // This makes UVs independent of any specific vertex shader varying output name.
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    float min_dist_sq = 10000.0;        // Initialize with a large distance
    float second_min_dist_sq = 10000.0; // Second closest for anti-aliasing
    vec3 final_cell_color = vec3(0.0);  // Default to black
    vec3 second_cell_color = vec3(0.0); // Second closest cell color

    // Calculate base cell dimensions (each cell is larger now)
    float base_cell_width = 1.0 / float(NUM_CELLS_X);
    float base_cell_height = 1.0 / float(NUM_CELLS_Y);

    for (int i = 0; i < NUM_CELLS_X; i++) {
        for (int j = 0; j < NUM_CELLS_Y; j++) {

            // 1. Define the BASE UV coordinate for this cell's color sampling AND as the center of its orbit.
            vec2 uv_base_grid_point = vec2( (float(i) + 0.5) * base_cell_width,
                                            (float(j) + 0.5) * base_cell_height );

            // 2. SEED COLOR for the cell: Sampled from u_texture at the fixed base grid point.
            vec3 cell_color_seed = texture2D(u_texture, uv_base_grid_point).rgb;

            // 3. DYNAMIC FEATURE POINT LOCATION via predetermined orbital paths:
            //    Movement is based on time and unique cell ID, NOT u_texture content.
            
            // Normalized grid indices [0,1] for unique animation parameters per point.
            float norm_i = float(i) / max(1.0, float(NUM_CELLS_X - 1)); 
            float norm_j = float(j) / max(1.0, float(NUM_CELLS_Y - 1));

            float time_factor = u_time * TIME_ANIMATION_SPEED;

            // Define unique frequencies and phases for each point's orbit.
            // These create diverse Lissajous-like paths.
            float freq_x = 1.0 + norm_i * 1.5 + sin(norm_j * 3.14159 + time_factor * 0.1) * 0.5; 
            float freq_y = 1.0 + norm_j * 1.5 + cos(norm_i * 3.14159 + time_factor * 0.15) * 0.5; 
            
            float phase_offset_x = norm_i * 6.2831853; // ~2*PI * norm_i
            float phase_offset_y = norm_j * 6.2831853 * 1.3; // ~2*PI * norm_j * 1.3 for more variation

            // Define the orbit radius for this point
            float radius_x = base_cell_width * ORBIT_RADIUS_FACTOR;
            float radius_y = base_cell_height * ORBIT_RADIUS_FACTOR;

            vec2 offset_from_base;
            offset_from_base.x = radius_x * sin(freq_x * time_factor + phase_offset_x);
            offset_from_base.y = radius_y * cos(freq_y * time_factor + phase_offset_y + norm_i * 1.57079); // Extra phase variation

            vec2 uv_dynamic_feature_point = uv_base_grid_point + offset_from_base;
            
            // Clamp to ensure points stay definitively within bounds [0,1].
            uv_dynamic_feature_point = clamp(uv_dynamic_feature_point, 0.001, 0.999); // Tiny margin from true edge
            
            // 4. Calculate squared distance from current fragment (uv) to this dynamic feature point
            vec2 diff_to_feature = uv - uv_dynamic_feature_point;
            float dist_sq = dot(diff_to_feature, diff_to_feature);

            if (dist_sq < min_dist_sq) {
                // New closest found - previous closest becomes second closest
                second_min_dist_sq = min_dist_sq;
                second_cell_color = final_cell_color;
                
                min_dist_sq = dist_sq;
                final_cell_color = cell_color_seed;
            } else if (dist_sq < second_min_dist_sq) {
                second_min_dist_sq = dist_sq;
                second_cell_color = cell_color_seed;
            }
        }
    }

    // Simple anti-aliasing: blend between closest and second closest near boundaries
    float min_dist = sqrt(min_dist_sq);
    float second_min_dist = sqrt(second_min_dist_sq);
    
    // Calculate how close we are to the boundary between cells
    float boundary_distance = second_min_dist - min_dist;
    
    // Use pixel derivatives to determine appropriate smoothing width
    float pixel_size = length(vec2(dFdx(min_dist), dFdy(min_dist)));
    float smooth_width = pixel_size * 1.5;
    
    // Only apply anti-aliasing very close to boundaries
    float blend_factor = smoothstep(0.0, smooth_width, boundary_distance);
    
    // Blend between the two closest colors for anti-aliasing
    vec3 aa_color = mix(mix(final_cell_color, second_cell_color, 0.5), final_cell_color, blend_factor);

    gl_FragColor = vec4(aa_color, 1.0);
}