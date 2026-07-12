extends State
## Approach the player on the ground. Transitions to Idle (decision) periodically
## or when in attack range.

@export var approach_time: float = 0.6

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = approach_time


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	if b.target == null or not is_instance_valid(b.target):
		return
	var dist := b.distance_to_target()
	if dist < 100.0 or _timer <= 0.0:
		b.state_machine.transition_to(&"Idle")
		return
	b.move_toward_target(b.approach_speed, delta)
