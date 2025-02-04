extends Node3D

@export_group("Camera")
@export_range(0.0, 10.0) var camera_mouse_sensitivity: float = 0.25
@export_range(0.0, 10.0) var camera_stick_sensitivity: float = 0.5
@export_range(1.0, 10.0) var mouse_mult: float = 0.01
@export_range(1.0, 10.0) var camera_stick_mult: float = 10.0
@export var min_spring_arm_length: float = 2.0
@export var med_spring_arm_length: float = 7.0
@export var max_spring_arm_length: float = 12.0
@export var spring_arm_length: float = med_spring_arm_length
@export var camera_follow_speed: float = 0.1
@export var zoom_speed: float = 0.05

var camera_mouse_direction := Vector2.ZERO
var camera_stick_rotation := Vector2.ZERO
var camera_stick_input := Vector2.ZERO
var is_camera_motion: bool = false

@onready var parent: RigidBody3D = get_parent()
@onready var camera: Camera3D = %Camera
@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm: SpringArm3D = %SpringArm
@onready var camera_pointer: Node3D = %CameraPointer
@onready var camera_destination: Marker3D = %CameraDestination

func _ready() -> void:
	camera.global_transform = camera_destination.global_transform

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("zoom_in"):
		spring_arm_length = clamp(spring_arm_length - 1.0, min_spring_arm_length, max_spring_arm_length)
	if event.is_action_pressed("zoom_out"):
		spring_arm_length = clamp(spring_arm_length + 1.0, min_spring_arm_length, max_spring_arm_length)
	if event.is_action_pressed("zoom_in_big"):
		spring_arm_length = handle_big_zoom_in(spring_arm_length)
	if event.is_action_pressed("zoom_out_big"):
		spring_arm_length = handle_big_zoom_out(spring_arm_length)

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
	camera_pointer.global_rotation_degrees = Vector3(-90.0, camera_pivot.global_rotation_degrees.y, 0.0)
	camera_mouse_direction = Vector2.ZERO

	# camera.global_transform = lerp(camera.global_transform, camera_destination.global_transform, camera_follow_speed)
	spring_arm.spring_length = lerp(spring_arm.spring_length, spring_arm_length, zoom_speed)
	pass

func handle_big_zoom_in(length: float) -> float:
	if length > min_spring_arm_length && length <= med_spring_arm_length:
		return min_spring_arm_length
	elif length > med_spring_arm_length && length <= max_spring_arm_length:
		return med_spring_arm_length
	else:
		return length

func handle_big_zoom_out(length: float) -> float:
	if length >= min_spring_arm_length && length < med_spring_arm_length:
		return med_spring_arm_length
	elif length >= med_spring_arm_length && length < max_spring_arm_length:
		return max_spring_arm_length
	else:
		return length
