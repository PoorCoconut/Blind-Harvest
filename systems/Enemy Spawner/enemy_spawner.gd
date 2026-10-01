extends Node2D
class_name EnemySpawner

@export var spawn_bounds: Rect2
@export var min_player_distance: float = 250.0
@export var obstacle_layer: int = 1

@export_category("Grace Periods")
@export var trespasser_grace_duration: float = 15.0
var _trespasser_grace_timer: float = 0.0

@onready var day_orchestrator: DayOrchestrator = $"../DayOrchestrator"

# A dictionary to track the remaining cooldown for each unique config
var _config_timers: Dictionary = {}

func _ready() -> void:
	# You can delete the global SpawnTimer node entirely.
	pass

func _process(delta: float) -> void:
	var day_data = day_orchestrator.current_day_data
	
	if day_data == null or day_data.enemy_configs.is_empty():
		return
		
	# 1. Handle the Trespasser Grace Period
	if get_tree().get_nodes_in_group("trespasser").size() > 0:
		_trespasser_grace_timer = trespasser_grace_duration
	elif _trespasser_grace_timer > 0.0:
		_trespasser_grace_timer -= delta

	# 2. Process Individual Enemy Timers
	for config in day_data.enemy_configs:
		# Initialize the timer if this config hasn't been tracked yet
		if not _config_timers.has(config):
			_config_timers[config] = config.spawn_interval
			
		_config_timers[config] -= delta
		
		# When this specific enemy's timer hits zero, attempt a spawn
		if _config_timers[config] <= 0.0:
			# Reset the timer immediately so it continuously cycles
			_config_timers[config] = config.spawn_interval
			
			_attempt_specific_spawn(config)

func _attempt_specific_spawn(config: EnemySpawnConfig) -> void:
	# Block if it's the Trespasser and the grace period is still ticking
	if config.enemy_id == "trespasser" and _trespasser_grace_timer > 0.0:
		return
		
	# Enforce the maximum active cap for this specific enemy
	var current_count = get_tree().get_nodes_in_group(config.enemy_id).size()
	if current_count >= config.max_active_at_once:
		return
		
	try_spawn_enemy(config)

func try_spawn_enemy(config: EnemySpawnConfig) -> void:
	var enemy_instance: Node2D = config.enemy_scene.instantiate()
	
	enemy_instance.add_to_group(config.enemy_id)
	
	var space_state = get_world_2d().direct_space_state
	var player = get_tree().get_first_node_in_group("player")
	var max_attempts = 15
	
	for i in range(max_attempts):
		var random_pos = Vector2(
			randf_range(spawn_bounds.position.x, spawn_bounds.end.x),
			randf_range(spawn_bounds.position.y, spawn_bounds.end.y)
		)
		
		if player and random_pos.distance_to(player.global_position) < min_player_distance:
			continue
			
		var query = PhysicsPointQueryParameters2D.new()
		query.position = random_pos
		query.collision_mask = obstacle_layer
		
		var intersections = space_state.intersect_point(query)
		
		if intersections.is_empty():
			enemy_instance.global_position = random_pos
			add_child(enemy_instance)
			
			if config.enemy_id == "crow" or enemy_instance.has_method("_scare_crow"):
				var plots = get_tree().get_nodes_in_group("farming_plot")
				if plots.size() > 0:
					enemy_instance.target_plot = plots.pick_random()
			
			return 
			
	enemy_instance.queue_free()
