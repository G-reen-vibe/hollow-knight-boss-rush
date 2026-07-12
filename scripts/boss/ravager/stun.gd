extends State
## Stun state: the boss hit a wall during charge and is stunned for 1.0s.
## This is a BIG punish window for the player — the boss is fully vulnerable
## and can't attack or move.

@export var duration: float = 1.0

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = duration
	var b := target as Ravager
	b.velocity = Vector2.ZERO
	# Visual: dim + dizzy sway.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "modulate", Color(0.5, 0.5, 0.6), 0.2)
	# Sway back and forth.
	var tw2 := b.create_tween().set_loops(4)
	tw2.tween_property(b.sprite, "rotation", 0.15, 0.15)
	tw2.tween_property(b.sprite, "rotation", -0.15, 0.15)
	tw2.tween_property(b.sprite, "rotation", 0.0, 0.1)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	_timer -= delta
	b.velocity.x = move_toward(b.velocity.x, 0.0, 1000.0 * delta)
	if _timer <= 0.0:
		b.sprite.modulate = Color.WHITE
		b.sprite.rotation = 0.0
		b.state_machine.transition_to(&"Recover")


func exit() -> void:
	target.sprite.modulate = Color.WHITE
	target.sprite.rotation = 0.0
