class_name LevelProgression
extends RefCounted

const EXPERIENCE_PER_LEVEL: int = 100
const MAX_LEVEL: int = 20


# Adds character EXP and returns a summary for UI and testing.
# This deliberately does not roll stat growths or play animations.
static func add_experience(unit_data: UnitResource, amount: int) -> Dictionary:
	var result: Dictionary = {
		"previous_level": 0,
		"new_level": 0,
		"previous_experience": 0,
		"new_experience": 0,
		"experience_gained": 0,
		"levels_gained": 0,
		"reached_level_cap": false
	}

	if unit_data == null:
		return result

	result["previous_level"] = unit_data.level
	result["previous_experience"] = unit_data.experience

	# Normalise the saved progression values before applying rewards.
	unit_data.level = clampi(unit_data.level, 1, MAX_LEVEL)
	if unit_data.level >= MAX_LEVEL:
		unit_data.experience = 0
		result["new_level"] = unit_data.level
		result["new_experience"] = unit_data.experience
		result["reached_level_cap"] = true
		return result

	unit_data.experience = maxi(0, unit_data.experience)
	var remaining_capacity: int = (
		(MAX_LEVEL - unit_data.level) * EXPERIENCE_PER_LEVEL
		- unit_data.experience
	)
	var awarded: int = mini(maxi(0, amount), maxi(0, remaining_capacity))
	result["experience_gained"] = awarded
	unit_data.experience += awarded

	while unit_data.experience >= EXPERIENCE_PER_LEVEL and unit_data.level < MAX_LEVEL:
		unit_data.experience -= EXPERIENCE_PER_LEVEL
		unit_data.level += 1
		result["levels_gained"] += 1

	if unit_data.level >= MAX_LEVEL:
		unit_data.experience = 0
		result["reached_level_cap"] = true

	result["new_level"] = unit_data.level
	result["new_experience"] = unit_data.experience
	return result
