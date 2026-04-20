precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;
uniform int u_cells_x;
uniform int u_cells_y;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Use u_cells_x/y as frequency scaling for a smoother wave field
    // Instead of snapping to cells, we create a continuous wavy landscape
    float frequency = mix(5.0, 20.0, (float(u_cells_x) + float(u_cells_y)) / 2000.0);
    
    // Multi-layered sine wave movement for a "liquid" feel
    float wave_x = sin(uv.y * frequency + u_time * 0.5) * 0.05;
    float wave_y = cos(uv.x * frequency * 1.2 + u_time * 0.7) * 0.05;
    
    // Sample a broad "neighborhood" intensity that isn't locked to single pixels
    vec2 neighbor_uv = uv + vec2(wave_x, wave_y);
    vec4 neighbor_color = texture2D(u_texture, fract(neighbor_uv));
    
    // Displacement force is derived from neighborhood brightness but flows smoothly
    float displacement_force = (neighbor_color.r + neighbor_color.g + neighbor_color.b) / 3.0;
    
    // Final displacement direction wanders based on time
    vec2 drift = vec2(sin(u_time * 0.2), cos(u_time * 0.15)) * 0.1;
    vec2 target_uv = fract(uv + drift * displacement_force);
    
    // Mix based on a broad "pulsing" rather than strict cell checks
    float pulse = sin(u_time * 0.4) * 0.5 + 0.5;
    vec4 final_color = texture2D(u_texture, mix(uv, target_uv, pulse));
    
    gl_FragColor = vec4(final_color.rgb, 1.0);
}