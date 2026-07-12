extends State
## After landing: brief pause, then recover.

var _timer: float = 0.35


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = 0.35


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	b.velocity.x = move_toward(b.velocity.x, 0.0, 1000.0 * delta)
	if _timer <= 0.0:
		b.state_machine.transition_to(&"Recover")
