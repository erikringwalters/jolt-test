extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0) var camera_mouse_sensitivity := 0.25
@export_range(0.0, 1.0) var camera_stick_sensitivity := 0.5
@export_range(1.0, 10.0) var camera_stick_mult := 10.0

var camera_input_direction := Vector2.ZERO

@onready var parent = get_parent()

@onready var camera:Camera3D = %Camera
@onready var camera_pivot:Node3D = %CameraPivot

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

func _physics_process(_delta: float) -> void:
	# Camera Movement
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
