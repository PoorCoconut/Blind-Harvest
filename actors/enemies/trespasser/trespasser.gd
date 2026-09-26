extends Node2D
class_name Trespasser

signal player_caught
signal despawned

enum EState { IDLE, ALERT_SOUND, CHASING }

@export_category("Trigger")
@export var post_alert_delay: float = 3       # sound cue -> this delay -> it moves

@export_category("Chase")
@export var chase_speed: float = 200.0
@export var pitch_tween_duration: float = 1.0

@export_category("Despawn")
@export var safe_despawn_time: float = 5.0      # continuous safe-seconds needed to vanish

@onready var detection_area: Area2D = $DetectionArea
@onready var catch_area: Area2D = $CatchArea
@onready var chase: AudioStreamPlayer2D = $Chase
@onready var music_box: AudioStreamPlayer2D = $MusicBox   # adjust path if it's nested elsewhere

var state: EState = EState.IDLE
var _alert_timer: float = 0.0
var _safe_timer: float = 0.0
var _chase_active := false
var _pitch_tween: Tween

func _ready() -> void:
	catch_area.monitoring = false


func _process(delta: float) -> void:
	_process_despawn(delta)   # always runs, independent of trigger state
	
	match state:
		EState.ALERT_SOUND:
			_alert_timer -= delta
			if _alert_timer <= 0.0:
				_set_state(EState.CHASING)
		EState.CHASING:
			_process_chasing(delta)


# ---------- trigger (either path leads here, but only ever fires once) ----------
func _trigger() -> void:
	if state != EState.IDLE:
		return   # already triggered — ignore the music box's late finished signal
	
	music_box.stop()   # it's done its job; no reason to let it keep playing or fire again
	SoundBank.play_sfx("enemy_alert", global_position)
	_alert_timer = post_alert_delay
	_set_state(EState.ALERT_SOUND)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_trigger()

func _on_music_box_finished() -> void:
	_trigger()


# ---------- chase (permanent once started) ----------
func _process_chasing(delta: float) -> void:
	var should_chase := not GameManager.player_safe
	if should_chase != _chase_active:
		_chase_active = should_chase
		_set_chase_audio(should_chase)
	
	if not should_chase:
		return
	
	var player := _get_player()
	if player == null:
		return
	var direction := (player.global_position - global_position).normalized()
	global_position += direction * chase_speed * delta

func _get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player

func _set_chase_audio(active: bool) -> void:
	if _pitch_tween:
		_pitch_tween.kill()
	
	if active:
		chase.pitch_scale = 0.0
		chase.playing = true
		_pitch_tween = create_tween()
		_pitch_tween.tween_property(chase, "pitch_scale", 1.0, pitch_tween_duration)
	else:
		_pitch_tween = create_tween()
		_pitch_tween.tween_property(chase, "pitch_scale", 0.0, pitch_tween_duration)
		_pitch_tween.tween_callback(func() -> void:
			chase.playing = false)

# ---------- catch ----------
func _set_state(new_state: EState) -> void:
	state = new_state
	if state == EState.CHASING:
		catch_area.monitoring = true   # turns on, never off — no retreat

func _on_catch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not GameManager.player_safe:
		print("die")
		player_caught.emit()


# ---------- despawn ----------
func _process_despawn(delta: float) -> void:
	if GameManager.player_safe:
		_safe_timer += delta
		if _safe_timer >= safe_despawn_time:
			despawned.emit()
			queue_free()
	else:
		_safe_timer = 0.0
