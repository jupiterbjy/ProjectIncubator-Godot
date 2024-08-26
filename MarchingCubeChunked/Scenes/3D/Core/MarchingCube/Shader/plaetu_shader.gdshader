shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec4 TopColor : source_color;
uniform vec4 SideColor : source_color;
uniform vec4 HeightColor : source_color;


void fragment() {
	// Get worldspace pos & normal
	vec3 ws_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 ws_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;

	// Get up vector product & sample angle gradiant color
	float dot_prod = abs(dot(ws_normal, vec3(0.0, 1.0, 0.0)));
	vec3 angle_color = (dot_prod > 0.7) ? TopColor.rgb : SideColor.rgb;

	// Blend based on height
	ALBEDO = mix(angle_color, HeightColor.rgb, clamp(ws_pos.y * 3.0, 0.0, 1.0));
}
