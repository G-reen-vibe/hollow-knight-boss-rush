extends State
## After landing: stuck for 0.6s (punish window).

var _timer: float = 0.6


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = 0.6
	var b := target as HollowSentinel
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "modulate", Color(0.6, 0.6, 0.7), 0.15)


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	b.velocity.x = move_toward(b.velocity.x, 0.0, 1000.0 * delta)
	if _timer <= 0.0:
		b.sprite.modulate = Color.WHITE
		b.state_machine.transition_to(&"Recover")


func exit() -> void:
	target.sprite.modulate = Color.WHITE
