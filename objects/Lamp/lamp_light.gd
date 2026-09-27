extends Node2D
class_name LampLight

@onready var flash_light: PointLight2D = $FlashLight
@onready var radial_light: PointLight2D = $RadialLight
@onready var ground_light: PointLight2D = $GroundLight

func turn_off():
	flash_light.hide()
	radial_light.hide()
	ground_light.hide()

func turn_on():
	flash_light.show()
	radial_light.show()
	ground_light.show()
