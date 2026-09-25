extends Node2D

var player: Player = null

func _process(delta: float) -> void:
	if player and player.tool.frame == 1:
		player.can.refill(delta)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player.can._set_refilling(false)
		player = null
