extends Node2D

var player: Player = null
@onready var tutorial: RichTextLabel = $Tutorial

# Grid Power Variables
var max_grid_power: float = 100.0
var grid_power: float = 0.0
var _previous_power: float = -1.0
var grid_drain_rate: float = 3.33    # How fast the lamps die
var grid_charge_rate: float = 14.0  # How fast cranking restores them
var requires_cranking: bool = false

func _ready() -> void:
	add_to_group("generator")
	if GameManager.current_day == 0:
		tutorial.show()
		
	requires_cranking = GameManager.voltek_debt > 0

func _process(delta: float) -> void:
	# 1. Handle passive drain
	if requires_cranking and grid_power > 0.0:
		grid_power = maxf(grid_power - (grid_drain_rate * delta), 0.0)
	# 2. Handle player input and charging
	if player:
		if player.tool.frame == 2 and player.is_using_tool():
			player.battery.recharge(delta)
			
			if requires_cranking:
				grid_power = minf(grid_power + (grid_charge_rate * delta), max_grid_power)
		else:
			player.battery._set_charging(false)
			
	# 3. Apply visual updates only if the grid power changed
	if requires_cranking and grid_power != _previous_power:
		_update_lamps()
		_previous_power = grid_power

func _update_lamps() -> void:
	var ratio: float = grid_power / max_grid_power
	get_tree().call_group("lamp_lights", "set_light_energy", ratio)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player.battery._set_charging(false)
		player = null
