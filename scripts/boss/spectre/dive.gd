extends State
## Dive: dash along the locked direction. Contact hitbox is active during the
## dive. Ends after a fixed distance or on hitting a wall/floor.

const MAX_DIVE_DISTANCE: float = 600.0

var _travelled: float = 0.0
var _dive_dir_cached: Vector2 = Vector2.ZERO


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_travelled = 0.0
	_dive_dir_cached = Vector2.ZERO
	var b := target as Spectre
	# Lock the dive direction now (toward where the player is).
	if b.target != null and is_instance_valid(b.target):
		_dive_dir_cached = (b.target.global_position - b.global_position).normalized()
	else:
		_dive_dir_cached = Vector2.DOWN
	# Activate contact hitbox DURING the dive.
	b.activate_contact_hitbox(true)


func physics_process(delta: float) -> void:
	var b := target as Spectre
	var speed: float = b.dive_speed
	b.velocity = _dive_dir_cached * speed
	_travelled += speed * delta
	# Trail visual.
	if randf() < 0.5:
		_spawn_trail(b)
	# End conditions: hit wall, hit floor (while diving down), or max distance.
	if _travelled >= MAX_DIVE_DISTANCE or b.is_on_wall() or (b.is_on_floor() and _dive_dir_cached.y > 0.0):
		_end_dive(b)


func _end_dive(b: Spectre) -> void:
	b.velocity *= 0.3
	# Turn OFF contact hitbox when the dive ends.
	b.activate_contact_hitbox(false)
	b.state_machine.transition_to(&"Recover")


func _spawn_trail(b: Spectre) -> void:
	var trail := Polygon2D.new()
	trail.color = Color(0.8, 0.5, 1.0, 0.4)
	trail.polygon = [Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]
	trail.global_position = b.global_position
	b.get_parent().add_child(trail)
	var tw := b.create_tween()
	tw.tween_property(trail, "color:a", 0.0, 0.3)
	tw.parallel().tween_property(trail, "scale", Vector2(0.5, 0.5), 0.3)
	tw.tween_callback(trail.queue_free)


func exit() -> void:
	_dive_dir_cached = Vector2.ZERO
	var b := target as Spectre
	if b != null:
		b.activate_contact_hitbox(false)
