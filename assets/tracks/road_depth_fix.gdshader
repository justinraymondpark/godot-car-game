shader_type spatial;
render_mode depth_draw_opaque, depth_prepass_alpha, cull_back;

// Textures
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_texture : filter_linear_mipmap, repeat_enable;

// Colors and values
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

// Texture toggles
uniform bool has_albedo_texture = true;
uniform bool has_normal_texture = false;
uniform bool has_roughness_texture = false;

// Wrap mode: 0 = repeat, 1 = mirror, 2 = clamp
uniform int wrap_mode : hint_range(0, 2) = 1;

// DEPTH OFFSET - negative values push geometry "closer" to camera
// This helps prevent z-fighting with distant geometry
uniform float depth_offset : hint_range(-0.01, 0.01) = -0.0001;

vec2 apply_wrap_mode(vec2 uv) {
	if (wrap_mode == 1) {
		// Mirror
		vec2 t = mod(uv, 2.0);
		return mix(t, 2.0 - t, step(1.0, t));
	} else if (wrap_mode == 2) {
		// Clamp
		return clamp(uv, 0.0, 1.0);
	}
	// Default: repeat (handled by sampler)
	return uv;
}

void vertex() {
	// Apply depth offset by moving vertex slightly along view direction
	// This makes the surface render "in front of" where it actually is
	VERTEX += normalize(VERTEX) * depth_offset;
}

void fragment() {
	vec2 uv = apply_wrap_mode(UV);
	
	// Albedo
	if (has_albedo_texture) {
		vec4 tex_color = texture(albedo_texture, uv);
		ALBEDO = tex_color.rgb * albedo_color.rgb;
		ALPHA = tex_color.a * albedo_color.a;
	} else {
		ALBEDO = albedo_color.rgb;
		ALPHA = albedo_color.a;
	}
	
	// Normal map
	if (has_normal_texture) {
		vec3 normal_map = texture(normal_texture, uv).rgb;
		NORMAL_MAP = normal_map;
		NORMAL_MAP_DEPTH = normal_strength;
	}
	
	// Roughness
	if (has_roughness_texture) {
		ROUGHNESS = texture(roughness_texture, uv).r * roughness;
	} else {
		ROUGHNESS = roughness;
	}
	
	// Metallic
	METALLIC = metallic;
}
