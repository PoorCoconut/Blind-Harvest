extends Node2D
class_name FarmingPlot

signal harvested(amount: int)

enum FarmState { EMPTY, GROWING, READY }
enum Tool { NONE = 0, WATERING_CAN = 1, WRENCH = 2 }

const FRAME_EMPTY := 0
const FRAME_SEEDS := 1
const FRAME_RIPE := 5

@export_category("Growth")
@export var stage_time: float = 6.0     # seconds per growth stage
@export var max_stagger: float = 8.0    # max random delay per plant

@export_category("Water")
@export var water_drain_rate: float = 0.04  # per second (0.04 = ~25s of water)
@export var water_fill_rate: float = 0.6    # per second while watering

@export_category("Actions")
@export var action_interval: float = 0.06   # delay between each plant planted/harvested
@export var money_per_crop: int = 5

@onready var plants_node: Node2D = $Plants

var plants: Array[Sprite2D] = []
var ages: Array[float] = []
var order: Array[int] = []   # shuffled, so planting/harvesting looks organic

var state: FarmState = FarmState.EMPTY
var water: float = 0.0
var player: Player = null
var _action_timer: float = 0.0


func _ready() -> void:
	for child in plants_node.get_children():
		if child is Sprite2D:
			child.frame = FRAME_EMPTY
			plants.append(child)
			ages.append(0.0)
	order.assign(range(plants.size()))
	order.shuffle()


func _process(delta: float) -> void:
	match state:
		FarmState.EMPTY:
			if _holding(Tool.NONE) and _action_ready(delta):
				_plant_next()
		FarmState.GROWING:
			_process_growing(delta)
		FarmState.READY:
			if _holding(Tool.NONE) and _action_ready(delta):
				_harvest_next()


# ---------- EMPTY ----------
func _plant_next() -> void:
	for i in order:
		if plants[i].frame == FRAME_EMPTY:
			plants[i].frame = FRAME_SEEDS
			ages[i] = -randf_range(0.0, max_stagger)  # the stagger
			break
	
	if plants.all(func(p: Sprite2D) -> bool: return p.frame != FRAME_EMPTY):
		water = 0.0  # fresh seeds are thirsty
		state = FarmState.GROWING


# ---------- GROWING ----------
func _process_growing(delta: float) -> void:
	if _holding(Tool.WATERING_CAN):
		water = minf(water + water_fill_rate * delta, 1.0)
	
	if water > 0.0:
		water = maxf(water - water_drain_rate * delta, 0.0)
		for i in plants.size():
			ages[i] += delta
			var stage: int = 0 if ages[i] < 0.0 else mini(int(ages[i] / stage_time), 4)
			plants[i].frame = FRAME_SEEDS + stage
	
	# thirsty visual cue (swap for a bubble icon later)
	plants_node.modulate = Color(0.7, 0.7, 0.85) if water <= 0.0 else Color.WHITE
	
	if plants.all(func(p: Sprite2D) -> bool: return p.frame == FRAME_RIPE):
		plants_node.modulate = Color.WHITE
		state = FarmState.READY


# ---------- READY ----------
func _harvest_next() -> void:
	for i in order:
		if plants[i].frame == FRAME_RIPE:
			plants[i].frame = FRAME_EMPTY
			harvested.emit(money_per_crop)
			break
	
	if plants.all(func(p: Sprite2D) -> bool: return p.frame == FRAME_EMPTY):
		state = FarmState.EMPTY


# ---------- helpers ----------
func _holding(tool_id: Tool) -> bool:
	return player != null and player.is_using_tool() and player.get_tool_id() == tool_id


func _action_ready(delta: float) -> bool:
	_action_timer -= delta
	if _action_timer <= 0.0:
		_action_timer = action_interval
		return true
	return false


# ---------- InteractionArea signals ----------
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body as Player


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
