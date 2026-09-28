// Paper-theater material for a CanvasGroup: everything drawn inside the group is treated
// as one sheet of cut paper. Adds paper grain and fibers, a raised papier-mache relief
// along edges (lit from the top left), a soft shadow cast onto whatever is behind, and
// optional depth haze and blur for far scenery layers.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D grain_tex : repeat_enable, filter_linear;
uniform sampler2D fiber_tex : repeat_enable, filter_linear;

uniform float grain_strength = 0.14;
uniform float fiber_strength = 0.07;
uniform float grain_scale = 300.0;
uniform vec2 grain_offset = vec2(0.0);

uniform float bevel_radius = 3.0;
uniform float bevel_strength = 0.9;
uniform vec2 light_dir = vec2(-0.55, -0.85);

uniform vec2 shadow_offset = vec2(9.0, 11.0);
uniform float shadow_alpha = 0.35;
uniform float shadow_blur = 2.0;

uniform float blur = 0.0;
uniform vec4 haze_color : source_color = vec4(0.93, 0.86, 0.72, 1.0);
uniform float haze = 0.0;

vec4 straight(vec4 c) {
	return c.a > 0.0001 ? vec4(c.rgb / c.a, c.a) : vec4(0.0);
}

// "Height" of the paper: solid where there is paper, a little higher on light pieces so
// the cream cut edges between pieces read as raised folds.
float height(vec2 uv, float lod) {
	vec4 c = straight(textureLod(screen_tex, uv, lod));
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	return c.a * (0.7 + 0.3 * lum);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec4 c = straight(textureLod(screen_tex, SCREEN_UV, blur));

	// Papier-mache relief.
	float r = bevel_radius;
	float lod = 0.8 + blur;
	float hl = height(SCREEN_UV + vec2(-r, 0.0) * px, lod);
	float hr = height(SCREEN_UV + vec2(r, 0.0) * px, lod);
	float hu = height(SCREEN_UV + vec2(0.0, -r) * px, lod);
	float hd = height(SCREEN_UV + vec2(0.0, r) * px, lod);
	vec2 g = vec2(hr - hl, hd - hu);
	vec3 n = normalize(vec3(-g * 2.2, 1.0));
	vec3 l = normalize(vec3(light_dir, 0.9));
	float shade = dot(n, l) - l.z;
	c.rgb *= 1.0 + shade * bevel_strength;

	// Paper grain and fibers, stuck to the paper rather than the screen.
	vec2 pix = SCREEN_UV / px - grain_offset;
	float gn = texture(grain_tex, pix / grain_scale).r;
	float fb = texture(fiber_tex, pix / grain_scale * vec2(0.35, 2.5)).r;
	c.rgb *= 1.0 + (gn - 0.5) * grain_strength + (fb - 0.5) * fiber_strength;

	// Distance haze for far layers.
	c.rgb = mix(c.rgb, haze_color.rgb, haze);

	// Soft shadow cast onto whatever is behind the group.
	float sa = textureLod(screen_tex, SCREEN_UV - shadow_offset * px, shadow_blur).a * shadow_alpha;
	float out_a = c.a + sa * (1.0 - c.a);
	vec3 out_rgb = out_a > 0.0001 ? (c.rgb * c.a) / out_a : vec3(0.0);
	COLOR = vec4(out_rgb, out_a);
}
