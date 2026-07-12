class_name Player
extends CharacterBody2D
## Player character controller.
##
## Owns health/soul, ability flags, and a StateMachine that drives movement,
## combat, and spell/heal behaviour. States are children of the $StateMachine
## node and read/write this node's velocity and ability flags.

# --- Physics constants (tuned for Hollow Knight-like feel) -------------------

const GRAVITY: float = 2000.0
const MAX_FALL_SPEED: float = 780.0
const RUN_SPEED: float = 340.0
const RUN_ACCEL: float = 3200.0
const RUN_FRICTION: float = 3400.0
const AIR_ACCEL: float = 2400.0
const AIR_FRICTION: float = 1100.0
const JUMP_VELOCITY: float = -640.0
const DOUBLE_JUMP_VELOCITY: float = -580.0
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER: float = 0.12
const DASH_SPEED: float = 720.0
const DASH_DURATION: float = 0.22
const DASH_COOLDOWN: float = 0.30
const WALL_SLIDE_SPEED: float = 100.0
const WALL_JUMP_VEL: Vector2 = Vector2(440.0, -580.0)
const WALL_JUMP_LOCK: float = 0.16  # Air control locked after wall jump.
const ATTACK_DURATION: float = 0.22
const ATTACK_RECOVER: float = 0.06
const SPELL_DURATION: float = 0.40
const HEAL_DURATION: float = 0.80
const INVINCIBLE_TIME: float = 1.0

# --- Ability flags (set by upgrades / charms / meta) -------------------------

var can_double_jump: bool = true  # Also runtime flag: refreshed on landing.
var has_dash: bool = true         # Ability flag (always on in boss rush).
var has_wall_jump: bool = true
var has_spell: bool = true
var has_heal: bool = true

# --- Runtime state -----------------------------------------------------------

var max_health: int = Globals.PLAYER_MAX_HEALTH
var health: int = Globals.PLAYER_MAX_HEALTH
var max_soul: float = Globals.PLAYER_MAX_SOUL
var soul: float = 0.0

var facing: int = 1  # 1 = right, -1 = left
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_cooldown: float = 0.0
var wall_jump_lock: float = 0.0
var invincible: bool = false
var dead: bool = false
var input_lock: bool = false  # Locks directional input (for cutscenes, attacks)

# Soul sources: hitting enemies with nail adds soul (up to 99).
signal health_changed(current: int, maximum: int)
signal soul_changed(current: float, maximum: float)
signal died
signal spawned  # emitted after respawn

# --- Node refs ---------------------------------------------------------------

@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Node2D = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitboxPivot/AttackHitbox
@onready var up_attack_hitbox: Hitbox = $UpAttackHitbox
@onready var down_attack_hitbox: Hitbox = $DownAttackHitbox
@onready var attack_pivot: Node2D = $AttackHitboxPivot
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var spell_spawn: Marker2D = $SpellSpawn
@onready var slash_visual: Node2D = $SlashVisual
@onready var up_slash_visual: Node2D = $UpSlashVisual
@onready var down_slash_visual: Node2D = $DownSlashVisual


# --- Lifecycle ---------------------------------------------------------------

func _ready() -> void:
        Globals.assign_player_layers(self)
        add_to_group("player")
        health = max_health
        soul = 0.0
        health_changed.emit(health, max_health)
        soul_changed.emit(soul, max_soul)
        hurtbox.hit_taken.connect(_on_hurt)
        hurtbox.is_player = true
        hurtbox.is_enemy = false
        hurtbox.invincible_time = INVINCIBLE_TIME
        # Disable all attack hitboxes by default.
        _set_hitbox_active(attack_hitbox, false)
        _set_hitbox_active(up_attack_hitbox, false)
        _set_hitbox_active(down_attack_hitbox, false)
        # Configure hitboxes to only hit enemies.
        attack_hitbox.hits_player = false
        attack_hitbox.hits_enemies = true
        up_attack_hitbox.hits_player = false
        up_attack_hitbox.hits_enemies = true
        down_attack_hitbox.hits_player = false
        down_attack_hitbox.hits_enemies = true
        state_machine.target = self


func _physics_process(delta: float) -> void:
        if dead:
                return
        # Timers
        coyote_timer = max(0.0, coyote_timer - delta)
        jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
        dash_cooldown = max(0.0, dash_cooldown - delta)
        wall_jump_lock = max(0.0, wall_jump_lock - delta)

        # Apply gravity unless we're dashing (state handles its own).
        if state_machine.current_state == null or state_machine.current_state.name != &"Dash":
                velocity.y += GRAVITY * delta
                velocity.y = min(velocity.y, MAX_FALL_SPEED)

        # Air control (unless locked by wall-jump or by current state).
        if not input_lock and wall_jump_lock <= 0.0:
                _apply_horizontal_input(delta)

        move_and_slide()

        # Reset coyote timer when on floor.
        if is_on_floor():
                coyote_timer = COYOTE_TIME
        # Detect wall for wall-slide/jump via raycasts.
        _update_wall_status()


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
        if dead:
                return
        # Buffer jump on press.
        if event.is_action_pressed("jump"):
                jump_buffer_timer = JUMP_BUFFER
        if event.is_action_pressed("debug_respawn"):
                # Soft-respawn for debugging: heal and reset position.
                heal_to_full()
                global_position = Vector2.ZERO


func consume_jump_buffer() -> bool:
        if jump_buffer_timer > 0.0:
                jump_buffer_timer = 0.0
                return true
        return false


func consume_coyote() -> bool:
        if coyote_timer > 0.0:
                coyote_timer = 0.0
                return true
        return false


func _apply_horizontal_input(delta: float) -> void:
        var dir: float = Input.get_axis("move_left", "move_right")
        if dir != 0.0:
                facing = int(sign(dir))
                var accel := RUN_ACCEL if is_on_floor() else AIR_ACCEL
                velocity.x = move_toward(velocity.x, dir * RUN_SPEED, accel * delta)
        else:
                var friction := RUN_FRICTION if is_on_floor() else AIR_FRICTION
                velocity.x = move_toward(velocity.x, 0.0, friction * delta)


# --- Walls -------------------------------------------------------------------

var _on_wall: bool = false
var _wall_dir: int = 0  # -1 = wall to left, +1 = wall to right

@onready var wall_left: RayCast2D = $WallRayLeft
@onready var wall_right: RayCast2D = $WallRayRight


func _update_wall_status() -> void:
        wall_left.force_raycast_update()
        wall_right.force_raycast_update()
        _on_wall = (wall_left.is_colliding() or wall_right.is_colliding()) and not is_on_floor()
        if wall_left.is_colliding():
                _wall_dir = -1
        elif wall_right.is_colliding():
                _wall_dir = 1
        else:
                _wall_dir = 0


func is_on_wall_surface() -> bool:
        return _on_wall


func wall_direction() -> int:
        return _wall_dir


func do_wall_jump() -> void:
        var dir := -_wall_dir  # push away from wall
        velocity.x = dir * WALL_JUMP_VEL.x
        velocity.y = WALL_JUMP_VEL.y
        wall_jump_lock = WALL_JUMP_LOCK
        facing = dir


# --- Combat ------------------------------------------------------------------

func start_dash() -> void:
        dash_cooldown = DASH_COOLDOWN


func can_dash() -> bool:
        return has_dash and dash_cooldown <= 0.0


func apply_knockback(kb: Vector2) -> void:
        velocity = kb


func _on_hurt(damage: int, _source: Variant) -> void:
        if invincible or dead:
                return
        health = max(0, health - damage)
        health_changed.emit(health, max_health)
        Globals.player_health_changed.emit(health, max_health)
        invincible = true
        hurtbox.invincible_time = INVINCIBLE_TIME  # re-triggered via take_hit
        # Flash sprite.
        _start_hurt_flash()
        if health <= 0:
                _die()
        else:
                state_machine.transition_to(&"Hurt")


func _start_hurt_flash() -> void:
        var tw := create_tween()
        for i in 3:
                tw.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.08)
                tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)
        tw.tween_callback(func():
                invincible = false
        )


func _die() -> void:
        dead = true
        state_machine.transition_to(&"Dead")
        died.emit()
        Globals.player_died.emit()


func heal_to_full() -> void:
        health = max_health
        health_changed.emit(health, max_health)
        Globals.player_health_changed.emit(health, max_health)


func add_soul(amount: float) -> void:
        soul = clampf(soul + amount, 0.0, max_soul)
        soul_changed.emit(soul, max_soul)
        Globals.player_soul_changed.emit(soul, max_soul)


func consume_soul(amount: float) -> bool:
        if soul < amount:
                return false
        soul -= amount
        soul_changed.emit(soul, max_soul)
        Globals.player_soul_changed.emit(soul, max_soul)
        return true


func heal_one() -> void:
        health = min(max_health, health + 1)
        health_changed.emit(health, max_health)
        Globals.player_health_changed.emit(health, max_health)


# --- Hitbox helpers ----------------------------------------------------------

func _set_hitbox_active(hitbox: Hitbox, active: bool) -> void:
        for child in hitbox.get_children():
                if child is CollisionShape2D:
                        child.set_deferred("disabled", not active)
        hitbox.clear_cooldowns()


func activate_attack(kind: StringName) -> void:
        # kind: "side" | "up" | "down"
        match kind:
                &"side":
                        _set_hitbox_active(attack_hitbox, true)
                        attack_pivot.scale.x = facing
                        _show_slash(slash_visual, facing)
                &"up":
                        _set_hitbox_active(up_attack_hitbox, true)
                        _show_slash(up_slash_visual, 1)
                &"down":
                        _set_hitbox_active(down_attack_hitbox, true)
                        _show_slash(down_slash_visual, 1)


func _show_slash(visual: Node2D, dir: int) -> void:
        visual.visible = true
        visual.scale = Vector2(dir, 1)
        visual.modulate = Color(1, 1, 1, 1)
        # Animate the slash: scale up briefly then fade.
        var tw := create_tween()
        tw.tween_property(visual, "scale", Vector2(dir * 1.25, 1.25), 0.06)
        tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.16)
        tw.tween_callback(func(): visual.visible = false)


func deactivate_attacks() -> void:
        _set_hitbox_active(attack_hitbox, false)
        _set_hitbox_active(up_attack_hitbox, false)
        _set_hitbox_active(down_attack_hitbox, false)
        if slash_visual != null:
                slash_visual.visible = false
        if up_slash_visual != null:
                up_slash_visual.visible = false
        if down_slash_visual != null:
                down_slash_visual.visible = false


# --- Spell / projectile spawning --------------------------------------------

func spawn_spell_projectile() -> void:
        if not has_spell:
                return
        var scene := load("res://scenes/vengeful_spirit.tscn")
        if scene == null:
                return
        var proj := scene.instantiate() as VengefulSpirit
        proj.global_position = spell_spawn.global_position
        proj.direction = Vector2(facing, 0)
        proj.source_is_player = true
        get_parent().add_child(proj)
