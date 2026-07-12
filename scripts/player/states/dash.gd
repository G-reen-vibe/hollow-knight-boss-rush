extends State
## Dash (Mothwing Cloak). Brief horizontal burst with no gravity.


var _timer: float = 0.0
var _aerial: bool = false


func enter(msg: Dictionary = {}, _previous: State = null) -> void:
	var p := target as Player
	_timer = Player.DASH_DURATION
	_aerial = msg.get("aerial", false)
	p.input_lock = true
	p.start_dash()
	p.velocity.y = 0.0  # Cancel vertical momentum during dash.
	p.velocity.x = p.facing * Player.DASH_SPEED
	# Visual: scale sprite horizontally, add motion blur color tint.
	var tw := p.create_tween()
	tw.tween_property(p.sprite, "modulate:v", 1.3, 0.06)


func physics_process(delta: float) -> void:
	var p := target as Player
	_timer -= delta
	# Hold dash velocity (no friction during dash).
	p.velocity.x = p.facing * Player.DASH_SPEED
	p.velocity.y = 0.0

	if _timer <= 0.0:
		p.input_lock = false
		p.sprite.modulate.v = 1.0
		if p.is_on_floor():
			p.state_machine.transition_to(&"Idle")
		else:
			p.state_machine.transition_to(&"Fall")
		return

	# Cancel dash early into attack.
	if Input.is_action_just_pressed("attack"):
		var kind := &"side"
		if Input.is_action_pressed("ui_up"):
			kind = &"up"
		elif Input.is_action_pressed("ui_down") and not p.is_on_floor():
			kind = &"down"
		p.input_lock = false
		p.sprite.modulate.v = 1.0
		p.state_machine.transition_to(&"Attack", {"kind": kind, "aerial": not p.is_on_floor()})
		return


func exit() -> void:
	var p := target as Player
	p.input_lock = false
	p.sprite.modulate.v = 1.0
