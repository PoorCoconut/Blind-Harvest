extends Resource
class_name EnemySpawnConfig

@export var enemy_scene: PackedScene
@export var enemy_id: String = "" # e.g., "rabid_dog", "trespasser"
@export var max_active_at_once: int = 1
