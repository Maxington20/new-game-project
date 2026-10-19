
class_name PromotionEligibility
extends RefCounted


static func can_promote(
	unit_state: RunUnitState,
	progression: PermanentProgression,
	catalogue: AchievementCatalogue
) -> bool:
	if unit_state == null:
		return false

	if not unit_state.is_alive:
		return false

	var character: UnitResource = unit_state.character

	if character == null or character.unit_class == null:
		return false

	if character.level < PromotionCalculator.MIN_PROMOTION_LEVEL:
		return false

	# A promoted class has no further promotion path in our
	# current one-promotion system.
	if character.unit_class.promoted_class == null:
		return false

	var options: Array[UnitClassResource] = \
		PromotionOptions.get_available_promotions(
			character,
			progression,
			catalogue
		)

	return not options.is_empty()
