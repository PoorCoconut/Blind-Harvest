extends Node2D

@onready var house_shadow: Sprite2D = $HouseShadow
@onready var environment_shadow: Node2D = $EnvironmentShadow
@onready var day_orchestrator: DayOrchestrator = $DayOrchestrator
@onready var fader_anim: AnimationPlayer = $FaderAnim

@export_file("*.tscn") var tv_path : String
var tutorial_harvest_count: int = 0

func _ready() -> void:
	# Optional: Connect signals if the farm needs to react to the day ending
	$DayOrchestrator.day_ended.connect(_on_day_ended)

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
