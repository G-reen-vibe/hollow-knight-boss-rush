extends State
## Brief recovery state after an attack. Then transitions back to Idle.

@export var duration: float = 0.85

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        _timer = duration
        # Bosses are vulnerable during recovery (visual: dim the sprite briefly).
        var tw := target.create_tween()
        tw.tween_property(target.sprite, "modulate", Color(0.7, 0.7, 0.8), 0.1)
        tw.tween_property(target.sprite, "modulate", Color.WHITE, 0.2)


func physics_process(delta: float) -> void:
        var b := target as Boss
        _timer -= delta
        if b.is_on_floor():
                b.velocity.x = move_toward(b.velocity.x, 0.0, 600.0 * delta)
        if _timer <= 0.0:
                b.state_machine.transition_to(b.idle_state_name)
