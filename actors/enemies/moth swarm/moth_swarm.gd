extends Area2D
class_name MothSwarm

var player: Player
var speed: float = 35.0
var drain_multiplier: float = 5.0
var _darkness_timer: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not player:
		return
		
	# 1. The Counterplay: If the player's light is OFF
	if not player.flash_light.visible:
		_darkness_timer += delta
		# If the light stays off for a full second, the swarm dies
		if _darkness_timer >= 1.0:
			queue_free()
	else:
		# If they turn it back on too early, the timer completely resets
		_darkness_timer = 0.0 
		
		# Float directly toward the active light source
		position = position.move_toward(player.global_position, speed * delta)
		
		# 2. The Penalty: Drain the battery rapidly while touching the player
		if overlaps_body(player):
			player.battery.charge -= (player.battery.drain_rate * drain_multiplier) * delta
