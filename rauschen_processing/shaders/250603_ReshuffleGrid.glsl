precision mediump float;

uniform vec2 u_resolution;    // The resolution of the output screen
uniform sampler2D u_texture;  // The input texture with randomly colored pixels
uniform float u_time;         // Time uniform, for animations

// --- Helper Functions ---

// Pseudo-random number generator from a 2D vector seed
// Returns a float between 0.0 (inclusive) and 1.0 (exclusive)
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Generates a pseudo-random integer float between 0.0 (inclusive) 
// and max_val (exclusive, so up to floor(max_val - 0.00001)).
// 'max_val' should be a float (e.g., 10.0 for numbers 0-9).
float random_int(vec2 st, float max_val) {
    return floor(random(st) * max_val);
}

// --- Main Shader Logic ---
void main() {
    // --- 1. Determine Grid Dimensions (Randomly Based on Time) ---
    // These dimensions will change at discrete time intervals.

    // Speed at which grid dimensions change (lower value = slower change)
    // For example, 0.2 means dimensions change roughly every 1.0/0.2 = 5 seconds.
    float grid_change_speed = 0.2; 
    float discrete_time_grid = floor(u_time * grid_change_speed);

    // Minimum and maximum number of columns/rows for the grid.
    // Feel free to adjust these!
    float min_grid_dim = 2.0;
    float max_grid_dim = 10.0; // Max 10x10 grid

    // Calculate number of columns and rows
    // Using different seeds for columns and rows to make their changes independent.
    float num_cols = min_grid_dim + random_int(vec2(discrete_time_grid, 12.345), (max_grid_dim - min_grid_dim + 1.0));
    float num_rows = min_grid_dim + random_int(vec2(54.321, discrete_time_grid), (max_grid_dim - min_grid_dim + 1.0));

    // --- 2. Current Pixel and Cell Information ---
    // Get normalized UV coordinates for the current fragment [0,1]
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // Calculate the width and height of a single cell in UV space
    float cell_width = 1.0 / num_cols;
    float cell_height = 1.0 / num_rows;

    // Determine which output grid cell this fragment (pixel) belongs to.
    // These are the coordinates of the cell in the output grid (e.g., (0,0), (0,1), (1,0)...).
    float output_cell_idx_x = floor(uv.x / cell_width);
    float output_cell_idx_y = floor(uv.y / cell_height);

    // Calculate the UV coordinates *within* the current output cell (normalized to [0,1] for that cell).
    // fract(x) gives the fractional part of x.
    vec2 intra_cell_uv;
    intra_cell_uv.x = fract(uv.x / cell_width); 
    intra_cell_uv.y = fract(uv.y / cell_height);

    // --- 3. Shuffle Cells (Using a Cyclic Permutation) ---
    // This method ensures a true permutation: all original cells from the input texture
    // are displayed exactly once in the output, just in different positions.
    // The permutation is a cyclic shift that changes over time.

    // Speed at which the shuffle pattern changes
    // For example, 0.5 means the shuffle changes roughly every 1.0/0.5 = 2 seconds.
    float shuffle_change_speed = 0.5; 
    float discrete_time_shuffle = floor(u_time * shuffle_change_speed);

    float total_cells = num_cols * num_rows;

    // Calculate a "shift" amount for the permutation based on the discrete time.
    // This determines how many positions the cells are shifted.
    float shift_amount = random_int(vec2(discrete_time_shuffle, 99.99), total_cells);

    // Calculate the linear index of the current *output* cell.
    // (e.g., for a 3x3 grid, cell (1,1) would be 1*3 + 1 = 4th cell if 0-indexed).
    float output_cell_linear_idx = output_cell_idx_y * num_cols + output_cell_idx_x;

    // Determine the *source* cell's linear index by applying the inverse shift.
    // If P(source_idx) = (source_idx + shift_amount) % total_cells = output_idx,
    // then source_idx = (output_idx - shift_amount + total_cells) % total_cells.
    // GLSL's mod(x,y) behaves correctly for negative x (e.g. mod(-1.0, 10.0) = 9.0).
    float source_cell_linear_idx = mod(output_cell_linear_idx - shift_amount, total_cells);
    // Ensure it's positive if there's any doubt, though GLSL's mod is usually fine:
    // source_cell_linear_idx = mod(output_cell_linear_idx - shift_amount + total_cells, total_cells);


    // Convert the linear source index back to 2D source cell coordinates.
    float source_cell_idx_x = mod(source_cell_linear_idx, num_cols);
    float source_cell_idx_y = floor(source_cell_linear_idx / num_cols);

    // --- 4. Calculate Sample UV in the Source Texture ---
    // Now we construct the UV to sample from u_texture.
    // This UV corresponds to the pixel within the determined *source* cell.
    vec2 sample_uv;
    sample_uv.x = (source_cell_idx_x + intra_cell_uv.x) * cell_width;
    sample_uv.y = (source_cell_idx_y + intra_cell_uv.y) * cell_height;
    
    // --- 5. Sample Texture and Output Color ---
    gl_FragColor = texture2D(u_texture, sample_uv);
}