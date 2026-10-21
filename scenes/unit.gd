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

	if unit_data != null and unit_data.unit_class != null:
		match unit_data.unit_class.class_name_display.to_lower():
			"knight":
				draw_knight()
				return
			"archer":
				draw_archer()
				return
			"swordsman":
				draw_swordsman()
				return
			"fighter":
				draw_fighter()
				return

	# Existing square-and-letter appearance for other classes.
	var rect := Rect2(Vector2(4, 4), Vector2(CELL_SIZE - 8, CELL_SIZE - 8))
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

func draw_fighter() -> void:
	var outline := Color("#302b29")
	var skin := Color("#d6a077")
	var skin_shadow := Color("#a97050")
	var hair := Color("#49352b")
	var leather := Color("#77523b")
	var leather_light := Color("#a47a52")
	var steel := Color("#b7c5cd")
	var steel_dark := Color("#657784")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	# Wide boots.
	draw_rect(Rect2(8, 26, 7, 4), outline)
	draw_rect(Rect2(19, 26, 7, 4), outline)

	# Thick legs.
	draw_rect(Rect2(9, 21, 6, 6), leather)
	draw_rect(Rect2(19, 21, 6, 6), leather)

	# Broad torso.
	draw_rect(Rect2(7, 12, 20, 12), outline)
	draw_rect(Rect2(9, 13, 16, 10), team_color)

	# Leather belt.
	draw_rect(Rect2(9, 20, 16, 3), leather)
	draw_rect(Rect2(16, 20, 3, 3), leather_light)

	# Bare, muscular arms.
	draw_rect(Rect2(4, 13, 5, 10), skin_shadow)
	draw_rect(Rect2(5, 14, 4, 8), skin)
	draw_rect(Rect2(25, 13, 5, 10), skin_shadow)
	draw_rect(Rect2(25, 14, 4, 8), skin)

	# Hands.
	draw_rect(Rect2(4, 22, 5, 3), skin)
	draw_rect(Rect2(25, 22, 5, 3), skin)

	# Neck and face.
	draw_rect(Rect2(13, 11, 8, 4), skin_shadow)
	draw_rect(Rect2(11, 5, 12, 10), outline)
	draw_rect(Rect2(12, 7, 10, 7), skin)

	# Rough, dark hair.
	draw_rect(Rect2(10, 3, 14, 6), hair)
	draw_rect(Rect2(9, 6, 4, 5), hair)
	draw_rect(Rect2(21, 6, 4, 4), hair)

	# Eyes.
	draw_rect(Rect2(14, 11, 2, 1), outline)
	draw_rect(Rect2(19, 11, 2, 1), outline)

	# Axe handle on the right.
	draw_rect(Rect2(28, 8, 2, 20), leather)

	# Large steel axe head.
	draw_rect(Rect2(24, 4, 7, 9), steel_dark)
	draw_rect(Rect2(23, 5, 6, 7), steel)
	draw_rect(Rect2(21, 7, 3, 4), steel)
	draw_rect(Rect2(25, 3, 4, 2), steel)

	# Dim after acting.
	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)

func draw_swordsman() -> void:
	var outline := Color("#292b35")
	var leather := Color("#665044")
	var skin := Color("#d9a578")
	var hair := Color("#49372f")
	var steel := Color("#c5d5df")
	var steel_dark := Color("#657b8b")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	# Boots.
	draw_rect(Rect2(10, 26, 5, 4), outline)
	draw_rect(Rect2(19, 26, 5, 4), outline)

	# Legs.
	draw_rect(Rect2(11, 21, 4, 6), leather)
	draw_rect(Rect2(19, 21, 4, 6), leather)

	# Tunic and torso.
	draw_rect(Rect2(9, 12, 16, 12), outline)
	draw_rect(Rect2(10, 13, 14, 10), team_color)

	# Belt.
	draw_rect(Rect2(10, 20, 14, 2), leather)
	draw_rect(Rect2(16, 20, 2, 2), steel)

	# Arms.
	draw_rect(Rect2(6, 14, 4, 8), team_color.darkened(0.2))
	draw_rect(Rect2(24, 14, 4, 8), team_color.darkened(0.2))

	# Hands.
	draw_rect(Rect2(6, 21, 4, 3), skin)
	draw_rect(Rect2(24, 21, 4, 3), skin)

	# Neck and face.
	draw_rect(Rect2(14, 11, 6, 4), skin)
	draw_rect(Rect2(11, 5, 12, 10), outline)
	draw_rect(Rect2(12, 7, 10, 7), skin)

	# Dark, slightly swept hair.
	draw_rect(Rect2(10, 4, 14, 5), hair)
	draw_rect(Rect2(10, 7, 3, 5), hair)
	draw_rect(Rect2(21, 6, 3, 3), hair)

	# Eyes.
	draw_rect(Rect2(14, 11, 2, 1), outline)
	draw_rect(Rect2(19, 11, 2, 1), outline)

	# Light shoulder armour.
	draw_rect(Rect2(7, 13, 5, 3), steel_dark)
	draw_rect(Rect2(23, 13, 5, 3), steel_dark)

	# Sword held upright on the right.
	# Blade.
	draw_rect(Rect2(28, 3, 3, 15), steel)
	draw_rect(Rect2(28, 3, 1, 15), steel_dark)

	# Sword tip.
	draw_rect(Rect2(29, 1, 1, 2), steel)

	# Crossguard.
	draw_rect(Rect2(25, 18, 7, 2), Color("#b69a57"))

	# Grip and pommel.
	draw_rect(Rect2(28, 20, 3, 6), leather)
	draw_rect(Rect2(27, 25, 5, 2), steel_dark)

	# Dim after acting.
	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)

func draw_archer() -> void:
	var outline := Color("#302b29")
	var leather := Color("#765238")
	var leather_light := Color("#a67b4c")
	var tunic := Color("#547d48")
	var skin := Color("#d9a578")
	var hair := Color("#6c4930")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	# Boots.
	draw_rect(Rect2(10, 26, 5, 4), outline)
	draw_rect(Rect2(18, 26, 5, 4), outline)

	# Legs.
	draw_rect(Rect2(11, 21, 4, 6), leather)
	draw_rect(Rect2(18, 21, 4, 6), leather)

	# Tunic and torso.
	draw_rect(Rect2(9, 12, 15, 12), outline)
	draw_rect(Rect2(10, 13, 13, 10), tunic)

	# Leather belt.
	draw_rect(Rect2(10, 20, 13, 2), leather)
	draw_rect(Rect2(16, 20, 2, 2), leather_light)

	# Arms.
	draw_rect(Rect2(7, 14, 4, 8), leather)
	draw_rect(Rect2(23, 14, 4, 8), leather)
	draw_rect(Rect2(7, 20, 4, 3), skin)
	draw_rect(Rect2(23, 20, 4, 3), skin)

	# Face.
	draw_rect(Rect2(11, 6, 11, 9), outline)
	draw_rect(Rect2(12, 7, 9, 7), skin)

	# Hair.
	draw_rect(Rect2(10, 4, 13, 5), hair)
	draw_rect(Rect2(10, 7, 3, 5), hair)

	# Eyes.
	draw_rect(Rect2(14, 11, 2, 1), outline)
	draw_rect(Rect2(19, 11, 2, 1), outline)

	# Team-coloured shoulder scarf.
	draw_rect(Rect2(10, 13, 13, 3), team_color)

	# Quiver behind the shoulder.
	draw_rect(Rect2(22, 8, 5, 11), leather)
	draw_rect(Rect2(23, 6, 1, 5), Color("#c7c7b8"))
	draw_rect(Rect2(26, 7, 1, 5), Color("#c7c7b8"))

	# Wooden bow on the left side.
	var bow_color := Color("#a77b45")
	draw_rect(Rect2(3, 9, 2, 4), bow_color)
	draw_rect(Rect2(5, 13, 2, 4), bow_color)
	draw_rect(Rect2(6, 17, 2, 5), bow_color)
	draw_rect(Rect2(5, 22, 2, 4), bow_color)
	draw_rect(Rect2(3, 26, 2, 3), bow_color)

	# Bowstring.
	draw_line(Vector2(4, 10), Vector2(4, 28), Color("#e0d6b8"), 1.0)

	# Dim after acting.
	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)

func draw_knight() -> void:
	var armor_dark := Color("#354454")
	var armor_mid := Color("#788b9b")
	var armor_light := Color("#b7c7d2")
	var visor := Color("#202b36")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	# Feet and boots.
	draw_rect(Rect2(9, 25, 6, 5), armor_dark)
	draw_rect(Rect2(18, 25, 6, 5), armor_dark)

	# Armoured legs.
	draw_rect(Rect2(10, 19, 5, 8), armor_mid)
	draw_rect(Rect2(18, 19, 5, 8), armor_mid)

	# Main breastplate.
	draw_rect(Rect2(9, 12, 15, 11), armor_dark)
	draw_rect(Rect2(11, 13, 11, 8), armor_mid)

	# Team-coloured tunic beneath the armour.
	draw_rect(Rect2(13, 19, 7, 5), team_color)

	# Shoulder plates.
	draw_rect(Rect2(6, 13, 5, 7), armor_light)
	draw_rect(Rect2(22, 13, 5, 7), armor_light)

	# Wider helmet with pronounced side guards.
	draw_rect(Rect2(9, 5, 15, 10), armor_dark)
	draw_rect(Rect2(10, 6, 13, 7), armor_mid)

	# Helmet side guards.
	draw_rect(Rect2(8, 10, 4, 6), armor_light)
	draw_rect(Rect2(21, 10, 4, 6), armor_light)

	# Dark horizontal visor.
	draw_rect(Rect2(10, 10, 13, 3), visor)

	# Central helmet ridge.
	draw_rect(Rect2(16, 4, 2, 7), armor_light)

	# Team-coloured helmet plume.
	draw_rect(Rect2(14, 1, 6, 4), team_color)
	draw_rect(Rect2(12, 2, 4, 3), team_color)

	# Shield on the knight's left side.
	draw_rect(Rect2(4, 16, 8, 10), armor_dark)
	draw_rect(Rect2(5, 17, 6, 7), team_color)
	draw_rect(Rect2(7, 18, 2, 5), armor_light)

	# Lance held upright on the right.
	draw_rect(Rect2(27, 5, 2, 23), Color("#70583e"))
	draw_rect(Rect2(26, 2, 4, 6), armor_light)

	# Dim the entire character after acting.
	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)

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
