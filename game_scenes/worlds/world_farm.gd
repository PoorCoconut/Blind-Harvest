extends Node2D

@onready var ambience_world: AudioStreamPlayer = $AmbienceWorld

func _ready() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(ambience_world, "volume_db", 0, 5)


func _on_random_scare_ambience_timer_timeout() -> void:
	if randi_range(0, 100) >= 70:
		var amb_indx = randi_range(1,3)
		if amb_indx == 1:
			SoundBank.play_sfx("amb_horror")
		elif amb_indx == 2:
			SoundBank.play_sfx("amb_horror2")
		elif amb_indx == 3:
			SoundBank.play_sfx("amb_horror3")
