
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


static func add_weapon(
	unit_data: UnitResource,
	weapon: WeaponResource
) -> bool:
	if unit_data == null or weapon == null:
		return false

	if not has_space(unit_data):
		return false

	unit_data.inventory.append(weapon)
	return true


static func remove_weapon(
	unit_data: UnitResource,
	weapon: WeaponResource
) -> bool:
	if unit_data == null or weapon == null:
		return false

	var index: int = unit_data.inventory.find(weapon)

	if index == -1:
		return false

	unit_data.inventory.remove_at(index)
	return true


static func contains_weapon(
	unit_data: UnitResource,
	weapon: WeaponResource
) -> bool:
	if unit_data == null or weapon == null:
		return false

	return unit_data.inventory.has(weapon)
