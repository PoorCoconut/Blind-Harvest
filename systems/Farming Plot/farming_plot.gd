extends Node2D
class_name FarmingPlot

signal harvested(amount: int)
signal ready_to_harvest

enum PlantState { EMPTY, GROWING, READY }
enum Tool { NONE = 0, WATERING_CAN = 1, WRENCH = 2 }

const FRAME_EMPTY := 0
const FRAME_SEEDS := 1
const FRAME_RIPE := 5

@export_category("Water")
@export var water_fill_rate: float = 60.0   # per second while watering (fast)
@export var water_drain_rate: float = 3.0   # per second, always (slow)
@export var grow_time: float = 15.0          # seconds of WATERED time per growth stage

@export_category("Growth Visuals")
@export var max_stagger: float = 1.2        # random delay so crops don't pop together
@export var pop_duration: float = 0.5
@export var jiggle_degrees: float = 8.0
@export var wind_start_max: float = 10.0    # random range for the shader's wind_start

@export_category("Actions")
@export var action_interval: float = 0.06   # delay between each plant/harvest step
@export var money_per_crop: int = 5

@onready var plants_node: Node2D = $Plants
@onready var water_bar: TextureProgressBar = %WaterCanBar

@export_category("Water Bar")
@export var water_bar_pop_duration: float = 0.3
var _water_bar_tween: Tween


var plants: Array[Sprite2D] = []
var has_crop: Array[bool] = []
var order: Array[int] = []        # shuffled so planting/harvesting looks organic

var state: PlantState = PlantState.EMPTY
var stage: int = FRAME_EMPTY
var water: float = 0.0
var grow_progress: float = 0.0
var player: Player = null

var _action_timer: float = 0.0
var _pending_pops: int = 0


func _ready() -> void:
	for child in plants_node.get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			sprite.frame = FRAME_EMPTY
			
			# give every sprite its OWN material copy, then randomize the wind
			if sprite.material is ShaderMaterial:
				sprite.material = sprite.material.duplicate()
				(sprite.material as ShaderMaterial).set_shader_parameter(
					"wind_start", randf_range(0.0, wind_start_max))
			
			plants.append(sprite)
			has_crop.append(false)
	
	order.assign(range(plants.size()))
	order.shuffle()
	_set_state(PlantState.EMPTY)


func _process(delta: float) -> void:
	match state:
		PlantState.EMPTY:
			if _holding(Tool.NONE) and _action_ready(delta):
				_plant_next()
		PlantState.GROWING:
			_process_growing(delta)
		PlantState.READY:
			if _holding(Tool.NONE) and _action_ready(delta):
				_harvest_next()


# ---------- EMPTY ----------
func _plant_next() -> void:
	for i in order:
		if not has_crop[i]:
			has_crop[i] = true
			_pop(plants[i], FRAME_SEEDS, 0.0)
			break
	
	if not has_crop.has(false):
		stage = FRAME_SEEDS
		_set_state(PlantState.GROWING)


# ---------- GROWING ----------
func _process_growing(delta: float) -> void:
	var change := -water_drain_rate
	if player != null and player.is_watering:
		change += water_fill_rate
	water = clampf(water + change * delta, 0.0, water_bar.max_value)
	water_bar.value = water
	
	# the "must have water for X seconds" timer: pauses while dry, keeps its progress
	if water > 0.0 and stage < FRAME_RIPE:
		grow_progress += delta
		if grow_progress >= grow_time:
			grow_progress = 0.0
			_advance_stage()


func _advance_stage() -> void:
	stage += 1
	for sprite in plants:
		
		_pop(sprite, stage, randf_range(0.0, max_stagger))


# ---------- READY ----------
func _harvest_next() -> void:
	for i in order:
		if has_crop[i]:
			has_crop[i] = false
			var sprite := plants[i]
			var tween := create_tween()
			tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(func() -> void:
				if not has_crop[i]:   # don't wipe it if it was replanted already
					sprite.frame = FRAME_EMPTY)
			harvested.emit(money_per_crop)
			break
	
	if not has_crop.has(true):
		_set_state(PlantState.EMPTY)


# ---------- visuals ----------
func _pop(sprite: Sprite2D, frame: int, delay: float) -> void:
	_pending_pops += 1
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		sprite.frame = frame
		sprite.scale = Vector2.ZERO
		sprite.rotation = 0.0
		_jiggle(sprite)
		SoundBank.play_sfx("plant_grow", sprite.global_position, 0.5, 1.5, 500))
	tween.tween_property(sprite, "scale", Vector2.ONE, pop_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # swap to TRANS_ELASTIC for more bounce
	tween.finished.connect(_on_pop_finished)


func _jiggle(sprite: Sprite2D) -> void:
	var angle := deg_to_rad(jiggle_degrees) * (1.0 if randf() > 0.5 else -1.0)
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", angle, pop_duration * 0.25)
	tween.tween_property(sprite, "rotation", -angle * 0.6, pop_duration * 0.25)
	tween.tween_property(sprite, "rotation", 0.0, pop_duration * 0.5)


func _on_pop_finished() -> void:
	_pending_pops -= 1
	# only "ready" once the last crop has finished popping in
	if state == PlantState.GROWING and stage == FRAME_RIPE and _pending_pops == 0:
		_set_state(PlantState.READY)


# ---------- state ----------
func _set_state(new_state: PlantState) -> void:
	state = new_state
	_animate_water_bar(state == PlantState.GROWING)
	
	match state:
		PlantState.EMPTY:
			stage = FRAME_EMPTY
		PlantState.GROWING:
			water = 0.0
			grow_progress = 0.0
			water_bar.value = 0.0
		PlantState.READY:
			print("Crops are ready to harvest!")   # swap for a popup sprite later
			ready_to_harvest.emit()


# ---------- helpers ----------
func _holding(tool_id: Tool) -> bool:
	return player != null and player.is_using_tool() and player.get_tool_id() == tool_id


func _action_ready(delta: float) -> bool:
	_action_timer -= delta
	if _action_timer <= 0.0:
		_action_timer = action_interval
		return true
	return false


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body as Player


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

func _animate_water_bar(show: bool) -> void:
	if _water_bar_tween:
		_water_bar_tween.kill()
	
	_water_bar_tween = create_tween()
	
	if show:
		water_bar.visible = true
		water_bar.scale = Vector2.ZERO
		_water_bar_tween.tween_property(water_bar, "scale", Vector2.ONE, water_bar_pop_duration)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_water_bar_tween.tween_property(water_bar, "scale", Vector2.ZERO, water_bar_pop_duration * 0.6)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_water_bar_tween.tween_callback(func() -> void:
			water_bar.visible = false)
