extends Node3D

@export_group("Camera")
@export_range(0.0, 10.0) var camera_mouse_sensitivity: float = 0.25
@export_range(0.0, 10.0) var camera_stick_sensitivity: float = 0.5

@export_range(1.0, 10.0) var mouse_mult: float = 0.01
@export_range(1.0, 10.0) var camera_stick_mult: float = 10.0

var camera_mouse_direction := Vector2.ZERO
var camera_stick_rotation := Vector2.ZERO
var camera_stick_input := Vector2.ZERO
var is_camera_motion: bool = false

@onready var parent: RigidBody3D = get_parent()
@onready var camera: Camera3D = %Camera
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera_pointer: Node3D = %CameraPointerMesh

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	is_camera_motion = (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		camera_mouse_direction = event.screen_relative * camera_mouse_sensitivity * mouse_mult

func _process(delta: float) -> void:
	# Camera Movement
	camera_stick_input = Input.get_vector(
		"camera_left",
		"camera_right",
		"camera_up",
		"camera_down"
	)
	camera_stick_rotation = (camera_stick_input * camera_stick_mult * camera_stick_sensitivity)
	camera_pivot.rotation.x -= camera_mouse_direction.y + (camera_stick_rotation.y * delta)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2.5, PI / 4.0)
	camera_pivot.rotation.y -= camera_mouse_direction.x + (camera_stick_rotation.x * delta)
	camera_mouse_direction = Vector2.ZERO
	camera_pointer.global_rotation.y = camera.global_rotation.y


func _physics_process(delta: float) -> void:
	pass
