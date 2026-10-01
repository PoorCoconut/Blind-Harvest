extends Resource
class_name DayData

@export var day_number: int = 1
@export var tutorial_mode: bool = false
@export var is_raining: bool = false
@export var random_scares_enabled: bool = true

@export_category("Time Management")
@export var start_time: float = 0.0
@export var time_progresses: bool = true # If false, time freezes at start_time
@export var ends_on_timer: bool = true # If false, the day ignores the clock hitting the limit
@export var grid_relies_on_generator: bool = false

@export_category("Enemy Configuration")
@export var enemy_configs: Array[EnemySpawnConfig]
