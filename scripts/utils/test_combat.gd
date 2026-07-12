extends Node2D
## Test scene: spawns player + boss and wires HUD labels for live debugging.

@onready var player: Player = $Player
@onready var boss: Boss = $Boss
@onready var player_hp: Label = $HUD/PlayerHP
@onready var soul_label: Label = $HUD/Soul
@onready var boss_hp: Label = $HUD/BossHP
@onready var state_label: Label = $HUD/State


func _ready() -> void:
	player.add_to_group("player")
	boss.add_to_group("boss")
	player.health_changed.connect(_on_player_hp)
	player.soul_changed.connect(_on_soul)
	boss.health_changed.connect(_on_boss_hp)
	_on_player_hp(player.health, player.max_health)
	_on_soul(player.soul, player.max_soul)
	_on_boss_hp(boss.health, boss.max_health)


func _process(_delta: float) -> void:
	if player.state_machine.current_state != null:
		state_label.text = "P: %s | B: %s" % [player.state_machine.current_state.name, boss.state_machine.current_state.name if boss.state_machine.current_state != null else "?"]
	# Respawn on fall off arena.
	if player.global_position.y > 800.0:
		player.global_position = Vector2(-300, 100)
		player.velocity = Vector2.ZERO
		player.heal_to_full()


func _on_player_hp(current: int, maximum: int) -> void:
	player_hp.text = "HP: %d/%d" % [current, maximum]


func _on_soul(current: float, maximum: float) -> void:
	soul_label.text = "Soul: %d/%d" % [int(current), int(maximum)]


func _on_boss_hp(current: int, maximum: int) -> void:
	boss_hp.text = "Boss: %d/%d" % [current, maximum]
