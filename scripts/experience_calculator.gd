class_name ExperienceCalculator
extends RefCounted

# Initial FE7-inspired tuning, not an exact reproduction of FE7's formula.
const BASE_COMBAT_EXP: int = 10
const BASE_DEFEAT_BONUS: int = 20
const EXP_PER_LEVEL_DIFFERENCE: int = 2
const MIN_COMBAT_EXP: int = 1
const MIN_DEFEAT_BONUS: int = 1


# Calculate the reward for one combat encounter, not for each strike.
# did_participate means the unit made at least one valid attack or counterattack.
# defeated_opponent means this unit landed the finishing blow.
static func calculate_experience(
	unit_level: int,
	opponent_level: int,
	did_participate: bool,
	defeated_opponent: bool = false
) -> int:
	if not did_participate:
		return 0

	var level_difference: int = opponent_level - unit_level
	var combat_exp: int = maxi(
		MIN_COMBAT_EXP,
		BASE_COMBAT_EXP + level_difference * EXP_PER_LEVEL_DIFFERENCE
	)

	if not defeated_opponent:
		return combat_exp

	var defeat_bonus: int = maxi(
		MIN_DEFEAT_BONUS,
		BASE_DEFEAT_BONUS + level_difference * EXP_PER_LEVEL_DIFFERENCE
	)
	return combat_exp + defeat_bonus
