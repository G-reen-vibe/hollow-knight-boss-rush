class_name VengefulSpirit
extends Area2D
## Player's basic spell: a forward-moving projectile that pierces one enemy
## and grants soul on hit. Hollow Knight's "Vengeful Spirit".

@export var speed: float = 520.0
@export var damage: int = 1
@export var lifetime: float = 1.0
@export var knockback_force: float = 280.0
@export var source_is_player: bool = true

var direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _pierced: bool = false  # Vengeful Spirit pierces up to 2 enemies in HK
var _max_pierce: int = 2
var _hit_targets: Array[Node] = []


func _ready() -> void:
        collision_layer = 0
        collision_mask = Globals.LAYER_ENEMY_HURTBOX if source_is_player else Globals.LAYER_PLAYER_HURTBOX
        body_entered.connect(_on_body_entered)
        area_entered.connect(_on_area_entered)
        rotation = direction.angle()
        # Spawn visual.
        _spawn_visual()


func _process(delta: float) -> void:
        _lifetime_timer += delta
        if _lifetime_timer >= lifetime:
                queue_free()
                return
        global_position += direction * speed * delta


func _on_area_entered(other: Area2D) -> void:
        if other is Hurtbox:
                var hb: Hurtbox = other
                if source_is_player and not hb.is_enemy:
                        return
                if not source_is_player and not hb.is_player:
                        return
                if hb in _hit_targets:
                        return
                _hit_targets.append(hb)
                # Apply damage via a transient Hitbox-shaped effect (we directly invoke take_hit equivalent).
                # Build a transient Hitbox to leverage existing flow.
                var hit := _make_transient_hitbox()
                hb.take_hit(hit)
                hit.queue_free()
                # Increment pierce count.
                if _hit_targets.size() >= _max_pierce:
                        queue_free()


func _on_body_entered(_body: Node) -> void:
        # Hit walls? For simplicity, ignore (pass through geometry).
        pass


func _make_transient_hitbox() -> Hitbox:
        var hit := Hitbox.new()
        hit.damage = damage
        hit.knockback_force = knockback_force
        hit.hits_player = not source_is_player
        hit.hits_enemies = source_is_player
        return hit


func _spawn_visual() -> void:
        var poly := Polygon2D.new()
        poly.color = Color(0.6, 0.85, 1.0, 0.9)
        poly.polygon = [Vector2(-16, -6), Vector2(16, 0), Vector2(-16, 6), Vector2(-10, 0)]
        add_child(poly)
        # Add a glow trail.
        var glow := Polygon2D.new()
        glow.color = Color(0.8, 0.95, 1.0, 0.4)
        glow.polygon = [Vector2(-22, -10), Vector2(16, 0), Vector2(-22, 10), Vector2(-14, 0)]
        add_child(glow)
