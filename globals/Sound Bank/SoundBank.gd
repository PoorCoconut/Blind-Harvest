extends Node

#Store sound effects here...
var sfx_dict : Dictionary = {
	#Player
	"switch_item" : preload("uid://bjijy102bvn7x"),
	"f_light_on" : preload("uid://bn5a8hnv4mp63"),
	"f_light_off" : preload("uid://mida4lmec3wj"),
	"f_light_charged" : preload("uid://d36mpcho4e3ee"),
	
	
	#Ambiance
	"amb_horror" : preload("uid://elu5b7uru45u"),
	"amb_horror2" : preload("uid://cn5bssgip8fqt"),
	"amb_horror3" : preload("uid://cqxlr1wt3i4fc"),
	"amb_elk" : preload("uid://u52bctpqptdg"),
	"amb_elk2" : preload("uid://cvxsv87251owk"),
	
	#Gameplay
	"halfway" : preload("uid://dfqaixofmtviu"),
	"plant_grow" : preload("uid://db15gb87fhem8"),
	
	#Enemy
	"enemy_alert" : preload("uid://cbmxbm5nfh75r"),
	"growl" : preload("uid://c5albgm2i51tp"),
}

#Here is an example:
#"swing_sword": preload("res://audio/sfx/swing.ogg"),
#"jump": preload("res://audio/sfx/jump.ogg"),
#"slide_friction": preload("res://audio/sfx/friction.wav")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_sfx(sfx_name : String, spawn_pos : Vector2 = Vector2.ZERO, rand_low_range : float = 0.7, rand_high_range : float = 1.2, max_dist : float = 4096) -> void:
	#Check if sound exists
	if not sfx_dict.has(sfx_name):
		push_error("GameManager: SFX '" + sfx_name + "' not found in dictionary.")
		return
		
	#Create an audio player
	var sfx_player = AudioStreamPlayer2D.new()
	
	#Give it the specific sound from the dictionary and set its position
	sfx_player.stream = sfx_dict[sfx_name]
	sfx_player.global_position = spawn_pos
	sfx_player.pitch_scale = randf_range(rand_low_range, rand_high_range) #Change these values for more variation of the sounds
	sfx_player.bus = "SFX"
	sfx_player.max_distance = max_dist
	
	#Add it to the Game, play it, and queue_free when done
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()
