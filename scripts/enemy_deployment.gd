
class_name EnemyDeployment
extends RefCounted

const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")


static func create_unit(
	enemy_definition: UnitResource,
	grid_position: Vector2i
) -> Unit:
	if enemy_definition == null:
		return null

	var unit: Unit = UNIT_SCENE.instantiate()

	unit.unit_data = enemy_definition
	unit.team = Unit.Team.ENEMY
	unit.grid_position = grid_position

	return unit


static func create_encounter_units(
	encounter: EncounterResource
) -> Array[Unit]:
	var units: Array[Unit] = []

	if encounter == null or not encounter.is_valid():
		return units

	for index in range(encounter.enemies.size()):
		var unit := create_unit(
			encounter.enemies[index],
			encounter.enemy_spawn_positions[index]
		)

		if unit != null:
			units.append(unit)

	return units
