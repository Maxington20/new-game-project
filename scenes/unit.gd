
class_name Unit
extends Node2D

signal movement_finished

enum Team {
	PLAYER,
	ENEMY
}

@export var unit_data: UnitResource
@export var team: Team = Team.PLAYER
@export var grid_position: Vector2i = Vector2i.ZERO
@export var movement_speed: float = 160.0

const CELL_SIZE: int = 32

const PLAYER_COLOR := Color("#4682b4")
const ENEMY_COLOR := Color("#c74b50")

var current_hp: int = 0
var is_moving: bool = false


var movement_range: int:
	get:
		if unit_data == null or unit_data.unit_class == null:
			return 0

		return unit_data.unit_class.movement_range


func _ready() -> void:
	position = Vector2(grid_position * CELL_SIZE)

	if unit_data != null and unit_data.unit_class != null:
		current_hp = unit_data.unit_class.max_hp

	queue_redraw()


func _draw() -> void:
	var color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	var rect := Rect2(
		Vector2(4, 4),
		Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
	)

	draw_rect(rect, color)


func move_along_path(path: Array[Vector2i]) -> void:
	if is_moving or path.is_empty():
		return

	is_moving = true

	for cell in path:
		var target_position := Vector2(cell * CELL_SIZE)
		var duration := position.distance_to(target_position) / movement_speed

		var tween := create_tween()
		tween.tween_property(
			self,
			"position",
			target_position,
			duration
		)

		await tween.finished

		grid_position = cell

	is_moving = false
	movement_finished.emit()
