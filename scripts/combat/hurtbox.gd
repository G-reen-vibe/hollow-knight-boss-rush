class_name Hurtbox
extends Area2D
## A damage-receiving area.
##
## Place on a node that should take damage when a Hitbox overlaps it.
## Emits `hit_taken` and applies knockback to the parent (if CharacterBody2D).

@export var is_player: bool = false
@export var is_enemy: bool = true
@export var invincible_time: float = 0.6

signal hit_taken(damage: int, source: Hitbox)
signal invincibility_started
signal invincibility_ended

var _invincible: bool = false
var _invincible_timer: float = 0.0


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = Globals.LAYER_PLAYER_HURTBOX if is_player else Globals.LAYER_ENEMY_HURTBOX
	collision_mask = 0


func _process(delta: float) -> void:
	if _invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			_invincible = false
			invincibility_ended.emit()
			# Re-enable the hurtbox shape.
			for child in get_children():
				if child is CollisionShape2D:
					child.set_deferred("disabled", false)


func take_hit(source: Hitbox) -> void:
	if _invincible:
		return
	hit_taken.emit(source.damage, source)
	# Apply knockback to parent CharacterBody2D if present.
	var parent := get_parent()
	if parent is CharacterBody2D and source.knockback_force > 0.0:
		var dir: float = signf(parent.global_position.x - source.global_position.x)
		if dir == 0.0:
			dir = -1.0 if parent.scale.x > 0.0 else 1.0
		var kb := Vector2(dir * source.knockback_force, -source.knockback_force * 0.25)
		if parent.has_method("apply_knockback"):
			parent.apply_knockback(kb)
		else:
			parent.velocity += kb
	# Apply invincibility window.
	if invincible_time > 0.0:
		_invincible = true
		_invincible_timer = invincible_time
		invincibility_started.emit()
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)


func is_invincible() -> bool:
	return _invincible
