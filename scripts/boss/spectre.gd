class_name Spectre
extends Boss
## Spectre: a flying ranged boss.
##
## Floats above the player, periodically:
##   - Diving at the player's current position (telegraphed by glowing).
##   - Firing 3 spread projectiles toward the player.
##   - Repositioning to a new hover point.
##
## Phase 2 (HP <= 50%): faster, fires 5 projectiles in a fan.

const ATTACK_DIVE: StringName = &"TelegraphDive"
const ATTACK_SHOOT: StringName = &"TelegraphShoot"

@export var hover_speed: float = 90.0
@export var hover_height: float = -180.0  # Offset above player.
@export var hover_amplitude: float = 40.0
@export var projectile_speed: float = 320.0
@export var projectile_damage: int = 1
@export var projectile_count_phase1: int = 3
@export var projectile_count_phase2: int = 5
@export var dive_speed: float = 720.0


func _ready() -> void:
        boss_name = "Spectre"
        max_health = 20
        idle_state_name = &"Hover"
        phase_thresholds = [0.5]
        total_phases = 2
        super._ready()
        add_to_group("boss")


func _is_flying() -> bool:
        return true


func _on_phase_changed(phase: int) -> void:
        match phase:
                2:
                        hover_speed *= 1.3
                        dive_speed *= 1.15


func pick_next_action() -> StringName:
        var dist := distance_to_target()
        var roll := randf()
        # If close, dive. If far, shoot. Otherwise mix.
        if dist < 180.0 and roll < 0.7:
                return ATTACK_DIVE
        if dist > 380.0 and roll < 0.7:
                return ATTACK_SHOOT
        if roll < 0.55:
                return ATTACK_SHOOT
        return ATTACK_DIVE


func spawn_projectiles() -> void:
        var count: int = projectile_count_phase2 if current_phase >= 2 else projectile_count_phase1
        var center := (target.global_position - global_position).normalized() if target != null else Vector2.RIGHT
        var spread: float = 0.6 if current_phase >= 2 else 0.4
        for i in count:
                var angle_offset: float = 0.0
                if count > 1:
                        angle_offset = lerp(-spread, spread, float(i) / float(count - 1))
                var dir := center.rotated(angle_offset)
                _spawn_one_projectile(dir)


func _spawn_one_projectile(dir: Vector2) -> void:
        var proj := SpectreProjectile.new()
        proj.direction = dir
        proj.speed = projectile_speed
        proj.damage = projectile_damage
        proj.source_is_player = false
        proj.global_position = global_position
        get_parent().add_child(proj)
