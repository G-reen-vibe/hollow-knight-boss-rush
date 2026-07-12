extends State
## Wall slide. Slows descent while pressing into a wall. Jump = wall jump.


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        target.input_lock = false


func physics_process(_delta: float) -> void:
        var p := target as Player

        if p.is_on_floor():
                p.state_machine.transition_to(&"Idle")
                return

        if not p.is_on_wall_surface() or p.wall_direction() == 0:
                p.state_machine.transition_to(&"Fall")
                return

        # Stop holding into the wall -> fall.
        var holding_wall := (Input.is_action_pressed("move_left") and p.wall_direction() < 0) \
                or (Input.is_action_pressed("move_right") and p.wall_direction() > 0)
        if not holding_wall:
                p.state_machine.transition_to(&"Fall")
                return

        # Slow descent.
        p.velocity.y = min(p.velocity.y, Player.WALL_SLIDE_SPEED)

        # Wall jump.
        if Input.is_action_just_pressed("jump") and p.has_wall_jump:
                p.do_wall_jump()
                p.state_machine.transition_to(&"WallJump")
                return

        # Drop off wall by pressing away.
        if Input.is_action_just_pressed("dash") and p.can_dash():
                p.state_machine.transition_to(&"Dash", {"aerial": true})
                return
