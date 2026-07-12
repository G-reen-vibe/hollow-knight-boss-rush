extends Node2D
## ArenaBackground: draws an atmospheric, parallax-ish background.
##
## Spawns floating dust motes and a subtle vignette overlay. The background
## silhouettes are static (defined in the scene); this script just adds life
## with slow-moving particles and a soft pulse on the sky gradient.

@onready var sky: Polygon2D = $SkyGradient

var _motes: Array[Polygon2D] = []
var _time: float = 0.0


func _ready() -> void:
	# Spawn dust motes.
	for i in 30:
		var mote := Polygon2D.new()
		mote.color = Color(0.6, 0.6, 0.8, randf_range(0.1, 0.3))
		var size := randf_range(1.5, 3.5)
		mote.polygon = [Vector2(-size, -size), Vector2(size, -size), Vector2(size, size), Vector2(-size, size)]
		mote.position = Vector2(randf_range(-1400, 1400), randf_range(-600, 180))
		add_child(mote)
		_motes.append(mote)
		mote.set_meta(&"speed", randf_range(8, 20))
		mote.set_meta(&"phase", randf() * TAU)
		mote.set_meta(&"amp", randf_range(15, 40))


func _process(delta: float) -> void:
	_time += delta
	# Drift motes.
	for mote in _motes:
		var speed: float = mote.get_meta(&"speed", 10.0)
		var phase: float = mote.get_meta(&"phase", 0.0)
		var amp: float = mote.get_meta(&"amp", 20.0)
		mote.position.x -= speed * delta
		if mote.position.x < -1400:
			mote.position.x = 1400
			mote.position.y = randf_range(-600, 180)
		mote.position.y += sin(_time + phase) * amp * delta * 0.3
	# Subtle sky pulse.
	if sky != null:
		var pulse := 0.06 + sin(_time * 0.3) * 0.01
		sky.color = Color(pulse, pulse * 0.85, pulse * 1.8, 1.0)
