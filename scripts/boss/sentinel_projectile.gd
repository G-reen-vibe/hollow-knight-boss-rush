class_name SentinelProjectile
extends Area2D
## Hollow Sentinel's projectile: a fast-moving nail-like shard.

@export var speed: float = 360.0
@export var damage: int = 1
@export var lifetime: float = 2.5
@export var knockback_force: float = 240.0

var direction: Vector2 = Vector2.LEFT
var _lifetime_timer: float = 0.0


func _ready() -> void:
        collision_layer = 0
        collision_mask = Globals.LAYER_PLAYER_HURTBOX
        area_entered.connect(_on_area_entered)
        rotation = direction.angle()
        _spawn_visual()


func _process(delta: float) -> void:
        _lifetime_timer += delta
        if _lifetime_timer >= lifetime:
                queue_free()
                return
        global_position += direction * speed * delta


func _on_area_entered(other: Area2D) -> void:
        if other is Hurtbox and other.is_player:
                other.apply_damage(damage, knockback_force, global_position)
                queue_free()


func _spawn_visual() -> void:
        var poly := Polygon2D.new()
        poly.color = Color(0.95, 0.95, 1.0, 0.95)
        poly.polygon = [Vector2(-12, -4), Vector2(12, 0), Vector2(-12, 4), Vector2(-8, 0)]
        add_child(poly)
        var glow := Polygon2D.new()
        glow.color = Color(0.8, 0.9, 1.0, 0.4)
        glow.polygon = [Vector2(-18, -8), Vector2(14, 0), Vector2(-18, 8), Vector2(-12, 0)]
        add_child(glow)
        var col := CollisionShape2D.new()
        var circle := CircleShape2D.new()
        circle.radius = 8.0
        col.shape = circle
        add_child(col)
