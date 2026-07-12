extends State
## Telegraph a shot: charge briefly, then fire 3 projectiles at the player.

@export var telegraph_duration: float = 0.70


var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        _timer = telegraph_duration
        var b := target as HollowSentinel
        b.velocity.x = 0.0
        var tw := b.create_tween()
        tw.tween_property(b.sprite, "modulate", Color(1.5, 1.0, 2.0), telegraph_duration * 0.7)


func physics_process(delta: float) -> void:
        var b := target as HollowSentinel
        _timer -= delta
        if _timer <= 0.0:
                b.sprite.modulate = Color.WHITE
                # Phase 2 fires 3, phase 3 fires 5.
                var count: int = 5 if b.current_phase >= 3 else 3
                b.spawn_projectiles(count)
                b.state_machine.transition_to(&"Recover")
                return
