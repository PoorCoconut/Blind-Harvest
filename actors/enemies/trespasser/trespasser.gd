extends Node2D
class_name Trespasser

signal player_caught
signal despawned

enum EState { WAITING, ALERT_SOUND, CHASING }

@export_category("Trigger")
@export var natural_trigger_time: float = 20.0  # goes off on its own if never spotted early
@export var post_alert_delay: float = 2.5       # sound cue -> this delay -> it moves

@export_category("Chase")
@export var chase_speed: float = 90.0

@export_category("Despawn")
@export var safe_despawn_time: float = 5.0      # continuous safe-seconds needed to vanish

@onready var detection_area: Area2D = $DetectionArea
@onready var catch_area: Area2D = $CatchArea

var state: EState = EState.WAITING
var _natural_timer: float = 0.0
var _alert_timer: float = 0.0
var _safe_timer: float = 0.0


func _ready() -> void:
	_natural_timer = natural_trigger_time
	catch_area.monitoring = false


func _process(delta: float) -> void:
	_process_despawn(delta)   # always runs, independent of trigger state
	
	match state:
		EState.WAITING:
			_natural_timer -= delta
			if _natural_timer <= 0.0:
				_trigger()
		EState.ALERT_SOUND:
			_alert_timer -= delta
			if _alert_timer <= 0.0:
				_set_state(EState.CHASING)
		EState.CHASING:
			_process_chasing(delta)


# ---------- trigger (either path leads here) ----------
func _trigger() -> void:
	SoundBank.play_sfx("trespasser_alert", global_position)
	_alert_timer = post_alert_delay
	_set_state(EState.ALERT_SOUND)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if state == EState.WAITING and body.is_in_group("player"):
		_trigger()


# ---------- chase (permanent once started) ----------
func _process_chasing(delta: float) -> void:
	var player := _get_player()
	if player == null:
		return
	var direction := (player.global_position - global_position).normalized()
	global_position += direction * chase_speed * delta

func _get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


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
