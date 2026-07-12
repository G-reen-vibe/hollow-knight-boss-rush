class_name BossRushManager
extends Node
## Drives the boss rush flow: load arena -> spawn boss -> fight -> on boss death
## heal player slightly, advance to next boss -> ... -> victory screen.
##
## Also handles player death: show game over, allow retry from boss 1.

const BOSS_SCENES: Array[String] = [
        "res://scenes/bosses/ravager.tscn",
        "res://scenes/bosses/spectre.tscn",
        "res://scenes/bosses/hollow_sentinel.tscn",
]

const BOSS_NAMES: Array[String] = [
        "Ravager",
        "Spectre",
        "Hollow Sentinel",
]

const HEAL_BETWEEN_FIGHTS: int = 2  # Masks restored at the start of each new fight.
const FULL_HEAL_ON_BOSS_INDEX: int = 0  # Always full-heal before boss 0.

signal fight_started(boss_index: int, boss_name: String)
signal fight_won(boss_index: int)
signal rush_won
signal rush_lost

var current_boss_index: int = 0
var player: Player
var arena: Node2D
var current_boss: Boss
var arena_root: Node2D


var _game_over_shown: bool = false


func _ready() -> void:
        Globals.boss_died.connect(_on_boss_died)
        Globals.player_died.connect(_on_player_died)
        # Acquire player + arena references.
        await get_tree().process_frame
        _acquire_player()
        start_boss_rush()


func _unhandled_input(event: InputEvent) -> void:
        if _game_over_shown:
                if event.is_action_pressed("debug_respawn") or (event is InputEventKey and event.keycode == KEY_R):
                        _game_over_shown = false
                        get_tree().reload_current_scene()
                elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
                        get_tree().quit()


func _acquire_player() -> void:
        var players := get_tree().get_nodes_in_group("player")
        if players.size() > 0:
                player = players[0] as Player
        arena_root = get_parent() as Node2D


func start_boss_rush() -> void:
        current_boss_index = 0
        Globals.boss_rush_started.emit()
        start_fight(current_boss_index)


func start_fight(index: int) -> void:
        if index >= BOSS_SCENES.size():
                rush_won.emit()
                Globals.boss_rush_completed.emit()
                return
        # Clean up previous boss.
        if current_boss != null and is_instance_valid(current_boss):
                current_boss.queue_free()
                current_boss = null
        # Heal player.
        if index == FULL_HEAL_ON_BOSS_INDEX:
                player.heal_to_full()
        else:
                for i in HEAL_BETWEEN_FIGHTS:
                        if player.health < player.max_health:
                                player.heal_one()
                        else:
                                break
        # Reset soul to 0 at start of each fight.
        player.soul = 0.0
        player.soul_changed.emit(player.soul, player.max_soul)
        Globals.player_soul_changed.emit(player.soul, player.max_soul)
        # Reset player state and position.
        if player.state_machine.current_state != null:
                player.state_machine.transition_to(&"Idle")
        player.input_lock = false
        player.invincible = false
        player.dead = false
        player.sprite.modulate = Color.WHITE
        player.sprite.scale = Vector2(1, 1)
        # Position player on the left.
        player.global_position = Vector2(-300, 100)
        player.velocity = Vector2.ZERO
        # Spawn boss.
        var scene := load(BOSS_SCENES[index]) as PackedScene
        if scene == null:
                push_error("BossRushManager: failed to load boss scene: %s" % BOSS_SCENES[index])
                return
        current_boss = scene.instantiate() as Boss
        current_boss.global_position = Vector2(300, 100)
        arena_root.add_child(current_boss)
        current_boss.add_to_group("boss")
        Globals.current_boss_index = index
        Globals.total_bosses = BOSS_SCENES.size()
        Globals.current_boss_name = BOSS_NAMES[index]
        Globals.boss_index_changed.emit(index, BOSS_SCENES.size(), BOSS_NAMES[index])
        fight_started.emit(index, BOSS_NAMES[index])
        # Wire boss health to global signal.
        current_boss.health_changed.connect(func(cur, max_hp): Globals.boss_health_changed.emit(cur, max_hp))
        Globals.boss_health_changed.emit(current_boss.health, current_boss.max_health)


func _on_boss_died(boss: Node) -> void:
        if boss != current_boss:
                return
        fight_won.emit(current_boss_index)
        # Wait for death animation to play before advancing.
        await get_tree().create_timer(1.5).timeout
        current_boss = null
        current_boss_index += 1
        start_fight(current_boss_index)


func _on_player_died() -> void:
        rush_lost.emit()
        Globals.boss_rush_failed.emit()
        # Wait briefly then show game over UI; the GameOver scene handles retry.
        await get_tree().create_timer(2.0).timeout
        _show_game_over()


func _show_game_over() -> void:
        _game_over_shown = true
        var overlay := ColorRect.new()
        overlay.color = Color(0, 0, 0, 0.75)
        overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
        overlay.mouse_filter = Control.MOUSE_FILTER_STOP
        var label := Label.new()
        label.text = "DEFEATED\n\nPress R to retry from the beginning\nPress ESC to quit"
        label.add_theme_font_size_override(&"font_size", 36)
        label.add_theme_color_override(&"font_color", Color(0.9, 0.2, 0.2))
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.set_anchors_preset(Control.PRESET_FULL_RECT)
        overlay.add_child(label)
        # Add to canvas layer.
        var canvas := CanvasLayer.new()
        canvas.layer = 100
        canvas.add_child(overlay)
        get_tree().root.add_child(canvas)
