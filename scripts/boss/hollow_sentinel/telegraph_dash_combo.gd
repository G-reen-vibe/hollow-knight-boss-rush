extends State
## Telegraph a dash combo (phase 3 only).
##
## DESIGN: The boss shows a line indicator, then dashes across the arena to the
## opposite wall. After hitting the wall, it pauses briefly, then dashes back.
## Each dash goes to the WALL, not to the player. The player dodges by dashing
## through (i-frames) or jumping over.

@export var telegraph_duration: float = 0.8
@export var dash_speed: float = 580.0
@export var pause_between: float = 0.25

var _phase: int = 0  # 0 = telegraph, 1 = dash 1, 2 = pause, 3 = dash 2
var _timer: float = 0.0
var _dir: int = 1
var _line_marker: Node2D = null


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_phase = 0
	_timer = telegraph_duration
	var b := target as HollowSentinel
	b.velocity.x = 0.0
	var dir: float = b.horizontal_dir_to_target()
	_dir = int(sign(dir)) if dir != 0.0 else b.facing
	b.facing = _dir
	# Line indicator to the wall.
	var wall_x: float = 680.0 if _dir > 0 else -680.0
	var end_pos := Vector2(wall_x, b.global_position.y)
	_line_marker = b.spawn_line_indicator(b.global_position, end_pos, Color(1, 0.4, 0.3, 0.4))
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration)
	tw.parallel().tween_property(b.sprite, "modulate", Color(2.5, 0.6, 0.4), telegraph_duration * 0.5)


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	match _phase:
		0:
			if _timer <= 0.0:
				if _line_marker != null:
					_line_marker.queue_free()
					_line_marker = null
				_phase = 1
				b.sprite.scale = Vector2(1.0, 1.0)
				b.sprite.modulate = Color.WHITE
				b.activate_contact_hitbox(true)
		1:
			# Dash 1 — go to the wall.
			b.velocity.x = _dir * dash_speed
			b.velocity.y = 0.0
			if b.is_on_wall() or _timer <= -0.9:
				_phase = 2
				_timer = pause_between
				b.velocity.x = 0.0
				_dir *= -1
				b.facing = _dir
				b.activate_contact_hitbox(false)
		2:
			b.velocity.x = move_toward(b.velocity.x, 0.0, 1200.0 * delta)
			if _timer <= 0.0:
				_phase = 3
				b.activate_contact_hitbox(true)
		3:
			# Dash 2 — go back to the other wall.
			b.velocity.x = _dir * dash_speed
			b.velocity.y = 0.0
			if b.is_on_wall() or _timer <= -0.9:
				_end_combo(b)


func _end_combo(b: HollowSentinel) -> void:
	b.velocity.x = 0.0
	b.activate_contact_hitbox(false)
	b.state_machine.transition_to(&"Recover")


func exit() -> void:
	var b := target as HollowSentinel
	if b != null:
		b.activate_contact_hitbox(false)
	if _line_marker != null and is_instance_valid(_line_marker):
		_line_marker.queue_free()
