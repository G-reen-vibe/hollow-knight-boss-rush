class_name Hitbox
extends Area2D
## A damage-dealing area.
##
## Place on a node that should deal damage when its hitbox overlaps a Hurtbox.
## Enable/disable the underlying CollisionShape2D to toggle the hitbox.

@export var damage: int = 1
@export var knockback_force: float = 320.0
@export var hit_cooldown: float = 0.4  # Per-target hit cooldown.
@export var hits_player: bool = false  # If true, this hitbox damages the player.
@export var hits_enemies: bool = true

# target_node -> time remaining until it can be hit again
var _cooldowns: Dictionary[Node, float] = {}


func _ready() -> void:
        monitoring = true
        monitorable = true
        if hits_player and not hits_enemies:
                collision_mask = Globals.LAYER_PLAYER_HURTBOX
        elif hits_enemies and not hits_player:
                collision_mask = Globals.LAYER_ENEMY_HURTBOX
        else:
                collision_mask = Globals.LAYER_PLAYER_HURTBOX | Globals.LAYER_ENEMY_HURTBOX
        collision_layer = 0
        area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
        # Tick down cooldowns and prune finished ones.
        var to_remove: Array[Node] = []
        for target_node in _cooldowns:
                _cooldowns[target_node] -= delta
                if _cooldowns[target_node] <= 0.0:
                        to_remove.append(target_node)
        for t in to_remove:
                _cooldowns.erase(t)


func _on_area_entered(other: Area2D) -> void:
        if other is Hurtbox:
                var hurtbox: Hurtbox = other
                # Only hit valid targets.
                if hits_player and not hurtbox.is_player:
                        return
                if hits_enemies and not hurtbox.is_enemy:
                        return
                if _cooldowns.has(hurtbox):
                        return
                _cooldowns[hurtbox] = hit_cooldown
                hurtbox.take_hit(self)
                # Spawn hit effect at the contact point.
                _spawn_hit_effect(other.global_position)


func _spawn_hit_effect(at_pos: Vector2) -> void:
        # Brief white flash + particle burst.
        var fx := Node2D.new()
        fx.global_position = at_pos
        get_tree().current_scene.add_child(fx)
        # Flash circle.
        var flash := Polygon2D.new()
        flash.color = Color(1, 1, 1, 0.9)
        flash.polygon = [Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)]
        fx.add_child(flash)
        # Spark particles (simple lines radiating outward).
        for i in 6:
                var spark := Polygon2D.new()
                spark.color = Color(1, 0.95, 0.7, 0.9)
                var angle := (float(i) / 6.0) * TAU + randf_range(-0.3, 0.3)
                var len := randf_range(12, 22)
                spark.polygon = [Vector2(0, -1.5), Vector2(len, 0), Vector2(0, 1.5)]
                spark.rotation = angle
                fx.add_child(spark)
                var tw := fx.create_tween()
                tw.tween_property(spark, "position", Vector2(cos(angle), sin(angle)) * 28, 0.18).set_ease(Tween.EASE_OUT)
        # Animate the flash.
        var tw := fx.create_tween()
        tw.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.1)
        tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
        tw.tween_callback(fx.queue_free)


func clear_cooldowns() -> void:
        _cooldowns.clear()
