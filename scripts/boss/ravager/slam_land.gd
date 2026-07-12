extends State
## After landing: brief pause, then recover.

var _timer: float = 0.4


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = 0.4
	var b := target as Ravager
	# Squash on landing.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.3, 0.7), 0.1)
	tw.tween_property(b.sprite, "scale", Vector2(1.0, 1.0), 0.18)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	_timer -= delta
	b.velocity.x = move_toward(b.velocity.x, 0.0, 1000.0 * delta)
	if _timer <= 0.0:
		b.state_machine.transition_to(&"Recover")
