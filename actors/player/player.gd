extends CharacterBody2D
class_name Player

@export_category("PLAYER MOVEMENT")
@export var MAX_SPEED : float = 40
@export var ACCELERATION : float = 100
@export var FRICTION : float = 80

var CUR_DIR : Vector2

#Head look
var max_look_angle_degrees: float = 20.0:
	set(value):
		max_look_angle_degrees = value
		_max_look_rad = deg_to_rad(value)
		
@onready var visuals: Node2D = $Visuals
@onready var head_pivot: Node2D = $Visuals/HeadPivot
var _max_look_rad: float

#Player Hand
var min_hand_distance: float = 5.0
var max_hand_distance: float = 10.0
var max_mouse_reference: float = 100.0
@onready var hand_pivot: Node2D = $HandPivot
@onready var hand: Sprite2D = $HandPivot/Hand

func _ready() -> void:
	_max_look_rad = deg_to_rad(max_look_angle_degrees)

func _process(_delta: float) -> void:
	#Head code
	var diff: Vector2 = get_global_mouse_position() - head_pivot.global_position
	var facing_right: bool = diff.x >= 0.0
	visuals.scale.x = 1.0 if facing_right else -1.0
	if not facing_right:
		diff.x = -diff.x
	head_pivot.rotation = clampf(diff.angle(), -_max_look_rad, _max_look_rad)
	
	#Hand code
	update_floating_hand()

func _physics_process(_delta: float) -> void:
	move_and_slide()

func update_floating_hand() -> void:
	var diff: Vector2 = get_global_mouse_position() - hand_pivot.global_position
	hand_pivot.rotation = diff.angle()
	var distance_to_mouse: float = diff.length()
	var distance_ratio: float = clampf(distance_to_mouse / max_mouse_reference, 0.0, 1.0)
	var calculated_distance: float = lerpf(min_hand_distance, max_hand_distance, distance_ratio)
	hand.position = Vector2(calculated_distance, 0.0)
