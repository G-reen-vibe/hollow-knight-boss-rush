extends State
## Telegraph a shot.
##
## DESIGN: The boss glows brightly for 0.8s, then fires. The player can see
## the charge and dash away or behind the boss. Projectiles fire toward where
## the player WAS at the moment of firing (not tracking).

@export var telegraph_duration: float = 0.8

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = telegraph_duration
	var b := target as Spectre
	b.velocity = Vector2.ZERO
	# Visual: brighten and shrink slightly (charging up).
	var tw := b.create_tween()
	tw.tween_property(b.sprite, "modulate", Color(1.5, 1.0, 2.0), telegraph_duration * 0.7)
	tw.parallel().tween_property(b.sprite, "scale", Vector2(0.85, 1.15), telegraph_duration * 0.7)
	# Spawn a charge orb visual at the boss.
	var orb := Polygon2D.new()
	orb.color = Color(1.0, 0.7, 1.0, 0.6)
	orb.polygon = [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
	orb.name = "ChargeOrb"
	b.sprite.add_child(orb)
	var tw2 := b.create_tween()
	tw2.tween_property(orb, "scale", Vector2(2.5, 2.5), telegraph_duration)
	tw2.parallel().tween_property(orb, "modulate:a", 0.9, telegraph_duration)


func physics_process(delta: float) -> void:
	var b := target as Spectre
	_timer -= delta
	# Hold position.
	if b.target != null and is_instance_valid(b.target):
		var desired := Vector2(b.global_position.x, b.hover_height)
		b.velocity = (desired - b.global_position) * 2.0
	if _timer <= 0.0:
		# Remove charge orb.
		var orb := b.sprite.get_node_or_null("ChargeOrb")
		if orb != null:
			orb.queue_free()
		b.sprite.modulate = Color.WHITE
		b.sprite.scale = Vector2(1.0, 1.0)
		b.spawn_projectiles()
		b.state_machine.transition_to(&"Recover")
		return
