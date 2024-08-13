// Written by jupiterbjy@gmail.com
// As part of https://github.com/jupiterbjy/ProjectIncubator-Godot

shader_type spatial;
render_mode depth_prepass_alpha, fog_disabled, specular_disabled, unshaded;


uniform float point_size = 16.0;
uniform sampler2D sprite;


void vertex() {
	// Calculate distance from camera to mimic distance falloff
	// Ignore div by zero case, extremely rare anyway
	POINT_SIZE = point_size / distance(VERTEX, CAMERA_POSITION_WORLD);
}

void fragment() {
	// Use sprite as point image
	
	ALBEDO = texture(sprite, POINT_COORD).rgb * COLOR.rgb;
	ALPHA = texture(sprite, POINT_COORD).a * COLOR.a;
}
