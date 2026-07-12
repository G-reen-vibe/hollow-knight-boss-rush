extends State
## Jumping (rising). Switches to Fall when velocity.y >= 0.


func enter(msg: Dictionary = {}, _previous: State = null) -> void:
        # If we entered without already setting jump velocity, set it now.
        if msg.get("from_coyote", false) and target.velocity.y >= 0.0:
                target.velocity.y = Player.JUMP_VELOCITY
        target.input_lock = false


func physics_process(_delta: float) -> void:
        var p := target as Player
        if p.velocity.y >= 0.0:
                p.state_machine.transition_to(&"Fall")
                return

        # Variable jump: release early -> cut the jump short.
        if Input.is_action_just_released("jump") and p.velocity.y < Player.JUMP_VELOCITY * 0.5:
                p.velocity.y = Player.JUMP_VELOCITY * 0.5

        # Double jump.
        if Input.is_action_just_pressed("jump") and p.can_double_jump:
                p.velocity.y = Player.DOUBLE_JUMP_VELOCITY
                p.can_double_jump = false
                _spawn_burst_at(p)
                return

        # Wall jump.
        if p.is_on_wall_surface() and p.wall_direction() != 0:
                if Input.is_action_just_pressed("jump") and p.has_wall_jump:
                        p.do_wall_jump()
                        p.state_machine.transition_to(&"WallJump")
                        return
                # Wall-slide.
                if (Input.is_action_pressed("move_left") and p.wall_direction() < 0) \
                        or (Input.is_action_pressed("move_right") and p.wall_direction() > 0):
                        p.velocity.y = min(p.velocity.y, Player.WALL_SLIDE_SPEED)
                        p.state_machine.transition_to(&"WallSlide")
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
