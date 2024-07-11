// Basic Triplanar shader.
// Implentation based on https://www.martinpalko.com/triplanar-mapping/

shader_type spatial;
render_mode cull_back, diffuse_lambert;
// No need to render back and roughness, normalmap will do.

// Albedo Texture we'll use for each axis
uniform sampler2D TextureX : source_color;
uniform sampler2D TextureY : source_color;
uniform sampler2D TextureZ : source_color;

// Color blend amount
uniform float BlendFactor = 1.0;

// Will use normal map to demonstrate how to set normalmap UV
uniform sampler2D NormalMap : hint_normal;

// Albedo & Normal Map Texture scale
uniform float Scale = 0.25;


void fragment() {
	// Normal  and Position(VERTEX) comes in viewport space.
	// So we need to convert those first into worldspace.
	// ws = world space
	
	// For worldspace position we do need 4x4 mult
	vec3 ws_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// For vector we don't need position, so give (norm x, y, z, 0) to multiply 3x3 only
	vec3 ws_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	
	// Now calculate UV for each axis
	vec2 x_uv = ws_pos.zy / Scale;
	vec2 y_uv = ws_pos.xz / Scale;
	vec2 z_uv = ws_pos.xz / Scale;
	
	// Sample Albedo for each axis
	vec3 x_al = texture(TextureX, x_uv).rgb;
	vec3 y_al = texture(TextureY, y_uv).rgb;
	vec3 z_al = texture(TextureZ, z_uv).rgb;
	
	// Same for normal map
	vec3 x_norm = texture(NormalMap, x_uv).rgb;
	vec3 y_norm = texture(NormalMap, y_uv).rgb;
	vec3 z_norm = texture(NormalMap, z_uv).rgb;
	
	// Now calculating blending weight represending color contribution for each axis.
	// We'll control axis bias via power function.
	// Since we only need to know which axis its' biased to, abs worldspace normal.
	// As unlike unity godot shader pow signature is (vec3, vec3) so we create vector of BlendFactor.
	vec3 weight = normalize(pow(abs(ws_normal), vec3(BlendFactor, BlendFactor, BlendFactor)));
	
	// Normalize it or we'll shoot some color out into HDR range.
	weight = normalize(weight);
	
	// Finally mix color
	ALBEDO = x_al * weight.x + y_al * weight.y + z_al * weight.z;
	
	// And normal. Do note that we're giving normal map, not normal.
	// If we overwrite normal then lighting will seems to follow camera.
	NORMAL_MAP = x_norm * weight.x + y_norm * weight.y + z_norm * weight.z;
}
