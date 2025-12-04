shader_type spatial;

// Textures
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D metallic_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap, repeat_enable;

// Colors and values
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy : hint_range(0.0, 10.0) = 0.0;

// Toggle for which textures are used
uniform bool has_albedo_texture = true;
uniform bool has_normal_texture = false;
uniform bool has_roughness_texture = false;
uniform bool has_metallic_texture = false;
uniform bool has_emission_texture = false;

// Wrap mode: 0 = repeat, 1 = mirror, 2 = clamp
uniform int wrap_mode : hint_range(0, 2) = 1;

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
	if (has_metallic_texture) {
		METALLIC = texture(metallic_texture, uv).r * metallic;
	} else {
		METALLIC = metallic;
	}
	
	// Emission
	if (has_emission_texture) {
		EMISSION = texture(emission_texture, uv).rgb * emission_energy;
	} else {
		EMISSION = emission * emission_energy;
	}
}
