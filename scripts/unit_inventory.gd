class_name UnitInventory
extends RefCounted

const MAX_ITEMS: int = 5

static func get_items(unit_data: UnitResource) -> Array[WeaponResource]:
	if unit_data == null:
		return []
	return unit_data.inventory

static func has_space(unit_data: UnitResource) -> bool:
	if unit_data == null:
		return false
	return unit_data.inventory.size() < MAX_ITEMS

static func add_weapon(unit_data: UnitResource, weapon: WeaponResource) -> bool:
	if unit_data == null or weapon == null:
		return false
	if not has_space(unit_data):
		return false
	unit_data.inventory.append(weapon)
	return true

static func remove_weapon(unit_data: UnitResource, weapon: WeaponResource) -> bool:
	if unit_data == null or weapon == null:
		return false
	var index: int = unit_data.inventory.find(weapon)
	if index == -1:
		return false
	unit_data.inventory.remove_at(index)
	return true

static func contains_weapon(unit_data: UnitResource, weapon: WeaponResource) -> bool:
	if unit_data == null or weapon == null:
		return false
	return unit_data.inventory.has(weapon)

static func get_required_experience(rank: WeaponResource.WeaponRank) -> int:
	match rank:
		WeaponResource.WeaponRank.E: return WeaponProficiencyCalculator.RANK_E
		WeaponResource.WeaponRank.D: return WeaponProficiencyCalculator.RANK_D
		WeaponResource.WeaponRank.C: return WeaponProficiencyCalculator.RANK_C
		WeaponResource.WeaponRank.B: return WeaponProficiencyCalculator.RANK_B
		WeaponResource.WeaponRank.A: return WeaponProficiencyCalculator.RANK_A
		WeaponResource.WeaponRank.S: return WeaponProficiencyCalculator.RANK_S
	return WeaponProficiencyCalculator.RANK_E

static func can_equip(unit_data: UnitResource, weapon: WeaponResource) -> bool:
	if unit_data == null or weapon == null:
		return false
	if unit_data.unit_class == null or unit_data.weapon_proficiencies == null:
		return false
	if not contains_weapon(unit_data, weapon):
		return false
	if not unit_data.unit_class.can_use_weapon_type(weapon.weapon_type):
		return false
	var required_exp: int = get_required_experience(weapon.required_rank)
	return WeaponProficiencyCalculator.can_use_weapon(
		unit_data.weapon_proficiencies, weapon.weapon_type, required_exp
	)
