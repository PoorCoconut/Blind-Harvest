extends State
class_name CutENTITYRun_TopDown

func enterState():
	pass

func updateState(delta: float):
	if ENTITY.walk_sfx.volume_db != 0.0:
		if ENTITY.walk_sfx.playing == false:
			ENTITY.walk_sfx.playing = true
		ENTITY.walk_sfx.volume_db = lerpf(ENTITY.walk_sfx.volume_db, 5.0, delta * 10)
	movement(delta)

func movement(delta: float):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		ENTITY.CUR_DIR = direction
		ENTITY.velocity = ENTITY.velocity.move_toward(direction * ENTITY.MAX_SPEED, ENTITY.ACCELERATION * delta)
	else:
		ENTITY.velocity = ENTITY.velocity.move_toward(Vector2.ZERO, ENTITY.FRICTION * delta)
	
	ENTITY.move_and_slide()
	
	if direction == Vector2.ZERO and ENTITY.velocity.length() < 1.0:
		transition.emit(self, "Idle")
