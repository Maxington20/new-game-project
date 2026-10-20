
class_name TerrainEffectCalculator
extends RefCounted

static func calculate_turn_start_healing(
	current_hp: int,
	max_hp: int,
	terrain: TerrainResource
) -> int:
	if terrain == null:
		return 0

	if current_hp <= 0 or current_hp >= max_hp:
		return 0

	if terrain.turn_start_heal_percent <= 0.0:
		return 0

	var healing: int = maxi(
		1,
		floori(max_hp * terrain.turn_start_heal_percent)
	)

	return mini(healing, max_hp - current_hp)


static func calculate_terrain_damage(
	current_hp: int,
	terrain: TerrainResource,
	on_enter: bool
) -> int:
	if terrain == null or current_hp <= 0:
		return 0

	var damage: int = (
		terrain.damage_on_enter
		if on_enter
		else terrain.damage_on_turn_start
	)

	return mini(damage, current_hp)
