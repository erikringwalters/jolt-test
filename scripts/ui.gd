extends Control

@onready var fps_label:Label = %FPSLabel

func _process(delta: float) -> void:
    fps_label.text = str("FPS: ", Engine.get_frames_per_second())