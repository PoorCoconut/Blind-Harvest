extends Node2D

@export var news_atlas : Texture2D
@export var cell_size : Vector2i = Vector2i(64,64)
enum TV_State { IDLE, PLAYING, WAITING }

const CHARS_PER_SECOND : float = 40.0
const IMAGE_FADE_TIME : float = 0.5

@onready var orchestrator: AnimationPlayer = $Orchestrator
@onready var label_top: RichTextLabel = $Control/MarginContainer/VBoxContainer/LabelTop
@onready var news_image: TextureRect = $Control/MarginContainer/VBoxContainer/NewsImage
@onready var label_bottom: RichTextLabel = $Control/MarginContainer/VBoxContainer/LabelBottom
@onready var next_arrow: Sprite2D = $Control/MarginContainer/VBoxContainer/NextArrow

var current_day : int = 1
var state : TV_State = TV_State.IDLE
var skipping : bool = false
var tween : Tween

signal advance_pressed

#Day Dialogue
var dialogue : Dictionary = {
	0: [ # Day 0 (test day)
		{
			"top": "This is the Day 0 text. This day is for test messages.",
			"bottom": "When this text is finished, next_arrow is now shown.",
		},
		{
			"top": "Everything is hidden once the player clicks past next_arrow.",
			"image": Vector2i(0, 0),
			"bottom": "There is now an image above this text!",
		},
		{
			"image": Vector2i(0, 0),
			"bottom": "Sometimes there won't be a top message. Just an image and a text below.",
		},
		{
			"top": "A cycle can also be just a top message.",
		},
		{
			"top": "That concludes the news for today! Good Luck!!!",
			"image": Vector2i(0, 0),
		}
	],
	1: [ #Day 1 , Thieves and Burglars
		{
			"top" : "Good Day to all!\nToday's news report will tackle on an unfortunate statistic seen in the local neighborhood.",
		},
		{
			"top" : "Lately, there has been a rise of criminal activity.",
			"image" : Vector2i(0,1),
			"bottom" : "For your safety, lock all your doors and\nDO NOT go outside.",
		},
		{
			"top" : "If you find any suspicious activity in your area, DO NOT ENGAGE.\n\nYour LIFE will be in GREAT DANGER if you do!",
			
		},
		{
			"top" : "You must quietly leave the area\n slowly walk to your house and DO NOT LEAVE.\nIt is advised not to be noticed as you leave or your safety is compromised.",
			"image" : Vector2i(1,1),
		},
		{
			"top" : "This concludes today's news report.\nStay safe.\nDo not approach suspicious people.\nAnd . . . Have a Great Day!",
			"image" : Vector2i(0,0),
			"bottom" : "[This report has been brought to you by the Oracle Report Association]"
		}
	]
}

const PAUSES : Dictionary = { ".": 0.6, "!": 0.6, "?": 0.6, ",": 0.5, "\n": 1.0}

func _ready() -> void:
	hide_text(label_top)
	hide_text(label_bottom)
	news_image.hide()
	next_arrow.hide()

func _on_orchestrator_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		play_day(current_day)
	elif anim_name == "outro":
		print("Cutscene Finished!")

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("action"):
		return
	match state:
		TV_State.PLAYING:
			skip_to_end_of_cycle()
		TV_State.WAITING:
			advance_pressed.emit()

func play_day(day: int) -> void:
	for cycle : Dictionary in dialogue[day]:
		await play_cycle(cycle)
	orchestrator.play("outro")

func play_cycle(cycle: Dictionary) -> void:
	state = TV_State.PLAYING
	skipping = false

	if cycle.has("top"):
		await show_text(label_top, cycle["top"])
	if cycle.has("image"):
		await show_image(cycle["image"])
	if cycle.has("bottom"):
		await show_text(label_bottom, cycle["bottom"])
		
	#Cycle Finished
	next_arrow.show()
	state = TV_State.WAITING
	await advance_pressed
	
	#Get ready for the next cycle
	state = TV_State.IDLE
	next_arrow.hide()
	await reset()


func skip_to_end_of_cycle() -> void:
	skipping = true
	if tween and tween.is_valid():
		tween.custom_step(9999.0)

func new_tween() -> Tween:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	return tween

func show_text(label: RichTextLabel, text: String) -> void:
	label.text = text
	label.visible_ratio = 0.0
	label.show()
	if skipping:
		label.visible_ratio = 1.0
		return
	await tween_text(label)

func tween_text(label: RichTextLabel) -> void:
	var text := label.get_parsed_text()
	if text.is_empty():
		return
	label.visible_characters = 0
	var t := new_tween()
	var shown : int = 0
	
	for i in text.length():
		var pause : float = PAUSES.get(text[i], 0.0)
		# only pause if punctuation is followed by a space (skips "3.5", "...", and the very end)
		if pause > 0.0 and i + 1 < text.length() and text[i + 1] == " ":
			t.tween_property(label, "visible_characters", i + 1, (i + 1 - shown) / CHARS_PER_SECOND)
			t.tween_interval(pause)
			shown = i + 1
	
	if shown < text.length():
		t.tween_property(label, "visible_characters", text.length(), (text.length() - shown) / CHARS_PER_SECOND)
	await t.finished

func hide_text(label: RichTextLabel) -> void:
	label.hide()
	label.visible_ratio = 0.0

func show_image(cell: Vector2i, time: float = IMAGE_FADE_TIME) -> void:
	news_image.texture = get_atlas_cell(cell)
	news_image.modulate.a = 0.0
	news_image.show()
	if skipping:
		news_image.modulate.a = 1.0
		return
	var t := new_tween()
	t.tween_property(news_image, "modulate:a", 1.0, time)
	await t.finished

func get_atlas_cell(cell: Vector2i) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = news_atlas
	tex.region = Rect2(cell * cell_size, cell_size)
	return tex

func reset() -> void:
	if news_image.visible:
		var t := new_tween()
		t.tween_property(news_image, "modulate:a", 0.0, 0.3)
		await t.finished
	news_image.hide()
	hide_text(label_top)
	hide_text(label_bottom)
