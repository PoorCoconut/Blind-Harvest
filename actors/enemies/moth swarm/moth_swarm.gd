extends Area2D
class_name MothSwarm

var player: Player
var speed: float = 35.0
var drain_multiplier: float = 5.0
var _darkness_timer: float = 0.0
var _is_dying: bool = false

@onready var moth_particle: CPUParticles2D = $MothParticle

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not player or _is_dying:
		return
		
	# 1. The Counterplay: Check the unified light variable
	if not player.is_light_on:
		_darkness_timer += delta
		if _darkness_timer >= 1.0:
			_die()
	else:
		_darkness_timer = 0.0 
		position = position.move_toward(player.global_position, speed * delta)
		
		if overlaps_body(player):
			player.battery.charge -= (player.battery.drain_rate * drain_multiplier) * delta

func _die() -> void:
	_is_dying = true
	moth_particle.emitting = false
	
	# Instantly turn off the occluder so the player's vision returns
	for child in get_children():
		if child is LightOccluder2D:
			child.visible = false
			
	# Remove from the enemy group immediately so the spawner knows it is dead
	if is_in_group("moth_swarm"):
		remove_from_group("moth_swarm")
			
	# Wait for the remaining particles to finish their lifetime before freeing
	await get_tree().create_timer(moth_particle.lifetime).timeout
	queue_free()
