extends State
## After landing: the boss is STUCK for 0.7s — a free punish window for the
## player. This is the core "risk/reward" of the leap attack: if the player
## dodges, they get free hits; if they don't, they eat a shockwave.

var _timer: float = 0.7


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = 0.7
	var b := target as Ravager
	# Squash on landing.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.3, 0.7), 0.1)
	tw.tween_property(b.sprite, "scale", Vector2(1.0, 1.0), 0.18)
	# Visual cue: dim the sprite to show the boss is vulnerable.
	var tw2 := b.create_tween()
	tw2.tween_property(b.sprite, "modulate", Color(0.6, 0.6, 0.7), 0.15)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	_timer -= delta
	b.velocity.x = move_toward(b.velocity.x, 0.0, 1000.0 * delta)
	if _timer <= 0.0:
		b.sprite.modulate = Color.WHITE
		b.state_machine.transition_to(&"Recover")


func exit() -> void:
	target.sprite.modulate = Color.WHITE
