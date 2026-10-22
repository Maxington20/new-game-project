
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
			
			# Subtle, deterministic snow surface variation.
			if biome == Biome.SNOW:
				var snow_variation: int = (
					(x / 3) * 7 + (y / 3) * 11
				) % 5

				match snow_variation:
					0:
						color = Color("#e5f0f5")
					1:
						color = Color("#dae8ef")
					2:
						color = Color("#d3e3ec")
					3:
						color = Color("#dfedf3")
					_:
						color = Color("#e1edf3")

			# Lava scorches the surrounding ground.
			# This is visual only; gameplay properties remain unchanged.
			var scorched: bool = is_adjacent_to_lava(cell)

			# Lava tiles keep their own appearance.
			var terrain := get_terrain_at(cell)

			if terrain != null:
				if terrain.terrain_type == TerrainResource.TerrainType.LAVA:
					scorched = false

			if scorched:
				color = Color("#514943")

			# Special terrain colours.
			if terrain != null:
				var terrain_color := get_terrain_color(terrain)

				if terrain_color.a > 0.0 and not scorched:
					color = terrain_color

			# Blocked cells retain the surrounding biome's ground colour.
			if blocked_cells.has(cell):
				color = get_biome_ground_color(cell)

			# Draw the terrain background.
			draw_rect(rect, color)
			
			if blocked_cells.has(cell):
				draw_blocked_rock(cell, rect.position)

			# --------------------------------------------------
			# TERRAIN DECORATIONS
			# --------------------------------------------------

			if not blocked_cells.has(cell):
				if scorched:
					draw_scorched_tile(cell, rect.position)

				if terrain == null or terrain.terrain_type == TerrainResource.TerrainType.PLAINS:
					if not scorched:
						match biome:
							Biome.DESERT:
								draw_desert_tile(cell, rect.position)

							Biome.GRASSLAND:
								draw_plains_tile(cell, rect.position)

							Biome.SNOW:
								draw_snow_tile(cell, rect.position)

				else:
					match terrain.terrain_type:
						TerrainResource.TerrainType.FOREST:
							match biome:
								Biome.SNOW:
									draw_snow_tile(cell, rect.position)

								Biome.DESERT:
									draw_desert_tile(cell, rect.position)

							draw_forest_tile(rect.position)

						TerrainResource.TerrainType.FORT:
							draw_fort_tile(rect.position)

						TerrainResource.TerrainType.LAVA:
							draw_lava_tile(cell, rect.position)

			# --------------------------------------------------
			# SUBTLE GRID LINES
			# --------------------------------------------------

			var line_color: Color

			match biome:
				Biome.GRASSLAND:
					# Soft, transparent green.
					# Keeps tile boundaries readable without
					# creating a strong checkerboard appearance.
					line_color = Color("#42663b", 0.22)

				Biome.DESERT:
					line_color = DESERT_LINES

				Biome.SNOW:
					line_color = SNOW_LINES

				_:
					line_color = color_lines

			# Volcanic terrain retains stronger boundaries.
			if scorched or (
				terrain != null
				and terrain.terrain_type == TerrainResource.TerrainType.LAVA
			):
				line_color = Color("#403630", 0.55)

			# Draw the subtle tile boundary.
			draw_rect(
				rect,
				line_color,
				false,
				1.0
			)

			# --------------------------------------------------
			# MOVEMENT AND ATTACK HIGHLIGHTS
			# --------------------------------------------------

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
	# Draw scorched transitions after the underlying biome terrain.
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)

			if is_adjacent_to_lava(cell):
				var terrain := get_terrain_at(cell)

				if terrain != null:
					if terrain.terrain_type == TerrainResource.TerrainType.LAVA:
						continue

				draw_scorched_edges(
					cell,
					Vector2(cell * CELL_SIZE)
				)


func draw_forest_tile(tile_position: Vector2) -> void:
	if biome == Biome.DESERT:
		draw_desert_palm(tile_position + Vector2(2, 3))
		draw_desert_palm(tile_position + Vector2(13, 10))
		return

	var ground_shadow := Color("#416d40", 0.35)

	if biome == Biome.SNOW:
		ground_shadow = Color("#829da4", 0.35)

	# Small shadows beneath the individual trees.
	draw_rect(
		Rect2(tile_position + Vector2(3, 17), Vector2(11, 3)),
		ground_shadow
	)
	draw_rect(
		Rect2(tile_position + Vector2(18, 16), Vector2(11, 3)),
		ground_shadow
	)
	draw_rect(
		Rect2(tile_position + Vector2(9, 28), Vector2(15, 3)),
		ground_shadow
	)

	# Two smaller background trees.
	draw_pixel_tree(tile_position + Vector2(1, 0), 0.85)
	draw_pixel_tree(tile_position + Vector2(17, 0), 0.85)

	# Larger foreground tree.
	draw_pixel_tree(tile_position + Vector2(8, 11), 1.0)

func draw_desert_palm(position: Vector2) -> void:
	var outline := Color("#34372c")

	var trunk_dark := Color("#65472f")
	var trunk_mid := Color("#987047")
	var trunk_light := Color("#c49a62")

	var leaf_shadow := Color("#354d32")
	var leaf_dark := Color("#4c7040")
	var leaf_mid := Color("#64864b")
	var leaf_light := Color("#94a965")
	var leaf_highlight := Color("#b4c47d")

	# Ground shadow.
	draw_rect(
		Rect2(position + Vector2(3, 18), Vector2(12, 2)),
		Color("#8c7855", 0.45)
	)

	# --------------------------------------------------
	# CURVED PALM TRUNK
	# --------------------------------------------------

	# Dark outer silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(6, 19),
			position + Vector2(10, 19),
			position + Vector2(10, 13),
			position + Vector2(12, 8),
			position + Vector2(11, 5),
			position + Vector2(8, 5),
			position + Vector2(9, 9),
			position + Vector2(7, 13)
		]),
		outline
	)

	# Main trunk.
	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(7, 18),
			position + Vector2(9, 18),
			position + Vector2(9, 13),
			position + Vector2(11, 8),
			position + Vector2(10, 6),
			position + Vector2(9, 6),
			position + Vector2(10, 9),
			position + Vector2(8, 13)
		]),
		trunk_mid
	)

	# Shaded side.
	draw_rect(
		Rect2(position + Vector2(7, 14), Vector2(1, 4)),
		trunk_dark
	)

	# Sunlit trunk edge.
	draw_line(
		position + Vector2(9, 10),
		position + Vector2(8, 16),
		trunk_light,
		1.0
	)

	# Bark bands.
	draw_line(
		position + Vector2(7, 15),
		position + Vector2(9, 15),
		trunk_dark,
		1.0
	)

	draw_line(
		position + Vector2(8, 12),
		position + Vector2(10, 12),
		trunk_dark,
		1.0
	)

	# --------------------------------------------------
	# PALM FRONDS
	# --------------------------------------------------

	# Left frond, dark silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(10, 5),
			position + Vector2(6, 3),
			position + Vector2(2, 4),
			position + Vector2(0, 8),
			position + Vector2(3, 7),
			position + Vector2(5, 6),
			position + Vector2(8, 7)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(9, 5),
			position + Vector2(6, 4),
			position + Vector2(3, 5),
			position + Vector2(1, 7),
			position + Vector2(5, 6),
			position + Vector2(8, 6)
		]),
		leaf_mid
	)

	# Right frond.
	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(10, 5),
			position + Vector2(14, 3),
			position + Vector2(17, 5),
			position + Vector2(18, 9),
			position + Vector2(15, 7),
			position + Vector2(13, 6),
			position + Vector2(10, 7)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(10, 5),
			position + Vector2(14, 4),
			position + Vector2(16, 5),
			position + Vector2(17, 8),
			position + Vector2(13, 6)
		]),
		leaf_dark
	)

	# Upright central frond.
	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(8, 6),
			position + Vector2(7, 2),
			position + Vector2(10, 0),
			position + Vector2(13, 2),
			position + Vector2(12, 6)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(9, 5),
			position + Vector2(8, 2),
			position + Vector2(10, 1),
			position + Vector2(12, 2),
			position + Vector2(11, 5)
		]),
		leaf_light
	)

	# Hanging left leaf tips.
	draw_rect(
		Rect2(position + Vector2(1, 7), Vector2(2, 3)),
		leaf_shadow
	)

	draw_rect(
		Rect2(position + Vector2(4, 6), Vector2(2, 3)),
		leaf_dark
	)

	# Hanging right leaf tips.
	draw_rect(
		Rect2(position + Vector2(15, 7), Vector2(2, 3)),
		leaf_shadow
	)

	draw_rect(
		Rect2(position + Vector2(13, 6), Vector2(2, 3)),
		leaf_dark
	)

	# --------------------------------------------------
	# CEL-SHADED HIGHLIGHTS
	# --------------------------------------------------

	draw_line(
		position + Vector2(4, 5),
		position + Vector2(8, 5),
		leaf_light,
		1.0
	)

	draw_line(
		position + Vector2(11, 4),
		position + Vector2(14, 4),
		leaf_highlight,
		1.0
	)

	draw_rect(
		Rect2(position + Vector2(9, 3), Vector2(2, 2)),
		leaf_highlight
	)

	# Central crown shadow.
	draw_rect(
		Rect2(position + Vector2(8, 6), Vector2(4, 2)),
		leaf_shadow
	)

func draw_pixel_tree(
	position: Vector2,
	scale_factor: float = 1.0
) -> void:
	var outline := Color("#243e2b")
	var foliage_dark := Color("#315b38")
	var foliage_mid := Color("#47824a")
	var foliage_light := Color("#73a663")
	var foliage_highlight := Color("#a5cb83")

	var trunk_dark := Color("#49382d")
	var trunk_mid := Color("#79583d")
	var trunk_light := Color("#b08a5d")

	if biome == Biome.SNOW:
		outline = Color("#344b55")
		foliage_dark = Color("#58777c")
		foliage_mid = Color("#78999d")
		foliage_light = Color("#b5d1d7")
		foliage_highlight = Color("#eef6f7")

		trunk_dark = Color("#3e4a51")
		trunk_mid = Color("#65737a")
		trunk_light = Color("#9caeb6")

	draw_set_transform(position, 0.0, Vector2.ONE * scale_factor)

	# --------------------------------------------------
	# TRUNK AND ROOTS
	# --------------------------------------------------

	draw_rect(Rect2(7, 14, 5, 10), trunk_dark)
	draw_rect(Rect2(8, 15, 3, 8), trunk_mid)
	draw_rect(Rect2(8, 16, 1, 6), trunk_light)

	# Exposed roots.
	draw_rect(Rect2(5, 22, 4, 2), trunk_dark)
	draw_rect(Rect2(10, 22, 4, 2), trunk_dark)

	# --------------------------------------------------
	# CANOPY OUTLINE
	# --------------------------------------------------

	# Narrow crown.
	draw_rect(Rect2(7, 0, 5, 3), outline)
	draw_rect(Rect2(5, 2, 9, 4), outline)

	# Wider middle foliage.
	draw_rect(Rect2(3, 5, 13, 7), outline)
	draw_rect(Rect2(1, 8, 17, 5), outline)

	# Tapered lower foliage.
	draw_rect(Rect2(3, 12, 13, 4), outline)
	draw_rect(Rect2(5, 15, 9, 3), outline)

	# --------------------------------------------------
	# DARK FOLIAGE
	# --------------------------------------------------

	draw_rect(Rect2(8, 1, 3, 3), foliage_dark)
	draw_rect(Rect2(6, 3, 7, 4), foliage_dark)
	draw_rect(Rect2(4, 6, 11, 6), foliage_dark)
	draw_rect(Rect2(2, 9, 15, 3), foliage_dark)
	draw_rect(Rect2(4, 12, 11, 3), foliage_dark)
	draw_rect(Rect2(6, 15, 7, 2), foliage_dark)

	# --------------------------------------------------
	# MIDTONE FOLIAGE
	# --------------------------------------------------

	draw_rect(Rect2(7, 3, 5, 4), foliage_mid)
	draw_rect(Rect2(5, 6, 9, 5), foliage_mid)
	draw_rect(Rect2(3, 9, 11, 3), foliage_mid)
	draw_rect(Rect2(5, 12, 8, 2), foliage_mid)

	# --------------------------------------------------
	# CEL-SHADED LIGHT PLANES
	# --------------------------------------------------

	# Upper-left crown.
	draw_rect(Rect2(7, 2, 3, 3), foliage_light)
	draw_rect(Rect2(6, 5, 5, 3), foliage_light)

	# Left canopy surface.
	draw_rect(Rect2(4, 8, 5, 3), foliage_light)
	draw_rect(Rect2(3, 10, 3, 2), foliage_light)

	# Smaller right-side illuminated cluster.
	draw_rect(Rect2(11, 7, 3, 2), foliage_light)

	# --------------------------------------------------
	# BRIGHT HIGHLIGHTS
	# --------------------------------------------------

	draw_rect(Rect2(8, 2, 2, 1), foliage_highlight)
	draw_rect(Rect2(6, 5, 3, 1), foliage_highlight)
	draw_rect(Rect2(4, 8, 3, 1), foliage_highlight)
	draw_rect(Rect2(11, 7, 2, 1), foliage_highlight)

	# --------------------------------------------------
	# SHADOW BREAKS
	# --------------------------------------------------

	# Separate foliage masses without noisy outlines.
	draw_rect(Rect2(11, 10, 4, 1), foliage_dark)
	draw_rect(Rect2(8, 13, 4, 1), foliage_dark)
	draw_rect(Rect2(5, 12, 2, 1), foliage_dark)

	# Darker lower-right face.
	draw_rect(Rect2(13, 9, 3, 3), foliage_dark)
	draw_rect(Rect2(11, 14, 3, 2), foliage_dark)

	# --------------------------------------------------
	# SNOW ACCUMULATION
	# --------------------------------------------------

	if biome == Biome.SNOW:
		var snow_shadow := Color("#b9d5df")
		var snow_light := Color("#f3f9fb")

		draw_rect(Rect2(7, 0, 5, 2), snow_shadow)
		draw_rect(Rect2(7, 0, 4, 1), snow_light)

		draw_rect(Rect2(5, 4, 6, 2), snow_shadow)
		draw_rect(Rect2(5, 4, 5, 1), snow_light)

		draw_rect(Rect2(3, 8, 6, 2), snow_shadow)
		draw_rect(Rect2(3, 8, 5, 1), snow_light)

		draw_rect(Rect2(11, 6, 3, 1), snow_light)

	# Restore the normal drawing transform.
	draw_set_transform(Vector2.ZERO)

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

func is_adjacent_to_lava(cell: Vector2i) -> bool:
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			# Skip the tile itself.
			if x_offset == 0 and y_offset == 0:
				continue

			var neighbor := cell + Vector2i(x_offset, y_offset)

			if not is_cell_in_bounds(neighbor):
				continue

			var terrain := get_terrain_at(neighbor)

			if terrain != null:
				if terrain.terrain_type == TerrainResource.TerrainType.LAVA:
					return true

	return false

func get_terrain_color(terrain: TerrainResource) -> Color:
	if terrain == null:
		return Color.TRANSPARENT

	match terrain.terrain_type:
		TerrainResource.TerrainType.FOREST:
			match biome:
				Biome.SNOW:
					return get_biome_ground_color(Vector2i.ZERO)
				Biome.DESERT:
					return get_biome_ground_color(Vector2i.ZERO)
				_:
					return Color("#246b35")

		TerrainResource.TerrainType.FORT:
			match biome:
				Biome.DESERT:
					return DESERT_LIGHT
				Biome.SNOW:
					return SNOW_LIGHT
				_:
					return Color("#667788")

		TerrainResource.TerrainType.LAVA:
			return Color("#763b2d")

		_:
			return Color.TRANSPARENT


func get_movement_cost(cell: Vector2i) -> int:
	var terrain := get_terrain_at(cell)

	if terrain == null:
		return 1

	return terrain.movement_cost
	
	
func draw_fort_tile(tile_position: Vector2) -> void:
	var outline := Color("#26313c")
	var stone_dark := Color("#45586b")
	var stone_mid := Color("#788da0")
	var stone_light := Color("#b0c2ce")
	var stone_highlight := Color("#dce7eb")
	var mortar := Color("#526678")
	var gate_dark := Color("#202b35")
	var gate_mid := Color("#344554")

	# Desert forts use warm sandstone.
	if biome == Biome.DESERT:
		outline = Color("#59452f")
		stone_dark = Color("#856b4c")
		stone_mid = Color("#b89a6b")
		stone_light = Color("#dfc69a")
		stone_highlight = Color("#f1dfb9")
		mortar = Color("#947653")
		gate_dark = Color("#392e25")
		gate_mid = Color("#584634")

	# --------------------------------------------------
	# FOUNDATION AND CAST SHADOW
	# --------------------------------------------------

	# Dark foundation silhouette.
	draw_rect(
		Rect2(tile_position + Vector2(2, 13), Vector2(28, 18)),
		outline
	)

	# Darker lower-right stone face.
	draw_rect(
		Rect2(tile_position + Vector2(4, 16), Vector2(25, 13)),
		stone_dark
	)

	# --------------------------------------------------
	# MAIN CASTLE WALL
	# --------------------------------------------------

	# Wall silhouette.
	draw_rect(
		Rect2(tile_position + Vector2(8, 13), Vector2(16, 16)),
		outline
	)

	# Main stone surface.
	draw_rect(
		Rect2(tile_position + Vector2(9, 14), Vector2(14, 14)),
		stone_mid
	)

	# Upper-left illuminated edge.
	draw_rect(
		Rect2(tile_position + Vector2(9, 14), Vector2(14, 2)),
		stone_light
	)

	# Dark lower edge.
	draw_rect(
		Rect2(tile_position + Vector2(9, 26), Vector2(14, 2)),
		stone_dark
	)

	# --------------------------------------------------
	# STONE BLOCK DETAIL
	# --------------------------------------------------

	# Horizontal mortar joints.
	draw_rect(
		Rect2(tile_position + Vector2(9, 18), Vector2(14, 1)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(9, 23), Vector2(14, 1)),
		mortar
	)

	# Staggered vertical joints.
	draw_rect(
		Rect2(tile_position + Vector2(15, 15), Vector2(1, 3)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(12, 19), Vector2(1, 4)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(20, 19), Vector2(1, 4)),
		mortar
	)

	# Individual stone highlights.
	draw_rect(
		Rect2(tile_position + Vector2(10, 16), Vector2(4, 1)),
		stone_light
	)
	draw_rect(
		Rect2(tile_position + Vector2(17, 20), Vector2(4, 1)),
		stone_light
	)

	# --------------------------------------------------
	# LEFT TOWER
	# --------------------------------------------------

	draw_rect(
		Rect2(tile_position + Vector2(2, 7), Vector2(10, 23)),
		outline
	)

	draw_rect(
		Rect2(tile_position + Vector2(3, 8), Vector2(8, 21)),
		stone_mid
	)

	# Left-facing illuminated surface.
	draw_rect(
		Rect2(tile_position + Vector2(3, 8), Vector2(2, 20)),
		stone_light
	)

	# Right-side shadow.
	draw_rect(
		Rect2(tile_position + Vector2(9, 9), Vector2(2, 19)),
		stone_dark
	)

	# Stone joints.
	draw_rect(
		Rect2(tile_position + Vector2(4, 17), Vector2(6, 1)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(4, 23), Vector2(6, 1)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(7, 18), Vector2(1, 5)),
		mortar
	)

	# --------------------------------------------------
	# RIGHT TOWER
	# --------------------------------------------------

	draw_rect(
		Rect2(tile_position + Vector2(20, 7), Vector2(10, 23)),
		outline
	)

	draw_rect(
		Rect2(tile_position + Vector2(21, 8), Vector2(8, 21)),
		stone_mid
	)

	# Upper-left highlights.
	draw_rect(
		Rect2(tile_position + Vector2(21, 8), Vector2(2, 20)),
		stone_light
	)

	# Dark right edge.
	draw_rect(
		Rect2(tile_position + Vector2(27, 9), Vector2(2, 19)),
		stone_dark
	)

	# Stone joints.
	draw_rect(
		Rect2(tile_position + Vector2(22, 17), Vector2(6, 1)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(22, 23), Vector2(6, 1)),
		mortar
	)
	draw_rect(
		Rect2(tile_position + Vector2(25, 18), Vector2(1, 5)),
		mortar
	)

	# --------------------------------------------------
	# TOWER BATTLEMENTS
	# --------------------------------------------------

	# Dark parapet bands.
	draw_rect(
		Rect2(tile_position + Vector2(1, 7), Vector2(12, 3)),
		outline
	)
	draw_rect(
		Rect2(tile_position + Vector2(19, 7), Vector2(12, 3)),
		outline
	)

	# Individual raised merlons.
	for x in [2, 7, 21, 26]:
		draw_rect(
			Rect2(tile_position + Vector2(x, 3), Vector2(5, 6)),
			outline
		)

		draw_rect(
			Rect2(tile_position + Vector2(x + 1, 4), Vector2(3, 4)),
			stone_mid
		)

		# Light-catching top.
		draw_rect(
			Rect2(tile_position + Vector2(x + 1, 4), Vector2(3, 1)),
			stone_highlight
		)

		# Dark right edge.
		draw_rect(
			Rect2(tile_position + Vector2(x + 3, 5), Vector2(1, 3)),
			stone_dark
		)

	# --------------------------------------------------
	# CENTRAL WALL BATTLEMENTS
	# --------------------------------------------------

	draw_rect(
		Rect2(tile_position + Vector2(11, 12), Vector2(10, 3)),
		outline
	)

	for x in [12, 17]:
		draw_rect(
			Rect2(tile_position + Vector2(x, 9), Vector2(4, 5)),
			outline
		)

		draw_rect(
			Rect2(tile_position + Vector2(x + 1, 10), Vector2(2, 3)),
			stone_mid
		)

		draw_rect(
			Rect2(tile_position + Vector2(x + 1, 10), Vector2(2, 1)),
			stone_highlight
		)

	# --------------------------------------------------
	# TOWER WINDOWS
	# --------------------------------------------------

	# Narrow recessed arrow slits.
	draw_rect(
		Rect2(tile_position + Vector2(6, 13), Vector2(3, 6)),
		outline
	)
	draw_rect(
		Rect2(tile_position + Vector2(7, 14), Vector2(1, 4)),
		gate_dark
	)

	draw_rect(
		Rect2(tile_position + Vector2(23, 13), Vector2(3, 6)),
		outline
	)
	draw_rect(
		Rect2(tile_position + Vector2(24, 14), Vector2(1, 4)),
		gate_dark
	)

	# Stone lintels.
	draw_rect(
		Rect2(tile_position + Vector2(6, 12), Vector2(3, 1)),
		stone_highlight
	)
	draw_rect(
		Rect2(tile_position + Vector2(23, 12), Vector2(3, 1)),
		stone_highlight
	)

	# --------------------------------------------------
	# RECESSED CASTLE ENTRANCE
	# --------------------------------------------------

	# Dark outer doorway silhouette.
	draw_rect(
		Rect2(tile_position + Vector2(12, 23), Vector2(8, 8)),
		outline
	)
	draw_rect(
		Rect2(tile_position + Vector2(13, 21), Vector2(6, 3)),
		outline
	)
	draw_rect(
		Rect2(tile_position + Vector2(14, 20), Vector2(4, 2)),
		outline
	)

	# Recessed interior.
	draw_rect(
		Rect2(tile_position + Vector2(13, 24), Vector2(6, 7)),
		gate_dark
	)
	draw_rect(
		Rect2(tile_position + Vector2(14, 22), Vector2(4, 3)),
		gate_dark
	)

	# Right interior face catches a little reflected light.
	draw_rect(
		Rect2(tile_position + Vector2(18, 25), Vector2(1, 5)),
		gate_mid
	)

	# Stone arch highlights.
	draw_rect(
		Rect2(tile_position + Vector2(12, 23), Vector2(1, 5)),
		stone_light
	)
	draw_rect(
		Rect2(tile_position + Vector2(13, 21), Vector2(2, 1)),
		stone_light
	)

	# --------------------------------------------------
	# FOUNDATION HIGHLIGHTS
	# --------------------------------------------------

	draw_rect(
		Rect2(tile_position + Vector2(3, 29), Vector2(9, 1)),
		stone_light
	)
	draw_rect(
		Rect2(tile_position + Vector2(20, 29), Vector2(9, 1)),
		stone_light
	)

	# --------------------------------------------------
	# SNOW ACCUMULATION
	# --------------------------------------------------

	if biome == Biome.SNOW:
		var snow_shadow := Color("#b8cad6")
		var snow_light := Color("#f0f6fa")

		# Snow on tower battlements.
		for x in [2, 7, 21, 26]:
			draw_rect(
				Rect2(tile_position + Vector2(x, 3), Vector2(5, 2)),
				snow_shadow
			)

			draw_rect(
				Rect2(tile_position + Vector2(x, 3), Vector2(4, 1)),
				snow_light
			)

		# Snow on central battlements.
		for x in [12, 17]:
			draw_rect(
				Rect2(tile_position + Vector2(x, 9), Vector2(4, 2)),
				snow_shadow
			)

			draw_rect(
				Rect2(tile_position + Vector2(x, 9), Vector2(3, 1)),
				snow_light
			)

		# Snow along the foundation.
		draw_rect(
			Rect2(tile_position + Vector2(3, 29), Vector2(9, 2)),
			snow_shadow
		)
		draw_rect(
			Rect2(tile_position + Vector2(20, 29), Vector2(9, 2)),
			snow_shadow
		)

		draw_rect(
			Rect2(tile_position + Vector2(4, 29), Vector2(7, 1)),
			snow_light
		)
		draw_rect(
			Rect2(tile_position + Vector2(21, 29), Vector2(7, 1)),
			snow_light
		)

func draw_lava_tile(cell: Vector2i, tile_position: Vector2) -> void:
	var lava_deep := Color("#85251e")
	var lava_red := Color("#bb3520")
	var lava_orange := Color("#e65a20")
	var lava_bright := Color("#ff922c")
	var lava_yellow := Color("#ffc34e")
	var lava_hot := Color("#ffe39a")

	var rock_outline := Color("#211e23")
	var rock_dark := Color("#352b30")
	var rock_mid := Color("#514044")
	var rock_light := Color("#76585a")

	# Deterministic variation for each tile.
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		(cell.x * 73856093)
		^ (cell.y * 19349663)
		^ 193487
	) & 0x7fffffff

	# --------------------------------------------------
	# MOLTEN BASE
	# --------------------------------------------------

	# Fill the entire tile so adjacent lava tiles
	# naturally form one continuous molten area.
	draw_rect(
		Rect2(tile_position, Vector2(CELL_SIZE, CELL_SIZE)),
		lava_red
	)

	# Large, irregular darker currents.
	# Keep these away from tile boundaries to avoid
	# obvious discontinuities between neighbouring tiles.
	for i in range(4):
		var px := rng.randi_range(2, 23)
		var py := rng.randi_range(2, 25)
		var width := rng.randi_range(5, 9)
		var height := rng.randi_range(2, 4)

		draw_rect(
			Rect2(
				tile_position + Vector2(px, py),
				Vector2(width, height)
			),
			lava_deep
		)

	# --------------------------------------------------
	# ORANGE MOLTEN CURRENTS
	# --------------------------------------------------

	# Irregular stepped shapes rather than straight
	# horizontal or vertical channels.
	for i in range(3):
		var px := rng.randi_range(4, 20)
		var py := rng.randi_range(5, 24)

		draw_rect(
			Rect2(
				tile_position + Vector2(px, py),
				Vector2(7, 3)
			),
			lava_orange
		)

		draw_rect(
			Rect2(
				tile_position + Vector2(px + 3, py - 2),
				Vector2(6, 3)
			),
			lava_orange
		)

		draw_rect(
			Rect2(
				tile_position + Vector2(px + 6, py - 4),
				Vector2(4, 3)
			),
			lava_bright
		)

	# --------------------------------------------------
	# VOLCANIC CRUST
	# --------------------------------------------------

	# Dark floating rock formations.
	# Their angular silhouettes provide the cel-shaded look.
	var rock_count := rng.randi_range(2, 3)

	for i in range(rock_count):
		var rx := rng.randi_range(3, 20)
		var ry := rng.randi_range(4, 22)
		var rw := rng.randi_range(7, 11)
		var rh := rng.randi_range(5, 8)

		# Angular outer silhouette.
		draw_colored_polygon(
			PackedVector2Array([
				tile_position + Vector2(rx + 2, ry),
				tile_position + Vector2(rx + rw - 2, ry),
				tile_position + Vector2(rx + rw, ry + 2),
				tile_position + Vector2(rx + rw - 1, ry + rh),
				tile_position + Vector2(rx + 2, ry + rh),
				tile_position + Vector2(rx, ry + rh - 2),
				tile_position + Vector2(rx, ry + 2)
			]),
			rock_outline
		)

		# Main upper rock surface.
		draw_colored_polygon(
			PackedVector2Array([
				tile_position + Vector2(rx + 2, ry + 1),
				tile_position + Vector2(rx + rw - 3, ry + 1),
				tile_position + Vector2(rx + rw - 1, ry + 3),
				tile_position + Vector2(rx + rw - 2, ry + rh - 2),
				tile_position + Vector2(rx + 2, ry + rh - 2),
				tile_position + Vector2(rx + 1, ry + 3)
			]),
			rock_mid
		)

		# Bright upper-left edge.
		draw_rect(
			Rect2(
				tile_position + Vector2(rx + 2, ry + 1),
				Vector2(maxi(2, rw - 5), 1)
			),
			rock_light
		)

		# Dark lower face.
		draw_rect(
			Rect2(
				tile_position + Vector2(rx + 3, ry + rh - 2),
				Vector2(maxi(2, rw - 5), 1)
			),
			rock_dark
		)

	# --------------------------------------------------
	# HOT MOLTEN HIGHLIGHTS
	# --------------------------------------------------

	# Sparse bright areas give the impression of heat
	# without turning the entire tile yellow.
	for i in range(3):
		var hx := rng.randi_range(3, 25)
		var hy := rng.randi_range(3, 26)

		draw_rect(
			Rect2(
				tile_position + Vector2(hx, hy),
				Vector2(rng.randi_range(3, 5), 2)
			),
			lava_bright
		)

		draw_rect(
			Rect2(
				tile_position + Vector2(hx + 1, hy),
				Vector2(2, 1)
			),
			lava_yellow
		)

	# Occasional extremely hot spot.
	if rng.randf() < 0.45:
		var hx := rng.randi_range(5, 24)
		var hy := rng.randi_range(5, 24)

		draw_rect(
			Rect2(
				tile_position + Vector2(hx, hy),
				Vector2(4, 2)
			),
			lava_yellow
		)

		draw_rect(
			Rect2(
				tile_position + Vector2(hx + 1, hy),
				Vector2(2, 1)
			),
			lava_hot
		)

	# --------------------------------------------------
	# IRREGULAR LAVA BOUNDARIES
	# --------------------------------------------------

	# Only draw dark volcanic edges where lava meets
	# a non-lava tile.
	for direction in DIRECTIONS:
		var neighbor := cell + direction
		var neighbor_is_lava := false

		if is_cell_in_bounds(neighbor):
			var neighbor_terrain := get_terrain_at(neighbor)

			if neighbor_terrain != null:
				neighbor_is_lava = (
					neighbor_terrain.terrain_type
					== TerrainResource.TerrainType.LAVA
				)

		if neighbor_is_lava:
			continue

		match direction:
			Vector2i.UP:
				draw_rect(
					Rect2(tile_position + Vector2(0, 0), Vector2(32, 2)),
					rock_outline
				)
				draw_rect(
					Rect2(tile_position + Vector2(3, 2), Vector2(9, 2)),
					rock_dark
				)
				draw_rect(
					Rect2(tile_position + Vector2(19, 2), Vector2(7, 1)),
					rock_mid
				)

			Vector2i.DOWN:
				draw_rect(
					Rect2(tile_position + Vector2(0, 30), Vector2(32, 2)),
					rock_outline
				)
				draw_rect(
					Rect2(tile_position + Vector2(5, 28), Vector2(8, 2)),
					rock_dark
				)
				draw_rect(
					Rect2(tile_position + Vector2(21, 29), Vector2(6, 1)),
					rock_mid
				)

			Vector2i.LEFT:
				draw_rect(
					Rect2(tile_position + Vector2(0, 0), Vector2(2, 32)),
					rock_outline
				)
				draw_rect(
					Rect2(tile_position + Vector2(2, 5), Vector2(2, 9)),
					rock_dark
				)
				draw_rect(
					Rect2(tile_position + Vector2(2, 21), Vector2(1, 6)),
					rock_mid
				)

			Vector2i.RIGHT:
				draw_rect(
					Rect2(tile_position + Vector2(30, 0), Vector2(2, 32)),
					rock_outline
				)
				draw_rect(
					Rect2(tile_position + Vector2(28, 7), Vector2(2, 8)),
					rock_dark
				)
				draw_rect(
					Rect2(tile_position + Vector2(29, 22), Vector2(1, 6)),
					rock_mid
				)
	
	
func draw_scorched_tile(cell: Vector2i, tile_position: Vector2) -> void:
	var crack_dark := Color("#211f21")
	var crack_mid := Color("#332c2b")
	var rock_shadow := Color("#3d3836")
	var ash_mid := Color("#71665e")
	var ash_light := Color("#998779")
	var ember_red := Color("#a64024")
	var ember_orange := Color("#e97832")

	# Repeatable variation per tile.
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		(cell.x * 73856093)
		^ (cell.y * 19349663)
		^ 193487
	) & 0x7fffffff

	# --------------------------------------------------
	# IRREGULAR ROCK PATCHES
	# --------------------------------------------------

	var patch_count := rng.randi_range(1, 3)

	for i in range(patch_count):
		var px := rng.randi_range(3, 24)
		var py := rng.randi_range(4, 25)
		var width := rng.randi_range(4, 7)

		# Dark lower edge.
		draw_rect(
			Rect2(
				tile_position + Vector2(px + 1, py + 2),
				Vector2(width, 2)
			),
			rock_shadow
		)

		# Ash-covered surface.
		draw_rect(
			Rect2(
				tile_position + Vector2(px, py),
				Vector2(width, 2)
			),
			ash_mid
		)

		# Light-catching upper edge.
		draw_rect(
			Rect2(
				tile_position + Vector2(px, py),
				Vector2(maxi(2, width - 2), 1)
			),
			ash_light
		)

	# --------------------------------------------------
	# ANGULAR CRACKS
	# --------------------------------------------------

	var crack_count := rng.randi_range(1, 2)

	for i in range(crack_count):
		var cx := rng.randi_range(6, 23)
		var cy := rng.randi_range(5, 16)

		var start := tile_position + Vector2(cx, cy)
		var middle := tile_position + Vector2(cx + 3, cy + 5)
		var finish := tile_position + Vector2(cx, cy + 10)

		# Dark crack silhouette.
		draw_line(start, middle, crack_dark, 2.0)
		draw_line(middle, finish, crack_dark, 2.0)

		# Subtle highlighted rock edge.
		draw_line(
			start + Vector2(-1, 0),
			middle + Vector2(-1, 0),
			ash_mid,
			1.0
		)

		# Small branching fracture.
		if rng.randf() < 0.5:
			draw_line(
				middle,
				middle + Vector2(4, 2),
				crack_mid,
				1.0
			)

	# --------------------------------------------------
	# OCCASIONAL GLOWING EMBERS
	# --------------------------------------------------

	if rng.randf() < 0.35:
		var ex := rng.randi_range(7, 24)
		var ey := rng.randi_range(8, 24)

		draw_rect(
			Rect2(tile_position + Vector2(ex, ey), Vector2(3, 2)),
			ember_red
		)

		draw_rect(
			Rect2(tile_position + Vector2(ex + 1, ey), Vector2(1, 1)),
			ember_orange
		)

func draw_scorched_edges(cell: Vector2i, tile_position: Vector2) -> void:
	var ash_dark := Color("#302d2b")
	var ash_mid := Color("#514943")
	var ash_light := Color("#75675a")

	# Match the surrounding terrain instead of always using green.
	var edge_terrain_color: Color

	match biome:
		Biome.GRASSLAND:
			edge_terrain_color = Color("#65734f")
		Biome.DESERT:
			edge_terrain_color = Color("#b7a077")
		Biome.SNOW:
			edge_terrain_color = Color("#dceaf2")

	for direction in DIRECTIONS:
		var neighbor := cell + direction

		if not is_cell_in_bounds(neighbor):
			continue

		var neighbor_terrain := get_terrain_at(neighbor)

		# No transition between scorched ground and lava.
		if neighbor_terrain != null:
			if neighbor_terrain.terrain_type == TerrainResource.TerrainType.LAVA:
				continue

		# No transition between two scorched tiles.
		if is_adjacent_to_lava(neighbor):
			continue

		# Deterministic variation along the boundary.
		var seed_value: int = (
			cell.x * 73856093
			+ cell.y * 19349663
			+ direction.x * 83492791
			+ direction.y * 297121507
		) & 0x7fffffff

		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value

		# Irregular patches along the inner scorched boundary.
		for i in range(7):
			var along := rng.randi_range(0, 28)
			var depth := rng.randi_range(2, 9)
			var patch_width := rng.randi_range(2, 6)
			var patch_depth := rng.randi_range(2, 5)

			var patch_position := Vector2.ZERO

			match direction:
				Vector2i.UP:
					patch_position = Vector2(along, depth - 2)

				Vector2i.DOWN:
					patch_position = Vector2(
						along,
						32 - depth - patch_depth + 2
					)

				Vector2i.LEFT:
					patch_position = Vector2(depth - 2, along)

				Vector2i.RIGHT:
					patch_position = Vector2(
						32 - depth - patch_depth + 2,
						along
					)

			var patch_size := Vector2(patch_width, patch_depth)

			if direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
				patch_size = Vector2(patch_depth, patch_width)

			var patch_color := ash_light

			match i % 4:
				0:
					patch_color = edge_terrain_color
				1:
					patch_color = ash_light
				2:
					patch_color = ash_mid
				3:
					patch_color = ash_dark

			draw_rect(
				Rect2(tile_position + patch_position, patch_size),
				patch_color
			)

		# Small irregular notches matching the surrounding biome.
		for i in range(4):
			var offset := rng.randi_range(2, 27)
			var notch_length := rng.randi_range(2, 5)

			match direction:
				Vector2i.UP:
					draw_rect(
						Rect2(
							tile_position + Vector2(offset, 0),
							Vector2(2, notch_length)
						),
						edge_terrain_color
					)

				Vector2i.DOWN:
					draw_rect(
						Rect2(
							tile_position + Vector2(offset, 32 - notch_length),
							Vector2(2, notch_length)
						),
						edge_terrain_color
					)

				Vector2i.LEFT:
					draw_rect(
						Rect2(
							tile_position + Vector2(0, offset),
							Vector2(notch_length, 2)
						),
						edge_terrain_color
					)

				Vector2i.RIGHT:
					draw_rect(
						Rect2(
							tile_position + Vector2(32 - notch_length, offset),
							Vector2(notch_length, 2)
						),
						edge_terrain_color
					)

func draw_plains_tile(cell: Vector2i, tile_position: Vector2) -> void:
	var grass_dark := Color("#527849")
	var grass_mid := Color("#729b61")
	var grass_light := Color("#aecb91")

	var earth_dark := Color("#789369")
	var earth_light := Color("#aac394")

	var flower_yellow := Color("#e5d48a")

	# Repeatable variation for each map cell.
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		(cell.x * 73856093)
		^ (cell.y * 19349663)
		^ 83492791
	) & 0x7fffffff

	# --------------------------------------------------
	# SUBTLE GROUND DETAILS
	# --------------------------------------------------

	# About half the tiles receive a small ground patch.
	if rng.randf() < 0.5:
		var px := rng.randi_range(5, 23)
		var py := rng.randi_range(6, 25)
		var width := rng.randi_range(4, 7)

		# Light upper surface.
		draw_rect(
			Rect2(
				tile_position + Vector2(px, py),
				Vector2(width, 1)
			),
			earth_light
		)

		# Darker lower edge.
		draw_rect(
			Rect2(
				tile_position + Vector2(px + 1, py + 1),
				Vector2(width - 2, 1)
			),
			earth_dark
		)

	# --------------------------------------------------
	# SMALL CEL-SHADED GRASS CLUSTERS
	# --------------------------------------------------

	# Most tiles have zero or one cluster.
	var cluster_count := 0
	var density_roll := rng.randf()

	if density_roll < 0.20:
		cluster_count = 0
	elif density_roll < 0.90:
		cluster_count = 1
	else:
		cluster_count = 2

	for i in range(cluster_count):
		var gx := rng.randi_range(6, 25)
		var gy := rng.randi_range(12, 26)

		# Small dark base.
		draw_rect(
			Rect2(
				tile_position + Vector2(gx - 2, gy),
				Vector2(5, 1)
			),
			grass_dark
		)

		# Left blade.
		draw_rect(
			Rect2(
				tile_position + Vector2(gx - 2, gy - 3),
				Vector2(1, 3)
			),
			grass_mid
		)

		# Centre blade.
		draw_rect(
			Rect2(
				tile_position + Vector2(gx, gy - 5),
				Vector2(1, 5)
			),
			grass_mid
		)

		# Right blade.
		draw_rect(
			Rect2(
				tile_position + Vector2(gx + 2, gy - 3),
				Vector2(1, 3)
			),
			grass_mid
		)

		# Highlights on the upper-left sides.
		draw_rect(
			Rect2(
				tile_position + Vector2(gx, gy - 5),
				Vector2(1, 2)
			),
			grass_light
		)

		draw_rect(
			Rect2(
				tile_position + Vector2(gx - 2, gy - 3),
				Vector2(1, 1)
			),
			grass_light
		)

		# Slight shadow beneath the cluster.
		draw_rect(
			Rect2(
				tile_position + Vector2(gx - 1, gy + 1),
				Vector2(4, 1)
			),
			grass_dark
		)

	# --------------------------------------------------
	# OCCASIONAL FLOWERS
	# --------------------------------------------------

	if rng.randf() < 0.08:
		var fx := rng.randi_range(6, 25)
		var fy := rng.randi_range(8, 25)

		# Tiny stem.
		draw_rect(
			Rect2(
				tile_position + Vector2(fx, fy + 1),
				Vector2(1, 2)
			),
			grass_mid
		)

		# Single yellow flower pixel.
		draw_rect(
			Rect2(
				tile_position + Vector2(fx, fy),
				Vector2(1, 1)
			),
			flower_yellow
		)


func get_biome_ground_color(cell: Vector2i) -> Color:
	# Deterministic variation that remains consistent between redraws.
	var seed_value: int = absi(
		(cell.x * 73856093) ^ (cell.y * 19349663)
	)

	var variation: int = seed_value % 5

	match biome:
		Biome.DESERT:
			return DESERT_LIGHT if (cell.x + cell.y) % 2 == 0 else DESERT_DARK

		Biome.SNOW:
			return SNOW_LIGHT if (cell.x + cell.y) % 2 == 0 else SNOW_DARK

		_:
			# Grassland: subtle variation instead of a checkerboard.
			match variation:
				0:
					return Color("#86a977")
				1:
					return Color("#89ad7a")
				2:
					return Color("#83a574")
				3:
					return Color("#8aac7c")
				_:
					return Color("#87aa79")

func draw_desert_tile(cell: Vector2i, tile_position: Vector2) -> void:
	# Stable randomization: decorations don't change on redraw.
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		(cell.x * 73856093)
		^ (cell.y * 19349663)
		^ 83492791
	) & 0x7fffffff

	# Some tiles remain mostly empty.
	if rng.randf() < 0.30:
		return

	# Weighted selection of decoration types.
	var roll := rng.randf()
	var variation := 6

	if roll < 0.16:
		variation = 0  # Large dune
	elif roll < 0.30:
		variation = 4  # Low dune
	elif roll < 0.44:
		variation = 1  # Angular rock
	elif roll < 0.56:
		variation = 5  # Small stones
	elif roll < 0.69:
		variation = 2  # Dried grass
	elif roll < 0.85:
		variation = 3  # Wind ripples

	# Small positional offsets break up the grid pattern.
	var decoration_offset := Vector2(
		rng.randi_range(-2, 2),
		rng.randi_range(-2, 2)
	)

	tile_position += decoration_offset

	# Cel-shaded desert palette.
	var sand_shadow := Color("#ad9165")
	var sand_mid := Color("#c7ad7e")
	var sand_light := Color("#ead4a5")
	var sand_highlight := Color("#f5e3bc")

	var rock_outline := Color("#66594a")
	var rock_shadow := Color("#89765e")
	var rock_mid := Color("#b39a75")
	var rock_light := Color("#d6bd91")

	var dry_grass_dark := Color("#81744b")
	var dry_grass_light := Color("#b7a16b")

	match variation:
		0:
			# Small wind-shaped dune.
			# The three colour bands give it a raised appearance.
			draw_colored_polygon(
				PackedVector2Array([
					tile_position + Vector2(3, 21),
					tile_position + Vector2(9, 17),
					tile_position + Vector2(18, 16),
					tile_position + Vector2(27, 20),
					tile_position + Vector2(29, 23),
					tile_position + Vector2(4, 23)
				]),
				sand_shadow
			)

			draw_colored_polygon(
				PackedVector2Array([
					tile_position + Vector2(5, 20),
					tile_position + Vector2(11, 17),
					tile_position + Vector2(18, 17),
					tile_position + Vector2(25, 20),
					tile_position + Vector2(22, 20),
					tile_position + Vector2(11, 19)
				]),
				sand_light
			)

			draw_line(
				tile_position + Vector2(11, 17),
				tile_position + Vector2(18, 17),
				sand_highlight,
				1.0
			)

		1:
			# Angular stone with a dark outline.
			draw_rect(
				Rect2(tile_position + Vector2(9, 19), Vector2(9, 6)),
				rock_outline
			)

			draw_rect(
				Rect2(tile_position + Vector2(10, 18), Vector2(7, 5)),
				rock_mid
			)

			draw_rect(
				Rect2(tile_position + Vector2(11, 18), Vector2(5, 2)),
				rock_light
			)

			draw_rect(
				Rect2(tile_position + Vector2(14, 22), Vector2(3, 2)),
				rock_shadow
			)

			# Small secondary pebble.
			draw_rect(
				Rect2(tile_position + Vector2(23, 11), Vector2(4, 3)),
				rock_outline
			)

			draw_rect(
				Rect2(tile_position + Vector2(23, 11), Vector2(3, 1)),
				rock_light
			)

		2:
			# Sparse, dried grass tuft.
			draw_rect(
				Rect2(tile_position + Vector2(13, 23), Vector2(6, 2)),
				sand_shadow
			)

			draw_line(
				tile_position + Vector2(16, 23),
				tile_position + Vector2(11, 17),
				dry_grass_dark,
				2.0
			)

			draw_line(
				tile_position + Vector2(16, 23),
				tile_position + Vector2(17, 15),
				dry_grass_dark,
				2.0
			)

			draw_line(
				tile_position + Vector2(16, 23),
				tile_position + Vector2(22, 18),
				dry_grass_light,
				2.0
			)

			draw_rect(
				Rect2(tile_position + Vector2(16, 17), Vector2(1, 4)),
				dry_grass_light
			)

		3:
			# Layered wind ripples.
			draw_line(
				tile_position + Vector2(5, 11),
				tile_position + Vector2(17, 11),
				sand_light,
				2.0
			)

			draw_line(
				tile_position + Vector2(8, 13),
				tile_position + Vector2(19, 13),
				sand_shadow,
				1.0
			)

			draw_line(
				tile_position + Vector2(17, 22),
				tile_position + Vector2(27, 22),
				sand_mid,
				2.0
			)

			draw_line(
				tile_position + Vector2(19, 21),
				tile_position + Vector2(25, 21),
				sand_highlight,
				1.0
			)

		4:
			# Low dune with a darker leeward slope.
			draw_colored_polygon(
				PackedVector2Array([
					tile_position + Vector2(4, 19),
					tile_position + Vector2(10, 16),
					tile_position + Vector2(19, 16),
					tile_position + Vector2(27, 20),
					tile_position + Vector2(24, 22),
					tile_position + Vector2(8, 22)
				]),
				sand_mid
			)

			draw_line(
				tile_position + Vector2(10, 16),
				tile_position + Vector2(19, 16),
				sand_highlight,
				2.0
			)

			draw_line(
				tile_position + Vector2(8, 22),
				tile_position + Vector2(24, 22),
				sand_shadow,
				1.0
			)

		5:
			# Scattered small stones.
			draw_rect(
				Rect2(tile_position + Vector2(7, 21), Vector2(5, 3)),
				rock_outline
			)

			draw_rect(
				Rect2(tile_position + Vector2(8, 21), Vector2(3, 1)),
				rock_light
			)

			draw_rect(
				Rect2(tile_position + Vector2(21, 9), Vector2(4, 3)),
				rock_shadow
			)

			draw_rect(
				Rect2(tile_position + Vector2(21, 9), Vector2(3, 1)),
				rock_light
			)

			draw_line(
				tile_position + Vector2(16, 26),
				tile_position + Vector2(24, 26),
				sand_shadow,
				1.0
			)

		6:
			# Mostly bare sand, with subtle wind marks.
			draw_line(
				tile_position + Vector2(8, 12),
				tile_position + Vector2(14, 12),
				sand_highlight,
				1.0
			)

			draw_line(
				tile_position + Vector2(10, 14),
				tile_position + Vector2(18, 14),
				sand_shadow,
				1.0
			)

			draw_rect(
				Rect2(tile_position + Vector2(23, 23), Vector2(3, 1)),
				sand_light
			)

func draw_snow_tile(cell: Vector2i, tile_position: Vector2) -> void:
	var snow_bright := Color("#ffffff")
	var snow_light := Color("#edf5f9")
	var snow_shadow := Color("#b5cbd9")
	var snow_deep := Color("#91afc2")

	var seed_value: int = absi(
		cell.x * 73856093 ^ cell.y * 19349663
	)

	var pattern: int = seed_value % 12

	match pattern:
		0:
			# Large, softly stepped snowdrift.
			draw_rect(
				Rect2(tile_position + Vector2(4, 21), Vector2(23, 3)),
				snow_shadow
			)
			draw_rect(
				Rect2(tile_position + Vector2(7, 19), Vector2(18, 3)),
				snow_light
			)
			draw_rect(
				Rect2(tile_position + Vector2(11, 17), Vector2(11, 2)),
				snow_bright
			)
			draw_rect(
				Rect2(tile_position + Vector2(8, 24), Vector2(16, 1)),
				snow_deep
			)

		1:
			# Wind-sculpted ridge.
			draw_rect(
				Rect2(tile_position + Vector2(3, 15), Vector2(8, 2)),
				snow_light
			)
			draw_rect(
				Rect2(tile_position + Vector2(9, 14), Vector2(12, 2)),
				snow_bright
			)
			draw_rect(
				Rect2(tile_position + Vector2(19, 16), Vector2(9, 2)),
				snow_light
			)
			draw_rect(
				Rect2(tile_position + Vector2(10, 17), Vector2(15, 1)),
				snow_shadow
			)

		2:
			# Small irregular drift.
			draw_rect(
				Rect2(tile_position + Vector2(15, 23), Vector2(13, 3)),
				snow_shadow
			)
			draw_rect(
				Rect2(tile_position + Vector2(17, 21), Vector2(9, 2)),
				snow_light
			)
			draw_rect(
				Rect2(tile_position + Vector2(20, 20), Vector2(5, 1)),
				snow_bright
			)

		3:
			# A tiny patch of exposed icy ground.
			draw_rect(
				Rect2(tile_position + Vector2(12, 23), Vector2(7, 2)),
				snow_deep
			)
			draw_rect(
				Rect2(tile_position + Vector2(10, 22), Vector2(10, 1)),
				snow_shadow
			)
			draw_rect(
				Rect2(tile_position + Vector2(13, 22), Vector2(4, 1)),
				snow_light
			)

		4:
			# Very subtle snow surface variation.
			draw_rect(
				Rect2(tile_position + Vector2(7, 10), Vector2(12, 1)),
				snow_light
			)
			draw_rect(
				Rect2(tile_position + Vector2(11, 11), Vector2(8, 1)),
				snow_shadow
			)

		_:
			# Most snow tiles remain untouched.
			pass


func draw_blocked_rock(cell: Vector2i, tile_position: Vector2) -> void:
	var outline := Color("#292c30")
	var shadow := Color("#41474a")
	var midtone := Color("#707b7e")
	var light := Color("#a5b0af")
	var highlight := Color("#c9d0cd")

	match biome:
		Biome.DESERT:
			outline = Color("#544536")
			shadow = Color("#80654a")
			midtone = Color("#aa8962")
			light = Color("#d0ad7c")
			highlight = Color("#ead0a1")

		Biome.SNOW:
			outline = Color("#394a55")
			shadow = Color("#637b88")
			midtone = Color("#91a9b6")
			light = Color("#c3d5dc")
			highlight = Color("#eef6f8")

	# Small deterministic variation between rocks.
	var variation: int = (
		(cell.x * 73856093) ^ (cell.y * 19349663)
	) & 0x7fffffff

	var offset_x: int = variation % 3 - 1

	var p := tile_position + Vector2(offset_x, 0)

	# Ground shadow.
	draw_rect(
		Rect2(p + Vector2(3, 27), Vector2(26, 3)),
		Color(outline, 0.35)
	)

	# Main rock: dark angular silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			p + Vector2(3, 25),
			p + Vector2(4, 16),
			p + Vector2(9, 10),
			p + Vector2(16, 7),
			p + Vector2(23, 11),
			p + Vector2(28, 18),
			p + Vector2(29, 25),
			p + Vector2(25, 28),
			p + Vector2(7, 28)
		]),
		outline
	)

	# Lower shaded face.
	draw_colored_polygon(
		PackedVector2Array([
			p + Vector2(5, 19),
			p + Vector2(13, 17),
			p + Vector2(23, 19),
			p + Vector2(27, 25),
			p + Vector2(24, 27),
			p + Vector2(8, 27)
		]),
		shadow
	)

	# Main illuminated rock face.
	draw_colored_polygon(
		PackedVector2Array([
			p + Vector2(5, 18),
			p + Vector2(10, 11),
			p + Vector2(16, 8),
			p + Vector2(22, 12),
			p + Vector2(25, 18),
			p + Vector2(19, 22),
			p + Vector2(11, 21)
		]),
		midtone
	)

	# Upper-left light plane.
	draw_colored_polygon(
		PackedVector2Array([
			p + Vector2(6, 17),
			p + Vector2(10, 11),
			p + Vector2(16, 9),
			p + Vector2(15, 16),
			p + Vector2(11, 20)
		]),
		light
	)

	# Small bright edge.
	draw_line(
		p + Vector2(10, 11),
		p + Vector2(16, 9),
		highlight,
		1.0
	)

	# Angular fracture.
	draw_line(
		p + Vector2(16, 16),
		p + Vector2(20, 20),
		shadow,
		1.0
	)
	draw_line(
		p + Vector2(20, 20),
		p + Vector2(18, 24),
		outline,
		1.0
	)

	# Smaller foreground stone.
	draw_colored_polygon(
		PackedVector2Array([
			p + Vector2(2, 27),
			p + Vector2(4, 23),
			p + Vector2(8, 21),
			p + Vector2(12, 24),
			p + Vector2(13, 28),
			p + Vector2(4, 29)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			p + Vector2(4, 26),
			p + Vector2(5, 23),
			p + Vector2(8, 22),
			p + Vector2(11, 25),
			p + Vector2(10, 27)
		]),
		light
	)

	# Snow resting on the rock's upper surfaces.
	if biome == Biome.SNOW:
		draw_rect(
			Rect2(p + Vector2(12, 8), Vector2(6, 2)),
			Color("#f5fafc")
		)
		draw_rect(
			Rect2(p + Vector2(9, 10), Vector2(5, 1)),
			Color("#e3f0f5")
		)
		draw_rect(
			Rect2(p + Vector2(5, 23), Vector2(4, 1)),
			Color("#f5fafc")
		)
