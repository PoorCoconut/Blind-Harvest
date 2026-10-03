extends Control

@onready var text: RichTextLabel = $MarginContainer/VBoxContainer/Text
@onready var back_hint: RichTextLabel = $MarginContainer/VBoxContainer/BackHint
@export_file("*.tscn") var credits_path : String
var safe : bool = false
var pressed : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.stop_music()
	text.visible_ratio = 0.0
	back_hint.visible_ratio = 0.0
	
	text.text = "[wave]Congratulations![/wave]\nYou have survived this peculiar week.\nYour final score is: P " + str(GameManager.current_money)
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(text, "visible_ratio", 1.0, 5)
	await tween.finished
	var tween2 : Tween = get_tree().create_tween()
	tween2.tween_property(back_hint, "visible_ratio", 1.0, 1)
	await tween2.finished
	safe = true

func _unhandled_input(event: InputEvent) -> void:
	if safe and not pressed:
		# Ignore button releases and held-down repeating keys
		if not event.is_pressed() or event.is_echo():
			return
			
		# Only listen to physical keyboard keys and mouse clicks
		if event is InputEventKey or event is InputEventMouseButton:
			
			# Filter out mouse wheel scrolling
			if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
				return
				
			# If it passes all checks, lock the input and proceed
			pressed = true
			GameManager.load_next_level(credits_path)
