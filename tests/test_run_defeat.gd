
extends Node


func _ready() -> void:
	print("=== RUN DEFEAT INTEGRATION TEST ===")

	var roster: CharacterRoster = load(
		"res://resources/rosters/default_roster.tres"
	)

	var run := RunState.new()
	run.current_encounter = 1

	for character_id in ["alden", "brienne", "rowan"]:
		var definition: UnitResource = roster.get_character_by_id(character_id)

		if definition == null:
			push_error("Missing character: " + character_id)
			return

		run.army.append(RunUnitState.create(definition))

	# Leave Alden as the only surviving character.
	run.army[1].apply_damage(999)
	run.army[2].apply_damage(999)

	print("Starting encounter: ", run.current_encounter)
	print("Living characters: ", run.get_living_units().size())
	print("Run defeated before battle: ", run.is_defeated)

	if not RunManager.start_run(run):
		push_error("Could not start test run")
		return

	get_tree().change_scene_to_file.call_deferred(
		"res://scenes/battlefield.tscn"
	)
