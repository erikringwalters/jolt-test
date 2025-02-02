extends Node3D

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 50.0
@export var rotation_speed := 12.0
@export var jump_speed := 5.0
@export var jump_cooldown_time := 0.1
@export var slow_movement_threshold := 0.001

@export_group("Camera")

enum States { IDLE, RUNNING, SLIDING, JUMPING, FALLING }

var state: States = States.IDLE
var last_movement_direction := Vector3.BACK
var idle_color:Color

@onready var parent = get_parent()

@onready var collision:CollisionShape3D = %Collision

@onready var camera:Camera3D = %Camera
@onready var ground_detector:Area3D = %GroundDetector
@onready var ground_detector_mesh:MeshInstance3D = %GroundDetectorMesh
@onready var jump_timer:Timer = %JumpTimer

func _physics_process(delta: float) -> void:
	# RigidBody Movement
	var raw_input := Input.get_vector(
		"move_left", 
		"move_right", 
		"move_up", 
		"move_down"
	)

	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	if state in [States.IDLE, States.RUNNING, States.SLIDING]:
		# Movement
		var vel = parent.linear_velocity.move_toward(move_direction * move_speed, acceleration * delta)
		parent.linear_velocity.x = clamp(vel.x, -move_speed, move_speed)
		parent.linear_velocity.z = clamp(vel.z, -move_speed, move_speed)
	
		# Rotation
		if move_direction.length() > slow_movement_threshold:
			last_movement_direction = move_direction
		var target_angle := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
		collision.global_rotation.y = target_angle

	
	if (
			Input.is_action_just_pressed("jump")
			&& state in [States.IDLE, States.RUNNING, States.SLIDING] 
			&& jump_timer.is_stopped()
		):
		parent.linear_velocity.y = jump_speed
		jump_timer.start()

	set_state(move_direction)
	change_state_indicator_color()

func set_state(move_direction:Vector3) -> void:
	if is_grounded():
		if is_horizontal_near_zero(move_direction, slow_movement_threshold):
			state = States.IDLE if (
				is_horizontal_near_zero(parent.linear_velocity, slow_movement_threshold)
				) else States.SLIDING
		else: 
			state = States.RUNNING
	else:
		state = States.JUMPING if parent.linear_velocity.y > 0.0 else States.FALLING

func change_state_indicator_color() -> void:
	var color:Color = idle_color
	match state:
		States.IDLE: color = Color.LIGHT_GOLDENROD
		States.RUNNING: color = Color.LIGHT_GREEN
		States.SLIDING: color = Color.LAVENDER
		States.JUMPING: color = Color.LIGHT_BLUE
		States.FALLING: color = Color.LIGHT_PINK
	ground_detector_mesh.mesh.material.albedo_color = color

func is_grounded() -> bool:
	return !ground_detector.get_overlapping_bodies().is_empty()

func is_near_zero(value:float, threshold:float) -> bool:
	return value > -threshold && value < threshold

func is_horizontal_near_zero(value:Vector3, threshold:float):
	return is_near_zero(value.x, threshold) and is_near_zero(value.z, threshold)
