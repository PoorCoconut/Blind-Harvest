extends Node
class_name Battery
## Tracks the player's light power. Drains passively over time (lights running),
## and recharges via recharge() when the player is at the generator with the wrench.
## Broadcasts every change through Events.player_battery_updated — same pattern as WateringCan.

@export var max_charge: float = 200.0
@export var drain_rate: float = 1.5     # charge lost per second, always-on drain
@export var charge_rate: float = 20.0   # charge gained per second, while held at the generator

var charge: float = max_charge:
	set(value):
		var clamped := clampf(value, 0.0, max_charge)
		if clamped == charge:
			return
		charge = clamped
		Events.player_battery_updated.emit(charge, max_charge)

# Optional: add a ChargeSFX AudioStreamPlayer child if you want a hum while charging,
# same pattern as WateringCan's RefillSFX. Safe to leave unset — see _set_charging below.
@onready var charge_sfx: AudioStreamPlayer = $ChargeSFX if has_node("ChargeSFX") else null

var _charging := false
var _charge_tween: Tween

func _ready() -> void:
	charge = max_charge
	# Force an initial broadcast so the HUD and lights start in sync on scene load.
	Events.player_battery_updated.emit(charge, max_charge)

## Call every frame the lights are considered "on". Returns false once empty,
## same false-when-exhausted convention as WateringCan.use().
func drain(delta: float) -> bool:
	if charge <= 0.0:
		return false
	charge -= drain_rate * delta
	return charge > 0.0

## Call while the player holds the wrench AND the tool button inside the generator's area.
func recharge(delta: float) -> void:
	charge += charge_rate * delta
	_set_charging(true)

func _set_charging(on: bool) -> void:
	if on == _charging:
		return
	_charging = on
	
	if not charge_sfx:
		return
	if _charge_tween:
		_charge_tween.kill()
	_charge_tween = create_tween()
	_charge_tween.tween_property(charge_sfx, "volume_db", 2.0 if on else -80.0, 0.5)

func get_ratio() -> float:
	return charge / max_charge if max_charge > 0.0 else 0.0

func is_empty() -> bool:
	return charge <= 0.0
