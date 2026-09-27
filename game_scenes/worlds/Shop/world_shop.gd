extends Control
class_name WorldShop

@export_file("*.tscn") var next_level_path : String
@onready var fader: AnimationPlayer = $Fader

@export_category("Shop Costs")
@export var watering_can_costs : Array[int] = [200, 300, 400, 500]
@export var battery_costs : Array[int] = [300, 450, 600, 1000]
@export var flashlight_cost : int = 500
@export var boots_cost : int = 300

@export_category("End of Day costs")
@export var food_cost : int = 50
@export var electricity_cost : int = 100
@export var water_cost : int = 80

@onready var money_label: Label = $ShopContainer/VBoxContainer/MoneyLabel

@onready var watering_can_cost_label: Label = $ShopContainer/VBoxContainer/WateringCan/VBoxContainer/WCLabels/WateringCanCostLabel
@onready var purchase_watering_can: Button = $ShopContainer/VBoxContainer/WateringCan/VBoxContainer/WCLabels/PurchaseWateringCan
@onready var water_can_upgrade_bar: TextureProgressBar = $ShopContainer/VBoxContainer/WateringCan/VBoxContainer/WCBars/WaterCanUpgradeBar

@onready var battery_cost_label: Label = $ShopContainer/VBoxContainer/Battery/VBoxContainer/BLabels/BatteryCostLabel
@onready var purchase_battery: Button = $ShopContainer/VBoxContainer/Battery/VBoxContainer/BLabels/PurchaseBattery
@onready var battery_upgrade_bar: TextureProgressBar = $ShopContainer/VBoxContainer/Battery/VBoxContainer/BBars/BatteryUpgradeBar

@onready var purchase_flashlight: Button = $ShopContainer/VBoxContainer/Flashlight/PurchaseFlashlight
@onready var flashlight_cost_label: Label = $ShopContainer/VBoxContainer/Flashlight/FlashlightCostLabel

@onready var purchase_boots: Button = $ShopContainer/VBoxContainer/Boots/PurchaseBoots
@onready var boots_cost_label: Label = $ShopContainer/VBoxContainer/Boots/BootsCostLabel

#End of Day messages
@onready var out_money_label: Label = $BlackBG/VBoxContainer/OutMoneyLabel
@onready var current_food_cost: Label = $BlackBG/VBoxContainer/CurrentFoodCost
@onready var current_power_cost: Label = $BlackBG/VBoxContainer/CurrentPowerCost
@onready var current_water_cost: Label = $BlackBG/VBoxContainer/CurrentWaterCost
@onready var out_money_after_label: Label = $BlackBG/VBoxContainer/OutMoneyAfterLabel
@onready var statuses: RichTextLabel = $BlackBG/VBoxContainer/Statuses

var status_texts : Array[String] = [
	"You are [wave amp = 10.0]HUNGRY.[/wave] ",
	"[wave amp=8.0]Power[/wave] has been cut.",
	"[wave amp=8.0]Water[/wave] has been cut."
]

func _ready() -> void:
	money_label.text = "P " + str(GameManager.current_money)
	
	if GameManager.can_level >= watering_can_costs.size():
		purchase_watering_can.disabled = true
		purchase_watering_can.text = "MAX"
		watering_can_cost_label.text = ""
	else:
		watering_can_cost_label.text = "Costs: P " + str(watering_can_costs[GameManager.can_level])
	
	if GameManager.battery_level >= battery_costs.size():
		purchase_battery.disabled = true
		purchase_battery.text = "MAX"
		battery_cost_label.text = ""
	else:
		battery_cost_label.text = "Costs: P " + str(battery_costs[GameManager.battery_level])
	
	flashlight_cost_label.text = "Costs: P " + str(flashlight_cost)
	boots_cost_label.text = "Costs: P " + str(boots_cost)
	
	water_can_upgrade_bar.value = GameManager.can_level
	battery_upgrade_bar.value = GameManager.battery_level
	
	if GameManager.can_level == watering_can_costs.size():
		purchase_watering_can.disabled = true
		purchase_watering_can.text = "MAX"
		
	if GameManager.battery_level == battery_costs.size():
		purchase_battery.disabled = true
		purchase_battery.text = "MAX"
		
	if GameManager.bought_flashlight:
		purchase_flashlight.disabled = true
		purchase_flashlight.text = "PURCHASED"
		
	if GameManager.bought_boots:
		purchase_boots.disabled = true
		purchase_boots.text = "PURCHASED"
	
	
	MusicManager.change_music("day", 0.0)


func _on_fader_animation_finished(anim_name: StringName) -> void:
	if anim_name == "outro":
		GameManager.load_next_level(next_level_path)


func _on_leave_button_pressed() -> void:
	if GameManager.current_day != 0:
		MusicManager.stop_music()
	
	var food_short := false
	var power_short := false
	var water_short := false
	out_money_label.text = "You have\nP " + str(GameManager.current_money)
	# Food — paid immediately, no debt if you can't afford it
	if GameManager.current_money - food_cost < 0:
		food_short = true
		GameManager.is_hungry = true
		current_food_cost.text = "You couldn't afford food tonight."
	else:
		GameManager.current_money -= food_cost
		GameManager.is_hungry = false
		current_food_cost.text = "You purchased food for " + str(food_cost)

	# Electricity — day 3 free, otherwise pay off prior debt + today's bill
	if GameManager.current_day == 3:
		current_power_cost.text = "Voltek Corp Services will not charge you tonight."
	else:
		var power_due = electricity_cost + GameManager.voltek_debt
		if GameManager.current_money - power_due < 0:
			power_short = true
			GameManager.voltek_debt = power_due - GameManager.current_money
			GameManager.current_money = 0
			current_power_cost.text = "Voltek Corp Services has cut your power. You owe " + str(GameManager.voltek_debt) + "."
		else:
			GameManager.current_money -= power_due
			GameManager.voltek_debt = 0
			current_power_cost.text = "Voltek Corp Services has cut " + str(power_due)

	# Water — same pattern, no day-3 exception
	var water_due = water_cost + GameManager.seaqua_debt
	if GameManager.current_money - water_due < 0:
		water_short = true
		GameManager.seaqua_debt = water_due - GameManager.current_money
		GameManager.current_money = 0
		current_water_cost.text = "Seaqua Waterline has cut your water. You owe " + str(GameManager.seaqua_debt) + "."
	else:
		GameManager.current_money -= water_due
		GameManager.seaqua_debt = 0
		current_water_cost.text = "Seaqua Waterline has cut " + str(water_due)
	out_money_after_label.text = "Your current balance is now " + str(GameManager.current_money)

	# Status readout — this label was declared but never actually populated
	statuses.text = ""
	if food_short:
		statuses.text += status_texts[0] + "\n"
	if power_short:
		statuses.text += status_texts[1] + "\n"
	if water_short:
		statuses.text += status_texts[2] + "\n"

	#GameManager.current_day += 1
	fader.play("outro")


func _on_purchase_watering_can_pressed() -> void:
	if GameManager.can_level >= watering_can_costs.size():
		return
	var cost = watering_can_costs[GameManager.can_level]
	if GameManager.current_money - cost < 0:
		print("NOT ENOUGH MONEY!")
		return
	GameManager.current_money -= cost
	GameManager.can_level += 1
	water_can_upgrade_bar.value = GameManager.can_level
	money_label.text = "P " + str(GameManager.current_money)
	if GameManager.can_level == watering_can_costs.size():
		purchase_watering_can.disabled = true
		watering_can_cost_label.text = ""
		purchase_watering_can.text = "MAX"
	else:
		watering_can_cost_label.text = "Costs: P " + str(watering_can_costs[GameManager.can_level])


func _on_purchase_battery_pressed() -> void:
	if GameManager.battery_level >= battery_costs.size():
		return
	var cost = battery_costs[GameManager.battery_level]
	if GameManager.current_money - cost < 0:
		print("NOT ENOUGH MONEY!")
		return
	GameManager.current_money -= cost
	GameManager.battery_level += 1
	battery_upgrade_bar.value = GameManager.battery_level
	money_label.text = "P " + str(GameManager.current_money)
	if GameManager.battery_level == battery_costs.size():
		purchase_battery.disabled = true
		battery_cost_label.text = ""
		purchase_battery.text = "MAX"
	else:
		battery_cost_label.text = "Costs: P " + str(battery_costs[GameManager.battery_level])


func _on_purchase_flashlight_pressed() -> void:
	if GameManager.current_money - flashlight_cost < 0:
		print("NOT ENOUGH MONEY!")
		return
	
	GameManager.current_money -= flashlight_cost
	money_label.text = "P " + str(GameManager.current_money)
	
	purchase_flashlight.disabled = true
	purchase_flashlight.text = "PURCHASED"
	flashlight_cost_label.text = ""


func _on_purchase_boots_pressed() -> void:
	if GameManager.current_money - boots_cost < 0:
		print("NOT ENOUGH MONEY!")
		return
	
	GameManager.current_money -= boots_cost
	money_label.text = "P " + str(GameManager.current_money)
	
	purchase_boots.disabled = true
	purchase_boots.text = "PURCHASED"
	boots_cost_label.text = ""
