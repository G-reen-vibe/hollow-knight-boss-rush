extends State
## Telegraph a slash: rear back, then activate a wide melee hitbox in front.

@export var telegraph_duration: float = 0.50
@export var active_duration: float = 0.20


var _timer: float = 0.0
var _phase: int = 0  # 0 = telegraph, 1 = active


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
        _timer = telegraph_duration
        _phase = 0
        var b := target as HollowSentinel
        b.velocity.x = 0.0
        # Face player.
        var dir: float = b.horizontal_dir_to_target()
        if dir != 0.0:
                b.facing = int(sign(dir))
        var tw := b.create_tween()
        tw.tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration)
        tw.parallel().tween_property(b.sprite, "modulate", Color(2, 0.7, 0.5), telegraph_duration * 0.5)


func physics_process(delta: float) -> void:
        var b := target as HollowSentinel
        _timer -= delta
        if _phase == 0:
                # Telegraph done -> active.
                if _timer <= 0.0:
                        _phase = 1
                        _timer = active_duration
                        b.sprite.scale = Vector2(1.2, 0.9)
                        b.sprite.modulate = Color.WHITE
                        _spawn_slash_hitbox(b)
        else:
                if _timer <= 0.0:
                        b.sprite.scale = Vector2(1.0, 1.0)
                        b.state_machine.transition_to(&"Recover")


func _spawn_slash_hitbox(b: HollowSentinel) -> void:
        var area := Area2D.new()
        area.collision_layer = 0
        area.collision_mask = Globals.LAYER_PLAYER_HURTBOX
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(80, 50)
        shape.shape = rect
        area.add_child(shape)
        area.global_position = b.global_position + Vector2(b.facing * 50, 0)
        b.get_parent().add_child(area)
        # Visual slash.
        var poly := Polygon2D.new()
        poly.color = Color(1.0, 1.0, 1.0, 0.7)
        poly.polygon = [Vector2(-40, -25), Vector2(40, -25), Vector2(40, 25), Vector2(-40, 25)]
        area.add_child(poly)
        area.call_deferred("set_monitoring", true)
        area.set_deferred("monitorable", false)
        await b.get_tree().process_frame
        for hurt in area.get_overlapping_areas():
                if hurt is Hurtbox and hurt.is_player:
                        hurt.apply_damage(1, 360.0, b.global_position)
                        break
        var tw := b.create_tween()
        tw.tween_property(poly, "color:a", 0.0, 0.15)
        tw.parallel().tween_property(poly, "scale", Vector2(1.5, 1.0), 0.15)
        tw.tween_callback(area.queue_free)
