class_name RunCharacterFactory
extends RefCounted


static func create_character(definition: UnitResource) -> UnitResource:
	if definition == null or definition.unit_class == null:
		return null

	# Keep shared class/weapon definitions, but isolate mutable character data.
	var character: UnitResource = definition.duplicate(false) as UnitResource
	character.level = 1
	character.experience = 0

	if definition.stats != null:
		character.stats = definition.stats.duplicate(true) as UnitStatsResource
	else:
		character.stats = UnitStatsResource.from_class(definition.unit_class)

	if definition.growth_rates != null:
		character.growth_rates = definition.growth_rates.duplicate(true) as UnitGrowthResource

	if definition.weapon_proficiencies != null:
		character.weapon_proficiencies = definition.weapon_proficiencies.duplicate(true) as WeaponProficiencyResource
	else:
		character.weapon_proficiencies = WeaponProficiencyResource.new()

	# Copy the inventory container so adding/removing equipment during a run
	# never changes the permanent character definition.
	character.inventory = definition.inventory.duplicate()
	return character
