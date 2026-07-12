class_name SpectreProjectile
extends Area2D
## Spectre's projectile: a slow-moving orb that damages the player.

@export var speed: float = 320.0
@export var damage: int = 1
@export var lifetime: float = 3.0
@export var knockback_force: float = 240.0
@export var source_is_player: bool = false

var direction: Vector2 = Vector2.LEFT
var _lifetime_timer: float = 0.0


func _ready() -> void:
        collision_layer = 0
        collision_mask = Globals.LAYER_PLAYER_HURTBOX
        area_entered.connect(_on_area_entered)
        _spawn_visual()
        rotation = direction.angle()


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
        poly.color = Color(0.8, 0.5, 1.0, 0.9)
        poly.polygon = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
        add_child(poly)
        var glow := Polygon2D.new()
        glow.color = Color(1.0, 0.7, 1.0, 0.4)
        glow.polygon = [Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]
        add_child(glow)

        # Collision shape.
        var col := CollisionShape2D.new()
        var circle := CircleShape2D.new()
        circle.radius = 10.0
        col.shape = circle
        add_child(col)
