
extends Node

func _ready() -> void:
	var template: UnitResource = load(
		"res://resources/characters/brienne.tres"
	)

	var roster := CharacterRoster.new()

	for i in range(8):
		var definition: UnitResource = template.duplicate(false) as UnitResource
		definition.character_name = "Test Unit " + str(i + 1)
		roster.characters.append(definition)

	var selection := ArmySelection.new(roster)

	for character in roster.characters:
		selection.select_character(character)

	# Start the first run.
	var first_run: RunState = RunState.create(selection)

	if first_run == null:
		push_error("Failed to create first run")
		return

	# Simulate progression during the first run.
	first_run.army[0].character.level = 10
	first_run.army[0].character.experience = 75
	first_run.army[0].character.stats.strength += 5
	first_run.army[0].apply_damage(999)

	first_run.advance_encounter()
	first_run.advance_encounter()

	print("--- First Run ---")
	print("Level: ", first_run.army[0].character.level)
	print("EXP: ", first_run.army[0].character.experience)
	print("HP: ", first_run.army[0].current_hp)
	print("Alive: ", first_run.army[0].is_alive)
	print("Encounter: ", first_run.current_encounter)

	# Start a completely new run using the same selection.
	var second_run: RunState = RunState.create(selection)

	if second_run == null:
		push_error("Failed to create second run")
		return

	print("--- Second Run ---")
	print("Level: ", second_run.army[0].character.level)
	print("EXP: ", second_run.army[0].character.experience)
	print("HP: ", second_run.army[0].current_hp)
	print("Alive: ", second_run.army[0].is_alive)
	print("Encounter: ", second_run.current_encounter)

	print("--- Independence Checks ---")
	print(
		"Separate character resources: ",
		first_run.army[0].character != second_run.army[0].character
	)
	print(
		"Separate stats resources: ",
		first_run.army[0].character.stats != second_run.army[0].character.stats
	)
	print(
		"Original definition unchanged: ",
		roster.characters[0].level == 1
	)
