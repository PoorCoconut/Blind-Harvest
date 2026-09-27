extends CanvasLayer

@export var follow_speed: float = 6.0       # lower = longer trail
@export var min_trail_speed: float = 4.0    # units/sec, so the trail always finishes
@export_range(0.0, 1.0) var low_water_ratio: float = 0.2

@onready var WhiteBar = %WhiteBar
@onready var BarChaser = %BarChaser

@onready var battery_white_bar: TextureProgressBar = %BatteryWhiteBar
@onready var battery_chaser: TextureProgressBar = %BatteryChaser

var _real: float = 0.0     # true water value
var _trail: float = 0.0    # what the white bar is showing (unrounded)
var _low_tween: Tween
var _is_low := false

var _battery_real: float = 0.0     # true battery value
var _battery_trail: float = 0.0    # what the battery white bar is showing (unrounded)


func _ready() -> void:
	Events.player_water_updated.connect(_on_water_updated)
	Events.player_battery_updated.connect(_on_battery_updated)


func _on_water_updated(current: float, maximum: float) -> void:
	WhiteBar.max_value = maximum
	BarChaser.max_value = maximum
	
	_real = current
	BarChaser.value = _real           # real value, instant
	
	if _real >= _trail:               # refilling: no trail needed
		_trail = _real
		WhiteBar.value = _trail
	
	#_update_low_warning(current, maximum)

func _on_battery_updated(current: float, maximum: float) -> void:
	battery_white_bar.max_value = maximum
	battery_chaser.max_value = maximum
	
	_battery_real = current
	battery_chaser.value = _battery_real     # real value, instant
	
	if _battery_real >= _battery_trail:      # recharging: no trail needed
		_battery_trail = _battery_real
		battery_white_bar.value = _battery_trail

func _process(delta: float) -> void:
	_update_trail(delta, _real, _trail, WhiteBar, "_trail")
	_update_trail(delta, _battery_real, _battery_trail, battery_white_bar, "_battery_trail")


# Eases a white "trail" bar down toward its real value, never slower than
# min_trail_speed, and stops exactly at the real value. Shared by both bars.
func _update_trail(delta: float, real: float, trail: float, bar: TextureProgressBar, trail_var: String) -> void:
	if trail <= real:
		return
	
	var gap := trail - real
	var move := maxf(gap * (1.0 - exp(-follow_speed * delta)), min_trail_speed * delta)
	var new_trail := maxf(trail - move, real)
	
	set(trail_var, new_trail)
	bar.value = new_trail


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
