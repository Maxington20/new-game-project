
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
	var ids: Dictionary = {}
	var names: Dictionary = {}

	for character in characters:
		if character == null:
			return false

		var id: String = character.character_id.strip_edges()
		var name: String = character.character_name.strip_edges()

		if id.is_empty() or name.is_empty():
			return false

		if ids.has(id) or names.has(name):
			return false

		if character.unit_class == null:
			return false

		ids[id] = true
		names[name] = true

	return true
	
	

func get_character_by_id(character_id: String) -> UnitResource:
	for character in characters:
		if character == null:
			continue

		if character.character_id == character_id:
			return character

	return null
