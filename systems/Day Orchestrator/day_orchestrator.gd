extends Node
class_name DayOrchestrator

signal halfway_reached
signal day_ended
signal lightning_struck

@export_category("Day Configuration")
@export var day_database: Array[DayData]

@export_category("Lighting Colors")
@export var night_color: Color
@export var midnight_color: Color
@export var day_color: Color
@export_range(0.0, 1.0) var midnight_peak: float = 0.8

@export_category("Scene References")
@export var day_night_modulate: CanvasModulate
@export var ambience_world: AudioStreamPlayer
@export var rain_particles: CPUParticles2D
@export var lamp_lights: Node2D
@export var rain_audio: AudioStreamPlayer

var current_day_data: DayData
var night_day_cycle: float = 5.0 * 60.0 # 3 minutes
var current_time: float = 0.0
var flash_intensity: float = 0.0
var next_lightning_strike: float = 0.0

var _halfway_triggered: bool = false
var _day_ended_triggered: bool = false

func _ready() -> void:
	if GameManager.current_day < day_database.size():
		current_day_data = day_database[GameManager.current_day]
		apply_day_configuration()
	else:
		print_debug("Warning: No DayData found for day ", GameManager.current_day)

func apply_day_configuration() -> void:
	current_time = current_day_data.start_time
	
	if current_time >= (night_day_cycle / 2.0):
		_halfway_triggered = true
		
	# Assign grid rules based on Voltek Debt OR the DayData configuration
	var generator = get_tree().get_first_node_in_group("generator")
	if generator:
		generator.requires_cranking = (GameManager.voltek_debt > 0) or current_day_data.grid_relies_on_generator
	
	if current_day_data.tutorial_mode:
		ambience_world.stop()
	else:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(ambience_world, "volume_db", 0, 5)

	if current_day_data.is_raining:
		rain_particles.emitting = true
		if rain_audio:
			rain_audio.play()
		next_lightning_strike = randf_range(5.0, 15.0)
		
	else:
		rain_particles.emitting = false
		if rain_audio:
			rain_audio.stop()

func _process(delta: float) -> void:
	if _day_ended_triggered:
		return
	if current_day_data.time_progresses:
		current_time += delta
		
	update_lighting()
	check_milestones()
	# The new lightning logic
	if current_day_data.is_raining:
		next_lightning_strike -= delta
		if next_lightning_strike <= 0.0:
			trigger_lightning()
			# Pick a random time for the NEXT strike (e.g., between 15 and 35 seconds)
			next_lightning_strike = randf_range(15.0, 35.0)

func update_lighting() -> void:
	var progress: float = current_time / night_day_cycle
	var base_color: Color
	
	if progress <= midnight_peak:
		var t: float = progress / midnight_peak
		base_color = night_color.lerp(midnight_color, t)
	else:
		var t: float = (progress - midnight_peak) / (1.0 - midnight_peak)
		base_color = midnight_color.lerp(day_color, t)
	
	# Blend the standard time color with pure white based on lightning intensity
	day_night_modulate.color = base_color.lerp(Color.WHITE, flash_intensity)

func check_milestones() -> void:
	if current_time >= (night_day_cycle / 2.0) and not _halfway_triggered:
		_halfway_triggered = true
		SoundBank.play_sfx("halfway")
		halfway_reached.emit()
		
	# Only auto-end if this day is configured to end on the timer
	if current_day_data.ends_on_timer and current_time >= night_day_cycle:
		end_day()

func trigger_lightning() -> void:
	var flash_tween = get_tree().create_tween()
	flash_tween.tween_property(self, "flash_intensity", 0.8, 0.05)
	flash_tween.tween_property(self, "flash_intensity", 0.0, 0.4)
	
	lightning_struck.emit()
	
	var thunder_delay = randf_range(0.5, 2.5)
	await get_tree().create_timer(thunder_delay).timeout
	
	if is_inside_tree() and not _day_ended_triggered:
		var thunder_var = randi_range(1, 4)
		if thunder_var == 1:
			SoundBank.play_sfx("thunder1")
		elif thunder_var == 2:
			SoundBank.play_sfx("thunder2")
		elif thunder_var == 3:
			SoundBank.play_sfx("thunder3")
		elif thunder_var == 4:
			SoundBank.play_sfx("thunder4")
		GameManager.do_camera_shake(1, 1)

func _on_random_scare_ambience_timer_timeout() -> void:
	if current_day_data == null or not current_day_data.random_scares_enabled:
		return
	
	if randi_range(0, 100) >= 70:
		var amb_indx = randi_range(1, 5)
		if amb_indx == 1:
			SoundBank.play_sfx("amb_horror")
		elif amb_indx == 2:
			SoundBank.play_sfx("amb_horror2")
		elif amb_indx == 3:
			SoundBank.play_sfx("amb_horror3")
		elif amb_indx == 4:
			SoundBank.play_sfx("amb_elk")
		elif amb_indx == 5:
			SoundBank.play_sfx("amb_elk2")

func end_day() -> void:
	if _day_ended_triggered:
		return
		
	_day_ended_triggered = true
	SoundBank.play_sfx("rooster")
	SoundBank.play_sfx("harp")
	GameManager.current_day += 1
	day_ended.emit()
