shader_type canvas_item;

uniform float phase = 0.0;

void fragment() {
	vec4 surface = texture(TEXTURE, UV) * COLOR;
	// A brief moving reflection across the facets, followed by a quiet interval.
	float sweep = mod(TIME + phase, 5.5) * 0.55 - 0.5;
	float distance_to_light = abs(UV.x * 0.7 + UV.y * 0.3 - sweep);
	float glint = (1.0 - smoothstep(0.0, 0.075, distance_to_light)) * 0.38;
	surface.rgb = mix(surface.rgb, vec3(1.0), glint);
	COLOR = surface;
}
