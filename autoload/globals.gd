extends Node
## Globals (autoload)
##
## Single source of truth for game-wide constants, signals, and shared state.
## Loaded as the `Globals` autoload.

# --- Signals -----------------------------------------------------------------

signal player_died
signal boss_died(boss: Node)
signal boss_health_changed(current: int, maximum: int)
signal player_health_changed(current: int, maximum: int)
signal player_soul_changed(current: float, maximum: float)
signal boss_rush_started
signal boss_rush_completed
signal boss_rush_failed
signal boss_index_changed(index: int, total: int, boss_name: String)

# --- Gameplay constants ------------------------------------------------------

const PLAYER_MAX_HEALTH: int = 6
const PLAYER_MAX_SOUL: float = 99.0
const SOUL_PER_HIT: float = 11.0
const HEAL_SOUL_COST: float = 33.0
const HEAL_AMOUNT: int = 1
const SPELL_SOUL_COST: float = 33.0

const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4
const LAYER_PLAYER_HITBOX: int = 8
const LAYER_ENEMY_HITBOX: int = 16
const LAYER_PLAYER_HURTBOX: int = 32
const LAYER_ENEMY_HURTBOX: int = 64

# Shared collision masks (used by Hitbox/Hurtbox components).
# Hitbox: area that DEALS damage. Hurtbox: area that RECEIVES damage.
const MASK_PLAYER_HITBOX: int = LAYER_PLAYER_HURTBOX      # player's hitbox can hit enemy hurtbox
const MASK_ENEMY_HITBOX: int = LAYER_PLAYER_HURTBOX       # enemy's hitbox can hit player hurtbox

# --- Boss rush state ---------------------------------------------------------

var current_boss_index: int = 0
var total_bosses: int = 0
var current_boss_name: String = ""

## Names of the bosses in the rush, in order. Driven by the BossRush manager.
var boss_roster: Array[StringName] = []

# --- Helpers -----------------------------------------------------------------

func reset_run() -> void:
        current_boss_index = 0
        current_boss_name = ""

func assign_player_layers(body: Node) -> void:
        if body is CollisionObject2D:
                body.collision_layer = LAYER_PLAYER
                body.collision_mask = LAYER_WORLD

## Spawn a brief floating damage number at world position.
func spawn_damage_number(world_pos: Vector2, amount: int, color: Color = Color.WHITE) -> void:
        var label := Label.new()
        label.text = str(amount)
        label.position = world_pos + Vector2(randf_range(-8.0, 8.0), -16.0)
        label.modulate = color
        label.z_index = 100
        label.add_theme_font_size_override(&"font_size", 20)
        # Auto-attach to the scene tree root so it survives parent scene swaps.
        var tree := Engine.get_main_loop() as SceneTree
        tree.current_scene.add_child(label)
        var tween := label.create_tween()
        tween.tween_property(label, "position:y", label.position.y - 24.0, 0.4)
        tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
        tween.tween_callback(label.queue_free)
