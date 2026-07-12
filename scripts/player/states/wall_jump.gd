extends State
## Brief state right after a wall jump. Air control locked for WALL_JUMP_LOCK.


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	target.input_lock = false


func physics_process(_delta: float) -> void:
	var p := target as Player
	if p.wall_jump_lock <= 0.0:
		if p.velocity.y < 0.0:
			p.state_machine.transition_to(&"Jump")
		else:
			p.state_machine.transition_to(&"Fall")
		return

	if Input.is_action_just_pressed("attack"):
		var kind := &"side"
		if Input.is_action_pressed("ui_up"):
			kind = &"up"
		elif Input.is_action_pressed("ui_down"):
			kind = &"down"
		p.state_machine.transition_to(&"Attack", {"kind": kind, "aerial": true})
		return
