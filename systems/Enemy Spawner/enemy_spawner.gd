extends Node2D
class_name EnemySpawner

@export var spawn_bounds: Rect2
@export var min_player_distance: float = 250.0
@export var obstacle_layer: int = 1

@onready var day_orchestrator: DayOrchestrator = $"../DayOrchestrator"
@onready var spawn_timer: Timer = $"../SpawnTimer"

func _ready() -> void:
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var day_data = day_orchestrator.current_day_data
	
	if day_data == null or day_data.enemy_configs.is_empty():
		return
		
	# Build a list of enemies that are legally allowed to spawn right now
	var available_configs: Array[EnemySpawnConfig] = []
	
	for config in day_data.enemy_configs:
		# Ask Godot how many enemies of this specific ID currently exist
		var current_count = get_tree().get_nodes_in_group(config.enemy_id).size()
		
		if current_count < config.max_active_at_once:
			available_configs.append(config)
			
	# If every enemy has hit its individual cap, do nothing
	if available_configs.is_empty():
		return
		
	# Pick a random enemy from the allowed pool
	var chosen_config = available_configs.pick_random()
	try_spawn_enemy(chosen_config)

func try_spawn_enemy(config: EnemySpawnConfig) -> void:
	var enemy_instance: Node2D = config.enemy_scene.instantiate()
	
	# Automatically assign the enemy to its tracking group based on its ID
	enemy_instance.add_to_group(config.enemy_id)
	
	var space_state = get_world_2d().direct_space_state
	var player = get_tree().get_first_node_in_group("player")
	var max_attempts = 15
	
	for i in range(max_attempts):
		var random_pos = Vector2(
			randf_range(spawn_bounds.position.x, spawn_bounds.end.x),
			randf_range(spawn_bounds.position.y, spawn_bounds.end.y)
		)
		
		# Distance Check
		if player and random_pos.distance_to(player.global_position) < min_player_distance:
			continue
			
		# Obstacle Check
		var query = PhysicsPointQueryParameters2D.new()
		query.position = random_pos
		query.collision_mask = obstacle_layer
		
		var intersections = space_state.intersect_point(query)
		
		if intersections.is_empty():
			enemy_instance.global_position = random_pos
			add_child(enemy_instance)
			return 
			
	# Failed to find an empty spot
	enemy_instance.queue_free()
