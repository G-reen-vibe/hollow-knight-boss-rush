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
@export var move_speed: float = 120.0
@export var approach_speed: float = 80.0
@export var gravity: float = 1800.0
@export var flinch_time: float = 0.18
@export var can_flinch: bool = false  # Hollow Knight bosses mostly don't flinch.
@export var contact_damage: int = 1
@export var contact_knockback: float = 280.0

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
	health = max_health
	health_changed.emit(health, max_health)
	collision_layer = Globals.LAYER_ENEMY
	collision_mask = Globals.LAYER_WORLD
	# Configure hurtbox.
	hurtbox.is_player = false
	hurtbox.is_enemy = true
	hurtbox.invincible_time = 0.05  # Bosses have very short invuln.
	hurtbox.hit_taken.connect(_on_hurt)
	# Configure contact hitbox (damage-on-touch).
	if contact_hitbox != null:
		contact_hitbox.damage = contact_damage
		contact_hitbox.knockback_force = contact_knockback
		contact_hitbox.hits_player = true
		contact_hitbox.hits_enemies = false
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

func _on_hurt(damage: int, _source: Hitbox) -> void:
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


# --- AI hooks (override in subclass) ---

func pick_next_attack() -> StringName:
	# Default: subclass implements this.
	return &"Idle"
