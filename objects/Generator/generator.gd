extends Node2D

var player: Player = null
@onready var tutorial: RichTextLabel = $Tutorial

func _ready() -> void:
	if GameManager.current_day == 0:
		tutorial.show()

func _process(delta: float) -> void:
	if not player:
		return
	if player.tool.frame == 2 and player.is_using_tool():
		player.battery.recharge(delta)
	else:
		player.battery._set_charging(false)   # button released / tool switched: stop the sfx

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player.battery._set_charging(false)
		player = null
