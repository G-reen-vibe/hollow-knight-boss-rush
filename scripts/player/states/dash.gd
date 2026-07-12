extends State
## Dash (Mothwing Cloak). Brief horizontal burst with no gravity.
## Grants i-frames for the first 60% of the dash so the player can dash
## THROUGH bosses and projectiles (Hollow Knight's core dodge mechanic).


var _timer: float = 0.0
var _aerial: bool = false


func enter(msg: Dictionary = {}, _previous: State = null) -> void:
        var p := target as Player
        _timer = Player.DASH_DURATION
        _aerial = msg.get("aerial", false)
        p.input_lock = true
        p.start_dash()
        p.velocity.y = 0.0  # Cancel vertical momentum during dash.
        p.velocity.x = p.facing * Player.DASH_SPEED
        # Grant i-frames for most of the dash duration.
        p.invincible = true
        p.hurtbox.set_deferred("monitorable", false)
        # Visual: scale sprite horizontally, add motion blur color tint.
        var tw := p.create_tween()
        tw.tween_property(p.sprite, "modulate:v", 1.3, 0.06)
        # Schedule end of i-frames slightly before dash ends.
        var iframe_time := Player.DASH_DURATION * 0.75
        var tw2 := p.create_tween()
        tw2.tween_interval(iframe_time)
        tw2.tween_callback(func():
                if p != null and is_instance_valid(p):
                        p.invincible = false
                        p.hurtbox.set_deferred("monitorable", true)
        )


func physics_process(delta: float) -> void:
        var p := target as Player
        _timer -= delta
        # Hold dash velocity (no friction during dash).
        p.velocity.x = p.facing * Player.DASH_SPEED
        p.velocity.y = 0.0

        if _timer <= 0.0:
                p.input_lock = false
                p.sprite.modulate.v = 1.0
                p.invincible = false
                p.hurtbox.set_deferred("monitorable", true)
                if p.is_on_floor():
                        p.state_machine.transition_to(&"Idle")
                else:
                        p.state_machine.transition_to(&"Fall")
                return

        # Cancel dash early into attack.
        if Input.is_action_just_pressed("attack"):
                var kind := &"side"
                if Input.is_action_pressed("ui_up"):
                        kind = &"up"
                elif Input.is_action_pressed("ui_down") and not p.is_on_floor():
                        kind = &"down"
                p.input_lock = false
                p.sprite.modulate.v = 1.0
                p.invincible = false
                p.hurtbox.set_deferred("monitorable", true)
                p.state_machine.transition_to(&"Attack", {"kind": kind, "aerial": not p.is_on_floor()})
                return


func exit() -> void:
        var p := target as Player
        p.input_lock = false
        p.sprite.modulate.v = 1.0
        p.invincible = false
        p.hurtbox.set_deferred("monitorable", true)
