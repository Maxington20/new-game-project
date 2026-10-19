
class_name PromotionCalculator
extends RefCounted

const MIN_PROMOTION_LEVEL: int = 10

const STAT_NAMES: Array[String] = [
	"max_hp", "strength", "skill", "speed", "luck", "defense", "resistance"
]

const WEAPON_FIELDS: Array[String] = [
	"sword", "lance", "axe", "bow", "anima", "light", "dark", "staff"
]

const DEFAULT_CAPS: Dictionary = {
	"max_hp": 60,
	"strength": 20,
	"skill": 20,
	"speed": 20,
	"luck": 30,
	"defense": 20,
	"resistance": 20
}


static func promote(
	unit_data: UnitResource,
	target_class: UnitClassResource = null
) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"reason": "",
		"previous_class": "",
		"new_class": "",
		"previous_level": 0,
		"previous_experience": 0,
		"stat_increases": {},
		"weapon_exp_increases": {}
	}

	for stat_name in STAT_NAMES:
		result["stat_increases"][stat_name] = 0

	for weapon_name in WEAPON_FIELDS:
		result["weapon_exp_increases"][weapon_name] = 0

	if unit_data == null or unit_data.unit_class == null:
		result["reason"] = "Unit or class is missing"
		return result

	if unit_data.level < MIN_PROMOTION_LEVEL:
		result["reason"] = "Unit must be at least level 10 to promote"
		return result

	var old_class: UnitClassResource = unit_data.unit_class

	var new_class: UnitClassResource = target_class

	if new_class == null:
		new_class = old_class.promoted_class

	if new_class == null or new_class == old_class:
		result["reason"] = "No valid promoted class assigned"
		return result

	if new_class.promotion_bonuses == null:
		result["reason"] = "Promoted class has no promotion bonuses resource"
		return result

	if unit_data.stats == null:
		unit_data.stats = UnitStatsResource.from_class(old_class)

	result["previous_class"] = old_class.class_name_display
	result["new_class"] = new_class.class_name_display
	result["previous_level"] = unit_data.level
	result["previous_experience"] = unit_data.experience

	var bonuses: UnitPromotionBonusesResource = new_class.promotion_bonuses
	var caps: UnitStatCapsResource = new_class.stat_caps

	for stat_name in STAT_NAMES:
		var before: int = int(unit_data.stats.get(stat_name))
		var bonus: int = maxi(0, int(bonuses.get(stat_name)))

		var cap: int = int(DEFAULT_CAPS[stat_name])

		if caps != null:
			cap = int(caps.get(stat_name))

		var after: int = mini(before + bonus, cap)

		unit_data.stats.set(stat_name, after)
		result["stat_increases"][stat_name] = after - before

	# Preserve existing weapon proficiency behaviour.
	var weapon_bonuses: WeaponPromotionBonusResource = \
		new_class.weapon_promotion_bonuses

	if weapon_bonuses != null:
		if unit_data.weapon_proficiencies == null:
			unit_data.weapon_proficiencies = WeaponProficiencyResource.new()

		var proficiencies: WeaponProficiencyResource = \
			unit_data.weapon_proficiencies

		for weapon_name in WEAPON_FIELDS:
			var property_name: String = weapon_name + "_exp"
			var minimum_name: String = weapon_name + "_minimum"

			var before: int = int(proficiencies.get(property_name))
			var bonus: int = int(weapon_bonuses.get(property_name))
			var minimum: int = int(weapon_bonuses.get(minimum_name))

			var after: int = clampi(
				maxi(before + bonus, minimum),
				0,
				255
			)

			proficiencies.set(property_name, after)
			result["weapon_exp_increases"][weapon_name] = after - before

	unit_data.unit_class = new_class
	unit_data.level = 1
	unit_data.experience = 0

	result["success"] = true

	return result
