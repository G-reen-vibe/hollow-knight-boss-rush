extends State
## Attack state (nail slash). Supports side / up / down (pogo) variants.

var _timer: float = 0.0
var _kind: StringName = &"side"
var _aerial: bool = false
var _pogoed: bool = false


func enter(msg: Dictionary = {}, _previous: State = null) -> void:
	var p := target as Player
	_kind = msg.get("kind", &"side")
	_aerial = msg.get("aerial", false)
	_timer = Player.ATTACK_DURATION
	_pogoed = false
	p.input_lock = true  # No movement during attack (air control still keeps momentum).
	# Activate the matching hitbox.
	p.activate_attack(_kind)
	# Snap facing on side attacks.
	if _kind == &"side":
		p.facing = int(sign(Input.get_axis("move_left", "move_right"))) if Input.get_axis("move_left", "move_right") != 0 else p.facing
	# Brief lunge forward on side attack.
	if _kind == &"side" and p.is_on_floor():
		p.velocity.x += p.facing * 60.0
	# Visual squash/stretch.
	var tw := p.create_tween()
	match _kind:
		&"side":
			tw.tween_property(p.sprite, "scale", Vector2(1.2, 0.85), 0.05)
		&"up":
			tw.tween_property(p.sprite, "scale", Vector2(0.85, 1.2), 0.05)
		&"down":
			tw.tween_property(p.sprite, "scale", Vector2(0.85, 1.2), 0.05)
	tw.tween_property(p.sprite, "scale", Vector2(1.0, 1.0), 0.10)


func physics_process(delta: float) -> void:
	var p := target as Player
	_timer -= delta

	# Apply gravity if aerial.
	if _aerial and _kind != &"down":
		p.velocity.y += Player.GRAVITY * delta
		p.velocity.y = min(p.velocity.y, Player.MAX_FALL_SPEED)

	# Down-attack pogo: if we hit something, bounce up.
	if _kind == &"down" and not _pogoed:
		if p.down_attack_hitbox.get_overlapping_areas().size() > 0:
			_pogoed = true
			p.velocity.y = -360.0
		elif p.down_attack_hitbox.get_overlapping_bodies().size() > 0:
			_pogoed = true
			p.velocity.y = -360.0
		else:
			# Apply gravity during down attack.
			p.velocity.y += Player.GRAVITY * delta
			p.velocity.y = min(p.velocity.y, Player.MAX_FALL_SPEED)

	if _timer <= 0.0:
		p.deactivate_attacks()
		p.input_lock = false
		if p.is_on_floor():
			p.state_machine.transition_to(&"Idle")
		else:
			p.state_machine.transition_to(&"Fall")
		return

	# Cancel into another attack (combo) only on ground.
	if Input.is_action_just_pressed("attack") and p.is_on_floor() and _timer < Player.ATTACK_DURATION * 0.5:
		p.deactivate_attacks()
		var kind := &"side"
		if Input.is_action_pressed("ui_up"):
			kind = &"up"
		p.state_machine.transition_to(&"Attack", {"kind": kind, "aerial": false})
		return


func exit() -> void:
	var p := target as Player
	p.deactivate_attacks()
	p.input_lock = false
