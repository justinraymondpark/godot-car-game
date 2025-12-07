extends Node

## Attach this script to the Track node to fix texture wrap modes at runtime.
## It converts materials using specific textures to use a custom mirrored shader.
## Also applies depth offset to fix z-fighting with distant geometry.

## TOGGLE THIS IN INSPECTOR TO ENABLE/DISABLE THE SHADER
@export var enable_shader_fix := true

## USE WEB SHADER - Auto-detects web platform, or can force ON
@export var use_web_shader := false

# Auto-detect web platform
var is_web_platform := false

# Textures that need MIRRORED wrap mode (wrap_mode = 1)
const MIRROR_TEXTURES := [
	"texture_548",
	"texture_571",
	"texture_597",
	"texture_521",
	"texture_612",
]

# Textures that need CLAMP (Extend) wrap mode (wrap_mode = 2)
const CLAMP_TEXTURES := [
	"texture_665",
	"texture_1172",
]

# Apply depth fix shader to ALL materials (to fix z-fighting)
const APPLY_DEPTH_FIX_TO_ALL := true

var depth_fix_shader: Shader
var processed_materials := {}  # Cache to avoid processing same material twice
var depth_fixed_count := 0


func _ready() -> void:
	print("=== TRACK TEXTURE FIXER V10 ===")
	if not enable_shader_fix:
		print("Track texture fixer DISABLED")
		return
	
	# Detect platform
	is_web_platform = OS.get_name() == "Web"
	
	if is_web_platform or use_web_shader:
		depth_fix_shader = preload("res://assets/tracks/road_depth_fix_web.gdshader")
		print("Using WEB shader (Platform: ", OS.get_name(), ", Force Web: ", use_web_shader, ")")
	else:
		depth_fix_shader = preload("res://assets/tracks/road_depth_fix.gdshader")
		print("Using DESKTOP shader (Platform: ", OS.get_name(), ")")
	
	# Fix all materials in this node and children
	fix_texture_wrap_modes(self)
	print("Track texture wrap modes fixed! Processed ", processed_materials.size(), " materials.")
	print("Applied depth fix to ", depth_fixed_count, " materials.")


func fix_texture_wrap_modes(node: Node) -> void:
	if node is MeshInstance3D:
		fix_mesh_materials(node as MeshInstance3D)
	
	for child in node.get_children():
		fix_texture_wrap_modes(child)


func fix_mesh_materials(mesh_instance: MeshInstance3D) -> void:
	var mesh := mesh_instance.mesh
	if not mesh:
		return
	
	for surface_idx in mesh.get_surface_count():
		var material := mesh_instance.get_active_material(surface_idx)
		if material and material is StandardMaterial3D:
			var std_mat := material as StandardMaterial3D
			
			# Get wrap mode for this material
			var wrap_mode := get_wrap_mode_for_material(std_mat)
			
			# Apply depth fix shader to all materials, or just ones that need wrap fix
			if APPLY_DEPTH_FIX_TO_ALL or wrap_mode >= 0:
				var new_material := convert_to_shader_material(std_mat, wrap_mode)
				mesh_instance.set_surface_override_material(surface_idx, new_material)
				depth_fixed_count += 1


func get_wrap_mode_for_material(material: StandardMaterial3D) -> int:
	# Check albedo texture path
	if material.albedo_texture:
		var tex_path: String = material.albedo_texture.resource_path
		
		for mirror_tex in MIRROR_TEXTURES:
			if mirror_tex in tex_path:
				return 1  # Mirror
		
		for clamp_tex in CLAMP_TEXTURES:
			if clamp_tex in tex_path:
				return 2  # Clamp
	
	return -1  # No change needed


func convert_to_shader_material(std_mat: StandardMaterial3D, wrap_mode: int) -> ShaderMaterial:
	# Check cache
	var cache_key := str(std_mat.resource_path) + "_" + str(wrap_mode)
	if cache_key in processed_materials:
		return processed_materials[cache_key]
	
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = depth_fix_shader
	
	# Set wrap mode (0 = repeat, 1 = mirror, 2 = clamp)
	if wrap_mode >= 0:
		shader_mat.set_shader_parameter("wrap_mode", wrap_mode)
	else:
		shader_mat.set_shader_parameter("wrap_mode", 0)  # Default repeat
	
	# Set depth offset (negative = closer to camera)
	shader_mat.set_shader_parameter("depth_offset", -0.0005)
	
	# Copy albedo
	if std_mat.albedo_texture:
		shader_mat.set_shader_parameter("has_albedo_texture", true)
		shader_mat.set_shader_parameter("albedo_texture", std_mat.albedo_texture)
	else:
		shader_mat.set_shader_parameter("has_albedo_texture", false)
	shader_mat.set_shader_parameter("albedo_color", std_mat.albedo_color)
	
	# Copy normal map
	if std_mat.normal_texture:
		shader_mat.set_shader_parameter("has_normal_texture", true)
		shader_mat.set_shader_parameter("normal_texture", std_mat.normal_texture)
		shader_mat.set_shader_parameter("normal_strength", std_mat.normal_scale)
	else:
		shader_mat.set_shader_parameter("has_normal_texture", false)
	
	# Copy roughness
	if std_mat.roughness_texture:
		shader_mat.set_shader_parameter("has_roughness_texture", true)
		shader_mat.set_shader_parameter("roughness_texture", std_mat.roughness_texture)
	else:
		shader_mat.set_shader_parameter("has_roughness_texture", false)
	shader_mat.set_shader_parameter("roughness", std_mat.roughness)
	
	# Metallic
	shader_mat.set_shader_parameter("metallic", std_mat.metallic)
	
	# Cache it
	processed_materials[cache_key] = shader_mat
	
	return shader_mat
