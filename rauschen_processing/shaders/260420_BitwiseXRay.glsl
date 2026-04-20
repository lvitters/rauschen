precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;
uniform int u_cells_x;
uniform int u_cells_y;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Density/scale factor derived from u_cells_x/y
    float scale = (float(u_cells_x) + float(u_cells_y)) / 20.0;
    
    vec4 color = texture2D(u_texture, uv);
    
    // Instead of snapping to cells, use them as a "unit" for the glitch speed
    float t = u_time * (1.0 + scale * 0.01);
    
    // Smooth, drifting X-ray offsets that aren't locked to the grid
    // Using scale as a magnitude multiplier
    vec2 offset = vec2(sin(t), cos(t * 0.7)) * 0.1 * (scale / 100.0);
    
    // Sample the reference content with the drift
    vec4 ref = texture2D(u_texture, fract(uv + offset));
    
    // Simulated "XOR" via absolute difference
    vec3 xor_color = abs(color.rgb - ref.rgb);
    
    // Scanline/Glitch pattern intensity driven by "density" (u_cells)
    float scanline_freq = float(u_cells_y) * 0.05;
    float scanline = sin(uv.y * scanline_freq + u_time * 8.0);
    
    // High-contrast mask that drifts and doesn't snap to cell borders
    float flash_pattern = sin(uv.x * scale * 0.1 + uv.y * scale * 0.15 + u_time * 4.0);
    float flash_threshold = 0.95 - (scale * 0.001); // Denser grid makes flashes more frequent
    float grid_flash = step(flash_threshold, flash_pattern);
    
    vec3 final_rgb = xor_color;
    
    // Conditional inversion based on the drifting patterns
    if (scanline > 0.92 || grid_flash > 0.5) {
        final_rgb = 1.0 - final_rgb;
    }
    
    // Boost contrast for a sharp digital aesthetic
    final_rgb = smoothstep(0.1, 0.9, final_rgb);

    gl_FragColor = vec4(final_rgb, 1.0);
}