
class_name Unit
extends Node2D

signal movement_finished

@export var grid_position: Vector2i = Vector2i.ZERO
@export var movement_range: int = 5
@export var movement_speed: float = 160.0

const CELL_SIZE: int = 32
const UNIT_COLOR := Color("#4682b4")

var is_moving: bool = false


func _ready() -> void:
	position = Vector2(grid_position) * CELL_SIZE


func _draw() -> void:
	var rect := Rect2(
		Vector2(4, 4),
		Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
	)

	draw_rect(rect, UNIT_COLOR)


func move_to_cell(target_cell: Vector2i) -> void:
	if is_moving:
		return

	is_moving = true

	var current_cell := grid_position
	var path: Array[Vector2i] = []

	# Move horizontally first.
	while current_cell.x != target_cell.x:
		current_cell.x += signi(target_cell.x - current_cell.x)
		path.append(current_cell)

	# Then move vertically.
	while current_cell.y != target_cell.y:
		current_cell.y += signi(target_cell.y - current_cell.y)
		path.append(current_cell)

	for cell in path:
		var target_position := Vector2(cell) * CELL_SIZE

		var distance := position.distance_to(target_position)
		var duration := distance / movement_speed

		var tween := create_tween()
		tween.tween_property(
			self,
			"position",
			target_position,
			duration
		)

		await tween.finished

	grid_position = target_cell
	is_moving = false
	movement_finished.emit()
