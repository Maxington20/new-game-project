class_name StatGrowthCalculator
extends RefCounted

const STAT_NAMES: Array[String] = [
	"max_hp", "strength", "skill", "speed", "luck", "defense", "resistance"
]

# FE7 unpromoted-class caps. Promoted class-specific caps will be
# supplied by the class system when promotion is implemented.
const UNPROMOTED_CAPS: Dictionary = {
	"max_hp": 60,
	"strength": 20,
	"skill": 20,
	"speed": 20,
	"luck": 30,
	"defense": 20,
	"resistance": 20
}

# Rolls each growth independently and applies the result, respecting stat caps.
# Returns actual increases (not successful rolls blocked by a cap).
# Does not change level, EXP, or current battle HP.
static func roll_and_apply(unit_data: UnitResource) -> Dictionary:
	var increases: Dictionary = {}
	for stat_name in STAT_NAMES:
		increases[stat_name] = 0

	if unit_data == null or unit_data.growth_rates == null:
		return increases

	if unit_data.stats == null:
		if unit_data.unit_class == null:
			return increases
		unit_data.stats = UnitStatsResource.from_class(unit_data.unit_class)

	for stat_name in STAT_NAMES:
		var current_value: int = int(unit_data.stats.get(stat_name))
		var cap: int = int(UNPROMOTED_CAPS[stat_name])
		if current_value >= cap:
			continue

		var chance: int = clampi(int(unit_data.growth_rates.get(stat_name)), 0, 100)
		if randi_range(0, 99) < chance:
			unit_data.stats.set(stat_name, current_value + 1)
			increases[stat_name] = 1

	return increases
