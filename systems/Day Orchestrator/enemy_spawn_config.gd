extends Resource
class_name EnemySpawnConfig

@export var enemy_scene: PackedScene
@export var enemy_id: String = "" 
@export var max_active_at_once: int = 1
@export var spawn_interval: float = 10.0 # How often this specific enemy tries to spawn
