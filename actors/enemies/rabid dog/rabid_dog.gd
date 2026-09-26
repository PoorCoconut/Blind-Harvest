extends CharacterBody2D
class_name RabidDog

signal player_caught

enum DogState { WANDER, CHASING }

@export_category("Wander")
@export var wander_speed: float = 25.0
@export var wander_turn_interval_min: float = 1.5
@export var wander_turn_interval_max: float = 4.0
@export var wander_max_turn_degrees: float = 60.0
@export var wander_turn_speed: float = 90.0     # deg/sec while roaming

@export_category("Avoidance")
@export var avoid_turn_speed: float = 220.0     # deg/sec — fastest, always wins if something's ahead

@export_category("Chase")
@export var chase_speed: float = 70.0
@export var chase_turn_speed: float = 200.0     # deg/sec while chasing
@export var give_up_time: float = 6.0

@onready var detection_area: Area2D = $DetectionArea
@onready var catch_area: Area2D = $CatchArea
@onready var ray_front_left: RayCast2D = $Sensors/RayFrontLeft
@onready var ray_front_right: RayCast2D = $Sensors/RayFrontRight
@onready var ray_left: RayCast2D = $Sensors/RayLeft
@onready var ray_right: RayCast2D = $Sensors/RayRight

@onready var growl: AudioStreamPlayer2D = $Growl
@onready var chase: AudioStreamPlayer2D = $Chase


@onready var visuals: Node2D = $Visuals
@onready var sensors: Node2D = $Sensors


var state: DogState = DogState.WANDER
var _facing: float = 0.0         # actual current facing (radians) — turns gradually
var _desired_angle: float = 0.0  # angle something wants it to face this frame
var _avoiding := false
var _wander_timer: float = 0.0
var _chase_timer: float = 0.0
var target: Player = null


func _ready() -> void:
	catch_area.monitoring = false
	_facing = rotation
	_desired_angle = _facing
	_pick_new_wander_time()

func _physics_process(delta: float) -> void:
	match state:
		DogState.WANDER:
			_process_wander(delta)
		DogState.CHASING:
			_process_chase(delta)
	
	_apply_avoidance()   # can override _desired_angle after the state logic runs
	
	var speed := chase_speed if state == DogState.CHASING else wander_speed
	var turn_speed := avoid_turn_speed if _avoiding \
		else (chase_turn_speed if state == DogState.CHASING else wander_turn_speed)
	
	_facing = _turn_toward(_facing, _desired_angle, deg_to_rad(turn_speed) * delta)
	visuals.rotation = _facing          # was: rotation = _facing
	sensors.rotation = _facing
	velocity = Vector2.RIGHT.rotated(_facing) * speed
	move_and_slide()


func _turn_toward(current: float, target_angle: float, max_step: float) -> float:
	var diff := wrapf(target_angle - current, -PI, PI)
	return current + clampf(diff, -max_step, max_step)


# ---------- wander ----------
func _process_wander(_delta: float) -> void:
	_wander_timer -= _delta
	if _wander_timer <= 0.0:
		var offset := deg_to_rad(randf_range(-wander_max_turn_degrees, wander_max_turn_degrees))
		_desired_angle = _facing + offset
		_pick_new_wander_time()

func _pick_new_wander_time() -> void:
	_wander_timer = randf_range(wander_turn_interval_min, wander_turn_interval_max)


# ---------- avoidance (runs every frame, in every state) ----------
func _apply_avoidance() -> void:
	ray_front_left.force_raycast_update()
	ray_front_right.force_raycast_update()
	ray_left.force_raycast_update()
	ray_right.force_raycast_update()
	
	var left_blocked := ray_left.is_colliding() or ray_front_left.is_colliding()
	var right_blocked := ray_right.is_colliding() or ray_front_right.is_colliding()
	
	_avoiding = left_blocked or right_blocked
	if left_blocked and right_blocked:
		_desired_angle = _facing + PI          # boxed in — turn around
	elif left_blocked:
		_desired_angle = _facing + deg_to_rad(90)   # clear to the right — steer that way
	elif right_blocked:
		_desired_angle = _facing - deg_to_rad(90)   # clear to the left


# ---------- chase ----------
func _on_detection_area_body_entered(body: Node2D) -> void:
	if state == DogState.WANDER and body.is_in_group("player"):
		SoundBank.play_sfx("enemy_alert", global_position)
		target = body as Player
		_chase_timer = give_up_time
		_set_state(DogState.CHASING)
		
		if not chase.playing:
			chase.play()

func _process_chase(delta: float) -> void:
	if GameManager.player_safe or target == null:
		_give_up()
		return
	
	_chase_timer -= delta
	if _chase_timer <= 0.0:
		_give_up()
		return
	
	_desired_angle = (target.global_position - global_position).angle()

func _give_up() -> void:
	target = null
	_set_state(DogState.WANDER)
	_pick_new_wander_time()


func _set_state(new_state: DogState) -> void:
	state = new_state
	catch_area.monitoring = state == DogState.CHASING


func _on_catch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not GameManager.player_safe:
		print("bitten")
		player_caught.emit()


func _on_timer_timeout() -> void:
	if not growl.playing and randi_range(1, 2) == 1:
		print("growl")
		growl.pitch_scale = randf_range(0.7, 1.2)
		growl.play()
