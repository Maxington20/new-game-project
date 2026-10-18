
class_name CharacterRoster
extends Resource

@export var characters: Array[UnitResource] = []


func get_all_characters() -> Array[UnitResource]:
	return characters.duplicate()


func get_character(character_name: String) -> UnitResource:
	for character in characters:
		if character == null:
			continue

		if character.character_name == character_name:
			return character

	return null


func contains_character(character: UnitResource) -> bool:
	if character == null:
		return false

	for roster_character in characters:
		if roster_character == character:
			return true

	return false


func is_valid() -> bool:
	var names: Dictionary = {}

	for character in characters:
		if character == null:
			return false

		if character.character_name.strip_edges().is_empty():
			return false

		if names.has(character.character_name):
			return false

		names[character.character_name] = true

	return true
