
extends Node2D

@onready var grid = $Grid

var selected_unit: Unit = null
var is_unit_moving: bool = false
var current_paths: Dictionary = {}


func _ready() -> void:
	grid.cell_selected.connect(_on_cell_selected)


func _on_cell_selected(cell: Vector2i) -> void:
	if is_unit_moving:
		return

	var unit := get_unit_at(cell)

	if unit != null:
		select_unit(unit)
		return

	if selected_unit != null and cell in grid.highlighted_cells:
		move_selected_unit(cell)
		return

	deselect_unit()


func get_unit_at(cell: Vector2i) -> Unit:
	for child in get_children():
		if child is Unit and child.grid_position == cell:
			return child

	return null


func get_occupied_cells(excluded_unit: Unit) -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []

	for child in get_children():
		if child is Unit and child != excluded_unit:
			occupied.append(child.grid_position)

	return occupied


func select_unit(unit: Unit) -> void:
	selected_unit = unit

	var occupied := get_occupied_cells(unit)

	var result: Dictionary = grid.get_reachable_cells(
		unit.grid_position,
		unit.movement_range,
		occupied
	)

	current_paths = result["previous"]

	grid.selected_cell = unit.grid_position
	grid.highlighted_cells.clear()

	for cell in result["distances"].keys():
		if cell != unit.grid_position:
			grid.highlighted_cells.append(cell)

	grid.queue_redraw()


func deselect_unit() -> void:
	selected_unit = null
	current_paths.clear()

	grid.selected_cell = Vector2i(-1, -1)
	grid.highlighted_cells.clear()
	grid.queue_redraw()


func move_selected_unit(destination: Vector2i) -> void:
	var unit := selected_unit

	var path: Array[Vector2i] = grid.reconstruct_path(
		unit.grid_position,
		destination,
		current_paths
	)

	if path.is_empty():
		return

	is_unit_moving = true
	deselect_unit()

	unit.move_along_path(path)
	await unit.movement_finished

	is_unit_moving = false
