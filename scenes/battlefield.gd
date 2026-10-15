
extends Node2D

@onready var grid = $Grid

var selected_unit: Unit = null
var is_unit_moving: bool = false


func _ready() -> void:
	grid.cell_selected.connect(_on_cell_selected)


func _on_cell_selected(cell: Vector2i) -> void:
	if is_unit_moving:
		return

	var unit := get_unit_at(cell)

	if unit != null:
		select_unit(unit)
		return

	if selected_unit != null:
		if cell in grid.highlighted_cells:
			move_selected_unit(cell)
			return

	deselect_unit()


func get_unit_at(cell: Vector2i) -> Unit:
	for child in get_children():
		if child is Unit and child.grid_position == cell:
			return child

	return null


func select_unit(unit: Unit) -> void:
	selected_unit = unit

	grid.selected_cell = unit.grid_position
	grid.highlighted_cells = grid.get_cells_in_range(
		unit.grid_position,
		unit.movement_range
	)

	grid.queue_redraw()


func deselect_unit() -> void:
	selected_unit = null

	grid.selected_cell = Vector2i(-1, -1)
	grid.highlighted_cells.clear()

	grid.queue_redraw()


func move_selected_unit(cell: Vector2i) -> void:
	is_unit_moving = true

	var unit := selected_unit
	deselect_unit()

	unit.move_to_cell(cell)
	await unit.movement_finished

	is_unit_moving = false
