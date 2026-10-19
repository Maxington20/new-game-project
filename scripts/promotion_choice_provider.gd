
class_name PromotionChoiceProvider
extends RefCounted


static func get_choices(
	unit_state: RunUnitState,
	progression: PermanentProgression,
	catalogue: AchievementCatalogue
) -> Array[UnitClassResource]:
	var result: Array[UnitClassResource] = []

	if not PromotionEligibility.can_promote(
		unit_state,
		progression,
		catalogue
	):
		return result

	return PromotionOptions.get_available_promotions(
		unit_state.character,
		progression,
		catalogue
	)
