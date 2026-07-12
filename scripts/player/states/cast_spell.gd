extends State
## Cast spell: Vengeful Spirit (forward projectile). Locks movement briefly.

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	var p := target as Player
	_timer = Player.SPELL_DURATION
	p.input_lock = true
	p.velocity.x = 0.0
	# Spawn the projectile a bit into the cast so it visually leaves the hand.
	# We'll spawn at ~30% of the duration.
	var tw := p.create_tween()
	tw.tween_interval(Player.SPELL_DURATION * 0.25)
	tw.tween_callback(p.spawn_spell_projectile)
	# Visual flash.
	tw.parallel().tween_property(p.sprite, "modulate", Color(0.7, 0.9, 1.0), 0.05)
	tw.tween_property(p.sprite, "modulate", Color.WHITE, 0.20)


func physics_process(delta: float) -> void:
	var p := target as Player
	_timer -= delta
	# Apply gravity during cast (small).
	p.velocity.y += Player.GRAVITY * delta
	p.velocity.y = min(p.velocity.y, Player.MAX_FALL_SPEED)
	if _timer <= 0.0:
		p.input_lock = false
		if p.is_on_floor():
			p.state_machine.transition_to(&"Idle")
		else:
			p.state_machine.transition_to(&"Fall")


func exit() -> void:
	target.input_lock = false
