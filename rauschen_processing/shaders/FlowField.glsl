#ifdef GL_ES
precision mediump float;
#endif

// claude.ai vibe coding

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

// map a value from one range to another
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, uv);
    
    // use the texture's brightness to influence the flow field intensity
    float brightness = (texColor.r + texColor.g + texColor.b) / 3.0;
    
    // create multiple layers of flow fields using different scales
    float flowScale1 = 3.0;  // large scale flow patterns
    float flowScale2 = 8.0;  // medium scale flow details
    float flowScale3 = 20.0; // small scale flow details
    
    // use different noise layers for more varied flow directions
    float noise1 = snoise(vec2(uv.x * flowScale1, uv.y * flowScale1) + u_time * 0.2);
    float noise2 = snoise(vec2(uv.y * flowScale2, uv.x * flowScale2) + u_time * 0.1);
    float noise3 = snoise(vec2(uv.x * flowScale3 + 100.0, uv.y * flowScale3 + 100.0) + u_time * 0.3);
    
    // create more complex angle by combining noise at different scales
    float angle1 = noise1 * 6.28;
    float angle2 = noise2 * 3.14;
    float angle3 = noise3 * 1.57;
    
    // combine angles with different weights
    float angle = angle1 * 0.5 + angle2 * 0.3 + angle3 * 0.2;
    
    // use position-dependent flow direction
    // create vortex-like patterns
    vec2 center = vec2(0.5, 0.5);
    vec2 toCenter = center - uv;
    float distToCenter = length(toCenter);
    float vortexAngle = atan(toCenter.y, toCenter.x);
    
    // combine noise-based angles with position-based flow
    angle += vortexAngle * (0.2 + 0.1 * sin(u_time * 0.2));
    
    // add some spiraling based on distance to center
    angle += distToCenter * 4.0 * sin(u_time * 0.1);
    
    // create a vector from the angle with varying magnitude
    float flowMagnitude = 0.01 + 0.005 * sin(u_time * 0.3 + uv.x * 10.0);
    vec2 flowVector = vec2(cos(angle), sin(angle)) * flowMagnitude;
    
    // scale the displacement by the brightness of the texture
    // brighter areas flow more, darker areas flow less
    flowVector *= brightness + 0.2;
    
    // add some turbulence that varies with position
    flowVector += vec2(
        snoise(uv * 15.0 + vec2(0.0, u_time * 0.2)) * 0.002,
        snoise(uv * 15.0 + vec2(u_time * 0.2, 0.0)) * 0.002
    );
    
    // sample the texture at the flowed coordinates
    vec4 flowColor = texture2D(u_texture, uv + flowVector);
    
    // add slight color variation based on the flow direction
    vec3 tint = vec3(
        0.9 + 0.1 * cos(angle),
        0.9 + 0.1 * cos(angle + 2.09),
        0.9 + 0.1 * sin(angle)
    );
    
    // mix the original texture with the flowed texture
    vec3 finalColor = mix(texColor.rgb, flowColor.rgb * tint, 0.9);
    
    // add subtle noise to the result for more texture
    float detailNoise = snoise(uv * 30.0 + u_time) * 0.03;
    finalColor += vec3(detailNoise);
    
    // ensure colors stay in valid range
    finalColor = clamp(finalColor, 0.0, 1.0);
    
    gl_FragColor = vec4(finalColor, 1.0);
}