class_name Ravager
extends Boss
## Ravager: a heavy ground boss.
##
## Attacks (picked based on player distance and current phase):
##   - Leap: jumps in an arc toward the player, slams down with shockwave.
##   - Charge: telegraphs, then dashes horizontally across the arena.
##
## Phase 1 (HP > 50%): Leap and Charge, slow idle.
## Phase 2 (HP <= 50%): Same attacks + faster cooldowns + occasional double-attack.

const ATTACK_LEAP: StringName = &"TelegraphLeap"
const ATTACK_CHARGE: StringName = &"TelegraphCharge"

@export var leap_speed_x: float = 320.0
@export var leap_speed_y: float = -540.0
@export var charge_speed: float = 520.0
@export var charge_distance: float = 700.0

# Distance thresholds for picking attacks.
const LEAP_RANGE_MIN: float = 80.0
const LEAP_RANGE_MAX: float = 380.0
const CHARGE_RANGE_MIN: float = 280.0


func _ready() -> void:
        boss_name = "Ravager"
        max_health = 24
        phase_thresholds = [0.5]  # Phase 2 at 50% HP.
        total_phases = 2
        super._ready()
        add_to_group("boss")


func _is_flying() -> bool:
        return false


func _on_phase_changed(phase: int) -> void:
        # Phase 2: faster movement.
        match phase:
                2:
                        move_speed *= 1.25
                        approach_speed *= 1.25


func pick_next_action() -> StringName:
        var dist := distance_to_target()
        # Phase 2 adds a chance to chain attacks.
        var phase2 := current_phase >= 2
        var roll := randf()
        if dist < LEAP_RANGE_MIN:
                # Too close: leap straight up & slam.
                if roll < 0.6 or not phase2:
                        return ATTACK_LEAP
                return ATTACK_CHARGE
        if dist > CHARGE_RANGE_MIN and (roll < 0.5 or not phase2):
                return ATTACK_CHARGE
        # Mid-range: prefer leap.
        if dist <= LEAP_RANGE_MAX:
                if roll < 0.65:
                        return ATTACK_LEAP
                return ATTACK_CHARGE
        # Far away: charge to close distance.
        return ATTACK_CHARGE
