extends Control

@onready var text: RichTextLabel = $Text
@export_file("*.tscn") var menu_path : String
@export_file("*.tscn") var farm_path : String
var safe : bool = false
var pressed : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.stop_music()
	text.visible_ratio = 0.0
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(text, "visible_ratio", 1.0, 5)
	await tween.finished
	safe = true

func _input(event: InputEvent) -> void:
	if safe and not pressed:
		# Ignore button releases and held-down repeating keys
		if not event.is_pressed() or event.is_echo():
			return
			
		# Only listen to physical keyboard keys and mouse clicks
		if event is InputEventKey or event is InputEventMouseButton:
			
			# Optional: Filter out mouse wheel scrolling
			if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
				return
				
			# Check if the exact key pressed was 'R'
			if event is InputEventKey and event.keycode == KEY_R:
				GameManager.load_farm_checkpoint()
				GameManager.load_next_level(farm_path)
			else:
				GameManager.load_next_level(menu_path)
