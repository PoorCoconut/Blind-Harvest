extends Node2D

@onready var ambience_world: AudioStreamPlayer = $AmbienceWorld
@onready var day_night_modulate: CanvasModulate = $DayNightModulate
@onready var house_shadow: Sprite2D = $HouseShadow
@onready var environment_shadow: Node2D = $EnvironmentShadow

@export var night_color : Color
@export var midnight_color : Color
@export var day_color : Color
@export_range(0.0, 1.0) var midnight_peak : float = 0.8

var night_day_cycle : float = (3) * 60 #This is by minutes
var current_time : float = 0.0 #This counts from 0.0 to night_day_cycle
var _reached_day := false
var halfway : bool = false


func _ready() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(ambience_world, "volume_db", 0, 5)


func _process(delta: float) -> void:
	if current_time < night_day_cycle:
		current_time += delta
		update_modulate()
	if current_time <= night_day_cycle/2 + 1 and current_time >= night_day_cycle/2 - 1 and not halfway:
		print("halfway!")
		halfway = true
		SoundBank.play_sfx("halfway")


func update_modulate() -> void:
	var progress: float = current_time / night_day_cycle   # 0.0 to 1.0
	
	var color: Color
	if progress <= midnight_peak:
		# night -> midnight, over the first `midnight_peak` of the cycle
		var t: float = progress / midnight_peak
		color = night_color.lerp(midnight_color, t)
	else:
		# midnight -> day, over the remaining part of the cycle
		var t: float = (progress - midnight_peak) / (1.0 - midnight_peak)
		color = midnight_color.lerp(day_color, t)
	
	day_night_modulate.color = color
	
	if progress >= 1.0 and not _reached_day:
		_reached_day = true
		print("Day has arrived.")   # hook scene changes / spawns here later


func _on_random_scare_ambience_timer_timeout() -> void:
	if randi_range(0, 100) >= 70:
		var amb_indx = randi_range(1,3)
		if amb_indx == 1:
			SoundBank.play_sfx("amb_horror")
		elif amb_indx == 2:
			SoundBank.play_sfx("amb_horror2")
		elif amb_indx == 3:
			SoundBank.play_sfx("amb_horror3")


func _on_house_shadow_area_body_entered(body: Node2D) -> void:
	if body is Player:
		GameManager.player_safe = true
		var shadow_tween : Tween = get_tree().create_tween()
		shadow_tween.tween_property(house_shadow, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
		var env_tween : Tween = get_tree().create_tween()
		env_tween.tween_property(environment_shadow, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _on_house_shadow_area_body_exited(body: Node2D) -> void:
	if body is Player:
		GameManager.player_safe = false
		var shadow_tween : Tween = get_tree().create_tween()
		shadow_tween.tween_property(house_shadow, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		var env_tween : Tween = get_tree().create_tween()
		env_tween.tween_property(environment_shadow, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
