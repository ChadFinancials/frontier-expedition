// A watercolor sky painted on rough paper: a top-to-bottom wash with blotchy pigment,
// darker pooled edges and paper grain.
shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.24, 0.35, 0.5, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.96, 0.74, 0.38, 1.0);
uniform sampler2D wash_tex : repeat_enable, filter_linear;
uniform sampler2D grain_tex : repeat_enable, filter_linear;
uniform float wash_strength = 0.1;
uniform float grain_strength = 0.1;
uniform float drift = 0.0;
uniform vec2 size = vec2(1920.0, 1080.0);

void fragment() {
	vec2 p = UV * size;
	float t = clamp(UV.y + (texture(wash_tex, p / 900.0 + vec2(drift, 0.0)).r - 0.5) * 0.18, 0.0, 1.0);
	vec3 col = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, t));
	float blot = texture(wash_tex, p / 420.0 + vec2(drift * 0.5, 0.3)).r;
	col *= 1.0 + (blot - 0.5) * wash_strength * 2.0;
	// Pigment pools toward the edges of the sheet.
	vec2 e = min(UV, 1.0 - UV);
	float edge = smoothstep(0.0, 0.08, min(e.x, e.y));
	col *= mix(0.95, 1.0, edge);
	float gn = texture(grain_tex, p / 300.0).r;
	col *= 1.0 + (gn - 0.5) * grain_strength;
	COLOR = vec4(col, 1.0);
}
