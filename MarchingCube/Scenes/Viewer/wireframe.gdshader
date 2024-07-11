// Wireframe shader to show backside of texture
// From on https://godotshaders.com/shader/wireframe/
// Just changed misleading name 'outline_width' as it just displaces not thicken line

shader_type spatial;
render_mode unshaded, wireframe;

uniform vec4 albedo : source_color = vec4(1.0,0.0,0.0,1.0);
uniform float displacement : hint_range(0.0, 10.0, 0.1) = 3.0;


void vertex() {
	// 
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);

	vec2 offset = normalize(clip_normal.xy) / VIEWPORT_SIZE *
		clip_position.w * displacement;

	clip_position.xy += offset;
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
}