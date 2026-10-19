
class_name EncounterCollection
extends Resource

@export var encounters: Array[EncounterResource] = []


func get_encounter(number: int) -> EncounterResource:
	if number < 1 or number > encounters.size():
		return null

	return encounters[number - 1]


func is_valid() -> bool:
	if encounters.size() != RunState.TOTAL_ENCOUNTERS:
		return false

	for index in range(encounters.size()):
		var encounter := encounters[index]

		if encounter == null or not encounter.is_valid():
			return false

		if encounter.encounter_number != index + 1:
			return false

	return true
