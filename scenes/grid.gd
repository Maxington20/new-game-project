
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

var selected_cell: Vector2i = Vector2i(-1, -1)
var highlighted_cells: Array[Vector2i] = []


func _draw() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)

			var position := Vector2(
				x * CELL_SIZE,
				y * CELL_SIZE
			)

			var rect := Rect2(
				position,
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

			if not is_cell_in_bounds(cell):
				return

			cell_selected.emit(cell)


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < GRID_WIDTH
		and cell.y >= 0
		and cell.y < GRID_HEIGHT
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE / 2.0,
		cell.y * CELL_SIZE + CELL_SIZE / 2.0
	)


func get_cells_in_range(
	origin: Vector2i,
	movement_range: int
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)

			var distance := (
				absi(cell.x - origin.x)
				+ absi(cell.y - origin.y)
			)

			if distance <= movement_range:
				cells.append(cell)

	return cells
