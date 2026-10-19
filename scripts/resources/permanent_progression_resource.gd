
class_name PermanentProgression
extends Resource

@export var unlocked_character_ids: Array[String] = []
@export var character_achievements: Array[CharacterAchievementProgress] = []


func is_character_unlocked(character_id: String) -> bool:
	return unlocked_character_ids.has(character_id)


func unlock_character(character_id: String) -> bool:
	if character_id.strip_edges().is_empty():
		return false

	if is_character_unlocked(character_id):
		return false

	unlocked_character_ids.append(character_id)
	return true


func get_unlocked_characters(roster: CharacterRoster) -> Array[UnitResource]:
	var result: Array[UnitResource] = []

	if roster == null:
		return result

	for character in roster.characters:
		if character == null:
			continue

		if is_character_unlocked(character.character_id):
			result.append(character)

	return result


func get_character_progress(character_id: String) -> CharacterAchievementProgress:
	for progress in character_achievements:
		if progress != null and progress.character_id == character_id:
			return progress

	return null


func get_or_create_character_progress(
	character_id: String
) -> CharacterAchievementProgress:
	if character_id.strip_edges().is_empty():
		return null

	var existing: CharacterAchievementProgress = get_character_progress(character_id)

	if existing != null:
		return existing

	var progress := CharacterAchievementProgress.new()
	progress.character_id = character_id
	character_achievements.append(progress)

	return progress


func add_achievement_progress(
	character_id: String,
	achievement_id: String,
	amount: int = 1
) -> void:
	if achievement_id.strip_edges().is_empty() or amount <= 0:
		return

	var progress: CharacterAchievementProgress = get_or_create_character_progress(
		character_id
	)

	if progress == null:
		return

	progress.add_progress(achievement_id, amount)
