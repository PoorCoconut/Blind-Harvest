extends State
class_name PlayerIdle_TopDown

func enterState():
	pass

func updateState(delta : float):
	PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, PLAYER.FRICTION * delta)
	
	if(Input.get_vector("move_left", "move_right", "move_up", "move_down")):
		#Transition to Run State
		transition.emit(self, "Run")
	
	PLAYER.move_and_slide()
