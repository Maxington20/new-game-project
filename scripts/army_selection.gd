
class_name ArmySelection
extends RefCounted

const MAX_ARMY_SIZE: int = 8

var roster: CharacterRoster
var progression: PermanentProgression
var selected_characters: Array[UnitResource] = []


func _init(
	character_roster: CharacterRoster,
	permanent_progression: PermanentProgression
) -> void:
	roster = character_roster
	progression = permanent_progression


func select_character(character: UnitResource) -> bool:
	if character == null:
		return false

	if roster == null or progression == null:
		return false

	if not roster.contains_character(character):
		return false

	if not progression.is_character_unlocked(character.character_id):
		return false

	if selected_characters.has(character):
		return false

	if selected_characters.size() >= MAX_ARMY_SIZE:
		return false

	selected_characters.append(character)
	return true


func deselect_character(character: UnitResource) -> bool:
	var index: int = selected_characters.find(character)

	if index == -1:
		return false

	selected_characters.remove_at(index)
	return true


func get_selected_characters() -> Array[UnitResource]:
	return selected_characters.duplicate()


func is_ready() -> bool:
	if selected_characters.size() != MAX_ARMY_SIZE:
		return false

	if roster == null or progression == null:
		return false

	for character in selected_characters:
		if not roster.contains_character(character):
			return false

		if not progression.is_character_unlocked(character.character_id):
			return false

	return true


func clear() -> void:
	selected_characters.clear()
