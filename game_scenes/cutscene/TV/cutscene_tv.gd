extends Node2D

@export var news_atlas : Texture2D
@export var cell_size : Vector2i = Vector2i(64,64)
@export_file("*.tscn") var shop_path : String
enum TV_State { IDLE, PLAYING, WAITING }

const CHARS_PER_SECOND : float = 40.0
const IMAGE_FADE_TIME : float = 0.5

@onready var orchestrator: AnimationPlayer = $Orchestrator
@onready var label_top: RichTextLabel = $Control/MarginContainer/VBoxContainer/LabelTop
@onready var news_image: TextureRect = $Control/MarginContainer/VBoxContainer/NewsImage
@onready var label_bottom: RichTextLabel = $Control/MarginContainer/VBoxContainer/LabelBottom
@onready var next_arrow: Sprite2D = $Control/MarginContainer/VBoxContainer/NextArrow

var current_day : int = 3
var state : TV_State = TV_State.IDLE
var skipping : bool = false
var tween : Tween

signal advance_pressed

#Day Dialogue
var dialogue : Dictionary = {
	0: [ # Day 0, tutorial day
		{
			"top": "Good Day to all!",
			"image" : Vector2i(0,0),
			"bottom": "This report has been brought to you by the Oracle Report Association.\nA little farming guide for all the farmers out there.",
		},
		{
			"top": "Growing crops is incredibly easy!",
			"image": Vector2i(1, 0),
			"bottom": "You just need water, patience and love!",
		},
		{
			"top": "When watering crops, pay attention to any meter of your water cans.",
			"image": Vector2i(2, 0),
			"bottom": "Crops need its soil constantly wet to grow.",
		},
		{
			"top": "This report has also been sponsored!",
			"image": Vector2i(3, 0),
			"bottom" : "Drop by to the Agora Mart [TM] to buy goodies and upgrades!\tThey have items every farmer needs!",
		},
		{
			"top" : "In other news,\nVoltek Corporation services as well as Seaqua waterline have recently raised their service payment.",
			"image": Vector2i(4, 0),
			"bottom": "This means farmers may have to pay more from their pockets to ensure their services remain stable",
		},
		{
			"top": "Forwarned is forearmed.\nThis concludes the report for today, have a great day.",
			"image": Vector2i(0, 0),
		}
	],
	1: [ #Day 1 , Trespassers
		{
			"top" : "Good Day to all!\nToday's news report will tackle on an unfortunate statistic seen in the local neighborhood.",
		},
		{
			"top" : "Lately, there has been a rise of criminal activity.\nA trespasser with a music box has been spotted roaming through the town.",
			"image" : Vector2i(0,1),
			"bottom" : "For your safety, lock all your doors and\nDO NOT go outside.",
		},
		{
			"bottom" : "Reports have said that it attacks anyone when its music box finishes playing twice.\nAs long as you are inside your house by then,\nyou. are. safe."
			
		},
		{
			"top" : "If you find any suspicious activity in your area, DO NOT ENGAGE.\n\nYour LIFE will be in GREAT DANGER if you do!",
			"image" : Vector2i(1,1),
			
		},
		{
			"top":"When dealing with this stranger, it is advised not to approach them. Listen vigilantly and rush towards your house.",
		},
		{
			"top" : "Forewarned is forearmed.\nStay safe and have a great evening.",
			"image" : Vector2i(0,0),
			"bottom" : "[This report has been brought to you by the Oracle Report Association]"
		}
	],
	2:[
		{
			"top" : "The Oracle Report Association greets you all!",
			"image" : Vector2i(0,0),
			"bottom":"Today's news report will tackle on the recent rabies pandemic happening in the local area."
		},
		{
			"image" : Vector2i(0,2),
			"bottom": "Multiple dogs have been found aimlessly wandering the streets.\nDO NOT APPROACH THEM.\nDO NOT FEED THEM.\nDO NOT ENGAGE WITH THEM.",
		},
		{
			"top" : "It is most likely a dog infected with the Rabies Virus.",
			"image" : Vector2i(1,2),
			"bottom" : "Dealing with them is 'easy'!",
		},
		{
			"top":"You may hear barking in the distance when it is about to enter your area.",
			"bottom":"When it IS in your area. You may hear footsteps and growling. Use this information wisely to have a rough location where the dog is."
		},
		{
			"top":"These dogs are notorious and stubborn and may or may not leave the area.",
			"image" : Vector2i(2,1),
			"bottom":"Staying inside your house makes you safe from attacks but it won't do anything.",
		},
		{
			"top":"It's unpredictable wandering may be dangerous especially at night where visiblity is low.",
			"bottom":"Be advised. If you are near it, the dog WILL attack.",
		},
		{
			"top":"Dealing with dog attacks:",
			"bottom":"There are multiple ways of dealing with dog attacks but to put it simply...\nRUN AWAY!\nIt may give up chasing you and go back to aimlessly wander around."
		},
		{
			"top":"In unrelated news,\nthere has been reports of a massive storm incoming tomorrow night.",
			"bottom":"The Voltek Corporation has issued a notice of a complete power grid shutoff tomorrow night. Be Prepared!"
		},
		{
			"top" : "Forewarned is forearmed.\nHave a safe night and don't let the doggies bite!",
			"image" : Vector2i(0,0),
			"bottom" : "[This report has been brought to you by the Oracle Report Association]"
		}
	],
	3:[
		{
			"top":"A cloudy day to all!",
			"image" : Vector2i(0,0),
			"bottom":"This is the Oracle Report Association here to give your daily report."
		},
		{
			"top":"Heavy rain has now already been reported happening in the local area.",
			"bottom":"This rain is expected to worsen tonight. Be Prepared!"
		},
		{
			"top":"The Voltek Corporation has begin shutting down the power grid.",
			"bottom":"Tonight will be a very dark night."
		},
		{
			"top":"Threats of the previous nights have begin rising. Dogs and the mysterious trespassers have become rampant",
			"bottom":"Your safety is heavily breached. It is advised to stay inside the house until the storm passes. Otherwise, you will need to deal with such threats in darkness."
		},
		{
			"top":"If you have generators, it may help you incredibly tonight!",
		},
		{
			"bottom":"For the farmers out there, the rain will help you tonight as it may water them for free!",
		},
		{
			"top":"Forwarned is forearmed.\nThat concludes today's report.",
			"bottom":"Stay safe and get ready for evacuation if things get worse.\n[This report has been brought to you by the Oracle Report Association]"
		}
	]
}

const PAUSES : Dictionary = { ".": 0.6, "!": 0.6, "?": 0.6, ",": 0.5, "\n": 1.0}

func _ready() -> void:
	GameManager.save_game()
	current_day = GameManager.current_day
	hide_text(label_top)
	hide_text(label_bottom)
	news_image.hide()
	next_arrow.hide()

func _on_orchestrator_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		play_day(current_day)
	elif anim_name == "outro":
		GameManager.load_next_level(shop_path)

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
