
class_name EnemyAI
extends Node

const KILL_BONUS: int = 1000
const DAMAGE_WEIGHT: int = 10
const HIT_WEIGHT: float = 0.1


func choose_action(
	enemy: Unit,
	player_units: Array[Unit],
	grid: BattlefieldGrid,
	occupied_cells: Array[Vector2i],
	friendly_cells: Array[Vector2i] = []
) -> Dictionary:
	if enemy == null or enemy.current_hp <= 0:
		return {}

	var living_players: Array[Unit] = []

	for player in player_units:
		if is_instance_valid(player) and player.current_hp > 0:
			living_players.append(player)

	if living_players.is_empty():
		return {}

	# Find every tile this enemy can reach this turn.
	var movement: Dictionary = grid.get_reachable_cells(
		enemy.grid_position,
		enemy.movement_range,
		occupied_cells,
		friendly_cells
	)

	var distances: Dictionary = movement["distances"]
	var previous: Dictionary = movement["previous"]

	var best_attack_score: float = -INF
	var best_attack_cell: Vector2i = enemy.grid_position
	var best_target: Unit = null

	# Evaluate all legal destinations and possible attacks.
	for cell in distances.keys():
		var destination: Vector2i = cell

		if destination in occupied_cells:
			continue

		for player in living_players:
			if not can_attack_from(enemy, destination, player):
				continue

			var score: float = score_attack(
				enemy,
				player
			)

			# Prefer using less movement when attacks are equal.
			score -= float(distances[destination]) * 0.01

			if score > best_attack_score:
				best_attack_score = score
				best_attack_cell = destination
				best_target = player

	if best_target != null:
		return {
			"destination": best_attack_cell,
			"path": build_path(
				grid,
				enemy.grid_position,
				best_attack_cell,
				previous
			),
			"target": best_target
		}

	
	# No attack is possible this turn.
	# Move toward the nearest player using terrain-aware distances.
	var best_move_cell: Vector2i = enemy.grid_position
	var best_move_score: float = INF

	for cell in distances.keys():
		var destination: Vector2i = cell

		if destination in occupied_cells:
			continue

		var nearest_distance: int = 999999

		for player in living_players:
			# The player's occupied tile is still walkable terrain.
			# This calculation ignores units but respects obstacles.
			var distance: int = grid.get_path_distance(
				destination,
				player.grid_position
			)

			if distance == -1:
				continue

			nearest_distance = mini(
				nearest_distance,
				distance
			)

		if nearest_distance == 999999:
			continue

		var move_score: float = float(nearest_distance)

		# Break ties by preferring less movement.
		move_score += float(distances[destination]) * 0.001

		if move_score < best_move_score:
			best_move_score = move_score
			best_move_cell = destination

	return {
		"destination": best_move_cell,
		"path": build_path(
			grid,
			enemy.grid_position,
			best_move_cell,
			previous
		),
		"target": null
	}


func can_attack_from(
	attacker: Unit,
	destination: Vector2i,
	defender: Unit
) -> bool:
	if attacker.equipped_weapon == null:
		return false

	if defender.current_hp <= 0:
		return false

	var distance: int = manhattan_distance(
		destination,
		defender.grid_position
	)

	return (
		distance >= attacker.min_attack_range
		and distance <= attacker.max_attack_range
	)


func score_attack(
	attacker: Unit,
	defender: Unit
) -> float:
	# CombatCalculator uses the attacker's current grid position
	# to determine whether an attack is legal.
	# Temporarily evaluate the destination independently by
	# calculating the combat stats without changing the unit.

	var attacker_class: UnitClassResource = (
		attacker.unit_data.unit_class
	)

	var defender_class: UnitClassResource = (
		defender.unit_data.unit_class
	)

	var triangle: int = (
		CombatCalculator.get_weapon_triangle_advantage(
			attacker,
			defender
		)
	)

	var attack_power: int = (
		attacker_class.strength
		+ attacker.equipped_weapon.might
		+ triangle * CombatCalculator.TRIANGLE_DAMAGE_BONUS
	)

	var damage: int = maxi(
		0,
		attack_power - defender_class.defense
	)

	var hit_rate: int = (
		CombatCalculator.get_hit_rate(attacker)
		+ triangle * CombatCalculator.TRIANGLE_HIT_BONUS
		- CombatCalculator.get_avoid(defender)
	)

	hit_rate = clampi(hit_rate, 0, 100)

	var score: float = (
		float(damage * DAMAGE_WEIGHT)
		+ float(hit_rate) * HIT_WEIGHT
	)

	if damage >= defender.current_hp:
		score += KILL_BONUS

	return score


func build_path(
	grid: Node,
	start: Vector2i,
	destination: Vector2i,
	previous: Dictionary
) -> Array[Vector2i]:
	if start == destination:
		return []

	return grid.reconstruct_path(
		start,
		destination,
		previous
	)


func manhattan_distance(
	a: Vector2i,
	b: Vector2i
) -> int:
	return (
		absi(a.x - b.x)
		+ absi(a.y - b.y)
	)
