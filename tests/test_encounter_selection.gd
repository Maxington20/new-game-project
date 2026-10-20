
extends Node


func _ready() -> void:
	var run := RunState.new()
	run.current_encounter = 2

	var roster: CharacterRoster = load(
		"res://resources/rosters/default_roster.tres"
	)

	for character in roster.characters:
		run.army.append(RunUnitState.create(character))

	RunManager.start_run(run)

	print("STARTING ENCOUNTER: ", run.current_encounter)
	print("ARMY SIZE: ", run.army.size())

	_test_pathfinding()
	_test_friendly_movement()
	_test_enemy_deployment()

	get_tree().change_scene_to_file.call_deferred(
		"res://scenes/battlefield.tscn"
	)


func _test_pathfinding() -> void:
	var map_scene: PackedScene = load(
		"res://scenes/maps/battlefield_map_02.tscn"
	)

	var test_grid: BattlefieldGrid = map_scene.instantiate()

	print("=== PATHFINDING TEST ===")

	print(
		"Straight path: ",
		test_grid.get_path_distance(
			Vector2i(5, 2),
			Vector2i(5, 8)
		)
	)

	print(
		"Around wall: ",
		test_grid.get_path_distance(
			Vector2i(6, 5),
			Vector2i(8, 5)
		)
	)

	print(
		"Blocked destination: ",
		test_grid.get_path_distance(
			Vector2i(6, 5),
			Vector2i(7, 5)
		)
	)

	print("=== TEST COMPLETE ===")

	test_grid.free()


func _test_friendly_movement() -> void:
	var map_scene: PackedScene = load(
		"res://scenes/maps/battlefield_map_01.tscn"
	)

	var test_grid: BattlefieldGrid = map_scene.instantiate()

	var occupied: Array[Vector2i] = [
		Vector2i(3, 2)
	]

	var friendly: Array[Vector2i] = [
		Vector2i(3, 2)
	]

	var blocked_result := test_grid.get_reachable_cells(
		Vector2i(2, 2),
		2,
		occupied
	)

	var friendly_result := test_grid.get_reachable_cells(
		Vector2i(2, 2),
		2,
		occupied,
		friendly
	)

	print("=== FRIENDLY MOVEMENT TEST ===")

	print(
		"Friendly tile reachable: ",
		friendly_result["distances"].has(Vector2i(3, 2))
	)

	print(
		"Beyond friendly reachable: ",
		friendly_result["distances"].has(Vector2i(4, 2))
	)

	print(
		"Friendly tile blocked without permission: ",
		not blocked_result["distances"].has(Vector2i(3, 2))
	)

	print("=== TEST COMPLETE ===")

	test_grid.free()


func _test_enemy_deployment() -> void:
	var collection: EncounterCollection = load(
		"res://resources/encounters/default_encounters.tres"
	)

	var encounter: EncounterResource = collection.get_encounter(2)

	var enemies := EnemyDeployment.create_encounter_units(encounter)

	print("=== ENEMY DEPLOYMENT TEST ===")
	print("Created units: ", enemies.size())

	for enemy in enemies:
		print(
			"Team: ", enemy.team,
			" | Position: ", enemy.grid_position
		)

		enemy.free()

	print("=== TEST COMPLETE ===")
