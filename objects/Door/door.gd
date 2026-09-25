extends Node2D

@onready var sprite: Sprite2D = $Sprite

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		sprite.frame = 1

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		sprite.frame = 0
