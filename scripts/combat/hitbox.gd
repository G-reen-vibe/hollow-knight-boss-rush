class_name Hitbox
extends Area2D
## A damage-dealing area.
##
## Place on a node that should deal damage when its hitbox overlaps a Hurtbox.
## Enable/disable the underlying CollisionShape2D to toggle the hitbox.

@export var damage: int = 1
@export var knockback_force: float = 320.0
@export var hit_cooldown: float = 0.4  # Per-target hit cooldown.
@export var hits_player: bool = false  # If true, this hitbox damages the player.
@export var hits_enemies: bool = true

# target_node -> time remaining until it can be hit again
var _cooldowns: Dictionary[Node, float] = {}


func _ready() -> void:
	monitoring = true
	monitorable = true
	if hits_player and not hits_enemies:
		collision_mask = Globals.LAYER_PLAYER_HURTBOX
	elif hits_enemies and not hits_player:
		collision_mask = Globals.LAYER_ENEMY_HURTBOX
	else:
		collision_mask = Globals.LAYER_PLAYER_HURTBOX | Globals.LAYER_ENEMY_HURTBOX
	collision_layer = 0
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	# Tick down cooldowns and prune finished ones.
	var to_remove: Array[Node] = []
	for target_node in _cooldowns:
		_cooldowns[target_node] -= delta
		if _cooldowns[target_node] <= 0.0:
			to_remove.append(target_node)
	for t in to_remove:
		_cooldowns.erase(t)


func _on_area_entered(other: Area2D) -> void:
	if other is Hurtbox:
		var hurtbox: Hurtbox = other
		# Only hit valid targets.
		if hits_player and not hurtbox.is_player:
			return
		if hits_enemies and not hurtbox.is_enemy:
			return
		if _cooldowns.has(hurtbox):
			return
		_cooldowns[hurtbox] = hit_cooldown
		hurtbox.take_hit(self)


func clear_cooldowns() -> void:
	_cooldowns.clear()
