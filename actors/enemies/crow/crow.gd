extends Area2D
class_name Crow

@export var silent_crow : bool = false
@export var override_target : bool = false
@export var override_target_plot : FarmingPlot

var target_plot: FarmingPlot:
	set(value):
		target_plot = value
		if target_plot != null:
			var random_offset = Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
			_target_position = target_plot.farm_plot_center.global_position + random_offset

var speed: float = 60.0
var _target_position: Vector2
var _base_target_position: Vector2

var _landed: bool = false
var _flying_away: bool = false
var _hop_timer: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var head_pivot: Node2D = $Visuals/HeadPivot
@onready var bird_flap: AudioStreamPlayer2D = $BirdFlap

func _ready() -> void:
	if not silent_crow:
		SoundBank.play_sfx("crow_caw2")
		bird_flap.play()
	
	if override_target and override_target_plot:
		target_plot = override_target_plot

func _process(delta: float) -> void:
	if _flying_away:
		position.y -= (speed * 1.5) * delta
		return
		
	if not _landed and target_plot:
		# Face the direction of the target plot while flying
		var dir = sign(_target_position.x - position.x)
		if dir != 0:
			visuals.scale.x = dir
			
		position = position.move_toward(_target_position, speed * delta)
		
		if position.distance_to(_target_position) < 5.0:
			_landed = true
			bird_flap.stop()
			_base_target_position = _target_position # Lock in the pivot point
			_hop_timer = randf_range(1.0, 2.5)
			target_plot.add_crow()
			
	elif _landed and not _flying_away:
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop()
			_hop_timer = randf_range(2.0, 4.0)

func _hop() -> void:
	# Pick a tiny random offset around their base landing spot
	var wander_offset = Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	var new_pos = _base_target_position + wander_offset
	
	# Face the direction they are hopping
	var dir = sign(new_pos.x - position.x)
	if dir != 0:
		visuals.scale.x = dir

	# Calculate duration so short hops are fast and long hops take slightly longer
	var dist = position.distance_to(new_pos)
	var duration = clampf(dist / (speed * 0.4), 0.15, 0.3)
	
	# Tween 1: Move the root position flatly across the ground
	var move_tween = create_tween()
	move_tween.tween_property(self, "position", new_pos, duration)
	
	# Tween 2: Bounce the visuals node up and down to create the jump arc
	var arc_tween = create_tween()
	arc_tween.tween_property(visuals, "position:y", -6.0, duration * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	arc_tween.tween_property(visuals, "position:y", 0.0, duration * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# Chain the peck animation to happen exactly when they land from the hop
	arc_tween.tween_callback(_peck)

func _peck() -> void:
	if _flying_away: 
		return
		
	var peck_tween = create_tween()
	peck_tween.tween_property(head_pivot, "rotation_degrees", 30.0, 0.05)
	peck_tween.tween_callback(func() -> void: 
		SoundBank.play_sfx("bird_pick", Vector2.ZERO, 0.7, 1.2, 1000)
	)
	peck_tween.tween_property(head_pivot, "rotation_degrees", 0.0, 0.1)

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _flying_away:
		_scare_crow()

func _scare_crow() -> void:
	_flying_away = true
	bird_flap.play()
	SoundBank.play_sfx("crow_caw1", global_position)
	
	if _landed and target_plot:
		target_plot.remove_crow()
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
