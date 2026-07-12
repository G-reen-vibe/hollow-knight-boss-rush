extends Node
## TestRunner: simulates a player AI to play through the boss rush.
##
## Attach to a test scene that contains a MainGame instance. The AI will:
##   - Move toward the boss
##   - Attack when in range
##   - Heal when health is low and soul is sufficient
##   - Cast spells at range
##   - Dash to dodge when boss is telegraphing
##
## Logs periodic state snapshots and reports pass/fail at the end.

const RUN_DURATION: float = 180.0  # 3 minutes max per test run.
const INVINCIBLE_PLAYER: bool = true  # Make player invincible for testing progression.

var main_game: Node2D
var player: Player
var manager: BossRushManager
var elapsed: float = 0.0
var log_lines: Array[String] = []
var error_count: int = 0
var last_boss_index: int = -1
var boss_kills: int = 0
var player_deaths: int = 0

# AI state
var _ai_attack_cd: float = 0.0
var _ai_dash_cd: float = 0.0
var _ai_heal_cd: float = 0.0
var _ai_cast_cd: float = 0.0


func _ready() -> void:
        # Find main game.
        await get_tree().process_frame
        await get_tree().process_frame
        main_game = get_parent()
        _acquire_player()
        _acquire_manager()
        _log("TestRunner started. Player=%s Manager=%s" % [player != null, manager != null])
        # Hook signals.
        Globals.boss_died.connect(_on_boss_died)
        Globals.player_died.connect(_on_player_died)
        Globals.boss_rush_completed.connect(_on_rush_won)
        Globals.boss_rush_failed.connect(_on_rush_failed)
        Globals.boss_index_changed.connect(_on_boss_index_changed)


func _acquire_player() -> void:
        var players := get_tree().get_nodes_in_group("player")
        if players.size() > 0:
                player = players[0]


func _acquire_manager() -> void:
        var mgrs := get_tree().get_nodes_in_group("boss_rush_manager")
        if mgrs.size() > 0:
                manager = mgrs[0]
        if manager == null and main_game != null:
                # Try to find it as a child of main_game.
                for child in main_game.get_children():
                        if child is BossRushManager:
                                manager = child
                                break


func _process(delta: float) -> void:
        elapsed += delta
        if elapsed >= RUN_DURATION:
                _finish("TIMEOUT (no completion within %ds)" % RUN_DURATION)
                return
        if player == null or not is_instance_valid(player):
                _log("DEBUG: player is null or invalid. player=%s" % [player])
                # Try to re-acquire.
                _acquire_player()
                if player == null or not is_instance_valid(player):
                        _log("DEBUG: re-acquire failed; player nodes in group: %d" % get_tree().get_nodes_in_group("player").size())
                        _finish("Player instance lost")
                        return
                _log("DEBUG: re-acquired player.")
        # Test mode: keep player alive to verify game flow.
        if INVINCIBLE_PLAYER and player.health < player.max_health:
                player.heal_to_full()
        _run_ai(delta)
        # Periodic log.
        if int(elapsed) % 10 == 0 and abs(elapsed - int(elapsed)) < 0.05:
                _log("t=%ds boss_idx=%d player_hp=%d/%d soul=%d" % [
                        int(elapsed), last_boss_index, player.health, player.max_health, int(player.soul)
                ])


func _run_ai(delta: float) -> void:
        _ai_attack_cd = max(0.0, _ai_attack_cd - delta)
        _ai_dash_cd = max(0.0, _ai_dash_cd - delta)
        _ai_heal_cd = max(0.0, _ai_heal_cd - delta)
        _ai_cast_cd = max(0.0, _ai_cast_cd - delta)

        if player.dead:
                _release_all()
                return

        # Find current boss.
        var boss := _current_boss()
        if boss == null:
                _release_all()
                return

        var boss_x: float = boss.global_position.x
        var player_x: float = player.global_position.x
        var dist: float = abs(boss_x - player_x)
        var dir_to_boss: float = sign(boss_x - player_x)
        var boss_state_name: StringName = &""
        if boss.state_machine != null and boss.state_machine.current_state != null:
                boss_state_name = boss.state_machine.current_state.name

        # Dodge telegraphs.
        var is_telegraph: bool = boss_state_name.begins_with("Telegraph")
        var is_active_attack: bool = boss_state_name in [&"Leap", &"Dive", &"Charge", &"SlamLand", &"DashCombo"]
        if (is_telegraph or is_active_attack) and _ai_dash_cd <= 0.0:
                if dir_to_boss != 0.0:
                        _press_dir(-dir_to_boss, 0.05)
                        _press_action("dash", 0.05)
                        _ai_dash_cd = 0.5
                        return

        # Heal if hurt and have soul, and boss is far/recovering.
        if player.health <= 3 and player.soul >= Globals.HEAL_SOUL_COST and _ai_heal_cd <= 0.0 and dist > 200.0:
                _press_action("heal", 0.1)
                _ai_heal_cd = 2.0
                return

        # Cast spell at range when safe.
        if dist > 220.0 and player.soul >= Globals.SPELL_SOUL_COST and _ai_cast_cd <= 0.0:
                if dir_to_boss != 0.0:
                        _press_dir(dir_to_boss, 0.05)
                        _press_action("cast_spell", 0.05)
                        _ai_cast_cd = 1.2
                        return

        # Attack if in melee range and boss isn't actively attacking.
        if dist < 90.0 and _ai_attack_cd <= 0.0 and not is_active_attack:
                if dir_to_boss != 0.0:
                        _press_dir(dir_to_boss, 0.05)
                _press_action("attack", 0.05)
                _ai_attack_cd = 0.35
                # Back off after attacking.
                _ai_dash_cd = 0.2  # Brief lock to prevent immediate re-approach.
                return

        # Movement: maintain ~150 unit distance from boss.
        const SAFE_DIST: float = 150.0
        if dist < SAFE_DIST - 20.0:
                # Too close - back off.
                if dir_to_boss != 0.0:
                        _press_dir(-dir_to_boss, delta)
                # If backed into a wall, jump.
                if player.is_on_wall() and player.is_on_floor():
                        _press_action("jump", 0.05)
        elif dist > SAFE_DIST + 30.0:
                # Too far - approach.
                if dir_to_boss != 0.0:
                        _press_dir(dir_to_boss, delta)
        else:
                # In safe range - hold position.
                _release("move_left")
                _release("move_right")

        # Random jump to vary movement.
        if randf() < 0.005 and player.is_on_floor():
                _press_action("jump", 0.05)


func _current_boss() -> Boss:
        if manager != null and manager.current_boss != null and is_instance_valid(manager.current_boss):
                return manager.current_boss
        var bosses := get_tree().get_nodes_in_group("boss")
        if bosses.size() > 0:
                return bosses[0] as Boss
        return null


# --- Input simulation --------------------------------------------------------

func _press_dir(dir: float, duration: float) -> void:
        if dir < 0.0:
                _press_action("move_left", duration)
                _release("move_right")
        elif dir > 0.0:
                _press_action("move_right", duration)
                _release("move_left")


func _press_action(action: StringName, duration: float) -> void:
        Input.action_press(action)
        # Schedule release.
        var tw := get_tree().create_timer(duration)
        tw.timeout.connect(func():
                Input.action_release(action)
        )


func _release(action: StringName) -> void:
        Input.action_release(action)


func _release_all() -> void:
        for action in ["move_left", "move_right", "jump", "attack", "dash", "cast_spell", "heal"]:
                Input.action_release(action)


# --- Signal handlers ---------------------------------------------------------

func _on_boss_died(_boss: Node) -> void:
        boss_kills += 1
        _log("BOSS KILLED (total kills: %d)" % boss_kills)


func _on_player_died() -> void:
        player_deaths += 1
        _log("PLAYER DIED (total deaths: %d)" % player_deaths)


func _on_rush_won() -> void:
        _finish("VICTORY")


func _on_rush_failed() -> void:
        _finish("FAILED (player died)")


func _on_boss_index_changed(index: int, total: int, boss_name: String) -> void:
        last_boss_index = index
        _log("Boss index changed: %d/%d (%s)" % [index + 1, total, boss_name])


# --- Logging -----------------------------------------------------------------

func _log(msg: String) -> void:
        log_lines.append("[%.2fs] %s" % [elapsed, msg])
        print("[TestRunner] ", msg)


func _finish(reason: String) -> void:
        _log("FINISH: %s" % reason)
        _log("Stats: kills=%d deaths=%d boss_idx_reached=%d" % [boss_kills, player_deaths, last_boss_index])
        # Write log to file.
        var log_path := "res://test_runner.log"
        var f := FileAccess.open(log_path, FileAccess.WRITE)
        if f != null:
                for line in log_lines:
                        f.store_line(line)
                f.close()
                print("[TestRunner] Log written to ", log_path)
        set_process(false)
        # Quit after a short delay.
        await get_tree().create_timer(1.0).timeout
        get_tree().quit()
