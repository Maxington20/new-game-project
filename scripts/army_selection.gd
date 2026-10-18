
class_name ArmySelection
extends RefCounted

const MAX_ARMY_SIZE: int = 8

var roster: CharacterRoster
var selected_characters: Array[UnitResource] = []


func _init(character_roster: CharacterRoster) -> void:
	roster = character_roster


func select_character(character: UnitResource) -> bool:
	if character == null:
		return false

	if roster == null or not roster.contains_character(character):
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
	return selected_characters.size() == MAX_ARMY_SIZE


func clear() -> void:
	selected_characters.clear()
