shader_type canvas_item;
render_mode unshaded;

uniform vec2 control_size = vec2(104.0, 100.0);
uniform float corner_radius = 22.0;
uniform vec4 top_color : source_color = vec4(1.0, 0.99, 0.96, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.95, 0.91, 0.83, 1.0);
uniform vec4 base_color : source_color = vec4(0.72, 0.60, 0.44, 1.0);
uniform float press_depth = 0.0;
uniform float disabled_amount = 0.0;
uniform float hover_amount = 0.0;
uniform bool round_button = false;
varying vec4 vertex_tint;

void vertex() { vertex_tint = COLOR; }

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 canvas_size = control_size + vec2(10.0, 15.0);
	vec2 p = UV * canvas_size;
	vec2 face_size = control_size - vec2(0.0, 2.0);
	vec2 center = vec2(5.0, 3.0 + press_depth * 1.5) + face_size * 0.5;
	if (round_button) {
		// Always a true circle centred in the control, whatever its laid-out size.
		float d = min(control_size.x, control_size.y) - 2.0;
		face_size = vec2(d);
		center = vec2(5.0 + control_size.x * 0.5, 3.0 + press_depth * 1.5 + (control_size.y - 2.0) * 0.5);
	}
	float radius = min(corner_radius, min(face_size.x, face_size.y) * 0.49);
	if (round_button) { radius = face_size.x * 0.5; }
	float face_d = rounded_box(p - center, face_size * 0.5, radius);
	float base_d = rounded_box(p - center - vec2(0.0, 1.8 - press_depth), face_size * 0.5, radius);
	float shadow_d = rounded_box(p - center - vec2(0.0, 3.0 - press_depth), face_size * 0.5, radius);
	float aa = max(fwidth(face_d), 0.7);
	float face_mask = 1.0 - smoothstep(-aa, aa, face_d);
	float base_mask = 1.0 - smoothstep(-aa, aa, base_d);
	float shadow_mask = (1.0 - smoothstep(-1.5, 4.5, shadow_d)) * 0.08;
	vec3 base = mix(base_color.rgb, vec3(0.74, 0.70, 0.64), disabled_amount * 0.6);
	vec3 color = mix(vec3(0.15, 0.10, 0.05), base, base_mask);
	float alpha = max(shadow_mask, base_mask);
	float t = clamp((p.y - center.y + face_size.y * 0.5) / face_size.y, 0.0, 1.0);
	vec3 face = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, t));
	face += hover_amount * 0.012;
	face = mix(face, vec3(0.93, 0.91, 0.87), disabled_amount * 0.45);
	// A broad satin highlight, with a narrow rim catching light at the top.
	float satin = exp(-pow((t - 0.16) * 3.2, 2.0)) * 0.09;
	face = mix(face, vec3(1.0), satin * (1.0 - disabled_amount));
	float rim = exp(-pow((face_d + 0.7) / 1.3, 2.0));
	vec3 rim_color = mix(vec3(0.70, 0.61, 0.46), vec3(1.0, 1.0, 0.98), 1.0 - t);
	face = mix(face, rim_color, rim * mix(0.16, 0.07, t));
	color = mix(color, face, face_mask);
	alpha = max(alpha, face_mask);
	COLOR = vec4(color, alpha) * vertex_tint;
}
