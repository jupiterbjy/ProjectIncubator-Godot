// Written by jupiterbjy@gmail.com
// As part of https://github.com/jupiterbjy/ProjectIncubator-Godot
// Uses sprite image for each points

shader_type spatial;
render_mode depth_prepass_alpha, fog_disabled, specular_disabled, unshaded;

uniform float point_size : hint_range(1.0, 1000.0, 1) = 16.0;
uniform sampler2D sprite;

uniform float brightness_multiplier = 1.0;

// Used to designate UV start point
uniform vec2 uv_start = vec2(0.0);

// Used to designate UV width/height
uniform vec2 uv_range = vec2(1.0);


void vertex() {
	// Calculate distance from camera to mimic distance falloff.
	// Ignore div by zero case, extremely rare anyway.
	// Since VERTEX is local coord, translate it into world space using MODEL_MATRIX.
	POINT_SIZE = point_size / distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
}


void fragment() {
	// cut corners to form circle
	if (distance(POINT_COORD, vec2(0.5, 0.5)) > 0.5) {
		discard;
	}

	// Crop UV & flip to match orientation
	vec2 uv = uv_start + uv_range * vec2(POINT_COORD.x, 1.0 - POINT_COORD.y);

	vec4 tex_color = clamp(texture(sprite, uv) * brightness_multiplier, 0.0, 1.0);

	// Convert to greyscale - preferrably provide greyscale image and comment this out
	float lumi = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));

	// Uncomment alpha if needed
	ALBEDO = lumi * COLOR.rgb;
	//ALPHA = tex_color.a * COLOR.a;
}
