class_name CombatCalculator
extends RefCounted

const TRIANGLE_DAMAGE_BONUS: int = 1
const TRIANGLE_HIT_BONUS: int = 15
const FOLLOW_UP_SPEED_DIFFERENCE: int = 4

static func can_attack(attacker: Unit, defender: Unit) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return false
	if attacker.current_hp <= 0 or defender.current_hp <= 0 or attacker.team == defender.team:
		return false
	var weapon: WeaponResource = attacker.equipped_weapon
	if weapon == null or attacker.unit_data == null:
		return false
	if not UnitInventory.can_equip(attacker.unit_data, weapon):
		return false
	var distance: int = absi(attacker.grid_position.x - defender.grid_position.x) + absi(attacker.grid_position.y - defender.grid_position.y)
	return distance >= weapon.min_range and distance <= weapon.max_range

static func get_weapon_triangle_advantage(attacker: Unit, defender: Unit) -> int:
	var attacker_weapon: WeaponResource = attacker.equipped_weapon
	var defender_weapon: WeaponResource = defender.equipped_weapon
	if attacker_weapon == null or defender_weapon == null:
		return 0
	var attacker_type: WeaponResource.WeaponType = attacker_weapon.weapon_type
	var defender_type: WeaponResource.WeaponType = defender_weapon.weapon_type
	match attacker_type:
		WeaponResource.WeaponType.SWORD:
			if defender_type == WeaponResource.WeaponType.AXE: return 1
			if defender_type == WeaponResource.WeaponType.LANCE: return -1
		WeaponResource.WeaponType.LANCE:
			if defender_type == WeaponResource.WeaponType.SWORD: return 1
			if defender_type == WeaponResource.WeaponType.AXE: return -1
		WeaponResource.WeaponType.AXE:
			if defender_type == WeaponResource.WeaponType.LANCE: return 1
			if defender_type == WeaponResource.WeaponType.SWORD: return -1
	return 0

static func get_attack_speed(unit: Unit) -> int:
	if unit.stats == null or unit.unit_data.unit_class == null:
		return 0
	var weapon_weight: int = 0
	if unit.equipped_weapon != null:
		weapon_weight = unit.equipped_weapon.weight
	var penalty: int = maxi(0, weapon_weight - unit.unit_data.unit_class.constitution)
	return unit.stats.speed - penalty

static func get_hit_rate(unit: Unit) -> int:
	if unit.equipped_weapon == null or unit.stats == null:
		return 0
	return unit.equipped_weapon.hit + 2 * unit.stats.skill + floori(unit.stats.luck / 2.0)


static func get_avoid(
	unit: Unit,
	terrain_avoid_bonus: int = 0
) -> int:
	if unit.stats == null:
		return 0

	return (
		2 * get_attack_speed(unit)
		+ unit.stats.luck
		+ terrain_avoid_bonus
	)



static func get_displayed_hit(
	attacker: Unit,
	defender: Unit,
	terrain_avoid_bonus: int = 0
) -> int:
	if not can_attack(attacker, defender):
		return 0

	var triangle: int = get_weapon_triangle_advantage(
		attacker,
		defender
	)

	return clampi(
		get_hit_rate(attacker)
		+ triangle * TRIANGLE_HIT_BONUS
		- get_avoid(defender, terrain_avoid_bonus),
		0,
		100
	)


static func get_critical_rate(unit: Unit) -> int:
	if unit.equipped_weapon == null or unit.stats == null:
		return 0
	return unit.equipped_weapon.critical + floori(unit.stats.skill / 2.0)

static func get_displayed_critical(attacker: Unit, defender: Unit) -> int:
	if not can_attack(attacker, defender):
		return 0
	return clampi(get_critical_rate(attacker) - defender.stats.luck, 0, 100)


static func calculate_damage(
	attacker: Unit,
	defender: Unit,
	terrain_defense_bonus: int = 0
) -> int:
	if not can_attack(attacker, defender):
		return 0

	var triangle: int = get_weapon_triangle_advantage(
		attacker,
		defender
	)

	var attack_power: int = (
		attacker.stats.strength
		+ attacker.equipped_weapon.might
		+ triangle * TRIANGLE_DAMAGE_BONUS
	)

	return maxi(
		0,
		attack_power
		- defender.stats.defense
		- terrain_defense_bonus
	)


static func can_counterattack(defender: Unit, attacker: Unit) -> bool:
	return can_attack(defender, attacker)

static func can_follow_up(attacker: Unit, defender: Unit) -> bool:
	return get_attack_speed(attacker) - get_attack_speed(defender) >= FOLLOW_UP_SPEED_DIFFERENCE

static func roll_hit(displayed_hit: int) -> bool:
	var roll_a: int = randi_range(0, 99)
	var roll_b: int = randi_range(0, 99)
	return roll_a + roll_b < displayed_hit * 2

static func roll_critical(displayed_critical: int) -> bool:
	return randi_range(0, 99) < displayed_critical


static func resolve_strike(
	attacker: Unit,
	defender: Unit,
	defender_terrain: TerrainResource = null
) -> Dictionary:
	if not can_attack(attacker, defender):
		return {
			"valid": false,
			"hit": false,
			"critical": false,
			"damage": 0
		}

	var defense_bonus := 0
	var avoid_bonus := 0

	if defender_terrain != null:
		defense_bonus = defender_terrain.defense_bonus
		avoid_bonus = defender_terrain.avoid_bonus

	var hit_chance: int = get_displayed_hit(
		attacker,
		defender,
		avoid_bonus
	)

	var did_hit: bool = roll_hit(hit_chance)

	if not did_hit:
		return {
			"valid": true,
			"hit": false,
			"critical": false,
			"damage": 0
		}

	var critical_chance: int = get_displayed_critical(
		attacker,
		defender
	)

	var did_critical: bool = roll_critical(critical_chance)

	var damage: int = calculate_damage(
		attacker,
		defender,
		defense_bonus
	)

	if did_critical:
		damage *= 3

	return {
		"valid": true,
		"hit": true,
		"critical": did_critical,
		"damage": damage
	}
