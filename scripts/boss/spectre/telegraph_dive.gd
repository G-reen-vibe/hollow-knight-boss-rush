extends State
## Telegraph a dive.
##
## DESIGN:
##   - Lock the dive direction at telegraph start (toward where the player is NOW).
##   - Show a red line indicator along the dive path so the player sees exactly
##     where the boss will go.
##   - Long telegraph (1.0s) — plenty of time to step aside.
##   - After the dive, the boss recovers in place (vulnerable).

@export var telegraph_duration: float = 1.0

var _timer: float = 0.0
var _dive_dir: Vector2 = Vector2.DOWN
var _line_marker: Node2D = null


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as Spectre
	b.velocity = Vector2.ZERO
	# Lock direction toward player's current position.
	if b.target != null and is_instance_valid(b.target):
		_dive_dir = (b.target.global_position - b.global_position).normalized()
	else:
		_dive_dir = Vector2.DOWN
	# Show line indicator along the dive path.
	var end_pos := b.global_position + _dive_dir * 600.0
	_line_marker = b.spawn_line_indicator(b.global_position, end_pos, Color(1, 0.4, 1.0, 0.4))
	# Visual: pulse glow.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "modulate", Color(2.5, 1.0, 1.0), telegraph_duration * 0.5)
	tw.tween_property(b.sprite, "modulate", Color(1.5, 0.5, 1.0), telegraph_duration * 0.5)
	tw.parallel().tween_property(b.sprite, "scale", Vector2(1.2, 1.2), telegraph_duration * 0.5)


func physics_process(delta: float) -> void:
	var b := target as Spectre
	_timer -= delta
	b.velocity = _dive_dir * 30.0  # Slow drift during telegraph.
	if _timer <= 0.0:
		if _line_marker != null:
			_line_marker.queue_free()
			_line_marker = null
		b.sprite.modulate = Color.WHITE
		b.sprite.scale = Vector2(1.0, 1.0)
		b.state_machine.transition_to(&"Dive")
		return
