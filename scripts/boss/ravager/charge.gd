extends State
## Horizontal dash across the arena.
##
## DESIGN: The boss charges in a straight line until it hits a WALL (not the
## player). The contact hitbox is active during the charge, so the player must
## either dash THROUGH the boss (i-frames) or jump over it. On hitting the wall,
## the boss is stunned (vulnerable window).

var _travelled: float = 0.0
var _charge_dir: int = 1  # Locked at enter; NOT read from boss.facing.


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_travelled = 0.0
	var b := target as Ravager
	# Lock the charge direction NOW (from the telegraph). Do NOT read b.facing
	# during the charge — the boss base updates facing every frame to track
	# the player, which would flip the charge direction mid-dash.
	_charge_dir = b.facing
	# Activate contact hitbox DURING the charge (body is dangerous while moving).
	b.activate_contact_hitbox(true)
	# Stretch forward.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.2, 0.9), 0.1)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	var speed: float = b.charge_speed * (1.2 if b.current_phase >= 2 else 1.0)
	b.velocity.x = _charge_dir * speed
	b.velocity.y = 0.0
	_travelled += abs(b.velocity.x) * delta
	# Hit wall? -> stunned (vulnerable).
	if b.is_on_wall():
		_end_charge(b, true)
		return
	# Travelled far enough (safety valve — shouldn't hit this normally).
	if _travelled >= b.charge_distance:
		_end_charge(b, false)
		return


func _end_charge(b: Ravager, hit_wall: bool) -> void:
	b.velocity.x = 0.0
	b.sprite.scale = Vector2(1.0, 1.0)
	# Turn OFF contact hitbox immediately when the charge ends.
	b.activate_contact_hitbox(false)
	if hit_wall:
		# Wall stun! Big visual feedback + longer vulnerable window.
		var tw := b.create_tween()
		tw.tween_property(b.sprite, "scale", Vector2(0.9, 1.1), 0.08)
		tw.tween_property(b.sprite, "scale", Vector2(1.0, 1.0), 0.1)
		# Screen shake on wall hit.
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			var tw2 := cam.create_tween()
			var orig := cam.offset
			for i in 3:
				tw2.tween_property(cam, "offset", orig + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.04)
			tw2.tween_property(cam, "offset", orig, 0.05)
		# Go to a longer stun recovery.
		b.state_machine.transition_to(&"Stun")
	else:
		# Didn't hit a wall (ran out of distance) — still need to recover.
		b.state_machine.transition_to(&"Recover")


func exit() -> void:
	var b := target as Ravager
	# Ensure contact hitbox is off when leaving the state.
	b.activate_contact_hitbox(false)
