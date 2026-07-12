extends State
## Telegraph a charge: rear back briefly, then dash horizontally.

@export var telegraph_duration: float = 0.70

var _timer: float = 0.0
var _charge_dir: int = 1


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        _timer = telegraph_duration
        var b := target as Ravager
        b.velocity.x = 0.0
        # Face the player.
        var dir: float = b.horizontal_dir_to_target()
        _charge_dir = int(sign(dir)) if dir != 0.0 else b.facing
        b.facing = _charge_dir
        # Visual: lean back.
        var tw := b.create_tween()
        tw.tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration * 0.8)
        tw.parallel().tween_property(b.sprite, "modulate", Color(2, 0.6, 0.4), telegraph_duration * 0.4)


func physics_process(delta: float) -> void:
        var b := target as Ravager
        _timer -= delta
        if _timer <= 0.0:
                b.sprite.scale = Vector2(1.0, 1.0)
                b.sprite.modulate = Color.WHITE
                b.state_machine.transition_to(&"Charge")
                return
