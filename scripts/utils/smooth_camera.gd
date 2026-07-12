extends Camera2D
## Smooth-following camera. Set `follow_target` to the node to track.

@export var follow_target: NodePath
@export var smoothing: float = 6.0
@export var look_ahead: float = 80.0
@export var vertical_offset: float = -40.0

var _target_node: Node2D


func _ready() -> void:
	if not follow_target.is_empty():
		_target_node = get_node(follow_target)
	make_current()


func _process(delta: float) -> void:
	if _target_node == null or not is_instance_valid(_target_node):
		return
	# Look-ahead in the direction of horizontal velocity.
	var vel_x: float = 0.0
	if _target_node is CharacterBody2D:
		vel_x = (_target_node as CharacterBody2D).velocity.x
	var target_pos := _target_node.global_position
	target_pos.x += clamp(vel_x * 0.08, -look_ahead, look_ahead)
	target_pos.y += vertical_offset
	global_position = global_position.lerp(target_pos, 1.0 - exp(-smoothing * delta))
