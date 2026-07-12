extends State
## Hover: Spectre's idle state.
##
## DESIGN: Floats at a fixed height above the arena center (NOT directly above
## the player), gently bobbing. This gives the player room to move and attack.
## Picks the next attack after a delay.

@export var hover_duration: float = 1.0
@export var hover_height: float = -160.0  # Above the floor.
@export var hover_amplitude: float = 30.0
@export var track_factor: float = 0.3  # How much it follows the player (0=none, 1=full).

var _timer: float = 0.0
var _bob_phase: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = hover_duration
	_bob_phase = randf() * TAU


func physics_process(delta: float) -> void:
	var b := target as Spectre
	_timer -= delta
	_bob_phase += delta * 2.0
	if b.target == null or not is_instance_valid(b.target):
		return
	# Hover above the floor, partially tracking the player's X.
	var desired_x: float = lerp(b.global_position.x, b.target.global_position.x, track_factor * delta * 2.0)
	var desired := Vector2(desired_x + sin(_bob_phase) * b.hover_amplitude, b.hover_height)
	var diff := desired - b.global_position
	b.velocity = diff * 3.0
	if _timer <= 0.0:
		var next: StringName = b.pick_next_action()
		if next != &"" and next != name:
			b.state_machine.transition_to(next)
		else:
			_timer = hover_duration
