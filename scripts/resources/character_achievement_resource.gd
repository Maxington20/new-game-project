
class_name CharacterAchievementResource
extends Resource

@export_group("Identity")
@export var achievement_id: String = ""
@export var achievement_name: String = ""
@export_multiline var description: String = ""

@export_group("Requirements")
@export var statistic_id: String = ""
@export_range(1, 100000) var required_progress: int = 1

@export_group("Character")
@export var character_id: String = ""

@export_group("Rewards")
@export var unlocked_promotion: UnitClassResource


func is_completed(progression: PermanentProgression) -> bool:
	if progression == null:
		return false

	if character_id.strip_edges().is_empty():
		return false

	if statistic_id.strip_edges().is_empty():
		return false

	var progress: CharacterAchievementProgress = progression.get_character_progress(
		character_id
	)

	if progress == null:
		return false

	return progress.has_completed(statistic_id, required_progress)


func get_unlocked_promotion(
	progression: PermanentProgression
) -> UnitClassResource:
	if not is_completed(progression):
		return null

	return unlocked_promotion
