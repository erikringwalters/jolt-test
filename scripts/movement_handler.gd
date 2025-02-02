extends Node3D

enum States {IDLE, RUNNING, SLIDING, JUMPING, FALLING}

@export_group("Movement")
@export var move_speed: float = 8.0
@export var acceleration: float = 50.0
@export var rotation_speed: float = 12.0
@export var jump_speed: float = 5.0
@export var jump_cooldown_time: float = 0.1
@export var slow_movement_threshold: float = 0.001
@export var is_air_rotation_enabled: bool = true

var raw_input := Vector2.ZERO
var state := States.IDLE
var last_movement_direction := Vector3.BACK
var forward := Vector3.ZERO
var right := Vector3.ZERO
var velocity := Vector3.ZERO
var target_angle: float = 0.0
var move_direction := Vector3.ZERO
var idle_color := Color.LIGHT_GOLDENROD
var state_color := idle_color

@onready var parent: RigidBody3D = get_parent()
@onready var collision: CollisionShape3D = %Collision
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera
@onready var camera_pointer: MeshInstance3D = %CameraPointer
@onready var ground_detector: Area3D = %GroundDetector
@onready var ground_detector_mesh: MeshInstance3D = %GroundDetectorMesh
@onready var jump_timer: Timer = %JumpTimer

func _physics_process(delta: float) -> void:
	# Movement Input
	raw_input = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	
	camera_pointer.global_rotation.y = camera_pivot.global_rotation.y
	forward = -camera_pointer.global_basis.y
	right = camera_pointer.global_basis.x
	
	move_direction = forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * raw_input.length()

	# RigidBody Movement
	if can_walk():
		# Movement
		velocity = parent.linear_velocity.move_toward(move_direction * move_speed, acceleration * delta)
		parent.linear_velocity.x = clamp(velocity.x, -move_speed, move_speed)
		parent.linear_velocity.z = clamp(velocity.z, -move_speed, move_speed)
	
	if can_walk() || is_air_rotation_enabled:
		# Rotation
		if move_direction.length() > slow_movement_threshold:
			last_movement_direction = move_direction
		target_angle = Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
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
	pass

func set_state(direction: Vector3) -> void:
	if is_grounded():
		if is_horizontal_near_zero(direction, slow_movement_threshold):
			state = States.IDLE if (
				is_horizontal_near_zero(parent.linear_velocity, slow_movement_threshold)
				) else States.SLIDING
		else:
			state = States.RUNNING
	else:
		state = States.JUMPING if parent.linear_velocity.y > 0.0 else States.FALLING

func change_state_indicator_color() -> void:
	state_color = idle_color
	match state:
		States.IDLE: state_color = idle_color
		States.RUNNING: state_color = Color.LIGHT_GREEN
		States.SLIDING: state_color = Color.LAVENDER
		States.JUMPING: state_color = Color.LIGHT_BLUE
		States.FALLING: state_color = Color.LIGHT_PINK
	ground_detector_mesh.mesh.material.albedo_color = state_color

func is_grounded() -> bool:
	return !ground_detector.get_overlapping_bodies().is_empty()

func can_walk() -> bool:
	return state in [States.IDLE, States.RUNNING, States.SLIDING]

func is_near_zero(value: float, threshold: float) -> bool:
	return value > -threshold && value < threshold

func is_horizontal_near_zero(value: Vector3, threshold: float) -> bool:
	return is_near_zero(value.x, threshold) and is_near_zero(value.z, threshold)
