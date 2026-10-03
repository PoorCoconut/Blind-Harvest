extends Node2D

@onready var house_shadow: Sprite2D = $HouseShadow
@onready var environment_shadow: Node2D = $EnvironmentShadow
@onready var day_orchestrator: DayOrchestrator = $DayOrchestrator
@onready var fader_anim: AnimationPlayer = $FaderAnim
@onready var fences_removable: TileMapLayer = $Tilemap/FencesRemovable

@export_file("*.tscn") var tv_path : String
@export_file("*.tscn") var death_path : String
var tutorial_harvest_count: int = 0

func _ready() -> void:
	GameManager.save_farm_checkpoint()
	if GameManager.current_day == 0:
		MusicManager.change_music("day", 0.0)
	
	# Optional: Connect signals if the farm needs to react to the day ending
	KonamiManager.code_entered.connect(_on_code_entered)
	
	$DayOrchestrator.day_ended.connect(_on_day_ended)
	
	if GameManager.bought_fence:
		fences_removable.queue_free()

func _on_day_ended() -> void:
	MusicManager.stop_music()
	print("Day is over. Processing farm cleanup...")

func _on_house_shadow_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.player_safe = true
		fade_shadow(house_shadow, 0.0)
		fade_shadow(environment_shadow, 1.0)

func _on_house_shadow_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.player_safe = false
		fade_shadow(house_shadow, 1.0)
		fade_shadow(environment_shadow, 0.0)

func fade_shadow(target_node: Node2D, target_alpha: float) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(target_node, "modulate:a", target_alpha, 0.5)

func _on_farming_plot_harvested(amount: int) -> void:
	GameManager.add_money(amount)
	
	# Check if we are currently running the tutorial objective
	var day_data = day_orchestrator.current_day_data
	
	if day_data != null and day_data.tutorial_mode:
		tutorial_harvest_count += 1
		
		if tutorial_harvest_count >= 128:
			day_orchestrator.end_day()

func _on_day_orchestrator_day_ended() -> void:
	fader_anim.play("in")

func _on_fader_anim_animation_finished(_anim_name: StringName) -> void:
	GameManager.load_next_level(tv_path)

func _on_code_entered(code_name : String):
	if code_name == "pump":
		var player : Player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = $PumpTP.global_position
	elif code_name == "gen":
		var player : Player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = $GenTP.global_position

func _on_enemy_spawner_enemy_spawned(enemy: Node2D) -> void:
	if enemy.has_signal("player_caught"):
		enemy.player_caught.connect(_trigger_death_screen)

func _trigger_death_screen():
	GameManager.load_next_level(death_path)
