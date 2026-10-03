extends Node2D

@export var news_atlas : Texture2D
@export var cell_size : Vector2i = Vector2i(64,64)
@export_file("*.tscn") var shop_path : String
@export_file("*.tscn") var end_path : String
enum TV_State { IDLE, PLAYING, WAITING }

const CHARS_PER_SECOND : float = 40.0
const IMAGE_FADE_TIME : float = 0.5

@onready var orchestrator: AnimationPlayer = $Orchestrator
@onready var label_top: RichTextLabel = $Control/MarginContainer/VBoxContainer/LabelTop
@onready var news_image: TextureRect = $Control/MarginContainer/VBoxContainer/NewsImage
@onready var label_bottom: RichTextLabel = $Control/MarginContainer/VBoxContainer/LabelBottom
@onready var next_arrow: Sprite2D = $Control/MarginContainer/VBoxContainer/NextArrow

var current_day : int = 7
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
			"top" : "Crows may appear from time to time.",
			"image": Vector2i(4, 1),
			"bottom" : "Not dealing with them may hinder your crop development!"
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
			"top" : "Voltek services include constant light.\nA rather important service especially with how dark the nights have become!",
			"bottom" : "Seaqua's waterline is incredibly helpful as it allows for rapid water flow. Although our local government has issued free water for all, being cut of the water flow service is rather bothersome."
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
			"top":"Dealing with dog attacks:\nThere are multiple ways of dealing with dog attacks but to put it simply...\nRUN AWAY!\nIt may give up chasing you and go back to aimlessly wander around.",
			"image" : Vector2i(2,2),
		},
		{
			"top":"In unrelated news,\nthere has been reports of a massive storm incoming tomorrow night.",
			"image" : Vector2i(3,2),
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
			"image" : Vector2i(0,3),
			"bottom":"This rain is expected to worsen tonight. Be Prepared!"
		},
		{
			"top":"The Voltek Corporation has begun shutting down the power grid.",
			"image" : Vector2i(1,3),
			"bottom":"Tonight will be a very dark night."
		},
		{
			"top":"Threats of the previous nights have begun rising. Dogs and the mysterious trespassers have become rampant",
			"bottom":"Your safety is heavily breached. It is advised to stay inside the house until the storm passes. Otherwise, you will need to deal with such threats in darkness."
		},
		{
			"top":"If you have generators, it may help you incredibly when Voltek services are offline, especially for tonight!",
			"image" : Vector2i(2,3),
		},
		{
			"bottom":"For the farmers out there, the rain will help you tonight as it may water them for free!",
		},
		{
			"top":"Forwarned is forearmed.\nThat concludes today's report.",
			"image" : Vector2i(0,0),
			"bottom":"Stay safe and get ready for evacuation if things get worse.\n[This report has been brought to you by the Oracle Report Association]"
		}
	],
	4:[
		{
			"top":"What a pleasant morning to all!\nThis is the Oracle News Association here to give you your daily report.",
			"image":Vector2i(0,0),
		},
		{
			"top" : "The Storm seems to have calmed down overnight.",
			"image":Vector2i(0,4),
			"bottom":"There is a possibility another storm will happen soon, but right now, it is time to stop and smell the freshly wet ground."
		},
		{
			"image":Vector2i(1,4),
			"bottom":"Reports have shown a lot of insects and crows have been appearing in the local area."
		},
		{
			"top":"Moths are attracted to light.\nAlthough they pose no threat, they are rather a nuisance when left alone and they may partially block your view.",
			"image":Vector2i(2,4),
			"bottom":"If you have any light emitting devices, do TURN THEM OFF."
		},
		{
			"top":"A quick bath in darkness will render them to fly off somewhere else!",
			
		},
		{
			"top" : "A word for our sponsors,",
			"image":Vector2i(3,4),
			"bottom" : "Voltek Corporation has also returned their services! Expect light tonight if you have no unprocessed payments.",
		},
		{
			"top":"In other news, packs of rabid dogs seem to have started disappearing. It is expected that you may come across them at a chance of low to none.",
			"bottom":"Police have also started investigating on these 'Trespasser reports.'"
		},
		{
			"top":"It would seem that there may be a sort of organization behind them but it is quite speculative.",
			"image":Vector2i(0,1),
			"bottom":"It is still recommended not to engage in potentially suspicious activity",
		},
		{
			"top":"Forwarned is forearmed.\nThat concludes today's report.",
			"image" : Vector2i(0,0),
			"bottom":"Crows, moths and suspicious people, what a combo.\n[This report has been brought to you by the Oracle Report Association]"
		}
	],
	5:[
		{
			"top":"Greetings to all!",
			"image":Vector2i(0,0),
			"bottom":"This is the Oracle News Association here to bring the report for today."
		},
		{
			"top":"It seems that it is moth season!",
			"image":Vector2i(0,5),
			"bottom":"A surge of moths have suddenly appeared. This may be due to the recent storm!"
		},
		{
			"top":"Due to this influx, crows have began rapidly appearing",
			"image":Vector2i(1,5),
			"bottom":"Due to the crows, rabid dogs are back and they seem to be hunting the crows. Watch out!"
		},
		{
			"top":"The police have began cracking down the mysterious organization associated with trespassers.",
			"bottom":"As such, trespasser encounters have started dwindling."
		},
		{
			"top":"In other news, meteorologists have reported that another storm is to be expected tomorrow.",
			"image":Vector2i(0,4),
			"bottom":"They mention how odd another storm developing is and that the storm tomorrow will be very powerful"
		},
		{
			"top":"Voltek has began handing out notices for their absence of service tomorrow."
		},
		{
			"top":"Forwarned is forearmed.\nThat concludes today's report.",
			"image" : Vector2i(0,0),
			"bottom":"The Cycle of Life, trapped in a delicate chain.\n[This report has been brought to you by the Oracle Report Association]"
		}
	],
	6:[
		{
			"event": "hijack_start",
			"top":"██████ ██████ ███████████",
			"image":Vector2i(0,6),
			"bottom":"WE ████ HIJACKED ███ STATION"
		},
		{
			"top":"WE ████ ██ SEND █ MESSAGE ██ ███ WORLD",
			"image":Vector2i(1,6),
#REDEMPTION IS SOON. LISTEN TO THE MUSIC OF HEAVEN. THE BOX OF PANDORA, THE GATES OF THE AETHERS. HEAVEN. HEAVEN. HEAVEN. SEE US. LOOK AT US. PRAY TO BE INCLUDED TO HEAVEN! HEAVEN! HEAVEN!
#HAVE MERCY ON US! HELP US! DO NOT FORSAKE US! HEAVEN! HEAVEN! HEAVEN! THE TRUTH, THE LIGHT, THE LIFE ITSELF, BELONGING, ENTRANCING, CONFUSING. WORLD, HEAR OUR MESSAGE. HEAR US!
		},
		{
			"top" : "██████████ ██ █████ ██████ ██ ███ █████ ██ ███████ ███ ███ ██"
		},
		{
			"top" : "████████ ███ █████ ██ ███ ████████ ███████ ███████ ███████ ███ ███ ████ ██"
		},
		{
			"top" : "███ ████ ██ ██ ████████ ██ ███████ ███████ ███████"
		},
		{
			"top" : "████ █████ ██ ███ ████ ███ ██ ███ ███████ ███ ███████ ███████ ███████ ███"
		},
		{
			"top" : "██████ ███ ██████ ███ ████ ███████ ██████████ ███████████ ██████████"
		},
		{
			"top" : "██████ ████ ███ ████████ ████ ███"
		},
		{
			"top":"LOOK; PASSAGE!",
			"image":Vector2i(2,6),
			"bottom":"follow."
		},
		{
			"top":"LOOK; SHEEP!",
			"image":Vector2i(3,6),
			"bottom":"become meat."
		},
		{
			"top":"LOOK; FLESH!",
			"image":Vector2i(4,6),
			"bottom":"your true self."
		},
		{
			"event": "tv_off",
			"top":"Please Stand By..."
		},
		{
			"event": "restore_feed",
			"top":"Any message displayed today was not from the Oracle Report Association",
			"bottom":"We apologize for any distressing messages, images or audio that might have shown or played."
		},
		{
			"top":"Do not go outside.",
			"bottom":"Dangerous people are out there."
		},
		{
			"top":"Forwarned is forearmed."
		}
	],
	7:[
		{
			"top":"Greetings to all!",
			"image":Vector2i(0,0),
			"bottom":"This is the Oracle Report Association",
		},
		{
			"top":"We apologize for the technical issues yesterday.",
			"image":Vector2i(0,7),
			"bottom":"We have dealt with the matter at hand. To be transparent, the ORA had been hijacked by a criminal group."
		},
		{
			"top":"You may have associated them with the trespassers that ocassionaly appear.",
			"image":Vector2i(0,1),
		},
		{
			"top":"The police have cracked down this group and all have been sent to a mental prison camp.",
			"bottom":"Unfortunately, multiple deaths and injuries were recorded last night."
		},
		{
			"top":"A total of 3 deaths and 14 injured have been reported.",
			"image":Vector2i(1,7),
			"bottom":"May their souls rest in peace. May the injured have a speedy recovery."
		},
		{
			"top":"The recent rabies epidemic in dogs has also now been dealt with."
		},
		{
			"top":"Today may be a gloomy day, but the threats of the local area has now ceased.",
			"bottom":"This week has truly been the disaster for all, but we prevailed!"
		},
		{
			"top":"Forwarned is forearmed.\nThat concludes today's report.",
			"image" : Vector2i(0,0),
			"bottom":"[This report has been brought to you by the Oracle Report Association]"
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
		if GameManager.current_day != 7:
			GameManager.load_next_level(shop_path)
		else:
			GameManager.load_next_level(end_path)

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

	# 1. Fire the event first so the background/music changes before the text types out
	if cycle.has("event"):
		await _handle_event(cycle["event"])

	if cycle.has("top"):
		await show_text(label_top, cycle["top"])
	if cycle.has("image"):
		await show_image(cycle["image"])
	if cycle.has("bottom"):
		await show_text(label_bottom, cycle["bottom"])
		
	# Cycle Finished
	next_arrow.show()
	state = TV_State.WAITING
	await advance_pressed
	
	# Get ready for the next cycle
	state = TV_State.IDLE
	next_arrow.hide()
	await reset()

func _handle_event(event_name: String) -> void:
	match event_name:
		"hijack_start":
			# Hide the background and stop the standard news music
			SoundBank.play_sfx("news_horror")
			$Control/NewsBG.hide()
			$TVNoSig.play()
			$Control/NoSigBG.show()
			await get_tree().create_timer(0.5).timeout
			$TVNoSig.stop()
			$Control/NoSigBG.hide()
			$MusNews.stop()
			$Breathing.play()
			
			# Optional: Play a custom creepy track if you have one
			# SoundBank.play_sfx("creepy_drone")
			
		"tv_off":
			# Example of a scripted sequence without needing an AnimationPlayer track
			hide_text(label_top)
			hide_text(label_bottom)
			news_image.hide()
			$Control/NewsBG.hide()
			$Control/NoSigBG.show()
			
			$Breathing.stop()
			$TVNoSig.play()
			
			# Wait a moment in silence before continuing to the "Please Stand By" text
			
		"restore_feed":
			$Control/NoSigBG.hide()
			await get_tree().create_timer(0.2).timeout
			$Control/NoSigBG.show()
			await get_tree().create_timer(0.4).timeout
			$Control/NoSigBG.hide()
			$TVNoSig.stop()
			
			$Control/NewsBG.show()
			$MusNews.play()
			$MusNews.pitch_scale = 1.0 # Restore pitch from the intro track
			$AudStatic.pitch_scale = 1.0
			$AudStatic.play()


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
