extends Node2D
class_name LampLight

@onready var flash_light: PointLight2D = $FlashLight
@onready var radial_light: PointLight2D = $RadialLight
@onready var ground_light: PointLight2D = $GroundLight
@onready var light_buzz: AudioStreamPlayer2D = $LightBuzz

var _base_flash_energy: float
var _base_radial_energy: float
var _base_ground_energy: float

func _ready() -> void:
	add_to_group("lamp_lights")
	_base_flash_energy = flash_light.energy
	_base_radial_energy = radial_light.energy
	_base_ground_energy = ground_light.energy

func turn_off() -> void:
	flash_light.hide()
	radial_light.hide()
	ground_light.hide()

func turn_on() -> void:
	flash_light.show()
	radial_light.show()
	ground_light.show()

func set_light_energy(ratio: float) -> void:
	flash_light.energy = _base_flash_energy * ratio
	radial_light.energy = _base_radial_energy * ratio
	ground_light.energy = _base_ground_energy * ratio
	
	light_buzz.pitch_scale = lerpf(0.3, 1.0, ratio)
	
	if ratio <= 0.0:
		light_buzz.volume_db = -80.0
	else:
		light_buzz.volume_db = 0.0
