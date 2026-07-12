class_name HollowSentinel
extends Boss
## Hollow Sentinel: the final boss. Combines melee and ranged attacks.
##
## Phase 1 (HP > 66%): Walk + Leap + occasional Slash.
## Phase 2 (HP 33%-66%): Faster walk + Leap + Slash + 3-shot projectile spread.
## Phase 3 (HP <= 33%): All of the above, faster, plus a multi-hit dash combo.

const ATTACK_LEAP: StringName = &"TelegraphLeap"
const ATTACK_SLASH: StringName = &"TelegraphSlash"
const ATTACK_SHOOT: StringName = &"TelegraphShoot"
const ATTACK_DASH_COMBO: StringName = &"TelegraphDashCombo"

@export var leap_speed_x: float = 360.0
@export var leap_speed_y: float = -560.0
@export var charge_speed: float = 540.0
@export var projectile_speed: float = 360.0


func _ready() -> void:
        boss_name = "Hollow Sentinel"
        max_health = 24
        phase_thresholds = [0.66, 0.33]
        total_phases = 3
        super._ready()
        add_to_group("boss")


func _is_flying() -> bool:
        return false


func _on_phase_changed(phase: int) -> void:
        match phase:
                2:
                        move_speed *= 1.2
                        approach_speed *= 1.2
                3:
                        move_speed *= 1.15
                        approach_speed *= 1.15
                        leap_speed_x *= 1.1


func pick_next_action() -> StringName:
        var dist := distance_to_target()
        var roll := randf()
        # Phase 1: leap + slash only.
        if current_phase == 1:
                if dist < 140.0:
                        return ATTACK_SLASH if roll < 0.7 else ATTACK_LEAP
                return ATTACK_LEAP if roll < 0.7 else ATTACK_SLASH
        # Phase 2: + shoot.
        if current_phase == 2:
                if dist < 140.0:
                        if roll < 0.5: return ATTACK_SLASH
                        if roll < 0.8: return ATTACK_LEAP
                        return ATTACK_SHOOT
                if dist > 360.0:
                        if roll < 0.5: return ATTACK_SHOOT
                        return ATTACK_LEAP
                if roll < 0.4: return ATTACK_SLASH
                if roll < 0.75: return ATTACK_LEAP
                return ATTACK_SHOOT
        # Phase 3: + dash combo.
        if dist < 140.0:
                if roll < 0.35: return ATTACK_SLASH
                if roll < 0.6: return ATTACK_DASH_COMBO
                if roll < 0.85: return ATTACK_LEAP
                return ATTACK_SHOOT
        if dist > 360.0:
                if roll < 0.35: return ATTACK_SHOOT
                if roll < 0.7: return ATTACK_DASH_COMBO
                return ATTACK_LEAP
        if roll < 0.3: return ATTACK_SLASH
        if roll < 0.55: return ATTACK_LEAP
        if roll < 0.8: return ATTACK_SHOOT
        return ATTACK_DASH_COMBO


func spawn_projectiles(count: int = 3) -> void:
        if target == null or not is_instance_valid(target):
                return
        var center := (target.global_position - global_position).normalized()
        var spread := 0.45
        for i in count:
                var angle_offset: float = 0.0
                if count > 1:
                        angle_offset = lerp(-spread, spread, float(i) / float(count - 1))
                var dir := center.rotated(angle_offset)
                var proj := SentinelProjectile.new()
                proj.direction = dir
                proj.speed = projectile_speed
                proj.damage = 1
                proj.global_position = global_position
                get_parent().add_child(proj)
