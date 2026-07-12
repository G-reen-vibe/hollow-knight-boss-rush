class_name State
extends Node
## Base class for states used by StateMachine.

@warning_ignore("unused_signal")
signal finished(next_state: StringName, msg: Dictionary)

var state_machine: StateMachine
var target: Node  # The node being controlled (e.g. the Player or Boss).

# --- Lifecycle hooks (override in subclasses) -------------------------------

func enter(_msg: Dictionary = {}, _previous: State = null) -> void:
	pass

func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func process(_delta: float) -> void:
	pass

func unhandled_input(_event: InputEvent) -> void:
	pass

# --- Convenience -------------------------------------------------------------

func transition(state_name: StringName, msg: Dictionary = {}) -> void:
	state_machine.transition_to(state_name, msg)
