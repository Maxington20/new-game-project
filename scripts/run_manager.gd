
extends Node

signal run_started(run_state: RunState)
signal run_ended

var active_run: RunState = null


func start_run(run_state: RunState) -> bool:
	if run_state == null:
		push_error("RunManager: Cannot start a null run")
		return false

	if active_run != null:
		push_warning("RunManager: A run is already active")
		return false

	active_run = run_state
	run_started.emit(active_run)
	return true


func get_active_run() -> RunState:
	return active_run


func has_active_run() -> bool:
	return active_run != null


func end_run() -> void:
	if active_run == null:
		return

	active_run = null
	run_ended.emit()
