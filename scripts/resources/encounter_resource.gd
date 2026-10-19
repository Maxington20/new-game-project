
class_name EncounterResource
extends Resource

@export_range(1, 8) var encounter_number: int = 1

@export var enemies: Array[UnitResource] = []

@export var enemy_spawn_positions: Array[Vector2i] = []


func is_valid() -> bool:
	if enemies.is_empty():
		return false

	if enemies.size() != enemy_spawn_positions.size():
		return false

	for enemy in enemies:
		if enemy == null:
			return false

	return true
