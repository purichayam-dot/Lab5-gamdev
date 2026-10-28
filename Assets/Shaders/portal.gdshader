shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// ประตูมิติในซุ้มโทริอิ (วงหมุนสองสี)

uniform vec4 color_a : source_color = vec4(0.35, 0.95, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.45, 0.85, 1.0);
uniform float power : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= 1.15;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float swirl = sin(a * 3.0 + r * 9.0 - TIME * 3.0) * 0.5 + 0.5;
	float rings = sin(r * 18.0 - TIME * 5.0) * 0.5 + 0.5;
	float edge = smoothstep(1.0, 0.72, r);
	vec3 col = mix(color_a.rgb, color_b.rgb, swirl);
	col += vec3(1.0) * pow(1.0 - r, 3.0) * 0.8;
	ALBEDO = col * (0.4 + 0.6 * power) * 1.6;
	ALPHA = edge * mix(0.35, 0.65 + 0.35 * rings, power);
}
