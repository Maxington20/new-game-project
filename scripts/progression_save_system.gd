
class_name ProgressionSaveSystem
extends RefCounted

const SAVE_PATH: String = "user://permanent_progression.tres"


static func save_progression(progression: PermanentProgression) -> bool:
	if progression == null:
		return false

	var error: Error = ResourceSaver.save(progression, SAVE_PATH)

	if error != OK:
		push_error("Failed to save permanent progression: " + str(error))
		return false

	return true


static func load_progression() -> PermanentProgression:
	if not ResourceLoader.exists(SAVE_PATH):
		return PermanentProgression.new()

	var progression: PermanentProgression = ResourceLoader.load(
		SAVE_PATH,
		"",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP
	) as PermanentProgression

	if progression == null:
		push_error("Failed to load permanent progression")
		return null

	return progression
