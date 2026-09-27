#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm (in vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 5; ++i) {
        value += amplitude * noise(st);
        st = rot * st * 2.0 + shift;
        amplitude *= 0.5;
    }
    return value;
}

void main() {
    vec2 st = FlutterFragCoord().xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y;

    vec2 q = vec2(0.0);
    q.x = fbm(st + 0.01 * u_time);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.0);
    r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2) + 0.15 * u_time);
    r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8) + 0.126 * u_time);

    float f = fbm(st + r);

    // Deep midnight navy base (#0B1120 is roughly rgb(11, 17, 32))
    vec3 color = vec3(0.043, 0.067, 0.125);
    
    // Smooth variations
    color = mix(color, vec3(0.067, 0.094, 0.153), clamp((f*f)*4.0, 0.0, 1.0));
    color = mix(color, vec3(0.02, 0.03, 0.05), clamp(length(q), 0.0, 1.0));
    
    // Very subtle hint of Terminal Green (#10B981) where r is high
    color = mix(color, vec3(0.063, 0.725, 0.506) * 0.15, clamp(length(r.x)*0.5, 0.0, 1.0));

    vec3 finalColor = (f*f*f + 0.6*f*f + 0.5*f) * color;
    
    // Boost contrast slightly
    finalColor = smoothstep(0.0, 0.8, finalColor);
    
    fragColor = vec4(finalColor, 1.0);
}
