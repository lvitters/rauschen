precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;
uniform int u_cells_x;
uniform int u_cells_y;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Broad density scaling based on u_cells_x/y
    float scale_x = float(u_cells_x) * 0.1; 
    float scale_y = float(u_cells_y) * 0.1;
    
    // Create a base "jittered" grid coordinate
    // Adding time makes the "grid" drift and breathe rather than snapping strictly
    vec2 drift = vec2(sin(u_time * 0.1), cos(u_time * 0.15)) * 0.1;
    vec2 st = (uv + drift) * vec2(scale_x, scale_y);
    vec2 cell_idx = floor(st);
    
    // Decision to fragment - not strictly cell-aligned
    float decision = random(cell_idx + floor(u_time * 0.2));
    
    vec2 final_uv = uv;
    
    // If decision threshold is met, apply a "fragment" displacement
    if (decision > 0.7) {
        // Fragmentation scale is influenced by u_cells but not locked to them
        float frag_intensity = 0.05 + 0.1 * random(cell_idx);
        
        // Random "re-sampling" from a different area of the noise field
        vec2 offset_seed = cell_idx * 0.5 + floor(u_time * 0.8);
        vec2 sample_offset = vec2(random(offset_seed), random(offset_seed + 1.2)) - 0.5;
        
        // Final UV is a mix of current and sampled, scaled by the broad density
        final_uv += sample_offset * frag_intensity;
        
        // Add a secondary subdivision look using fract() of the density coordinates
        float sub_grid = step(0.95, fract(st.x * 2.0)) + step(0.95, fract(st.y * 2.0));
        if (sub_grid > 0.5) {
            final_uv = fract(final_uv * 1.1); // slight zoom-in on the fragments
        }
    }

    gl_FragColor = texture2D(u_texture, fract(final_uv));
}