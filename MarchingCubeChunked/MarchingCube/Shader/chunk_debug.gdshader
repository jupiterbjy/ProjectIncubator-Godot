shader_type spatial;
render_mode wireframe, cull_disabled, unshaded;

void fragment() {
	ALBEDO = vec3(1.0);
	ALPHA = 0.05;
	
	// Removing due to instance variable total size limit for web build
	//if (is_generating)
		//EMISSION = ALBEDO;
}
