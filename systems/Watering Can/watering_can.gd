extends Node
class_name WateringCan

@export var max_water: float = 100.0
@export var usage_rate: float = 20.0     # per second while spraying
@export var base_refill_rate: float = 20.0
var current_refill_rate: float = 0.0          # Use this variable for actual pumping

var water: float = 0.0
@onready var refill_sfx: AudioStreamPlayer = $RefillSFX  # add this node under WateringCan

var _refilling := false
var _refill_tween: Tween

func _ready() -> void:
	update_stats()
	_emit_update.call_deferred()   # deferred so the HUD is ready to listen


## Call every frame while spraying. Returns false if the can is empty.
func use(delta: float) -> bool:
	if water <= 0.0:
		return false
	_set_water(water - usage_rate * delta)
	return true


## Call every frame while at the pump.
func refill(delta: float) -> void:
	var before := water
	_set_water(water + current_refill_rate * delta)
	_set_refilling(water > before and not is_full())

func _set_refilling(on: bool) -> void:
	if on == _refilling:
		return
	_refilling = on
	
	if _refill_tween:
		_refill_tween.kill()
	_refill_tween = create_tween()
	_refill_tween.tween_property(refill_sfx, "volume_db", 0.0 if on else -80.0, 0.5)

func has_water() -> bool:
	return water > 0.0


func is_full() -> bool:
	return water >= max_water


func _set_water(value: float) -> void:
	var new_value := clampf(value, 0.0, max_water)
	if new_value == water:   # exact compare, so the last step to 0 always lands
		return
	water = new_value
	_emit_update()


func _emit_update() -> void:
	print("Watering Can Debug: ",water, "/", max_water)
	Events.player_water_updated.emit(water, max_water)

func update_stats() -> void:
	max_water = 100.0 + (100.0 * (GameManager.can_level * 0.25))
	
	# Always calculate off the protected base rate
	current_refill_rate = base_refill_rate + (base_refill_rate * (GameManager.can_level * 0.02))
	
	if GameManager.seaqua_debt > 0:
		current_refill_rate *= 0.45
		
	water = max_water
	
	print("Max Water: %s\nRefill Rate: %s" % [max_water, current_refill_rate])
