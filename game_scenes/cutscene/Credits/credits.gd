extends Node2D
@export_file("*.tscn") var menu_path : String

func _ready() -> void:
	MusicManager.stop_music()

func _on_camera_anim_animation_finished(_anim_name: StringName) -> void:
	GameManager.load_next_level(menu_path)
