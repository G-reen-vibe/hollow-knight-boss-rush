extends State
## Hover: Spectre's idle state. Floats above the player and gently bobs.
## When the timer expires, picks the next attack.


@export var hover_duration: float = 1.2

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
        # Hover above player.
        var desired := b.target.global_position + Vector2(0, b.hover_height)
        desired.x += sin(_bob_phase) * b.hover_amplitude
        var diff := desired - b.global_position
        b.velocity = diff * 4.0  # Strong pull to hover position.
        if _timer <= 0.0:
                var next: StringName = b.pick_next_action()
                if next != &"" and next != name:
                        b.state_machine.transition_to(next)
                else:
                        # Re-enter hover if no action picked.
                        _timer = hover_duration
