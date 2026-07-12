extends State
## Dead state. Plays a fade-out; signals up to the BossRush manager.


var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = 1.2
	target.input_lock = true
	target.velocity = Vector2.ZERO
	# Visual: fade out and shrink.
	var tw := target.create_tween()
	tw.tween_property(target.sprite, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(target.sprite, "scale", Vector2(0.6, 0.6), 1.0)


func physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		# Let the BossRush manager handle respawn / game over.
		pass
