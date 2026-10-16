
class_name WeaponProficiencyCalculator
extends RefCounted

const MAX_EXPERIENCE: int = 255

const RANK_E: int = 1
const RANK_D: int = 31
const RANK_C: int = 71
const RANK_B: int = 121
const RANK_A: int = 181
const RANK_S: int = 251


static func get_rank(experience: int) -> String:
	if experience >= RANK_S:
		return "S"

	if experience >= RANK_A:
		return "A"

	if experience >= RANK_B:
		return "B"

	if experience >= RANK_C:
		return "C"

	if experience >= RANK_D:
		return "D"

	if experience >= RANK_E:
		return "E"

	return "-"


static func get_next_rank_threshold(
	experience: int
) -> int:
	if experience < RANK_E:
		return RANK_E

	if experience < RANK_D:
		return RANK_D

	if experience < RANK_C:
		return RANK_C

	if experience < RANK_B:
		return RANK_B

	if experience < RANK_A:
		return RANK_A

	if experience < RANK_S:
		return RANK_S

	return MAX_EXPERIENCE


static func can_use_weapon(
	proficiencies: WeaponProficiencyResource,
	weapon_type: WeaponResource.WeaponType,
	required_experience: int
) -> bool:
	if proficiencies == null:
		return false

	var experience: int = proficiencies.get_experience(
		weapon_type
	)

	if experience <= 0:
		return false

	return experience >= required_experience
