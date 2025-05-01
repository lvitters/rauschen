#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform sampler2D u_texture;
uniform float u_time;

// simplex noise function
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v) {
	const vec4 C = vec4(0.211324865405187, 0.366025403784439,
			-0.577350269189626, 0.024390243902439);
	vec2 i  = floor(v + dot(v, C.yy));
	vec2 x0 = v -   i + dot(i, C.xx);
	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod(i, 289.0);
	vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
	+ i.x + vec3(0.0, i1.x, 1.0 ));
	vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
		dot(x12.zw,x12.zw)), 0.0);
	m = m*m ;
	m = m*m ;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

// curl noise - creates vector fields with no divergence
vec2 curl(vec2 p) {
    // small offset for gradient approximation
    float eps = 0.01;
    
    // sampling noise at offset points
    float n1 = snoise(vec2(p.x, p.y + eps));
    float n2 = snoise(vec2(p.x, p.y - eps));
    float n3 = snoise(vec2(p.x + eps, p.y));
    float n4 = snoise(vec2(p.x - eps, p.y));
    
    // approximate gradient using central differences
    float dy = (n1 - n2) / (2.0 * eps);
    float dx = (n3 - n4) / (2.0 * eps);
    
    // curl is perpendicular to gradient
    return vec2(dy, -dx);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, uv);
    
    // use curl noise for a more fluid-like divergence-free flow field
    // multiple layers of curl noise at different scales
    
    // small-scale details (high frequency noise)
    vec2 p1 = uv * 6.0 + u_time * 0.1;
    vec2 curl1 = curl(p1) * 0.003;
    
    // medium-scale flows
    vec2 p2 = uv * 3.0 - u_time * 0.05;
    vec2 curl2 = curl(p2) * 0.006;
    
    // large-scale flows
    vec2 p3 = uv * 1.5 + u_time * 0.02;
    vec2 curl3 = curl(p3) * 0.012;
    
    // turbulence detail
    vec2 p4 = uv * 12.0 - u_time * 0.2;
    vec2 curl4 = curl(p4) * 0.001;
    
    // combine curl noise at different scales
    vec2 flowVector = curl1 + curl2 + curl3 + curl4;
    
    // add variation based on texture color to create more interesting interactions
    float r = texColor.r * 2.0 - 1.0;
    float g = texColor.g * 2.0 - 1.0;
    float b = texColor.b * 2.0 - 1.0;
    
    // rotate flow vector based on color channels
    // this creates more varied directions based on pixel color
    float colorAngle = r * 0.5 + g * 0.3 + b * 0.2;
    float s = sin(colorAngle);
    float c = cos(colorAngle);
    vec2 rotatedFlow = vec2(
        flowVector.x * c - flowVector.y * s,
        flowVector.x * s + flowVector.y * c
    );
    
    // scale by brightness for stronger flow in brighter areas
    float brightness = (texColor.r + texColor.g + texColor.b) / 3.0;
    flowVector = rotatedFlow * (brightness + 0.2) * 1.5;
    
    // sample texture at offset position
    vec4 flowColor = texture2D(u_texture, uv + flowVector);
    
    // add subtle color variation based on flow direction
    float flowAngle = atan(flowVector.y, flowVector.x);
    vec3 tint = vec3(
        0.95 + 0.05 * cos(flowAngle),
        0.95 + 0.05 * cos(flowAngle + 2.09),
        0.95 + 0.05 * sin(flowAngle)
    );
    
    // mix the original texture with the flowed texture
    // vec3 finalColor = mix(texColor.rgb, flowColor.rgb * tint, 0.85);
    
	// since "buffer ping pong" has been implemented, mixing isn't needed anymore
    gl_FragColor = vec4(flowColor.rgb * tint, 1.0);
}