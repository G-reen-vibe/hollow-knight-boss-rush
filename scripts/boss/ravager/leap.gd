extends State
## Mid-air leap state. The boss follows a parabolic arc to the locked target
## position. On landing: shockwave + stuck recovery window.

var _has_landed: bool = false


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_has_landed = false


func physics_process(_delta: float) -> void:
	var b := target as Ravager
	if _has_landed:
		return
	# Gravity is applied by boss base _physics_process. We just detect landing.
	if b.is_on_floor() and b.velocity.y >= 0.0:
		_do_landed(b)
	elif b.velocity.y > 0.0:
		# Falling: tilt forward.
		b.sprite.rotation = lerp(b.sprite.rotation, b.facing * 0.25, 0.2)
	else:
		b.sprite.rotation = 0.0


func _do_landed(b: Ravager) -> void:
	_has_landed = true
	b.velocity.x = 0.0
	b.velocity.y = 0.0
	b.sprite.rotation = 0.0
	# Turn OFF contact hitbox immediately on landing — the boss is now stuck
	# and the player should be able to punish safely.
	b.activate_contact_hitbox(false)
	# Spawn shockwave hitboxes on either side (dodgeable by jumping).
	_spawn_shockwave(b, 1)
	_spawn_shockwave(b, -1)
	# Screen-shake feedback.
	_do_screen_shake(b, 6.0)
	b.state_machine.transition_to(&"SlamLand")


func _spawn_shockwave(b: Ravager, dir: int) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = Globals.LAYER_PLAYER_HURTBOX
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 16)
	shape.shape = rect
	area.add_child(shape)
	area.global_position = b.global_position + Vector2(dir * 50, 12)
	b.get_parent().add_child(area)
	# Visual.
	var poly := Polygon2D.new()
	poly.color = Color(1.0, 0.7, 0.3, 0.6)
	poly.polygon = [Vector2(-30, -8), Vector2(30, -8), Vector2(30, 8), Vector2(-30, 8)]
	area.add_child(poly)
	area.call_deferred("set_monitoring", true)
	area.set_deferred("monitorable", false)
	# Manual hit detection.
	await b.get_tree().process_frame
	for hurt in area.get_overlapping_areas():
		if hurt is Hurtbox and hurt.is_player:
			hurt.apply_damage(1, 360.0, b.global_position)
			break
	# Tween out and free.
	var tw := b.create_tween()
	tw.tween_property(poly, "color:a", 0.0, 0.25)
	tw.parallel().tween_property(area, "position:x", area.position.x + dir * 60.0, 0.25)
	tw.tween_callback(area.queue_free)


func _do_screen_shake(_b: Node, _amount: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := cam.create_tween()
	var orig := cam.offset
	for i in 4:
		tw.tween_property(cam, "offset", orig + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.04)
	tw.tween_property(cam, "offset", orig, 0.06)
