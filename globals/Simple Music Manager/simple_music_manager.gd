extends Node

@onready var menu: AudioStreamPlayer = $Menu
@onready var day: AudioStreamPlayer = $Day
@onready var news: AudioStreamPlayer = $News
@onready var end: AudioStreamPlayer = $End

func _ready() -> void:
	pass

func change_music(track:String):
	if track == "menu":
		#tween menu up, tween all the others down
		pass
	elif track == "day":
		pass
	elif track == "news":
		pass
	elif track == "end":
		pass
	else:
		print("NOT A VALID TRACK!")
