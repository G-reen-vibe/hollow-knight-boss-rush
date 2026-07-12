extends Node2D
## Test arena: spawns player, wires HUD to player signals for live debugging.

@onready var player: Player = $Player
@onready var health_label: Label = $HUD/HealthLabel
@onready var soul_label: Label = $HUD/SoulLabel
@onready var state_label: Label = $HUD/StateLabel


func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.soul_changed.connect(_on_soul_changed)
	_on_health_changed(player.health, player.max_health)
	_on_soul_changed(player.soul, player.max_soul)


func _process(_delta: float) -> void:
	if player.state_machine.current_state != null:
		state_label.text = "State: " + player.state_machine.current_state.name
		state_label.add_theme_color_override(&"font_color", Color(0.8, 0.9, 1.0))
	# Respawn on fall off arena.
	if player.global_position.y > 800.0:
		player.global_position = Vector2(0, 100)
		player.velocity = Vector2.ZERO
		player.heal_to_full()


func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "Health: %d/%d" % [current, maximum]


func _on_soul_changed(current: float, maximum: float) -> void:
	soul_label.text = "Soul: %d/%d" % [int(current), int(maximum)]
