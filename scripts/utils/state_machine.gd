class_name StateMachine
extends Node
## Generic finite state machine.
##
## Add as a child of the node whose states you want to manage.
## The first state added becomes the initial state.
## States are State nodes that are children of this StateMachine.

@export var initial_state: State

var current_state: State
var states: Dictionary[StringName, State] = {}

# The node that owns this state machine (typically the parent).
var target: Node


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
			child.target = target if target != null else get_parent()
	if initial_state == null and states.size() > 0:
		initial_state = states.values()[0]


func _physics_process(_delta: float) -> void:
	if current_state == null:
		if initial_state != null:
			transition_to(initial_state.name)
		return
	current_state.physics_process(_delta)


func _process(_delta: float) -> void:
	if current_state == null:
		return
	current_state.process(_delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state == null:
		return
	current_state.unhandled_input(event)


func transition_to(target_state: StringName, msg: Dictionary = {}) -> void:
	if not states.has(target_state):
		push_warning("StateMachine: state '%s' not found" % target_state)
		return
	var previous := current_state
	if previous != null:
		previous.exit()
	current_state = states[target_state]
	current_state.enter(msg, previous)
