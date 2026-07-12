extends Node2D
## Main game scene: arena + player + camera + boss rush manager + HUD.

@onready var player: Player = $Player


func _ready() -> void:
	player.add_to_group("player")
	# Set main scene for runtime-added nodes that need a scene root.
	Globals.boss_index_changed.emit(0, 3, "Ravager")
