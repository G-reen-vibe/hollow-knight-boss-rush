extends State
## Telegraph a leap. Locks target position at telegraph start, shows a ground
## marker. Long telegraph for fairness.

@export var telegraph_duration: float = 0.75

var _timer: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _marker: Node2D = null


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as HollowSentinel
	b.velocity.x = 0.0
	# Lock target position NOW.
	if b.target != null and is_instance_valid(b.target):
		_target_pos = b.target.global_position
		_target_pos.y = b.global_position.y
	else:
		_target_pos = b.global_position + Vector2(b.facing * 200, 0)
	# Ground marker.
	_marker = b.spawn_ground_marker(_target_pos, 40.0)
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "scale", Vector2(1.2, 0.75), telegraph_duration * 0.8)
	tw.parallel().tween_property(b.sprite, "modulate", Color(2, 0.7, 0.5), telegraph_duration * 0.4)


func physics_process(delta: float) -> void:
	var b := target as HollowSentinel
	_timer -= delta
	if _timer <= 0.0:
		if _marker != null:
			_marker.queue_free()
			_marker = null
		var diff := _target_pos - b.global_position
		var t: float = 0.5
		b.velocity.x = diff.x / t
		b.velocity.y = (diff.y - 0.5 * b.gravity * t * t) / t
		b.sprite.scale = Vector2(0.9, 1.15)
		b.sprite.modulate = Color.WHITE
		b.activate_contact_hitbox(true)
		b.state_machine.transition_to(&"Leap")
		return
