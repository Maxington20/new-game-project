
class_name AchievementCatalogue
extends Resource

@export var achievements: Array[CharacterAchievementResource] = []


func get_achievement(
	achievement_id: String,
	character_id: String
) -> CharacterAchievementResource:
	for achievement in achievements:
		if achievement == null:
			continue

		if achievement.achievement_id == achievement_id \
		and achievement.character_id == character_id:
			return achievement

	return null


func get_character_achievements(
	character_id: String
) -> Array[CharacterAchievementResource]:
	var result: Array[CharacterAchievementResource] = []

	for achievement in achievements:
		if achievement == null:
			continue

		if achievement.character_id == character_id:
			result.append(achievement)

	return result


func get_completed_achievements(
	character_id: String,
	progression: PermanentProgression
) -> Array[CharacterAchievementResource]:
	var result: Array[CharacterAchievementResource] = []

	if progression == null:
		return result

	for achievement in get_character_achievements(character_id):
		if achievement.is_completed(progression):
			result.append(achievement)

	return result
