extends State
## Dead state: plays a death animation and removes the boss from the tree
## after a delay. Emits `boss_died` (already emitted by Boss._die()).

var _timer: float = 1.4


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	target.input_lock = true if "input_lock" in target else false
	target.velocity = Vector2.ZERO
	# Visual: flash + shrink + fade.
	var tw := target.create_tween()
	for i in 4:
		tw.tween_property(target.sprite, "modulate", Color(3, 3, 3), 0.08)
		tw.tween_property(target.sprite, "modulate", Color.WHITE, 0.08)
	tw.tween_property(target.sprite, "scale", Vector2(0.4, 0.4), 0.8)
	tw.parallel().tween_property(target.sprite, "modulate:a", 0.0, 0.8)


func physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		target.queue_free()
