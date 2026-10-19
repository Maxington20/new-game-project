extends Node


func _ready() -> void:
	print("=== TERMINAL RUN STATE TEST ===")

	var run := RunState.new()
	run.current_encounter = 3

	print("Advance active run: ", run.advance_encounter())
	print("Encounter: ", run.current_encounter)

	run.is_defeated = true

	print("Advance defeated run: ", run.advance_encounter())
	print("Encounter after defeat: ", run.current_encounter)

	var completed_run := RunState.new()
	completed_run.current_encounter = 8
	completed_run.complete_run()

	print("Completed run: ", completed_run.is_completed)
	print("Advance completed run: ", completed_run.advance_encounter())

	print("=== TEST COMPLETE ===")
