extends State
## Telegraph a leap: crouch briefly, then jump toward the player.

@export var telegraph_duration: float = 0.4


var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as HollowSentinel
	b.velocity.x = 0.0
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.2, 0.75), telegraph_duration * 0.8)
	tw.parallel().tween_property(b.sprite, "modulate", Color(2, 0.7, 0.5), telegraph_duration * 0.4)


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	if _timer <= 0.0:
		var dir: float = b.horizontal_dir_to_target()
		if dir == 0.0:
			dir = float(b.facing)
		b.velocity.x = dir * b.leap_speed_x
		b.velocity.y = b.leap_speed_y
		b.sprite.scale = Vector2(0.9, 1.15)
		b.sprite.modulate = Color.WHITE
		b.state_machine.transition_to(&"Leap")
		return
