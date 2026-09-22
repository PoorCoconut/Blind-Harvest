extends State
class_name PlayerIdle_TopDown

func enterState():
	pass

func updateState(delta : float):
	if PLAYER.walk_sfx.volume_db != -80.0:
		PLAYER.walk_sfx.volume_db = lerpf(PLAYER.walk_sfx.volume_db, -80.0, delta * 10)
	elif PLAYER.walk_sfx.volume_db == -80.0 and PLAYER.walk_sfx.playing == false:
		PLAYER.walk_sfx.stop()
	
	PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, PLAYER.FRICTION * delta)
	
	if(Input.get_vector("move_left", "move_right", "move_up", "move_down")):
		#Transition to Run State
		transition.emit(self, "Run")
	
	PLAYER.move_and_slide()
