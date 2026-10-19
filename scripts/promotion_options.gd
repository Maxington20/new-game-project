
class_name PromotionOptions
extends RefCounted


static func get_available_promotions(
	character: UnitResource,
	progression: PermanentProgression,
	catalogue: AchievementCatalogue
) -> Array[UnitClassResource]:
	var result: Array[UnitClassResource] = []

	if character == null or character.unit_class == null:
		return result

	# Include the character's default promotion.
	var default_promotion: UnitClassResource = character.unit_class.promoted_class

	if default_promotion != null:
		result.append(default_promotion)

	# Include alternative promotions earned through achievements.
	if progression == null or catalogue == null:
		return result

	for achievement in catalogue.get_character_achievements(
		character.character_id
	):
		var alternative: UnitClassResource = achievement.get_unlocked_promotion(
			progression
		)

		if alternative != null and not result.has(alternative):
			result.append(alternative)

	return result
