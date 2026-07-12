extends State
## Telegraph a charge.
##
## DESIGN:
##   - Show a line indicator from the boss to the opposite wall so the player
##     knows the exact path.
##   - Boss charges in a straight line until it hits the opposite WALL (not the
##     player). This means the player can dodge by dashing THROUGH the boss
##     (i-frames) or jumping over.
##   - On hitting the wall, the boss is stunned for 0.8s (big punish window).

@export var telegraph_duration: float = 0.75

var _timer: float = 0.0
var _charge_dir: int = 1
var _line_marker: Node2D = null


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as Ravager
	b.velocity.x = 0.0
	# Charge toward the player's current side — but commit to the direction.
	var dir: float = b.horizontal_dir_to_target()
	_charge_dir = int(sign(dir)) if dir != 0.0 else b.facing
	b.facing = _charge_dir
	# Show a line indicator from boss to the wall in the charge direction.
	var wall_x: float = 680.0 if _charge_dir > 0 else -680.0
	var end_pos := Vector2(wall_x, b.global_position.y)
	_line_marker = b.spawn_line_indicator(b.global_position, end_pos, Color(1, 0.4, 0.3, 0.4))
	# Visual: lean back.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration * 0.8)
	tw.parallel().tween_property(b.sprite, "modulate", Color(2, 0.6, 0.4), telegraph_duration * 0.4)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	_timer -= delta
	if _timer <= 0.0:
		if _line_marker != null:
			_line_marker.queue_free()
			_line_marker = null
		b.sprite.scale = Vector2(1.0, 1.0)
		b.sprite.modulate = Color.WHITE
		b.state_machine.transition_to(&"Charge")
		return
