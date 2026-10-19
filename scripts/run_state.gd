
class_name RunState
extends Resource

const ARMY_SIZE: int = 8
const TOTAL_ENCOUNTERS: int = 8

@export var army: Array[RunUnitState] = []
@export var current_encounter: int = 0
@export var is_completed: bool = false
@export var is_defeated: bool = false

static func create(selection: ArmySelection) -> RunState:
	if selection == null or not selection.is_ready():
		return null

	var selected: Array[UnitResource] = selection.get_selected_characters()

	if selected.size() != ARMY_SIZE:
		return null

	var state := RunState.new()

	for definition in selected:
		var unit_state: RunUnitState = RunUnitState.create(definition)

		if unit_state == null:
			return null

		state.army.append(unit_state)

	state.current_encounter = 1
	return state


func get_living_units() -> Array[RunUnitState]:
	var living: Array[RunUnitState] = []

	for unit_state in army:
		if unit_state != null and unit_state.is_alive:
			living.append(unit_state)

	return living


func is_army_defeated() -> bool:
	return get_living_units().is_empty()


func advance_encounter() -> bool:
	if is_completed or is_defeated:
		return false

	if current_encounter < 1 or current_encounter >= TOTAL_ENCOUNTERS:
		return false

	current_encounter += 1
	return true


func complete_run() -> bool:
	if is_completed:
		return false

	if current_encounter != TOTAL_ENCOUNTERS:
		return false

	is_completed = true
	return true

func defeat_run() -> bool:
	if is_completed or is_defeated:
		return false

	if not is_army_defeated():
		return false

	is_defeated = true
	return true
