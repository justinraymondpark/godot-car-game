extends RigidBody3D

## Attach this to a RigidBody3D with the gate mesh as a child.
## The gate will break when hit with enough force.

@export var break_impulse := 300.0  ## Minimum impulse to break the gate
@export var break_sound: AudioStream  ## Optional: sound to play when breaking
@export var despawn_time := 5.0  ## How long until the broken gate disappears (0 = never)

var is_broken := false


func _ready() -> void:
	# Start frozen (static) until broken
	freeze = true
	
	# Connect to body_entered for collision detection
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if is_broken:
		return
	
	# Check if it's the car (RigidBody3D)
	if body is RigidBody3D and body != self:
		# Calculate impact force based on car's velocity and mass
		var car := body as RigidBody3D
		var impact_force := car.linear_velocity.length() * car.mass
		
		print("Gate impact force: ", impact_force)
		
		if impact_force > break_impulse:
			break_gate(car.linear_velocity)


func break_gate(impact_velocity: Vector3) -> void:
	is_broken = true
	freeze = false
	
	# Apply some force to make it fly away
	var push_force := impact_velocity.normalized() * 20.0
	push_force.y += 5.0  # Add some upward force
	apply_central_impulse(push_force)
	
	# Add some spin
	apply_torque_impulse(Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10)))
	
	# Play sound if set
	if break_sound:
		var audio := AudioStreamPlayer3D.new()
		audio.stream = break_sound
		get_parent().add_child(audio)
		audio.global_position = global_position
		audio.play()
		audio.finished.connect(audio.queue_free)
	
	print("Gate broken!")
	
	# Despawn after a while
	if despawn_time > 0:
		await get_tree().create_timer(despawn_time).timeout
		queue_free()
