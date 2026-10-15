
extends Node2D

signal cell_selected(cell: Vector2i)

const CELL_SIZE: int = 32
const GRID_WIDTH: int = 16
const GRID_HEIGHT: int = 12

const COLOR_LIGHT := Color("#8fae82")
const COLOR_DARK := Color("#78996c")
const COLOR_LINES := Color("#425c3b")
const COLOR_SELECTED := Color("#e8d36a")
const COLOR_MOVEMENT := Color("#6a9fe8")

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]

var selected_cell: Vector2i = Vector2i(-1, -1)
var highlighted_cells: Array[Vector2i] = []


func _draw() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)
			var rect := Rect2(
				Vector2(cell * CELL_SIZE),
				Vector2(CELL_SIZE, CELL_SIZE)
			)

			var color := COLOR_LIGHT

			if (x + y) % 2 == 1:
				color = COLOR_DARK

			if cell in highlighted_cells:
				color = COLOR_MOVEMENT

			if cell == selected_cell:
				color = COLOR_SELECTED

			draw_rect(rect, color)
			draw_rect(rect, COLOR_LINES, false, 1.0)


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
	occupied_cells: Array[Vector2i]
) -> Dictionary:
	var distances: Dictionary = {origin: 0}
	var previous: Dictionary = {}

	var queue: Array[Vector2i] = [origin]
	var index := 0

	while index < queue.size():
		var current := queue[index]
		index += 1

		if distances[current] >= movement_range:
			continue

		for direction in DIRECTIONS:
			var next := current + direction

			if not is_cell_in_bounds(next):
				continue

			if next in occupied_cells:
				continue

			if distances.has(next):
				continue

			distances[next] = distances[current] + 1
			previous[next] = current
			queue.append(next)

	return {
		"distances": distances,
		"previous": previous
	}


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
