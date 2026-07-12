extends State
## Telegraph a dive: glow and lock position briefly, then dive.


@export var telegraph_duration: float = 0.7

var _timer: float = 0.0
var _dive_dir: Vector2 = Vector2.DOWN


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as Spectre
	b.velocity = Vector2.ZERO
	# Lock direction toward player's current position.
	if b.target != null and is_instance_valid(b.target):
		_dive_dir = (b.target.global_position - b.global_position).normalized()
	else:
		_dive_dir = Vector2.DOWN
	# Visual: pulse glow + show a faint indicator line.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "modulate", Color(2.5, 1.0, 1.0), telegraph_duration * 0.5)
	tw.tween_property(b.sprite, "modulate", Color(1.5, 0.5, 1.0), telegraph_duration * 0.5)
	# Scale pulse.
	tw.parallel().tween_property(b.sprite, "scale", Vector2(1.2, 1.2), telegraph_duration * 0.5)


func physics_process(delta: float) -> void:
	var b := target as Spectre
	_timer -= delta
	# Slow drift down toward player during telegraph.
	b.velocity = _dive_dir * 40.0
	if _timer <= 0.0:
		b.sprite.modulate = Color.WHITE
		b.sprite.scale = Vector2(1.0, 1.0)
		b.state_machine.transition_to(&"Dive")
		return
