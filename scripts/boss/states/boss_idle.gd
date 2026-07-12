extends State
## Boss idle / decision state. Waits briefly then picks the next action.
##
## The boss subclass must override Boss.pick_next_action() to return a state
## name (e.g. &"Approach" or &"TelegraphLeap").

@export var min_idle: float = 0.4
@export var max_idle: float = 0.9

var _timer: float = 0.0


func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	_timer = randf_range(min_idle, max_idle)


func physics_process(delta: float) -> void:
	var b := target as Boss
	_timer -= delta
	if b.target == null or not is_instance_valid(b.target):
		return
	# Apply friction on ground.
	if b.is_on_floor():
		b.velocity.x = move_toward(b.velocity.x, 0.0, 800.0 * delta)
	if _timer <= 0.0:
		var next: StringName = b.pick_next_action()
		if next != &"" and next != name:
			b.state_machine.transition_to(next)
