extends State
## Idle / Run / grounded wait state.

func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        target.input_lock = false


func physics_process(delta: float) -> void:
        var p := target as Player
        if not p.is_on_floor():
                p.state_machine.transition_to(&"Fall")
                return

        # Jump (buffered).
        if p.consume_jump_buffer():
                p.velocity.y = Player.JUMP_VELOCITY
                p.can_double_jump = true
                p.state_machine.transition_to(&"Jump")
                return

        # Attack (with direction modifier).
        if Input.is_action_just_pressed("attack"):
                var kind := &"side"
                if Input.is_action_pressed("ui_up"):
                        kind = &"up"
                p.state_machine.transition_to(&"Attack", {"kind": kind})
                return

        # Dash.
        if Input.is_action_just_pressed("dash") and p.can_dash():
                p.state_machine.transition_to(&"Dash")
                return

        # Cast spell.
        if Input.is_action_just_pressed("cast_spell") and p.has_spell and p.consume_soul(Globals.SPELL_SOUL_COST):
                p.state_machine.transition_to(&"CastSpell")
                return

        # Heal.
        if Input.is_action_just_pressed("heal") and p.has_heal and p.soul >= Globals.HEAL_SOUL_COST and p.health < p.max_health:
                p.state_machine.transition_to(&"Heal")
                return
