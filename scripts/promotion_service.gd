
class_name PromotionService
extends RefCounted


static func promote(
	character: UnitResource,
	target_class: UnitClassResource,
	progression: PermanentProgression,
	catalogue: AchievementCatalogue
) -> Dictionary:
	if character == null or target_class == null:
		return {
			"success": false,
			"reason": "Character or target class is missing"
		}

	if character.unit_class == null:
		return {
			"success": false,
			"reason": "Character has no class"
		}

	# In our single-promotion system, only base classes
	# with a promotion path can promote.
	if character.unit_class.promoted_class == null:
		return {
			"success": false,
			"reason": "Character is not in a promotable class"
		}

	if character.level < PromotionCalculator.MIN_PROMOTION_LEVEL:
		return {
			"success": false,
			"reason": "Character has not reached the promotion level"
		}

	var available: Array[UnitClassResource] = \
		PromotionOptions.get_available_promotions(
			character,
			progression,
			catalogue
		)

	if not available.has(target_class):
		return {
			"success": false,
			"reason": "Promotion class is not unlocked for this character"
		}

	return PromotionCalculator.promote(character, target_class)
