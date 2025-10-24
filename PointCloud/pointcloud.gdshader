// Written by jupiterbjy@gmail.com
// As part of https://github.com/jupiterbjy/ProjectIncubator-Godot

shader_type spatial;
render_mode depth_prepass_alpha, fog_disabled, specular_disabled, unshaded;


uniform float point_size : hint_range(1.0, 1000.0, 1) = 16.0;


void vertex() {
	// Calculate distance from camera to mimic distance falloff.
	// Ignore div by zero case, extremely rare anyway.
	// Since VERTEX is local coord, translate it into world space using MODEL_MATRIX.
	POINT_SIZE = point_size / distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
}


void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
