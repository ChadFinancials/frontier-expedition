// Tabletop-theater lighting: a warm lamp pool in the middle of the stage, soft darkness
// toward the corners.
shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.55);
uniform float radius = 0.75;
uniform float softness = 0.55;
uniform float darkness = 0.4;
uniform vec4 warm : source_color = vec4(1.0, 0.82, 0.55, 1.0);
uniform float warmth = 0.08;
uniform float aspect = 1.7778;

void fragment() {
	vec2 d = (UV - center) * vec2(aspect, 1.0);
	float dist = length(d) / aspect * 1.6;
	float v = smoothstep(radius - softness, radius, dist);
	float glow = 1.0 - smoothstep(0.0, radius, dist);
	COLOR = vec4(mix(vec3(0.05, 0.03, 0.02), warm.rgb, glow), v * darkness + glow * warmth);
}
