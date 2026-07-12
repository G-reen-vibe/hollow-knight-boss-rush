class_name Boss
extends CharacterBody2D
## Base class for all bosses.
##
## Owns health, hurtbox, hitboxes, and a StateMachine for AI.
## Subclasses override `build_attack_weights()` and provide state nodes
## for each attack (TelegraphX / AttackX / RecoverX / Hurt / Dead).

signal health_changed(current: int, maximum: int)
signal boss_died
signal phase_changed(phase: int)

@export var max_health: int = 30
@export var boss_name: String = "Boss"
@export var idle_state_name: StringName = &"Idle"  # State to return to after Recover.
@export var move_speed: float = 120.0
@export var approach_speed: float = 80.0
@export var gravity: float = 1800.0
@export var flinch_time: float = 0.18
@export var can_flinch: bool = false  # Hollow Knight bosses mostly don't flinch.
@export var contact_damage: int = 1
@export var contact_knockback: float = 280.0
@export var contact_hit_cooldown: float = 1.0  # Long cooldown so touching doesn't melt HP.

var health: int = 30
var facing: int = 1  # 1 = right, -1 = left
var current_phase: int = 1
var total_phases: int = 1
var dead: bool = false
var target: Node2D  # The player

# Phase thresholds: phase N is active when health <= threshold[N-1].
# Empty array = single phase. Set by subclass in _ready.
var phase_thresholds: Array[float] = []

# --- Node refs (set by subclasses' scene) ---
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Node2D = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox  # Touch-damage hitbox.


func _ready() -> void:
        add_to_group("boss")
        health = max_health
        health_changed.emit(health, max_health)
        collision_layer = Globals.LAYER_ENEMY
        collision_mask = Globals.LAYER_WORLD
        # Configure hurtbox.
        hurtbox.is_player = false
        hurtbox.is_enemy = true
        hurtbox.invincible_time = 0.05  # Bosses have very short invuln.
        hurtbox.hit_taken.connect(_on_hurt)
        # Configure contact hitbox (damage-on-touch) — OFF by default.
        # Only activated during specific attack states, NOT during idle/approach.
        # This prevents the "boss stands on you and stuns you" problem.
        if contact_hitbox != null:
                contact_hitbox.damage = contact_damage
                contact_hitbox.knockback_force = contact_knockback
                contact_hitbox.hits_player = true
                contact_hitbox.hits_enemies = false
                contact_hitbox.hit_cooldown = contact_hit_cooldown
                activate_contact_hitbox(false)  # OFF by default.
        state_machine.target = self
        # Find player as target.
        await get_tree().process_frame
        _acquire_target()


func _acquire_target() -> void:
        # Default: find first Player in the scene.
        var players := get_tree().get_nodes_in_group("player")
        if players.size() > 0:
                target = players[0] as Node2D


func _physics_process(delta: float) -> void:
        if dead:
                return
        # Face the player.
        if target != null and is_instance_valid(target):
                var dx: float = target.global_position.x - global_position.x
                if abs(dx) > 4.0:
                        facing = int(sign(dx))
        # Apply gravity by default (flying bosses can override).
        if not _is_flying():
                velocity.y += gravity * delta
                velocity.y = min(velocity.y, 900.0)
        # Allow state to handle movement via hooks.
        move_and_slide()
        # Update phase based on health.
        _update_phase()


func _is_flying() -> bool:
        return false  # Override in flying bosses.


func _update_phase() -> void:
        if phase_thresholds.is_empty():
                return
        var new_phase := 1
        for i in phase_thresholds.size():
                if health <= phase_thresholds[i] * max_health:
                        new_phase = i + 2
        if new_phase != current_phase:
                current_phase = new_phase
                phase_changed.emit(current_phase)
                _on_phase_changed(current_phase)


func _on_phase_changed(_phase: int) -> void:
        # Override in subclass to add speed/attack changes.
        pass


# --- Combat ---

func _on_hurt(damage: int, _source: Variant) -> void:
        if dead:
                return
        health = max(0, health - damage)
        health_changed.emit(health, max_health)
        Globals.boss_health_changed.emit(health, max_health)
        # Brief red flash.
        var tw := create_tween()
        tw.tween_property(sprite, "modulate", Color(2, 0.5, 0.5), 0.05)
        tw.tween_property(sprite, "modulate", Color.WHITE, 0.10)
        # Grant player soul.
        if target != null and target.has_method("add_soul"):
                target.add_soul(Globals.SOUL_PER_HIT)
        if health <= 0:
                _die()
        elif can_flinch:
                state_machine.transition_to(&"Hurt")


func _die() -> void:
        dead = true
        state_machine.transition_to(&"Dead")
        boss_died.emit()
        Globals.boss_died.emit(self)
        # Disable contact hitbox.
        if contact_hitbox != null:
                for child in contact_hitbox.get_children():
                        if child is CollisionShape2D:
                                child.set_deferred("disabled", true)


func apply_knockback(kb: Vector2) -> void:
        # Most HK bosses don't get knocked back. Add to velocity for "heavy" feel.
        velocity += kb * 0.3


# --- Helpers for subclasses ---

func distance_to_target() -> float:
        if target == null or not is_instance_valid(target):
                return INF
        return global_position.distance_to(target.global_position)


func horizontal_dir_to_target() -> float:
        if target == null or not is_instance_valid(target):
                return 0.0
        return sign(target.global_position.x - global_position.x)


func move_toward_target(speed: float, delta: float) -> void:
        if target == null or not is_instance_valid(target):
                return
        var dir := horizontal_dir_to_target()
        velocity.x = move_toward(velocity.x, dir * speed, 1200.0 * delta)


func activate_contact_hitbox(active: bool) -> void:
        if contact_hitbox == null:
                return
        for child in contact_hitbox.get_children():
                if child is CollisionShape2D:
                        child.set_deferred("disabled", not active)


# --- Telegraph indicator helpers (used by attack states) ---------------------

## Spawn a ground marker at `world_pos` that pulses red. Returns the marker
## node so the caller can free it when the attack fires.
func spawn_ground_marker(world_pos: Vector2, radius: float = 36.0) -> Node2D:
        var marker := Node2D.new()
        marker.global_position = world_pos
        get_parent().add_child(marker)
        var segs := 24
        var ring := Polygon2D.new()
        ring.color = Color(1, 0.2, 0.2, 0.5)
        var pts := PackedVector2Array()
        for i in segs + 1:
                var a := (float(i) / segs) * TAU
                pts.append(Vector2(cos(a), sin(a)) * radius)
        ring.polygon = pts
        marker.add_child(ring)
        var fill := Polygon2D.new()
        fill.color = Color(1, 0.3, 0.3, 0.2)
        var pts2 := PackedVector2Array()
        for i in segs + 1:
                var a := (float(i) / segs) * TAU
                pts2.append(Vector2(cos(a), sin(a)) * radius)
        fill.polygon = pts2
        marker.add_child(fill)
        # Pulse.
        var tw := marker.create_tween().set_loops()
        tw.tween_property(fill, "color:a", 0.4, 0.2)
        tw.tween_property(fill, "color:a", 0.15, 0.2)
        return marker


## Spawn a line indicator from `from` to `to` showing a dive/charge path.
func spawn_line_indicator(from: Vector2, to: Vector2, color: Color = Color(1, 0.3, 0.3, 0.4)) -> Node2D:
        var marker := Node2D.new()
        get_parent().add_child(marker)
        var line := Polygon2D.new()
        line.color = color
        var dir := (to - from).normalized()
        var perp := Vector2(-dir.y, dir.x) * 12.0
        var len := from.distance_to(to)
        line.polygon = [from + perp, from - perp, to - perp, to + perp]
        line.global_position = Vector2.ZERO
        marker.add_child(line)
        # Pulse.
        var tw := marker.create_tween().set_loops()
        tw.tween_property(line, "color:a", 0.7, 0.15)
        tw.tween_property(line, "color:a", 0.25, 0.15)
        return marker


# --- AI hooks (override in subclass) ---

func pick_next_attack() -> StringName:
        # Default: subclass implements this.
        return &"Idle"
