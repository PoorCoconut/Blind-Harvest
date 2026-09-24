extends Node
class_name WateringCan

@export var max_water: float = 100.0
@export var usage_rate: float = 20.0     # per second while spraying
@export var refill_rate: float = 60.0    # per second at the pump

var water: float = 0.0


func _ready() -> void:
	water = max_water
	_emit_update.call_deferred()   # deferred so the HUD is ready to listen


## Call every frame while spraying. Returns false if the can is empty.
func use(delta: float) -> bool:
	if water <= 0.0:
		return false
	_set_water(water - usage_rate * delta)
	return true


## Call every frame while at the pump.
func refill(delta: float) -> void:
	_set_water(water + refill_rate * delta)


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
	Events.player_water_updated.emit(water, max_water)
