extends State
## Horizontal dash across the arena. Ends when hitting a wall or after distance.

var _travelled: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_travelled = 0.0
	var b := target as Ravager
	# Activate contact hitbox (already active by default; ensure it's enabled).
	b.activate_contact_hitbox(true)
	# Stretch forward.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.2, 0.9), 0.1)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	var speed: float = b.charge_speed * (1.2 if b.current_phase >= 2 else 1.0)
	b.velocity.x = _charge_dir() * speed
	b.velocity.y = 0.0
	_travelled += abs(b.velocity.x) * delta
	# Hit wall?
	if b.is_on_wall():
		_end_charge(b)
		return
	# Travelled far enough?
	if _travelled >= b.charge_distance:
		_end_charge(b)
		return


func _charge_dir() -> int:
	var b := target as Ravager
	return b.facing


func _end_charge(b: Ravager) -> void:
	b.velocity.x = 0.0
	b.sprite.scale = Vector2(1.0, 1.0)
	# Small wall-hit feedback.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(0.9, 1.1), 0.1)
	tw.tween_property(b.sprite, "scale", Vector2(1.0, 1.0), 0.1)
	b.state_machine.transition_to(&"Recover")


func exit() -> void:
	var b := target as Ravager
	b.activate_contact_hitbox(true)  # Leave on (default state).
