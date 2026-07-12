extends State
## Hurt state (after taking damage). Brief knockback + recovery.


var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = 0.25
	target.input_lock = true


func physics_process(delta: float) -> void:
	var p := target as Player
	_timer -= delta
	p.velocity.x = move_toward(p.velocity.x, 0.0, 1200.0 * delta)
	if _timer <= 0.0:
		p.input_lock = false
		p.state_machine.transition_to(&"Idle" if p.is_on_floor() else &"Fall")


func exit() -> void:
	target.input_lock = false
