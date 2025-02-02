extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.5


@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0

var camera_input_direction := Vector2.ZERO
var last_movement_direction := Vector3.BACK

@onready var camera_pivot:Node3D = %CameraPivot
@onready var camera:Camera3D = %Camera
@onready var collision:CollisionShape3D = %Collision

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
		camera_input_direction = event.screen_relative * mouse_sensitivity
	else: pass

func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x -= camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 6.0, PI / 3.0)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	
	camera_input_direction = Vector2.ZERO

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
	
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	move_and_slide()
	
	if move_direction.length() > 0.2:
		last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
	collision.global_rotation.y = target_angle
