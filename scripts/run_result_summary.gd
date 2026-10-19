
class_name RunResultSummary
extends RefCounted

var is_victory: bool = false
var encounters_completed: int = 0
var total_encounters: int = RunState.TOTAL_ENCOUNTERS
var survivors: Array[RunUnitState] = []
var casualties: Array[RunUnitState] = []


static func from_run(run: RunState) -> RunResultSummary:
	if run == null:
		return null

	if not run.is_completed and not run.is_defeated:
		return null

	var summary := RunResultSummary.new()

	summary.is_victory = run.is_completed

	if run.is_completed:
		summary.encounters_completed = run.current_encounter
	else:
		summary.encounters_completed = maxi(
			0,
			run.current_encounter - 1
		)

	for unit_state in run.army:
		if unit_state == null:
			continue

		if unit_state.is_alive:
			summary.survivors.append(unit_state)
		else:
			summary.casualties.append(unit_state)

	return summary
