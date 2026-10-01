extends Area2D
class_name Crow

var target_plot: FarmingPlot:
	set(value):
		target_plot = value
		# Create a scattered landing zone around the plot's origin
		var random_offset = Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
		_target_position = target_plot.global_position + random_offset

var speed: float = 60.0
var _target_position: Vector2

var _landed: bool = false
var _flying_away: bool = false

func _process(delta: float) -> void:
	if _flying_away:
		position.y -= (speed * 1.5) * delta
		return
		
	if not _landed and target_plot:
		# Move toward the unique offset position instead of the exact plot center
		position = position.move_toward(_target_position, speed * delta)
		
		if position.distance_to(_target_position) < 5.0:
			_landed = true
			target_plot.add_crow()

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _flying_away:
		_scare_crow()

func _scare_crow() -> void:
	_flying_away = true
	SoundBank.play_sfx("crow_caw", global_position)
	
	if _landed and target_plot:
		target_plot.remove_crow()
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
