extends CanvasLayer

@export var follow_speed: float = 6.0       # lower = longer trail
@export var min_trail_speed: float = 4.0    # units/sec, so the trail always finishes
@export_range(0.0, 1.0) var low_water_ratio: float = 0.2

@onready var WhiteBar = %WhiteBar
@onready var BarChaser = %BarChaser

var _real: float = 0.0     # true water value
var _trail: float = 0.0    # what the white bar is showing (unrounded)
var _low_tween: Tween
var _is_low := false


func _ready() -> void:
	Events.player_water_updated.connect(_on_water_updated)


func _on_water_updated(current: float, maximum: float) -> void:
	WhiteBar.max_value = maximum
	BarChaser.max_value = maximum
	
	_real = current
	BarChaser.value = _real           # real value, instant
	
	if _real >= _trail:               # refilling: no trail needed
		_trail = _real
		WhiteBar.value = _trail
	
	_update_low_warning(current, maximum)


func _process(delta: float) -> void:
	if _trail <= _real:
		return
	
	# ease toward the real value, but never slower than min_trail_speed
	var gap := _trail - _real
	var move := maxf(gap * (1.0 - exp(-follow_speed * delta)), min_trail_speed * delta)
	
	_trail = maxf(_trail - move, _real)   # clamped: stops exactly at the chaser
	WhiteBar.value = _trail


# only tweens when crossing the threshold, never per-frame
func _update_low_warning(current: float, maximum: float) -> void:
	var low := maximum > 0.0 and current / maximum <= low_water_ratio
	if low == _is_low:
		return
	_is_low = low
	
	if _low_tween:
		_low_tween.kill()
	_low_tween = create_tween()
	_low_tween.tween_property($BarContainer, "modulate",
		Color(1.0, 0.5, 0.5) if low else Color.WHITE, 0.3)
