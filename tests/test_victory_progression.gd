
extends Node


func _ready() -> void:
	print("=== VICTORY PROGRESSION TEST ===")

	var roster: CharacterRoster = load(
		"res://resources/rosters/default_roster.tres"
	)

	var run := RunState.new()
	run.current_encounter = RunState.TOTAL_ENCOUNTERS

	for character_id in ["alden", "brienne", "rowan"]:
		var definition: UnitResource = roster.get_character_by_id(character_id)

		if definition == null:
			push_error("Missing character: " + character_id)
			return

		run.army.append(RunUnitState.create(definition))

	if not RunManager.start_run(run):
		push_error("Could not start test run")
		return

	print("Starting encounter: ", run.current_encounter)
	print("Army members: ", run.army.size())

	get_tree().change_scene_to_file.call_deferred(
		"res://scenes/battlefield.tscn"
	)
