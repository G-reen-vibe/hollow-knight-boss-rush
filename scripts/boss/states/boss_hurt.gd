extends State
## Hurt / flinch state. Brief stagger, then return to Idle.

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = (target as Boss).flinch_time
	target.velocity.x *= -0.4  # Brief recoil.


func physics_process(delta: float) -> void:
	var b := target as Boss
	_timer -= delta
	if b.is_on_floor():
		b.velocity.x = move_toward(b.velocity.x, 0.0, 800.0 * delta)
	if _timer <= 0.0:
		b.state_machine.transition_to(&"Idle")
