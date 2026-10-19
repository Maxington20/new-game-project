
extends Node


func _ready() -> void:
	print("=== ENEMY DEPLOYMENT TEST ===")

	var encounter: EncounterResource = load(
		"res://resources/encounters/encounter_01.tres"
	)

	var units := EnemyDeployment.create_encounter_units(encounter)

	print("Created units: ", units.size())

	for unit in units:
		print(
			unit.unit_data.character_name,
			" | Team: ",
			unit.team,
			" | Position: ",
			unit.grid_position
		)

		unit.queue_free()

	print("=== TEST COMPLETE ===")
