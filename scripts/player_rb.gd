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

enum States {IDLE, RUNNING, SLIDING, JUMPING, FALLING}

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var state: States = States.IDLE
var _idle_color:Color

@onready var _camera_pivot:Node3D = %CameraPivot
@onready var _camera:Camera3D = %Camera
@onready var _collision:CollisionShape3D = %Collision
@onready var _ground_detector:Area3D = %GroundDetector
@onready var _ground_detector_mesh:MeshInstance3D = %GroundDetectorMesh
@onready var _jump_timer:Timer = %JumpTimer

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
		_camera_input_direction = event.screen_relative * camera_mouse_sensitivity
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
	
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * move_direction.length()
	
	_set_state(move_direction)
	_change_state_indicator_color()
	
	if state in [States.IDLE, States.RUNNING, States.SLIDING]:
		# Movement
		var vel = linear_velocity.move_toward(move_direction * move_speed, acceleration * delta)
		linear_velocity.x = clamp(vel.x, -move_speed, move_speed)
		linear_velocity.z = clamp(vel.z, -move_speed, move_speed)
		
		# Rotation
		if move_direction.length() > slow_movement_threshold:
			_last_movement_direction = move_direction
		var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
		_collision.global_rotation.y = target_angle
	
	if (
			Input.is_action_just_pressed("jump")
			&& state in [States.IDLE, States.RUNNING, States.SLIDING] 
			&& _jump_timer.is_stopped()
		):
		linear_velocity.y = jump_speed
		_jump_timer.start()

func handle_camera_movement() -> void:
	var camera_stick_input := Input.get_vector(
		"camera_left",
		"camera_right",
		"camera_up",
		"camera_down"
	)
	var camera_stick_rotation = (camera_stick_input * camera_stick_mult * camera_stick_sensitivity)
	_camera_pivot.rotation.x -= (_camera_input_direction.y + camera_stick_rotation.y) * get_physics_process_delta_time()
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 2.5, PI / 4.0)
	_camera_pivot.rotation.y -= (_camera_input_direction.x + camera_stick_rotation.x) * get_physics_process_delta_time()
	_camera_input_direction = Vector2.ZERO

func _is_grounded() -> bool:
	return !_ground_detector.get_overlapping_bodies().is_empty() 

func _set_state(move_direction:Vector3) -> void:
	if _is_grounded():
		if is_horizontal_near_zero(move_direction, slow_movement_threshold):
			state = States.IDLE if (
				is_horizontal_near_zero(linear_velocity, slow_movement_threshold)
				) else States.SLIDING
		else: 
			state = States.RUNNING
	else:
		state = States.JUMPING if linear_velocity.y > 0.0 else States.FALLING


func _change_state_indicator_color() -> void:
	var color:Color = _idle_color
	match state:
		States.IDLE: color = Color.LIGHT_GOLDENROD
		States.RUNNING: color = Color.LIGHT_GREEN
		States.SLIDING: color = Color.LAVENDER
		States.JUMPING: color = Color.LIGHT_BLUE
		States.FALLING: color = Color.LIGHT_PINK
	_ground_detector_mesh.mesh.material.albedo_color = color

func is_near_zero(value:float, threshold:float) -> bool:
	return value > -threshold && value < threshold

func is_horizontal_near_zero(value:Vector3, threshold:float):
	return is_near_zero(value.x, threshold) and is_near_zero(value.z, threshold)
