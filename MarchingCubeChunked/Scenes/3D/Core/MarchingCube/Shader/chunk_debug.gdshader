shader_type spatial;
render_mode wireframe, cull_disabled, unshaded;

instance uniform bool is_generating = false;

void vertex() {
	COLOR = is_generating ? vec4(2.0, 0.0, 0.0, 1.0) : vec4(1.0, 1.0, 1.0, 0.01);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;

	if (is_generating)
		EMISSION = ALBEDO * 4.0;
}
