shader_type canvas_item;
render_mode unshaded;

// Lit rounded block: a flat face with a smooth bevel that curves down to the edge.
uniform float uv_grid = 1.0;
uniform vec2 block_size = vec2(100.0, 100.0);
uniform float corner = 10.0;
uniform float bevel = 8.0;
uniform float bevel_height = 1.0;
uniform float ambient = 0.6;
uniform float light_strength = 0.55;
uniform float shine = 0.22;
uniform float shadow_strength = 0.5;
uniform float top_gloss = 0.0;
uniform float desaturate = 0.0;

// Capture vertex tint before Godot multiplies fragment COLOR by the texture.
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}

float rounded_sdf(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 half_size = block_size * 0.5;
	vec2 local_uv = fract(UV * uv_grid);
	vec2 p = (local_uv - 0.5) * block_size;
	float d = rounded_sdf(p, half_size, corner);
	float aa = max(fwidth(d), 0.5);
	float mask = 1.0 - smoothstep(-aa, aa, d);

	// Circular bevel profile: the slope is zero on the flat face and steepens toward the edge.
	float inward = clamp(-d / bevel, 0.0, 1.0);
	float u = 1.0 - inward;
	float slope = min(u / max(sqrt(max(1.0 - u * u, 0.0001)), 0.05) * bevel_height / bevel, 8.0);

	// Outward direction of the nearest edge at this pixel.
	vec2 q = abs(p) - half_size + vec2(corner);
	vec2 g = max(q, vec2(0.0));
	vec2 outward = length(g) > 0.0001 ? normalize(g) * sign(p) : (q.x > q.y ? vec2(sign(p.x), 0.0) : vec2(0.0, sign(p.y)));
	vec3 n = normalize(vec3(outward * slope, 1.0));

	vec3 light = normalize(vec3(-0.45, -0.6, 0.66));
	vec3 half_vec = normalize(light + vec3(0.0, 0.0, 1.0));
	float diffuse = max(dot(n, light), 0.0);
	float spec = pow(max(dot(n, half_vec), 0.0), 14.0) * shine;
	// Broad, restrained reflection along the curved edge.
	float corner_glint = pow(max(dot(n, normalize(vec3(-0.6, -0.6, 0.5))), 0.0), 8.0) * shine * 0.3;
	spec = (spec + corner_glint) * (1.0 - inward);

	vec4 base = texture(TEXTURE, UV) * vertex_tint;
	// Preserve the material color unless an explicit desaturation is requested.
	float luma = dot(base.rgb, vec3(0.3, 0.59, 0.11));
	base.rgb = mix(base.rgb, vec3(luma), desaturate);
	// Edges turned away from the light fall into shade; the flat face is unaffected.
	float away = max(-dot(n, light), 0.0);
	vec3 lit = base.rgb * (1.0 + (diffuse - light.z) * light_strength) * (1.0 - away * shadow_strength) + (vec3(1.0) - base.rgb) * spec;
	// Soft sheen across the upper part of the face, like the glossy reference tiles.
	float sheen = top_gloss * pow(1.0 - clamp(local_uv.y, 0.0, 1.0), 3.0);
	lit += vec3(sheen) * mask;
	COLOR = vec4(lit, base.a * mask);
}
