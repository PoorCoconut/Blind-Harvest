extends Node

var CURRENT_WORLD_STATE : String = "Nothing"
const SAVE_PATH : String = "user://savegame.json"

var player_safe : bool = false
var current_day : int = 0
var current_money : int = 280

#Shop stuff
var can_level : int = 0
var battery_level : int = 0
var bought_flashlight : bool = false
var bought_boots : bool = false
var bought_fence : bool = false

#Gameplay stuff
var voltek_debt : int = 0 #If these variables aren't 0, it must mean the player is in debt
var seaqua_debt : int = 0
var is_hungry : bool = false

var _checkpoint_money: int = 0

func _ready() -> void:
	print("GAME MANAGER LOADED!")
	load_game()
	print("Game Manager Stats:\n",
	#"","\n",
	"Current Day: ", current_day,"\n",
	"Can Level: ", can_level,"\n",
	"Battery Level: ", battery_level,"\n",
	"Seaqua debt: " ,seaqua_debt,"\n",
	"Voltek debt: ", voltek_debt,"\n",)

##SAVE FILE LOGIC
const GAME_SAVE_PATH : String = "user://gamestate.json"

func save_game() -> void:
	var save_data = {
		"current_day": current_day,
		"current_money": current_money,
		"can_level": can_level,
		"battery_level": battery_level,
		"bought_flashlight": bought_flashlight,
		"bought_boots": bought_boots,
		"voltek_debt": voltek_debt,
		"seaqua_debt": seaqua_debt,
		"is_hungry": is_hungry
	}
	var file = FileAccess.open(GAME_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("Failed to open save file for writing: ", FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	print("Game state saved!")


func load_game() -> void:
	if not FileAccess.file_exists(GAME_SAVE_PATH):
		print("No game state save found. Starting fresh!")
		return

	var file = FileAccess.open(GAME_SAVE_PATH, FileAccess.READ)
	var json_text = file.get_as_text()
	var save_data = JSON.parse_string(json_text)

	if save_data == null:
		print("Save file was corrupted or unreadable.")
		return

	current_day = save_data.get("current_day", current_day)
	current_money = save_data.get("current_money", current_money)
	can_level = save_data.get("can_level", can_level)
	battery_level = save_data.get("battery_level", battery_level)
	bought_flashlight = save_data.get("bought_flashlight", bought_flashlight)
	bought_boots = save_data.get("bought_boots", bought_boots)
	voltek_debt = save_data.get("voltek_debt", voltek_debt)
	seaqua_debt = save_data.get("seaqua_debt", seaqua_debt)
	is_hungry = save_data.get("is_hungry", is_hungry)

	print("Game state loaded!")

func delete_save() -> void:
	# 1. Wipe the file from the drive
	if FileAccess.file_exists(GAME_SAVE_PATH):
		DirAccess.remove_absolute(GAME_SAVE_PATH)
		print("Save file permanently deleted.")
	else:
		print("No save file found to delete.")

	# 2. Wipe the runtime memory
	current_day = 0
	current_money = 280
	can_level = 0
	battery_level = 0
	bought_flashlight = false
	bought_boots = false
	voltek_debt = 0
	seaqua_debt = 0
	is_hungry = false
	
	print("In-memory stats reset to default.")

##Next Level Helper Functions
func load_next_level(next_level_path : String) -> void:
	await ScreenTransition.trans_in().finished
	LoadingScreen.load_level(next_level_path)

##Camera Helper Functions
func do_camera_shake(intensity:float, time:float):
	if get_tree().get_first_node_in_group("camera"):
		var camera = get_tree().get_first_node_in_group("camera")
		var camera_tween = get_tree().create_tween()
		camera_tween.tween_method(camera.startCameraShake, intensity, 1.0, time)
		camera.startCameraShake(intensity)
		await get_tree().create_timer(time).timeout
		camera.resetCameraOffset()

func move_camera_to_player(player_pos : Vector2):
	if get_tree().get_first_node_in_group("camera"):
		var camera = get_tree().get_first_node_in_group("camera")
		camera.moveCameraToEntity(player_pos)

##Gameplay Helpers
func add_money(amount: int) -> void:
	current_money += amount

func save_farm_checkpoint() -> void:
	_checkpoint_money = current_money

func load_farm_checkpoint() -> void:
	current_money = _checkpoint_money
