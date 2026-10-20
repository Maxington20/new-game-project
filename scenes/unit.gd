class_name Unit
extends Node2D

signal movement_finished
signal terrain_cell_entered(unit: Unit, cell: Vector2i)
signal terrain_effect_finished

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


var current_hp: int = 0:
	set(value):
		if run_state != null:
			if not run_state.is_alive:
				current_hp = 0
				return

			var max_hp: int = value
			if stats != null:
				max_hp = stats.max_hp

			current_hp = clampi(value, 0, max_hp)
			run_state.current_hp = current_hp

			if current_hp == 0:
				run_state.is_alive = false
		else:
			current_hp = value
			
var is_moving: bool = false
var has_acted: bool = false
var took_terrain_damage: bool = false
var run_state: RunUnitState

var stats: UnitStatsResource:
	get:
		if unit_data == null:
			return null
		return unit_data.stats

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
	set(value):
		if unit_data == null:
			return
		unit_data.equipped_weapon = value

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

	if run_state != null:
		unit_data = run_state.character
		current_hp = run_state.current_hp

	elif unit_data != null and unit_data.unit_class != null:
		unit_data = unit_data.duplicate(false) as UnitResource

		if unit_data.stats == null:
			unit_data.stats = UnitStatsResource.from_class(unit_data.unit_class)
			
		else:
			unit_data.stats = unit_data.stats.duplicate(true) as UnitStatsResource

		if unit_data.weapon_proficiencies != null:
			unit_data.weapon_proficiencies = unit_data.weapon_proficiencies.duplicate(true) as WeaponProficiencyResource

		current_hp = unit_data.stats.max_hp

	queue_redraw()

# Call this on an active battlefield unit, rather than promoting
# its UnitResource directly, so current HP and its visual update too.
func promote() -> Dictionary:
	var result: Dictionary = PromotionCalculator.promote(unit_data)
	if not result["success"]:
		return result
	var hp_increase: int = int(result["stat_increases"]["max_hp"])
	current_hp = clampi(current_hp + hp_increase, 0, stats.max_hp)
	queue_redraw()
	return result
	

func promote_with_choice(
	target_class: UnitClassResource,
	progression: PermanentProgression,
	catalogue: AchievementCatalogue
) -> Dictionary:
	if run_state != null and not run_state.is_alive:
		return {
			"success": false,
			"reason": "Defeated units cannot promote"
		}

	var result: Dictionary = PromotionService.promote(
		unit_data,
		target_class,
		progression,
		catalogue
	)

	if not result["success"]:
		return result

	var hp_increase: int = int(result["stat_increases"]["max_hp"])
	current_hp = clampi(current_hp + hp_increase, 0, stats.max_hp)

	queue_redraw()

	return result


func _draw() -> void:
	var color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR
	if has_acted:
		color = color.darkened(0.5)
	var rect := Rect2(Vector2(4, 4), Vector2(CELL_SIZE - 8, CELL_SIZE - 8))
	draw_rect(rect, color)
	var class_letter := get_class_letter()
	var font := ThemeDB.fallback_font
	var font_size := 16
	var text_size := font.get_string_size(class_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_position := Vector2((CELL_SIZE - text_size.x) / 2.0, (CELL_SIZE + text_size.y) / 2.0 - 3.0)
	draw_string(font, text_position, class_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)

func get_class_letter() -> String:
	if unit_data == null or unit_data.unit_class == null:
		return "?"
	match unit_data.unit_class.class_name_display.to_lower():
		"swordsman": return "S"
		"knight": return "K"
		"general": return "G"
		"archer": return "A"
		"fighter": return "F"
		_: return "?"


func move_along_path(path: Array[Vector2i]) -> void:
	if is_moving:
		return

	if path.is_empty():
		movement_finished.emit()
		return

	is_moving = true

	for cell in path:
		if current_hp <= 0:
			break

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

		if terrain_cell_entered.has_connections():
			terrain_cell_entered.emit(self, cell)
			await terrain_effect_finished

		if current_hp <= 0:
			break

	is_moving = false
	movement_finished.emit()

	
	

func sync_run_state() -> void:
	if run_state == null:
		return

	run_state.current_hp = clampi(current_hp, 0, stats.max_hp)

	if run_state.current_hp == 0:
		run_state.is_alive = false
