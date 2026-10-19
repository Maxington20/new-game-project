
class_name BattlefieldDeployment
extends RefCounted

const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")


static func get_deployable_units(
	run_state: RunState
) -> Array[RunUnitState]:
	var result: Array[RunUnitState] = []

	if run_state == null:
		return result

	for unit_state in run_state.army:
		if unit_state == null:
			continue

		if not unit_state.is_alive:
			continue

		if unit_state.current_hp <= 0:
			continue

		result.append(unit_state)

	return result


static func create_unit(
	unit_state: RunUnitState,
	grid_position: Vector2i
) -> Unit:
	if unit_state == null:
		push_error("Cannot deploy a null unit state")
		return null

	if not unit_state.is_alive or unit_state.current_hp <= 0:
		push_error("Cannot deploy a dead character")
		return null

	if unit_state.character == null:
		push_error("Cannot deploy a character without data")
		return null

	var unit: Unit = UNIT_SCENE.instantiate() as Unit

	if unit == null:
		push_error("Failed to instantiate battlefield unit")
		return null

	unit.run_state = unit_state
	unit.team = Unit.Team.PLAYER
	unit.grid_position = grid_position

	return unit
