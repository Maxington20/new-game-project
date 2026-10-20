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

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]

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

			# Base checkerboard colour.
			var color := color_light

			if (x + y) % 2 == 1:
				color = color_dark

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

			# Draw normal grid lines.
			draw_rect(rect, color_lines, false, 1.0)

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
