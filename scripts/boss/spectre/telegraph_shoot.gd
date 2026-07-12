extends State
## Telegraph a shot: charge briefly, then fire projectiles.


@export var telegraph_duration: float = 0.55

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as Spectre
	b.velocity = Vector2.ZERO
	# Visual: brighten and shrink slightly.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "modulate", Color(1.5, 1.0, 2.0), telegraph_duration * 0.7)
	tw.parallel().tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration * 0.7)


func physics_process(delta: float) -> void:
	var b := target as Spectre
	_timer -= delta
	# Hold position above the player.
	if b.target != null and is_instance_valid(b.target):
		var desired := b.target.global_position + Vector2(0, b.hover_height)
		b.velocity = (desired - b.global_position) * 2.0
	if _timer <= 0.0:
		b.sprite.modulate = Color.WHITE
		b.sprite.scale = Vector2(1.0, 1.0)
		b.spawn_projectiles()
		b.state_machine.transition_to(&"Recover")
		return
