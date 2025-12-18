shader_type spatial;
render_mode wireframe, cull_disabled;

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0);
	EMISSION = vec3(0.1, 0.0, 0.0);
}
