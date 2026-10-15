
class_name CombatCalculator
extends RefCounted


static func can_attack(
	attacker: Unit,
	defender: Unit
) -> bool:
	if attacker == null or defender == null:
		return false

	if attacker.current_hp <= 0 or defender.current_hp <= 0:
		return false

	if attacker.team == defender.team:
		return false

	var weapon: WeaponResource = attacker.equipped_weapon

	if weapon == null:
		return false

	var distance: int = (
		absi(attacker.grid_position.x - defender.grid_position.x)
		+ absi(attacker.grid_position.y - defender.grid_position.y)
	)

	return (
		distance >= weapon.min_range
		and distance <= weapon.max_range
	)


static func calculate_damage(
	attacker: Unit,
	defender: Unit
) -> int:
	if not can_attack(attacker, defender):
		return 0

	if attacker.unit_data == null or defender.unit_data == null:
		return 0

	var attacker_class: UnitClassResource = (
		attacker.unit_data.unit_class
	)

	var defender_class: UnitClassResource = (
		defender.unit_data.unit_class
	)

	if attacker_class == null or defender_class == null:
		return 0

	var attack_power: int = (
		attacker_class.strength
		+ attacker.equipped_weapon.might
	)

	return maxi(
		0,
		attack_power - defender_class.defense
	)


static func can_counterattack(
	defender: Unit,
	attacker: Unit
) -> bool:
	return can_attack(defender, attacker)
