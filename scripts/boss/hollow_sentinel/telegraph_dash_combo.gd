extends State
## Telegraph a dash combo (phase 3 only): charge briefly, then dash twice
## across the arena with a brief pause between dashes.

@export var telegraph_duration: float = 0.5
@export var dash_speed: float = 620.0
@export var pause_between: float = 0.18

var _phase: int = 0  # 0 = telegraph, 1 = dash 1, 2 = pause, 3 = dash 2
var _timer: float = 0.0
var _dir: int = 1


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_phase = 0
	_timer = telegraph_duration
	var b := target as HollowSentinel
	b.velocity.x = 0.0
	# Face player.
	var dir: float = b.horizontal_dir_to_target()
	_dir = int(sign(dir)) if dir != 0.0 else b.facing
	b.facing = _dir
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration)
	tw.parallel().tween_property(b.sprite, "modulate", Color(2.5, 0.6, 0.4), telegraph_duration * 0.5)


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	match _phase:
		0:
			if _timer <= 0.0:
				_phase = 1
				b.sprite.scale = Vector2(1.0, 1.0)
				b.sprite.modulate = Color.WHITE
				b.activate_contact_hitbox(true)
		1:
			# Dash 1
			b.velocity.x = _dir * dash_speed
			b.velocity.y = 0.0
			if b.is_on_wall() or _timer <= -0.7:
				_phase = 2
				_timer = pause_between
				b.velocity.x = 0.0
				# Reverse direction for dash 2.
				_dir *= -1
				b.facing = _dir
		2:
			b.velocity.x = move_toward(b.velocity.x, 0.0, 1200.0 * delta)
			if _timer <= 0.0:
				_phase = 3
		3:
			# Dash 2
			b.velocity.x = _dir * dash_speed
			b.velocity.y = 0.0
			if b.is_on_wall() or _timer <= -0.7:
				_end_combo(b)


func _end_combo(b: HollowSentinel) -> void:
	b.velocity.x = 0.0
	b.state_machine.transition_to(&"Recover")


func exit() -> void:
	var b := target as HollowSentinel
	b.activate_contact_hitbox(true)
