extends State
class_name PlayerRun_TopDown

func enterState():
	pass

func updateState(delta: float):
	if PLAYER.walk_sfx.volume_db != 0.0:
		if PLAYER.walk_sfx.playing == false:
			PLAYER.walk_sfx.playing = true
		PLAYER.walk_sfx.volume_db = lerpf(PLAYER.walk_sfx.volume_db, 0.0, delta * 10)
	movement(delta)

func movement(delta: float):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		PLAYER.CUR_DIR = direction
		PLAYER.velocity = PLAYER.velocity.move_toward(direction * PLAYER.MAX_SPEED, PLAYER.ACCELERATION * delta)
	else:
		PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, PLAYER.FRICTION * delta)
	
	PLAYER.move_and_slide()
	
	if direction == Vector2.ZERO and PLAYER.velocity.length() < 1.0:
		transition.emit(self, "Idle")
