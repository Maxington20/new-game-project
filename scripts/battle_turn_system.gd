
class_name BattleTurnSystem
extends Node

signal phase_changed(team: Unit.Team)

var current_team: Unit.Team = Unit.Team.PLAYER
var units: Array[Unit] = []


func initialize(battle_units: Array[Unit]) -> void:
	units = battle_units
	start_phase(Unit.Team.PLAYER)


func start_phase(team: Unit.Team) -> void:
	current_team = team

	for unit in units:
		if not is_instance_valid(unit):
			continue

		if unit.current_hp <= 0:
			continue

		if unit.team == current_team:
			unit.has_acted = false
			unit.queue_redraw()

	phase_changed.emit(current_team)


func end_phase() -> void:
	if current_team == Unit.Team.PLAYER:
		start_phase(Unit.Team.ENEMY)
	else:
		start_phase(Unit.Team.PLAYER)


func can_unit_act(unit: Unit) -> bool:
	if not is_instance_valid(unit):
		return false

	return (
		unit.current_hp > 0
		and unit.team == current_team
		and not unit.has_acted
		and not unit.is_moving
	)


func mark_unit_acted(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return

	unit.has_acted = true
	unit.queue_redraw()


func are_all_units_done() -> bool:
	for unit in units:
		if not is_instance_valid(unit):
			continue

		if unit.current_hp <= 0:
			continue

		if unit.team == current_team and not unit.has_acted:
			return false

	return true
