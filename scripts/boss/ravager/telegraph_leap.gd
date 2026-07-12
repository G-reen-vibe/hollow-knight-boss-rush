extends State
## Telegraph a leap.
##
## DESIGN (Hollow Knight principles):
##   - Lock the target position at the START of the telegraph (where the player
##     is NOW). The boss commits to landing there — it does NOT track the player.
##   - Show a pulsing red ground marker at the landing spot so the player knows
##     exactly where to NOT be.
##   - Long telegraph (0.85s) gives the player time to walk/dash away.
##   - On landing, the boss is stuck for 0.7s (free hit window for the player).

@export var telegraph_duration: float = 0.85

var _timer: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _marker: Node2D = null


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as Ravager
	b.velocity.x = 0.0
	# Lock the target position NOW (where the player is at telegraph start).
	if b.target != null and is_instance_valid(b.target):
		_target_pos = b.target.global_position
		_target_pos.y = b.global_position.y  # Same vertical level (ground leap).
	else:
		_target_pos = b.global_position + Vector2(b.facing * 200, 0)
	# Show a ground marker at the landing spot.
	_marker = b.spawn_ground_marker(_target_pos, 44.0)
	# Visual: crouch (squash) + red flash.
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.2, 0.75), telegraph_duration * 0.8)
	tw.parallel().tween_property(b.sprite, "modulate", Color(2, 0.7, 0.5), telegraph_duration * 0.4)


func physics_process(delta: float) -> void:
	var b := target as Ravager
	_timer -= delta
	if _timer <= 0.0:
		# Free the marker.
		if _marker != null:
			_marker.queue_free()
			_marker = null
		# Launch toward the locked target position.
		var diff := _target_pos - b.global_position
		# Compute a parabolic arc: time to reach target ~0.55s.
		var t: float = 0.55
		b.velocity.x = diff.x / t
		b.velocity.y = (diff.y - 0.5 * b.gravity * t * t) / t
		b.sprite.scale = Vector2(0.9, 1.15)
		b.sprite.modulate = Color.WHITE
		# Activate contact hitbox during the leap (so the boss body is dangerous
		# while flying through the air, but NOT before).
		b.activate_contact_hitbox(true)
		b.state_machine.transition_to(&"Leap")
		return
