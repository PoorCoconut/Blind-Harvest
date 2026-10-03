extends State
class_name CutENTITYIdle_TopDown

func enterState():
	pass

func updateState(delta : float):
	if ENTITY.walk_sfx.volume_db != -80.0:
		ENTITY.walk_sfx.volume_db = lerpf(ENTITY.walk_sfx.volume_db, -80.0, delta * 10)
	elif ENTITY.walk_sfx.volume_db == -80.0 and ENTITY.walk_sfx.playing == false:
		ENTITY.walk_sfx.stop()
	
	ENTITY.velocity = ENTITY.velocity.move_toward(Vector2.ZERO, ENTITY.FRICTION * delta)
	
	if(Input.get_vector("move_left", "move_right", "move_up", "move_down")):
		#Transition to Run State
		transition.emit(self, "Run")
	
	ENTITY.move_and_slide()
