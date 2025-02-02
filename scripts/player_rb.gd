extends RigidBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var camera_mouse_sensitivity := 0.25
@export_range(0.0, 1.0) var camera_stick_sensitivity := 0.5
@export_range(1.0, 10.0) var camera_stick_mult := 10.0

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 50.0
@export var rotation_speed := 12.0
@export var jump_speed := 5.0
@export var jump_cooldown_time := 0.1
@export var slow_movement_threshold := 0.001

enum States { IDLE, RUNNING, SLIDING, JUMPING, FALLING }

var camera_input_direction := Vector2.ZERO
var last_movement_direction := Vector3.BACK
var state: States = States.IDLE
var idle_color:Color

@onready var camera_pivot:Node3D = %CameraPivot
@onready var camera:Camera3D = %Camera
@onready var collision:CollisionShape3D = %Collision
@onready var ground_detector:Area3D = %GroundDetector
@onready var ground_detector_mesh:MeshInstance3D = %GroundDetectorMesh
@onready var jump_timer:Timer = %JumpTimer

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		camera_input_direction = event.screen_relative * camera_mouse_sensitivity
	else: pass

func _physics_process(delta: float) -> void:
	# Camera Movement
	handle_camera_movement()
	
	# RigidBody Movement
	var raw_input := Input.get_vector(
		"move_left", 
		"move_right", 
		"move_up", 
		"move_down"
	)
	
	# TODO: Check movement speed when camera is high up
	
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * move_direction.length()
	
	set_state(move_direction)
	change_state_indicator_color()
	
	if state in [States.IDLE, States.RUNNING, States.SLIDING]:
		# Movement
		var vel = linear_velocity.move_toward(move_direction * move_speed, acceleration * delta)
		linear_velocity.x = clamp(vel.x, -move_speed, move_speed)
		linear_velocity.z = clamp(vel.z, -move_speed, move_speed)
		
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
		linear_velocity.y = jump_speed
		jump_timer.start()

func handle_camera_movement() -> void:
	var camera_stick_input := Input.get_vector(
		"camera_left",
		"camera_right",
		"camera_up",
		"camera_down"
	)
	var camera_stick_rotation = (camera_stick_input * camera_stick_mult * camera_stick_sensitivity)
	camera_pivot.rotation.x -= (camera_input_direction.y + camera_stick_rotation.y) * get_physics_process_delta_time()
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2.5, PI / 4.0)
	camera_pivot.rotation.y -= (camera_input_direction.x + camera_stick_rotation.x) * get_physics_process_delta_time()
	camera_input_direction = Vector2.ZERO

func is_grounded() -> bool:
	return !ground_detector.get_overlapping_bodies().is_empty() 

func set_state(move_direction:Vector3) -> void:
	if is_grounded():
		if is_horizontal_near_zero(move_direction, slow_movement_threshold):
			state = States.IDLE if (
				is_horizontal_near_zero(linear_velocity, slow_movement_threshold)
				) else States.SLIDING
		else: 
			state = States.RUNNING
	else:
		state = States.JUMPING if linear_velocity.y > 0.0 else States.FALLING


func change_state_indicator_color() -> void:
	var color:Color = idle_color
	match state:
		States.IDLE: color = Color.LIGHT_GOLDENROD
		States.RUNNING: color = Color.LIGHT_GREEN
		States.SLIDING: color = Color.LAVENDER
		States.JUMPING: color = Color.LIGHT_BLUE
		States.FALLING: color = Color.LIGHT_PINK
	ground_detector_mesh.mesh.material.albedo_color = color

func is_near_zero(value:float, threshold:float) -> bool:
	return value > -threshold && value < threshold

func is_horizontal_near_zero(value:Vector3, threshold:float):
	return is_near_zero(value.x, threshold) and is_near_zero(value.z, threshold)
