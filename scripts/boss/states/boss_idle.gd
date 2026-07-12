extends State
## Boss idle / decision state.
##
## DESIGN: The boss does NOT walk into the player during idle. It maintains a
## comfortable distance (~220px) so the player always has room to breathe.
## After a brief pause, it picks the next attack.

@export var min_idle: float = 0.5
@export var max_idle: float = 1.0
@export var preferred_distance: float = 220.0
@export var distance_tolerance: float = 40.0
@export var reposition_speed: float = 90.0

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        _timer = randf_range(min_idle, max_idle)


func physics_process(delta: float) -> void:
        var b := target as Boss
        _timer -= delta
        if b.target == null or not is_instance_valid(b.target):
                return
        # Reposition to maintain preferred distance — but DON'T crowd the player.
        var dist := b.distance_to_target()
        var dir := b.horizontal_dir_to_target()
        if dist < preferred_distance - distance_tolerance:
                # Too close — back away from the player.
                b.velocity.x = move_toward(b.velocity.x, -dir * reposition_speed, 800.0 * delta)
        elif dist > preferred_distance + distance_tolerance:
                # Too far — approach slowly.
                b.velocity.x = move_toward(b.velocity.x, dir * reposition_speed, 800.0 * delta)
        else:
                # In the sweet spot — hold position.
                b.velocity.x = move_toward(b.velocity.x, 0.0, 1000.0 * delta)
        # Friction on ground.
        if b.is_on_floor():
                b.velocity.x = move_toward(b.velocity.x, 0.0, 600.0 * delta)
        if _timer <= 0.0:
                var next: StringName = b.pick_next_action()
                if next != &"" and next != name:
                        b.state_machine.transition_to(next)
                else:
                        _timer = randf_range(min_idle, max_idle)
