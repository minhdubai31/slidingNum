shader_type canvas_item;
render_mode unshaded;
uniform vec2 rect_size = vec2(190.0, 195.0);
uniform float radius = 18.0;
uniform float shade_strength = 0.82;
varying vec2 point;
varying vec4 tint;

void vertex() {
	point = VERTEX;
	tint = COLOR;
}

void fragment() {
	vec2 q = abs(point - rect_size * 0.5) - rect_size * 0.5 + vec2(radius);
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float aa = max(fwidth(d), 0.65);
	float mask = 1.0 - smoothstep(-aa, aa, d);
	vec4 image = texture(TEXTURE, UV) * tint;
	float t = point.y / rect_size.y;
	float shade = smoothstep(0.38, 1.0, t) * shade_strength;
	image.rgb = mix(image.rgb, vec3(0.025, 0.10, 0.12), shade);
	image.a *= mask;
	COLOR = image;
}
