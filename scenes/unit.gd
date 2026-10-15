
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
const TEXT_COLOR := Color.WHITE

var current_hp: int = 0
var is_moving: bool = false
var has_acted: bool = false


var movement_range: int:
	get:
		if unit_data == null or unit_data.unit_class == null:
			return 0
		return unit_data.unit_class.movement_range


var equipped_weapon: WeaponResource:
	get:
		if unit_data == null:
			return null
		return unit_data.equipped_weapon


var min_attack_range: int:
	get:
		if equipped_weapon == null:
			return 0
		return equipped_weapon.min_range


var max_attack_range: int:
	get:
		if equipped_weapon == null:
			return 0
		return equipped_weapon.max_range


func _ready() -> void:
	position = Vector2(grid_position * CELL_SIZE)

	if unit_data != null and unit_data.unit_class != null:
		current_hp = unit_data.unit_class.max_hp

	queue_redraw()


func _draw() -> void:
	var color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	if has_acted:
		color = color.darkened(0.5)

	var rect := Rect2(
		Vector2(4, 4),
		Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
	)

	draw_rect(rect, color)

	var class_letter := get_class_letter()
	var font := ThemeDB.fallback_font
	var font_size := 16

	var text_size := font.get_string_size(
		class_letter,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)

	var text_position := Vector2(
		(CELL_SIZE - text_size.x) / 2.0,
		(CELL_SIZE + text_size.y) / 2.0 - 3.0
	)

	draw_string(
		font,
		text_position,
		class_letter,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		TEXT_COLOR
	)


func get_class_letter() -> String:
	if unit_data == null or unit_data.unit_class == null:
		return "?"

	match unit_data.unit_class.class_name_display.to_lower():
		"swordsman":
			return "S"
		"knight":
			return "K"
		"archer":
			return "A"
		"fighter":
			return "F"
		_:
			return "?"


func move_along_path(path: Array[Vector2i]) -> void:
	if is_moving:
		return

	if path.is_empty():
		movement_finished.emit()
		return

	is_moving = true

	for cell in path:
		var target_position := Vector2(cell * CELL_SIZE)
		var duration := (
			position.distance_to(target_position) / movement_speed
		)

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
