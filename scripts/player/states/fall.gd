extends State
## Falling (descending). Handles double jump, wall slide, and air actions.


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        target.input_lock = false


func physics_process(_delta: float) -> void:
        var p := target as Player

        # Landed.
        if p.is_on_floor():
                p.can_double_jump = true
                p.state_machine.transition_to(&"Idle")
                return

        # Coyote jump (just walked off a ledge).
        if p.consume_coyote() and p.consume_jump_buffer():
                p.velocity.y = Player.JUMP_VELOCITY
                p.state_machine.transition_to(&"Jump")
                return

        # Double jump.
        if Input.is_action_just_pressed("jump") and p.can_double_jump:
                p.velocity.y = Player.DOUBLE_JUMP_VELOCITY
                p.can_double_jump = false
                _spawn_burst_at(p)
                p.state_machine.transition_to(&"Jump", {"from_double": true})
                return

        # Wall slide detection.
        if p.is_on_wall_surface() and p.wall_direction() != 0 and p.velocity.y > 0.0:
                var holding_wall := (Input.is_action_pressed("move_left") and p.wall_direction() < 0) \
                        or (Input.is_action_pressed("move_right") and p.wall_direction() > 0)
                if holding_wall:
                        p.velocity.y = min(p.velocity.y, Player.WALL_SLIDE_SPEED)
                        p.state_machine.transition_to(&"WallSlide")
                        return

        # Wall jump from fall.
        if Input.is_action_just_pressed("jump") and p.is_on_wall_surface() and p.has_wall_jump:
                p.do_wall_jump()
                p.state_machine.transition_to(&"WallJump")
                return

        # Air attack.
        if Input.is_action_just_pressed("attack"):
                var kind := &"side"
                if Input.is_action_pressed("ui_up"):
                        kind = &"up"
                elif Input.is_action_pressed("ui_down"):
                        kind = &"down"
                p.state_machine.transition_to(&"Attack", {"kind": kind, "aerial": true})
                return

        # Air dash.
        if Input.is_action_just_pressed("dash") and p.can_dash():
                p.state_machine.transition_to(&"Dash", {"aerial": true})
                return

        # Spell in air.
        if Input.is_action_just_pressed("cast_spell") and p.has_spell and p.consume_soul(Globals.SPELL_SOUL_COST):
                p.state_machine.transition_to(&"CastSpell")
                return


func _spawn_burst_at(p: Player) -> void:
        var tw := p.create_tween()
        tw.tween_property(p.sprite, "scale", Vector2(0.85, 1.15), 0.08)
        tw.tween_property(p.sprite, "scale", Vector2(1.0, 1.0), 0.10)
