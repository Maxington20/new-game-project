
class_name BattlefieldGrid
extends Node2D

signal cell_selected(cell: Vector2i)

const CELL_SIZE: int = 32
const GRID_WIDTH: int = 16
const GRID_HEIGHT: int = 12

@export var terrain_cells: Array[TerrainCellResource] = []
@export var blocked_cells: Array[Vector2i] = []
@export var color_light: Color = Color("#8fae82")
@export var color_dark: Color = Color("#78996c")
@export var color_lines: Color = Color("#425c3b")

const COLOR_SELECTED := Color("#e8d36a")
const COLOR_MOVEMENT := Color("#6a9fe8")
const COLOR_ATTACK := Color("#d96b6b")

const DESERT_LIGHT := Color("#c9b38a")
const DESERT_DARK := Color("#b7a077")
const DESERT_LINES := Color("#8e7b5e")

const SNOW_LIGHT := Color("#e1e9ed")
const SNOW_DARK := Color("#cbd8df")
const SNOW_LINES := Color("#a5b8c3")

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]

enum Biome {
	GRASSLAND,
	DESERT,
	SNOW
}

@export var biome: Biome = Biome.GRASSLAND

var selected_cell: Vector2i = Vector2i(-1, -1)
var highlighted_cells: Array[Vector2i] = []
var attack_cells: Array[Vector2i] = []


func _draw() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)

			var rect := Rect2(
				Vector2(cell * CELL_SIZE),
				Vector2(CELL_SIZE, CELL_SIZE)
			)

			# Base ground colour depends on the map's biome.
			var color: Color = get_biome_ground_color(cell)
				
			

			# Special terrain.
			var terrain := get_terrain_at(cell)

			if terrain != null:
				var terrain_color := get_terrain_color(terrain)

				if terrain_color.a > 0.0:
					color = terrain_color

			# Blocked terrain.
			if blocked_cells.has(cell):
				color = Color("#555555")

			# Draw the terrain.
			draw_rect(rect, color)

			# Draw terrain decorations.
			if not blocked_cells.has(cell):
				if terrain == null or terrain.terrain_type == TerrainResource.TerrainType.PLAINS:
					match biome:
						Biome.DESERT:
							draw_desert_tile(cell, rect.position)

						Biome.GRASSLAND:
							draw_plains_tile(cell, rect.position)

						Biome.SNOW:
							pass
				else:
					match terrain.terrain_type:
						TerrainResource.TerrainType.FOREST:
							draw_forest_tile(rect.position)

						TerrainResource.TerrainType.FORT:
							draw_fort_tile(rect.position)

						TerrainResource.TerrainType.LAVA:
							draw_lava_tile(rect.position)

			# Draw grid lines appropriate for the biome.
			var line_color: Color = color_lines

			match biome:
				Biome.DESERT:
					line_color = DESERT_LINES
				Biome.SNOW:
					line_color = SNOW_LINES

			draw_rect(rect, line_color, false, 1.0)

			# Draw movement and attack borders.
			if cell in highlighted_cells:
				draw_rect(
					rect.grow(-2),
					COLOR_MOVEMENT,
					false,
					3.0
				)

			elif cell in attack_cells:
				draw_rect(
					rect.grow(-2),
					COLOR_ATTACK,
					false,
					3.0
				)

			# Selected unit takes priority.
			if cell == selected_cell:
				draw_rect(
					rect.grow(-2),
					COLOR_SELECTED,
					false,
					3.0
				)


func draw_forest_tile(tile_position: Vector2) -> void:
	# Three small trees arranged in a cluster.
	draw_pixel_tree(tile_position + Vector2(5, 5), 0.85)
	draw_pixel_tree(tile_position + Vector2(17, 3), 0.85)
	draw_pixel_tree(tile_position + Vector2(11, 16), 0.85)


func draw_pixel_tree(
	position: Vector2,
	scale_factor: float = 1.0
) -> void:
	var foliage_dark := Color("#164526")
	var foliage_light := Color("#3c9650")
	var trunk_color := Color("#795437")

	# Draw a small trunk.
	draw_rect(
		Rect2(
			position + Vector2(5, 11) * scale_factor,
			Vector2(3, 5) * scale_factor
		),
		trunk_color
	)

	# Draw the tree canopy using overlapping rectangles.
	draw_rect(
		Rect2(
			position + Vector2(3, 4) * scale_factor,
			Vector2(8, 9) * scale_factor
		),
		foliage_dark
	)

	draw_rect(
		Rect2(
			position + Vector2(1, 7) * scale_factor,
			Vector2(12, 4) * scale_factor
		),
		foliage_dark
	)

	# Highlight the upper part of the canopy.
	draw_rect(
		Rect2(
			position + Vector2(4, 5) * scale_factor,
			Vector2(5, 3) * scale_factor
		),
		foliage_light
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position := get_local_mouse_position()

			var cell := Vector2i(
				floori(mouse_position.x / CELL_SIZE),
				floori(mouse_position.y / CELL_SIZE)
			)

			if is_cell_in_bounds(cell):
				cell_selected.emit(cell)


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < GRID_WIDTH
		and cell.y >= 0
		and cell.y < GRID_HEIGHT
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL_SIZE) + Vector2.ONE * CELL_SIZE / 2.0


func get_reachable_cells(
	origin: Vector2i,
	movement_range: int,
	occupied_cells: Array[Vector2i],
	friendly_cells: Array[Vector2i] = []
) -> Dictionary:
	var distances: Dictionary = {origin: 0}
	var previous: Dictionary = {}

	var frontier: Array[Vector2i] = [origin]
	var visited: Dictionary = {}

	while not frontier.is_empty():
		# Find the unvisited cell with the lowest movement cost.
		var cheapest_index := 0

		for i in range(1, frontier.size()):
			if distances[frontier[i]] < distances[frontier[cheapest_index]]:
				cheapest_index = i

		var current := frontier[cheapest_index]
		frontier.remove_at(cheapest_index)

		if visited.has(current):
			continue

		visited[current] = true

		for direction in DIRECTIONS:
			var next := current + direction

			if not is_cell_walkable(next):
				continue

			# Friendly units can be passed through.
			# Enemy units block movement.
			if next in occupied_cells and next not in friendly_cells:
				continue

			var movement_cost := get_movement_cost(next)
			var new_distance: int = distances[current] + movement_cost

			if new_distance > movement_range:
				continue

			# Only update when we've found a cheaper route.
			if distances.has(next):
				if new_distance >= distances[next]:
					continue

			distances[next] = new_distance
			previous[next] = current

			frontier.append(next)

	return {
		"distances": distances,
		"previous": previous
	}


func get_attack_cells(
	origin: Vector2i,
	min_range: int,
	max_range: int
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)

			var distance := (
				absi(cell.x - origin.x)
				+ absi(cell.y - origin.y)
			)

			if distance >= min_range and distance <= max_range:
				cells.append(cell)

	return cells


func get_potential_attack_cells(
	movement_cells: Array[Vector2i],
	min_range: int,
	max_range: int
) -> Array[Vector2i]:
	var attackable: Dictionary = {}
	var movement_lookup: Dictionary = {}

	for cell in movement_cells:
		movement_lookup[cell] = true

	for origin in movement_cells:
		var cells := get_attack_cells(
			origin,
			min_range,
			max_range
		)

		for cell in cells:
			if not movement_lookup.has(cell):
				attackable[cell] = true

	var result: Array[Vector2i] = []

	for cell in attackable.keys():
		result.append(cell)

	return result


func reconstruct_path(
	origin: Vector2i,
	destination: Vector2i,
	previous: Dictionary
) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	if destination == origin:
		return path

	if not previous.has(destination):
		return path

	var current := destination

	while current != origin:
		path.push_front(current)
		current = previous[current]

	return path


func is_cell_walkable(cell: Vector2i) -> bool:
	return is_cell_in_bounds(cell) and not blocked_cells.has(cell)


func get_path_distance(
	start: Vector2i,
	destination: Vector2i
) -> int:
	if not is_cell_walkable(start):
		return -1

	if not is_cell_walkable(destination):
		return -1

	var distances: Dictionary = {start: 0}
	var frontier: Array[Vector2i] = [start]
	var visited: Dictionary = {}

	while not frontier.is_empty():
		# Find the cell with the lowest accumulated movement cost.
		var best_index := 0

		for i in range(1, frontier.size()):
			if distances[frontier[i]] < distances[frontier[best_index]]:
				best_index = i

		var current: Vector2i = frontier[best_index]
		frontier.remove_at(best_index)

		if visited.has(current):
			continue

		if current == destination:
			return distances[current]

		visited[current] = true

		for direction in DIRECTIONS:
			var next: Vector2i = current + direction

			if not is_cell_walkable(next):
				continue

			var movement_cost := get_movement_cost(next)
			var new_distance: int = distances[current] + movement_cost

			if distances.has(next):
				if new_distance >= distances[next]:
					continue

			distances[next] = new_distance
			frontier.append(next)

	return -1


func get_terrain_at(cell: Vector2i) -> TerrainResource:
	for terrain_cell in terrain_cells:
		if terrain_cell == null:
			continue

		if terrain_cell.position == cell:
			return terrain_cell.terrain

	return null


func get_terrain_color(terrain: TerrainResource) -> Color:
	if terrain == null:
		return Color.TRANSPARENT

	match terrain.terrain_type:
		TerrainResource.TerrainType.FOREST:
			return Color("#246b35")

		TerrainResource.TerrainType.FORT:
			return Color("#667788")

		TerrainResource.TerrainType.LAVA:
			return Color("#e65c20")

		_:
			return Color.TRANSPARENT


func get_movement_cost(cell: Vector2i) -> int:
	var terrain := get_terrain_at(cell)

	if terrain == null:
		return 1

	return terrain.movement_cost
	
	


func draw_fort_tile(tile_position: Vector2) -> void:
	var stone_dark := Color("#354454")
	var stone_mid := Color("#718498")
	var stone_light := Color("#a1b0bf")
	var gate_color := Color("#25303b")

	# Castle foundation.
	draw_rect(
		Rect2(tile_position + Vector2(3, 13), Vector2(26, 17)),
		stone_dark
	)

	# Main castle wall.
	draw_rect(
		Rect2(tile_position + Vector2(5, 15), Vector2(22, 13)),
		stone_mid
	)

	# Left tower.
	draw_rect(
		Rect2(tile_position + Vector2(3, 7), Vector2(8, 21)),
		stone_mid
	)

	# Right tower.
	draw_rect(
		Rect2(tile_position + Vector2(21, 7), Vector2(8, 21)),
		stone_mid
	)

	# Tower battlements.
	for x in [2, 7, 21, 26]:
		draw_rect(
			Rect2(tile_position + Vector2(x, 4), Vector2(5, 5)),
			stone_light
		)

	# Central wall battlements.
	for x in [12, 17]:
		draw_rect(
			Rect2(tile_position + Vector2(x, 11), Vector2(4, 5)),
			stone_light
		)

	# Castle gate.
	draw_rect(
		Rect2(tile_position + Vector2(13, 21), Vector2(6, 9)),
		gate_color
	)

	# Gate arch.
	draw_rect(
		Rect2(tile_position + Vector2(14, 19), Vector2(4, 3)),
		gate_color
	)

	# Small tower windows.
	draw_rect(
		Rect2(tile_position + Vector2(6, 13), Vector2(2, 4)),
		gate_color
	)

	draw_rect(
		Rect2(tile_position + Vector2(24, 13), Vector2(2, 4)),
		gate_color
	)



func draw_lava_tile(tile_position: Vector2) -> void:
	var lava_dark := Color("#b83d1c")
	var lava_bright := Color("#ffb52e")
	var lava_hot := Color("#ffe27a")

	# Subtle darker currents within the molten surface.
	draw_rect(
		Rect2(tile_position + Vector2(3, 5), Vector2(9, 3)),
		lava_dark
	)

	draw_rect(
		Rect2(tile_position + Vector2(20, 25), Vector2(8, 3)),
		lava_dark
	)

	# Main flowing lava channel.
	var main_flow := PackedVector2Array([
		tile_position + Vector2(0, 20),
		tile_position + Vector2(6, 17),
		tile_position + Vector2(12, 21),
		tile_position + Vector2(19, 14),
		tile_position + Vector2(25, 16),
		tile_position + Vector2(32, 10)
	])

	draw_polyline(main_flow, lava_bright, 4.0, false)

	# Bright inner highlights.
	var hot_flow := PackedVector2Array([
		tile_position + Vector2(6, 17),
		tile_position + Vector2(12, 21),
		tile_position + Vector2(19, 14)
	])

	draw_polyline(hot_flow, lava_hot, 2.0, false)

	# Smaller branching streams.
	draw_line(
		tile_position + Vector2(12, 21),
		tile_position + Vector2(10, 29),
		lava_bright,
		2.0
	)

	draw_line(
		tile_position + Vector2(25, 16),
		tile_position + Vector2(28, 24),
		lava_bright,
		2.0
	)

	# Small molten highlights.
	draw_rect(
		Rect2(tile_position + Vector2(4, 11), Vector2(4, 2)),
		lava_hot
	)

	draw_rect(
		Rect2(tile_position + Vector2(23, 5), Vector2(5, 2)),
		lava_hot
	)



func draw_plains_tile(cell: Vector2i, tile_position: Vector2) -> void:
	# A stable pseudo-random pattern based on cell coordinates.
	# No actual RNG, so redraws always produce the same result.
	var seed_value: int = absi(
		cell.x * 73856093 ^ cell.y * 19349663
	)

	var variation: int = seed_value % 4
	var grass_dark := Color("#527b47")
	var grass_light := Color("#a5c394")
	var flower_color := Color("#e8d78a")

	match variation:
		0:
			# Two small grass tufts.
			draw_line(
				tile_position + Vector2(8, 22),
				tile_position + Vector2(6, 17),
				grass_dark,
				1.0
			)
			draw_line(
				tile_position + Vector2(8, 22),
				tile_position + Vector2(10, 16),
				grass_dark,
				1.0
			)
			draw_line(
				tile_position + Vector2(23, 12),
				tile_position + Vector2(25, 8),
				grass_light,
				1.0
			)

		1:
			# Scattered short blades.
			for offset in [
				Vector2(5, 9),
				Vector2(19, 23),
				Vector2(27, 14)
			]:
				draw_line(
					tile_position + offset,
					tile_position + offset + Vector2(-2, -4),
					grass_dark,
					1.0
				)

		2:
			# A small tuft with a tiny flower.
			draw_line(
				tile_position + Vector2(11, 24),
				tile_position + Vector2(9, 19),
				grass_dark,
				1.0
			)
			draw_line(
				tile_position + Vector2(11, 24),
				tile_position + Vector2(14, 20),
				grass_dark,
				1.0
			)
			draw_rect(
				Rect2(tile_position + Vector2(23, 9), Vector2(2, 2)),
				flower_color
			)

		3:
			# Sparse ground details.
			draw_rect(
				Rect2(tile_position + Vector2(7, 14), Vector2(3, 1)),
				grass_light
			)
			draw_rect(
				Rect2(tile_position + Vector2(22, 25), Vector2(2, 1)),
				grass_dark
			)


func get_biome_ground_color(cell: Vector2i) -> Color:
	var is_light: bool = (cell.x + cell.y) % 2 == 0

	match biome:
		Biome.DESERT:
			return DESERT_LIGHT if is_light else DESERT_DARK

		Biome.SNOW:
			return SNOW_LIGHT if is_light else SNOW_DARK

		_:
			return color_light if is_light else color_dark


func draw_desert_tile(cell: Vector2i, tile_position: Vector2) -> void:
	# Deterministic variation: each cell keeps its pattern on redraw.
	var seed_value: int = absi(
		cell.x * 73856093 ^ cell.y * 19349663
	)

	var variation: int = seed_value % 5

	var sand_shadow := Color("#a58d65")
	var sand_highlight := Color("#dfc99d")
	var rock_color := Color("#887b69")

	match variation:
		0:
			# Short wind-swept sand lines.
			draw_line(
				tile_position + Vector2(5, 11),
				tile_position + Vector2(13, 11),
				sand_shadow,
				1.0
			)
			draw_line(
				tile_position + Vector2(18, 23),
				tile_position + Vector2(27, 23),
				sand_highlight,
				1.0
			)

		1:
			# A few small stones.
			draw_rect(
				Rect2(tile_position + Vector2(8, 20), Vector2(4, 3)),
				rock_color
			)
			draw_rect(
				Rect2(tile_position + Vector2(23, 9), Vector2(3, 2)),
				sand_shadow
			)

		2:
			# Sparse dried vegetation.
			draw_line(
				tile_position + Vector2(12, 24),
				tile_position + Vector2(9, 19),
				sand_shadow,
				1.0
			)
			draw_line(
				tile_position + Vector2(12, 24),
				tile_position + Vector2(15, 20),
				sand_shadow,
				1.0
			)

		3:
			# Subtle sand ripples.
			draw_line(
				tile_position + Vector2(6, 14),
				tile_position + Vector2(16, 14),
				sand_highlight,
				1.0
			)
			draw_line(
				tile_position + Vector2(11, 17),
				tile_position + Vector2(21, 17),
				sand_shadow,
				1.0
			)

		4:
			# Nearly bare sand.
			draw_rect(
				Rect2(tile_position + Vector2(21, 21), Vector2(3, 1)),
				sand_highlight
			)
