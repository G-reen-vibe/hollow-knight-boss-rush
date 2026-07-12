extends State
## Focus / Heal. Standing still and channeling to heal one mask.

var _timer: float = 0.0
var _completed: bool = false


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	var p := target as Player
	if not p.consume_soul(Globals.HEAL_SOUL_COST):
		p.state_machine.transition_to(&"Idle")
		return
	_timer = Player.HEAL_DURATION
	_completed = false
	p.input_lock = true
	p.velocity.x = 0.0
	# Visual: pulse the sprite.
	var tw := p.create_tween().set_loops(3)
	tw.tween_property(p.sprite, "modulate", Color(0.8, 1.0, 0.9), 0.18)
	tw.tween_property(p.sprite, "modulate", Color.WHITE, 0.18)


func physics_process(delta: float) -> void:
	var p := target as Player
	_timer -= delta
	# Apply gravity.
	p.velocity.y += Player.GRAVITY * delta
	p.velocity.y = min(p.velocity.y, Player.MAX_FALL_SPEED)

	# Cancel on movement or attack input.
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("dash") \
		or Input.is_action_just_pressed("jump") or abs(Input.get_axis("move_left", "move_right")) > 0.1:
		p.input_lock = false
		p.state_machine.transition_to(&"Idle" if p.is_on_floor() else &"Fall")
		return

	if _timer <= 0.0 and not _completed:
		_completed = true
		p.heal_one()
		# Spawn heal particles (just a tween).
		var tw2 := p.create_tween()
		tw2.tween_property(p.sprite, "scale", Vector2(1.15, 1.15), 0.1)
		tw2.tween_property(p.sprite, "scale", Vector2(1.0, 1.0), 0.15)
		tw2.tween_callback(func():
			p.input_lock = false
			p.state_machine.transition_to(&"Idle" if p.is_on_floor() else &"Fall")
		)


func exit() -> void:
	target.input_lock = false
