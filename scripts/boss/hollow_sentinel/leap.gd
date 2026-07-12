extends State
## Mid-air leap. On landing, spawn shockwave and transition to SlamLand.

var _has_landed: bool = false


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        _has_landed = false


func physics_process(_delta: float) -> void:
        var b := target as HollowSentinel
        if _has_landed:
                return
        if b.is_on_floor() and b.velocity.y >= 0.0:
                _do_landed(b)
        elif b.velocity.y > 0.0:
                b.sprite.rotation = lerp(b.sprite.rotation, b.facing * 0.2, 0.2)
        else:
                b.sprite.rotation = 0.0


func _do_landed(b: HollowSentinel) -> void:
        _has_landed = true
        b.velocity.x = 0.0
        b.velocity.y = 0.0
        b.sprite.rotation = 0.0
        # Shockwaves on both sides.
        _spawn_shockwave(b, 1)
        _spawn_shockwave(b, -1)
        # Squash effect.
        var tw := b.create_tween()
        tw.tween_property(b.sprite, "scale", Vector2(1.3, 0.7), 0.1)
        tw.tween_property(b.sprite, "scale", Vector2(1.0, 1.0), 0.18)
        b.state_machine.transition_to(&"SlamLand")


func _spawn_shockwave(b: HollowSentinel, dir: int) -> void:
        var area := Area2D.new()
        area.collision_layer = 0
        area.collision_mask = Globals.LAYER_PLAYER_HURTBOX
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(50, 14)
        shape.shape = rect
        area.add_child(shape)
        area.global_position = b.global_position + Vector2(dir * 45, 12)
        b.get_parent().add_child(area)
        var poly := Polygon2D.new()
        poly.color = Color(1.0, 0.85, 0.4, 0.7)
        poly.polygon = [Vector2(-25, -7), Vector2(25, -7), Vector2(25, 7), Vector2(-25, 7)]
        area.add_child(poly)
        area.call_deferred("set_monitoring", true)
        area.set_deferred("monitorable", false)
        await b.get_tree().process_frame
        for hurt in area.get_overlapping_areas():
                if hurt is Hurtbox and hurt.is_player:
                        hurt.apply_damage(1, 340.0, b.global_position)
                        break
        var tw := b.create_tween()
        tw.tween_property(poly, "color:a", 0.0, 0.25)
        tw.parallel().tween_property(area, "position:x", area.position.x + dir * 60.0, 0.25)
        tw.tween_callback(area.queue_free)
