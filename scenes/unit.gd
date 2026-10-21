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
	var skin_highlight := Color("#edbd91")
	var hair := Color("#49352b")
	var leather := Color("#77523b")
	var leather_light := Color("#a47a52")
	var steel := Color("#b7c5cd")
	var steel_dark := Color("#657784")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	# Shift the character left to make room for the axe.
	draw_set_transform(Vector2(-3, 0))

	# Thick legs with dark outlines.
	draw_rect(Rect2(8, 21, 8, 7), outline)
	draw_rect(Rect2(18, 21, 8, 7), outline)

	# Leather trousers.
	draw_rect(Rect2(9, 22, 6, 5), leather)
	draw_rect(Rect2(19, 22, 6, 5), leather)

	# Upper-left highlights.
	draw_rect(Rect2(9, 22, 2, 4), leather_light)
	draw_rect(Rect2(19, 22, 2, 4), leather_light)

	# Lower-right shadows.
	draw_rect(Rect2(13, 24, 2, 3), leather.darkened(0.3))
	draw_rect(Rect2(23, 24, 2, 3), leather.darkened(0.3))

	# Boots with defined silhouettes.
	draw_rect(Rect2(7, 26, 9, 5), outline)
	draw_rect(Rect2(18, 26, 9, 5), outline)

	# Leather boot uppers.
	draw_rect(Rect2(9, 27, 6, 2), leather)
	draw_rect(Rect2(20, 27, 6, 2), leather)

	# Boot highlights.
	draw_rect(Rect2(9, 27, 3, 1), leather_light)
	draw_rect(Rect2(20, 27, 3, 1), leather_light)

	# Broad torso with cel shading.
	var tunic_shadow := team_color.darkened(0.35)
	var tunic_highlight := team_color.lightened(0.25)

	# Dark torso silhouette.
	draw_rect(Rect2(7, 12, 20, 12), outline)

	# Main tunic.
	draw_rect(Rect2(9, 13, 16, 10), team_color)

	# Upper-left highlights.
	draw_rect(Rect2(9, 13, 10, 2), tunic_highlight)
	draw_rect(Rect2(9, 15, 3, 5), tunic_highlight)

	# Lower-right shadows.
	draw_rect(Rect2(20, 16, 5, 7), tunic_shadow)
	draw_rect(Rect2(14, 21, 11, 2), tunic_shadow)

	# Leather belt.
	draw_rect(Rect2(9, 20, 16, 3), leather)
	draw_rect(Rect2(16, 20, 3, 3), leather_light)

	# Left shoulder: rounded, muscular silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(8, 12),
			Vector2(5, 12),
			Vector2(3, 14),
			Vector2(3, 18),
			Vector2(5, 20),
			Vector2(9, 19),
			Vector2(11, 15)
		]),
		outline
	)

	# Left shoulder base colour.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(7, 13),
			Vector2(5, 14),
			Vector2(4, 16),
			Vector2(5, 19),
			Vector2(8, 18),
			Vector2(10, 15)
		]),
		skin
	)

	# Left shoulder highlight.
	draw_rect(Rect2(5, 14, 3, 2), skin_highlight)

	# Left shoulder shadow.
	draw_rect(Rect2(5, 18, 4, 1), skin_shadow)

	# Left forearm, tapering toward the wrist.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(4, 18),
			Vector2(9, 18),
			Vector2(9, 23),
			Vector2(8, 25),
			Vector2(4, 25),
			Vector2(3, 23)
		]),
		outline
	)

	draw_rect(Rect2(5, 19, 3, 5), skin)
	draw_rect(Rect2(7, 20, 1, 4), skin_shadow)
	draw_rect(Rect2(5, 19, 1, 3), skin_highlight)

	# Right shoulder: broad but slightly shadowed.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 12),
			Vector2(28, 12),
			Vector2(30, 14),
			Vector2(30, 18),
			Vector2(28, 20),
			Vector2(24, 19),
			Vector2(22, 15)
		]),
		outline
	)

	# Right shoulder base colour.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 13),
			Vector2(28, 14),
			Vector2(29, 16),
			Vector2(28, 19),
			Vector2(25, 18),
			Vector2(23, 15)
		]),
		skin
	)

	# Right shoulder highlight and shadow.
	draw_rect(Rect2(25, 14, 3, 2), skin_highlight)
	draw_rect(Rect2(26, 17, 3, 2), skin_shadow)

	# Right forearm.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 18),
			Vector2(29, 18),
			Vector2(30, 23),
			Vector2(29, 25),
			Vector2(25, 25),
			Vector2(24, 23)
		]),
		outline
	)

	draw_rect(Rect2(26, 19, 3, 5), skin)
	draw_rect(Rect2(28, 20, 1, 4), skin_shadow)
	draw_rect(Rect2(26, 19, 1, 3), skin_highlight)

	# Neck with shadow beneath the chin.
	draw_rect(Rect2(13, 11, 8, 5), outline)
	draw_rect(Rect2(14, 12, 6, 3), skin_shadow)

	# Head silhouette, narrower at the jaw.
	draw_rect(Rect2(11, 6, 12, 7), outline)
	draw_rect(Rect2(12, 12, 10, 2), outline)
	draw_rect(Rect2(14, 14, 7, 1), outline)

	# Face.
	draw_rect(Rect2(12, 7, 10, 5), skin)
	draw_rect(Rect2(13, 12, 8, 2), skin)

	# Cel-shaded face: light from upper-left.
	draw_rect(Rect2(12, 7, 6, 2), skin_highlight)
	draw_rect(Rect2(20, 9, 2, 3), skin_shadow)
	draw_rect(Rect2(18, 12, 3, 2), skin_shadow)

	# Hair silhouette with an uneven top.
	draw_rect(Rect2(11, 3, 11, 4), outline)
	draw_rect(Rect2(9, 5, 15, 3), outline)
	draw_rect(Rect2(10, 7, 3, 4), outline)
	draw_rect(Rect2(22, 6, 3, 4), outline)

	# Dark hair.
	draw_rect(Rect2(12, 4, 10, 3), hair)
	draw_rect(Rect2(10, 6, 13, 2), hair)
	draw_rect(Rect2(10, 8, 2, 2), hair)
	draw_rect(Rect2(22, 7, 2, 2), hair)

	# Hair highlights.
	draw_rect(Rect2(13, 4, 6, 1), hair.lightened(0.25))
	draw_rect(Rect2(11, 6, 4, 1), hair.lightened(0.15))

	# Eyes.
	draw_rect(Rect2(14, 10, 2, 1), outline)
	draw_rect(Rect2(19, 10, 2, 1), outline)

	# Reset the body transform.
	draw_set_transform(Vector2.ZERO)

	# Draw the axe on the right, with the blade facing outward.
	draw_set_transform(Vector2(50, 0), 0.0, Vector2(-1, 1))

	# Wooden axe handle.
	draw_rect(Rect2(27, 7, 3, 21), outline)
	draw_rect(Rect2(28, 8, 1, 19), leather_light)

	# Broad axe head outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(27, 3),
			Vector2(22, 3),
			Vector2(19, 6),
			Vector2(18, 10),
			Vector2(20, 14),
			Vector2(23, 16),
			Vector2(27, 13)
		]),
		outline
	)

	# Steel blade.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 4),
			Vector2(23, 4),
			Vector2(20, 7),
			Vector2(19, 10),
			Vector2(21, 13),
			Vector2(23, 14),
			Vector2(26, 12)
		]),
		steel
	)

	# Cel-shaded lower edge.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(19, 10),
			Vector2(21, 13),
			Vector2(23, 14),
			Vector2(26, 12),
			Vector2(26, 10),
			Vector2(22, 11)
		]),
		steel_dark
	)

	# Bright upper blade highlight.
	draw_line(
		Vector2(21, 7),
		Vector2(23, 5),
		Color("#e1e9ed"),
		1.0
	)

	# Reset drawing transform.
	draw_set_transform(Vector2.ZERO)

	# Dim the character after acting.
	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)


func draw_swordsman() -> void:
	var outline := Color("#292b35")
	var leather := Color("#665044")
	var leather_light := Color("#9b7860")
	var skin := Color("#d9a578")
	var skin_shadow := Color("#a97050")
	var skin_highlight := Color("#edbd91")
	var hair := Color("#49372f")
	var steel := Color("#c5d5df")
	var steel_dark := Color("#657b8b")
	var steel_highlight := Color("#edf5f8")
	var gold := Color("#b69a57")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	var tunic_shadow := team_color.darkened(0.35)
	var tunic_highlight := team_color.lightened(0.25)

	# Shift the body slightly left to make room for the sword.
	draw_set_transform(Vector2(-2, 0))

	# --------------------------------------------------
	# LEGS AND BOOTS
	# --------------------------------------------------

	# Slim legs with dark outlines.
	draw_rect(Rect2(10, 21, 6, 7), outline)
	draw_rect(Rect2(18, 21, 6, 7), outline)

	# Leather trousers.
	draw_rect(Rect2(11, 22, 4, 5), leather)
	draw_rect(Rect2(19, 22, 4, 5), leather)

	# Highlights and shadows.
	draw_rect(Rect2(11, 22, 1, 4), leather_light)
	draw_rect(Rect2(19, 22, 1, 4), leather_light)
	draw_rect(Rect2(14, 24, 1, 3), leather.darkened(0.3))
	draw_rect(Rect2(22, 24, 1, 3), leather.darkened(0.3))

	# Boots.
	draw_rect(Rect2(9, 26, 8, 5), outline)
	draw_rect(Rect2(18, 26, 8, 5), outline)

	draw_rect(Rect2(11, 27, 5, 2), leather)
	draw_rect(Rect2(20, 27, 5, 2), leather)

	# Boot highlights.
	draw_rect(Rect2(11, 27, 3, 1), leather_light)
	draw_rect(Rect2(20, 27, 3, 1), leather_light)

	# --------------------------------------------------
	# TORSO
	# --------------------------------------------------

	# Narrow, slightly tapered torso silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(11, 12),
			Vector2(23, 12),
			Vector2(25, 15),
			Vector2(24, 23),
			Vector2(10, 23),
			Vector2(9, 15)
		]),
		outline
	)

	# Main tunic.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(12, 13),
			Vector2(22, 13),
			Vector2(24, 16),
			Vector2(23, 22),
			Vector2(11, 22),
			Vector2(10, 16)
		]),
		team_color
	)

	# Upper-left highlights.
	draw_rect(Rect2(11, 15, 3, 5), tunic_highlight)
	draw_rect(Rect2(13, 13, 6, 2), tunic_highlight)

	# Lower-right shadows.
	draw_rect(Rect2(21, 16, 3, 6), tunic_shadow)
	draw_rect(Rect2(15, 21, 8, 1), tunic_shadow)

	# Diagonal leather strap across the chest.
	draw_line(
		Vector2(12, 14),
		Vector2(21, 21),
		outline,
		3.0
	)
	draw_line(
		Vector2(12, 14),
		Vector2(21, 21),
		leather_light,
		1.0
	)

	# Leather belt.
	draw_rect(Rect2(11, 20, 12, 3), outline)
	draw_rect(Rect2(12, 20, 10, 2), leather)
	draw_rect(Rect2(16, 20, 2, 2), gold)

	# --------------------------------------------------
	# ARMS AND SHOULDER ARMOUR
	# --------------------------------------------------

	# Left arm outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(9, 14),
			Vector2(6, 15),
			Vector2(6, 22),
			Vector2(8, 25),
			Vector2(11, 23),
			Vector2(12, 16)
		]),
		outline
	)

	# Left sleeve.
	draw_rect(Rect2(7, 16, 4, 5), team_color)
	draw_rect(Rect2(7, 16, 2, 2), tunic_highlight)
	draw_rect(Rect2(9, 18, 2, 3), tunic_shadow)

	# Left hand.
	draw_rect(Rect2(7, 21, 3, 3), skin)
	draw_rect(Rect2(9, 22, 1, 2), skin_shadow)

	# Right arm outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 14),
			Vector2(27, 15),
			Vector2(28, 22),
			Vector2(26, 25),
			Vector2(23, 23),
			Vector2(22, 16)
		]),
		outline
	)

	# Right sleeve.
	draw_rect(Rect2(23, 16, 4, 5), team_color)
	draw_rect(Rect2(23, 16, 2, 2), tunic_highlight)
	draw_rect(Rect2(25, 18, 2, 3), tunic_shadow)

	# Right hand.
	draw_rect(Rect2(24, 21, 3, 3), skin)
	draw_rect(Rect2(26, 22, 1, 2), skin_shadow)

	# Left shoulder armour silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 12),
			Vector2(7, 13),
			Vector2(6, 16),
			Vector2(11, 17),
			Vector2(13, 14)
		]),
		outline
	)

	# Left shoulder steel.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 13),
			Vector2(8, 14),
			Vector2(7, 15),
			Vector2(11, 16),
			Vector2(12, 14)
		]),
		steel
	)

	# Shoulder highlight.
	draw_line(
		Vector2(8, 14),
		Vector2(11, 13),
		steel_highlight,
		1.0
	)

	# Right shoulder armour silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 12),
			Vector2(26, 13),
			Vector2(28, 16),
			Vector2(23, 17),
			Vector2(21, 14)
		]),
		outline
	)

	# Right shoulder steel.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 13),
			Vector2(25, 14),
			Vector2(27, 15),
			Vector2(23, 16),
			Vector2(22, 14)
		]),
		steel_dark
	)

	# Small highlight.
	draw_rect(Rect2(23, 13, 2, 1), steel_highlight)

	# --------------------------------------------------
	# NECK AND FACE
	# --------------------------------------------------

	# Neck.
	draw_rect(Rect2(14, 11, 7, 5), outline)
	draw_rect(Rect2(15, 12, 5, 3), skin_shadow)

	# Head silhouette with narrower jaw.
	draw_rect(Rect2(11, 6, 12, 7), outline)
	draw_rect(Rect2(12, 12, 10, 2), outline)
	draw_rect(Rect2(14, 14, 7, 1), outline)

	# Face.
	draw_rect(Rect2(12, 7, 10, 5), skin)
	draw_rect(Rect2(13, 12, 8, 2), skin)

	# Cel-shaded face.
	draw_rect(Rect2(12, 7, 6, 2), skin_highlight)
	draw_rect(Rect2(20, 9, 2, 3), skin_shadow)
	draw_rect(Rect2(18, 12, 3, 2), skin_shadow)

	# --------------------------------------------------
	# HAIR
	# --------------------------------------------------

	# Swept hairstyle outline.
	draw_rect(Rect2(11, 3, 11, 4), outline)
	draw_rect(Rect2(9, 5, 15, 3), outline)
	draw_rect(Rect2(10, 7, 3, 4), outline)

	# Swept fringe extending to the right.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(19, 4),
			Vector2(24, 5),
			Vector2(25, 8),
			Vector2(22, 9),
			Vector2(20, 7)
		]),
		outline
	)

	# Main hair.
	draw_rect(Rect2(12, 4, 10, 3), hair)
	draw_rect(Rect2(10, 6, 13, 2), hair)
	draw_rect(Rect2(10, 8, 2, 2), hair)

	# Fringe.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(19, 5),
			Vector2(23, 6),
			Vector2(24, 8),
			Vector2(21, 8)
		]),
		hair
	)

	# Hair highlights.
	draw_rect(Rect2(13, 4, 6, 1), hair.lightened(0.3))
	draw_rect(Rect2(11, 6, 4, 1), hair.lightened(0.15))

	# Eyes.
	draw_rect(Rect2(14, 10, 2, 1), outline)
	draw_rect(Rect2(19, 10, 2, 1), outline)

	# Reset body transform.
	draw_set_transform(Vector2.ZERO)

	# --------------------------------------------------
	# SWORD - HELD CLOSE TO THE BODY
	# --------------------------------------------------

	# Blade outline: wider and positioned above the hand.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 17),
			Vector2(23, 7),
			Vector2(26, 2),
			Vector2(28, 7),
			Vector2(27, 17)
		]),
		outline
	)

	# Main steel blade.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 16),
			Vector2(24, 7),
			Vector2(26, 4),
			Vector2(27, 7),
			Vector2(26, 16)
		]),
		steel
	)

	# Dark right edge.
	draw_line(
		Vector2(26, 7),
		Vector2(26, 16),
		steel_dark,
		1.0
	)

	# Bright left edge.
	draw_line(
		Vector2(24, 8),
		Vector2(25, 5),
		steel_highlight,
		1.0
	)

	# Crossguard.
	draw_rect(Rect2(21, 16, 9, 3), outline)
	draw_rect(Rect2(22, 17, 7, 1), gold)

	# Grip.
	draw_rect(Rect2(24, 19, 4, 7), outline)
	draw_rect(Rect2(25, 20, 2, 5), leather)

	# Pommel.
	draw_rect(Rect2(23, 25, 6, 3), outline)
	draw_rect(Rect2(24, 26, 4, 1), steel_dark)

	# Hand wrapped around the grip.
	# Drawn last so it visibly overlaps the handle.
	draw_rect(Rect2(22, 20, 6, 4), outline)
	draw_rect(Rect2(23, 21, 4, 2), skin)
	draw_rect(Rect2(26, 22, 1, 1), skin_shadow)

	# --------------------------------------------------
	# ACTED-STATE DIMMING
	# --------------------------------------------------

	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)

func draw_archer() -> void:
	var outline := Color("#302b29")
	var leather := Color("#765238")
	var leather_light := Color("#a67b4c")
	var leather_shadow := Color("#493526")
	var tunic := Color("#547d48")
	var tunic_light := Color("#83a36b")
	var tunic_shadow := Color("#344f35")
	var skin := Color("#d9a578")
	var skin_light := Color("#edbd91")
	var skin_shadow := Color("#a97050")
	var hair := Color("#6c4930")
	var hair_light := Color("#97704a")
	var bow_color := Color("#a77b45")
	var bow_light := Color("#d0a366")
	var string_color := Color("#e8dcc0")
	var arrow_color := Color("#c7c7b8")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR

	# --------------------------------------------------
	# LEGS AND BOOTS
	# --------------------------------------------------

	draw_rect(Rect2(10, 21, 6, 7), outline)
	draw_rect(Rect2(18, 21, 6, 7), outline)

	draw_rect(Rect2(11, 22, 4, 5), leather)
	draw_rect(Rect2(19, 22, 4, 5), leather)

	draw_rect(Rect2(11, 22, 1, 4), leather_light)
	draw_rect(Rect2(19, 22, 1, 4), leather_light)
	draw_rect(Rect2(14, 24, 1, 3), leather_shadow)
	draw_rect(Rect2(22, 24, 1, 3), leather_shadow)

	# Boots.
	draw_rect(Rect2(9, 26, 8, 5), outline)
	draw_rect(Rect2(18, 26, 8, 5), outline)

	draw_rect(Rect2(11, 27, 5, 2), leather)
	draw_rect(Rect2(20, 27, 5, 2), leather)

	draw_rect(Rect2(11, 27, 3, 1), leather_light)
	draw_rect(Rect2(20, 27, 3, 1), leather_light)

	# --------------------------------------------------
	# QUIVER - BEHIND THE RIGHT SHOULDER
	# --------------------------------------------------

	# Arrow shafts.
	draw_rect(Rect2(23, 5, 2, 9), outline)
	draw_rect(Rect2(24, 6, 1, 7), arrow_color)

	draw_rect(Rect2(26, 6, 2, 9), outline)
	draw_rect(Rect2(27, 7, 1, 7), arrow_color)

	# Arrow fletching.
	draw_rect(Rect2(22, 6, 3, 2), Color("#e2e4d7"))
	draw_rect(Rect2(25, 7, 3, 2), Color("#e2e4d7"))

	# Quiver silhouette.
	draw_rect(Rect2(22, 10, 7, 12), outline)

	# Leather quiver.
	draw_rect(Rect2(23, 11, 5, 10), leather)
	draw_rect(Rect2(23, 11, 2, 8), leather_light)
	draw_rect(Rect2(27, 13, 1, 7), leather_shadow)

	# Quiver rim.
	draw_rect(Rect2(22, 10, 7, 2), leather_shadow)
	draw_rect(Rect2(23, 10, 5, 1), leather_light)

	# --------------------------------------------------
	# TORSO
	# --------------------------------------------------

	# Tapered silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(11, 12),
			Vector2(22, 12),
			Vector2(25, 15),
			Vector2(24, 23),
			Vector2(10, 23),
			Vector2(9, 15)
		]),
		outline
	)

	# Main tunic.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(12, 13),
			Vector2(21, 13),
			Vector2(24, 16),
			Vector2(23, 22),
			Vector2(11, 22),
			Vector2(10, 16)
		]),
		tunic
	)

	# Cel-shaded highlights.
	draw_rect(Rect2(11, 15, 3, 5), tunic_light)
	draw_rect(Rect2(13, 13, 6, 2), tunic_light)

	# Cel-shaded shadows.
	draw_rect(Rect2(21, 16, 3, 6), tunic_shadow)
	draw_rect(Rect2(15, 21, 8, 1), tunic_shadow)

	# Leather chest strap.
	draw_line(
		Vector2(21, 14),
		Vector2(13, 21),
		outline,
		3.0
	)
	draw_line(
		Vector2(21, 14),
		Vector2(13, 21),
		leather_light,
		1.0
	)

	# Belt.
	draw_rect(Rect2(10, 20, 14, 3), outline)
	draw_rect(Rect2(11, 20, 12, 2), leather)
	draw_rect(Rect2(16, 20, 3, 2), leather_light)

	# --------------------------------------------------
	# ARMS
	# --------------------------------------------------

	# Left arm reaches toward the bow.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 14),
			Vector2(7, 14),
			Vector2(5, 17),
			Vector2(5, 21),
			Vector2(7, 24),
			Vector2(11, 22),
			Vector2(12, 16)
		]),
		outline
	)

	# Left sleeve.
	draw_rect(Rect2(7, 15, 4, 5), tunic)
	draw_rect(Rect2(7, 15, 2, 2), tunic_light)
	draw_rect(Rect2(9, 18, 2, 2), tunic_shadow)

	# Left forearm.
	draw_rect(Rect2(6, 20, 4, 3), skin)
	draw_rect(Rect2(6, 20, 2, 1), skin_light)
	draw_rect(Rect2(9, 21, 1, 2), skin_shadow)

	# Right arm outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 14),
			Vector2(26, 14),
			Vector2(28, 17),
			Vector2(28, 23),
			Vector2(26, 25),
			Vector2(23, 23),
			Vector2(22, 16)
		]),
		outline
	)

	# Right sleeve.
	draw_rect(Rect2(23, 15, 4, 5), tunic)
	draw_rect(Rect2(23, 15, 2, 2), tunic_light)
	draw_rect(Rect2(25, 18, 2, 2), tunic_shadow)

	# Right forearm.
	draw_rect(Rect2(24, 20, 3, 4), skin)
	draw_rect(Rect2(24, 20, 1, 2), skin_light)
	draw_rect(Rect2(26, 21, 1, 3), skin_shadow)

	# --------------------------------------------------
	# LEATHER SHOULDER GUARDS
	# --------------------------------------------------

	# Left guard outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 12),
			Vector2(7, 13),
			Vector2(6, 16),
			Vector2(11, 17),
			Vector2(13, 14)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 13),
			Vector2(8, 14),
			Vector2(7, 15),
			Vector2(11, 16),
			Vector2(12, 14)
		]),
		leather
	)

	draw_line(
		Vector2(8, 14),
		Vector2(11, 13),
		leather_light,
		1.0
	)

	# Right guard outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 12),
			Vector2(26, 13),
			Vector2(28, 16),
			Vector2(23, 17),
			Vector2(21, 14)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 13),
			Vector2(25, 14),
			Vector2(27, 15),
			Vector2(23, 16),
			Vector2(22, 14)
		]),
		leather
	)

	draw_rect(Rect2(23, 13, 2, 1), leather_light)
	draw_rect(Rect2(25, 15, 2, 1), leather_shadow)

	# --------------------------------------------------
	# NECK AND FACE
	# --------------------------------------------------

	# Neck.
	draw_rect(Rect2(14, 11, 7, 5), outline)
	draw_rect(Rect2(15, 12, 5, 3), skin_shadow)

	# Head silhouette.
	draw_rect(Rect2(11, 6, 12, 7), outline)
	draw_rect(Rect2(12, 12, 10, 2), outline)
	draw_rect(Rect2(14, 14, 7, 1), outline)

	# Face.
	draw_rect(Rect2(12, 7, 10, 5), skin)
	draw_rect(Rect2(13, 12, 8, 2), skin)

	# Cel-shaded face.
	draw_rect(Rect2(12, 7, 6, 2), skin_light)
	draw_rect(Rect2(20, 9, 2, 3), skin_shadow)
	draw_rect(Rect2(18, 12, 3, 2), skin_shadow)

	# Eyes.
	draw_rect(Rect2(14, 10, 2, 1), outline)
	draw_rect(Rect2(19, 10, 2, 1), outline)

	# --------------------------------------------------
	# HAIR
	# --------------------------------------------------

	# Tousled hairstyle.
	draw_rect(Rect2(11, 3, 11, 4), outline)
	draw_rect(Rect2(9, 5, 15, 3), outline)
	draw_rect(Rect2(10, 7, 3, 4), outline)
	draw_rect(Rect2(22, 6, 3, 4), outline)

	draw_rect(Rect2(12, 4, 10, 3), hair)
	draw_rect(Rect2(10, 6, 13, 2), hair)
	draw_rect(Rect2(10, 8, 2, 2), hair)
	draw_rect(Rect2(22, 7, 2, 2), hair)

	# Hair highlights.
	draw_rect(Rect2(13, 4, 6, 1), hair_light)
	draw_rect(Rect2(11, 6, 4, 1), hair_light)

	# --------------------------------------------------
	# TEAM-COLOURED SCARF
	# --------------------------------------------------

	draw_rect(Rect2(11, 13, 12, 4), outline)
	draw_rect(Rect2(12, 14, 10, 2), team_color)

	draw_rect(
		Rect2(12, 14, 6, 1),
		team_color.lightened(0.25)
	)

	draw_rect(
		Rect2(19, 15, 3, 1),
		team_color.darkened(0.35)
	)

	# Scarf tail.
	draw_rect(Rect2(19, 16, 3, 4), outline)
	draw_rect(Rect2(20, 16, 2, 3), team_color)

	# --------------------------------------------------
	# BOW - OUTWARD-FACING RECURVE
	# --------------------------------------------------

	# Bowstring, drawn behind the wooden limbs.
	draw_line(
		Vector2(8, 7),
		Vector2(8, 29),
		string_color,
		1.0
	)

	# Dark outer bow outline.
	draw_line(Vector2(8, 7), Vector2(4, 11), outline, 4.0)
	draw_line(Vector2(4, 11), Vector2(3, 16), outline, 4.0)
	draw_line(Vector2(3, 16), Vector2(5, 20), outline, 4.0)
	draw_line(Vector2(5, 20), Vector2(3, 24), outline, 4.0)
	draw_line(Vector2(3, 24), Vector2(8, 29), outline, 4.0)

	# Wooden interior.
	draw_line(Vector2(8, 7), Vector2(4, 11), bow_color, 2.0)
	draw_line(Vector2(4, 11), Vector2(3, 16), bow_color, 2.0)
	draw_line(Vector2(3, 16), Vector2(5, 20), bow_color, 2.0)
	draw_line(Vector2(5, 20), Vector2(3, 24), bow_color, 2.0)
	draw_line(Vector2(3, 24), Vector2(8, 29), bow_color, 2.0)

	# Wooden highlights.
	draw_line(Vector2(7, 8), Vector2(4, 11), bow_light, 1.0)
	draw_line(Vector2(4, 24), Vector2(7, 28), bow_light, 1.0)

	# Reinforced grip.
	draw_rect(Rect2(3, 17, 5, 6), outline)
	draw_rect(Rect2(4, 18, 3, 4), leather)

	# Hand gripping the bow.
	draw_rect(Rect2(5, 19, 5, 4), outline)
	draw_rect(Rect2(6, 20, 3, 2), skin)
	draw_rect(Rect2(8, 21, 1, 1), skin_shadow)

	# --------------------------------------------------
	# ACTED-STATE DIMMING
	# --------------------------------------------------

	if has_acted:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(0, 0, 0, 0.45)
		)


func draw_knight() -> void:
	var outline := Color("#222b35")
	var armor_dark := Color("#354454")
	var armor_mid := Color("#788b9b")
	var armor_light := Color("#b7c7d2")
	var armor_highlight := Color("#e2edf2")
	var visor := Color("#202b36")
	var leather := Color("#70583e")
	var leather_light := Color("#a58a62")
	var team_color := PLAYER_COLOR if team == Team.PLAYER else ENEMY_COLOR
	var team_shadow := team_color.darkened(0.35)
	var team_highlight := team_color.lightened(0.3)

	# --------------------------------------------------
	# LEGS AND ARMOURED BOOTS
	# --------------------------------------------------

	# Heavy leg silhouettes.
	draw_rect(Rect2(8, 20, 8, 9), outline)
	draw_rect(Rect2(17, 20, 8, 9), outline)

	# Steel greaves.
	draw_rect(Rect2(9, 21, 6, 7), armor_mid)
	draw_rect(Rect2(18, 21, 6, 7), armor_mid)

	# Cel-shaded greaves.
	draw_rect(Rect2(9, 21, 2, 5), armor_light)
	draw_rect(Rect2(14, 22, 1, 6), armor_dark)
	draw_rect(Rect2(18, 21, 2, 5), armor_light)
	draw_rect(Rect2(23, 22, 1, 6), armor_dark)

	# Heavy boots.
	draw_rect(Rect2(7, 26, 10, 5), outline)
	draw_rect(Rect2(17, 26, 10, 5), outline)

	draw_rect(Rect2(9, 27, 7, 2), armor_dark)
	draw_rect(Rect2(19, 27, 7, 2), armor_dark)

	draw_rect(Rect2(9, 27, 4, 1), armor_light)
	draw_rect(Rect2(19, 27, 4, 1), armor_light)

	# --------------------------------------------------
	# TEAM-COLOURED TABARD
	# --------------------------------------------------

	# Cloth hangs beneath the breastplate.
	draw_rect(Rect2(11, 18, 12, 10), outline)
	draw_rect(Rect2(12, 19, 10, 8), team_color)

	# Fold highlights and shadows.
	draw_rect(Rect2(12, 19, 3, 7), team_highlight)
	draw_rect(Rect2(19, 20, 3, 7), team_shadow)

	# Centre seam.
	draw_rect(Rect2(16, 22, 1, 5), team_shadow)

	# --------------------------------------------------
	# HEAVY BREASTPLATE
	# --------------------------------------------------

	# Broad, angular torso silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(9, 11),
			Vector2(24, 11),
			Vector2(27, 15),
			Vector2(25, 23),
			Vector2(8, 23),
			Vector2(6, 15)
		]),
		outline
	)

	# Main steel breastplate.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 12),
			Vector2(23, 12),
			Vector2(26, 15),
			Vector2(24, 22),
			Vector2(9, 22),
			Vector2(7, 15)
		]),
		armor_mid
	)

	# Bright upper-left armour plane.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(10, 12),
			Vector2(16, 12),
			Vector2(16, 18),
			Vector2(10, 20),
			Vector2(8, 15)
		]),
		armor_light
	)

	# Dark right-side armour plane.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(21, 13),
			Vector2(24, 14),
			Vector2(25, 16),
			Vector2(23, 21),
			Vector2(19, 21)
		]),
		armor_dark
	)

	# Centre ridge.
	draw_rect(Rect2(16, 13, 2, 8), armor_light)
	draw_rect(Rect2(16, 13, 1, 6), armor_highlight)

	# Lower plate separation.
	draw_line(
		Vector2(10, 20),
		Vector2(23, 20),
		outline,
		1.0
	)

	# Waist buckle.
	draw_rect(Rect2(14, 20, 6, 4), outline)
	draw_rect(Rect2(15, 21, 4, 2), armor_light)
	draw_rect(Rect2(16, 21, 2, 1), armor_highlight)

	# --------------------------------------------------
	# ARMS AND SHOULDER PLATES
	# --------------------------------------------------

	# Left arm.
	draw_rect(Rect2(4, 14, 8, 12), outline)
	draw_rect(Rect2(5, 15, 6, 10), armor_mid)

	draw_rect(Rect2(5, 16, 2, 7), armor_light)
	draw_rect(Rect2(10, 17, 1, 7), armor_dark)

	# Right arm.
	draw_rect(Rect2(22, 14, 8, 12), outline)
	draw_rect(Rect2(23, 15, 6, 10), armor_mid)

	draw_rect(Rect2(23, 16, 2, 7), armor_light)
	draw_rect(Rect2(28, 17, 1, 7), armor_dark)

	# Broad left shoulder plate.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(9, 11),
			Vector2(5, 12),
			Vector2(3, 16),
			Vector2(4, 19),
			Vector2(11, 18),
			Vector2(13, 14)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(9, 12),
			Vector2(6, 13),
			Vector2(4, 16),
			Vector2(5, 18),
			Vector2(10, 17),
			Vector2(12, 14)
		]),
		armor_mid
	)

	draw_line(
		Vector2(6, 14),
		Vector2(10, 13),
		armor_highlight,
		2.0
	)
	draw_rect(Rect2(5, 17, 5, 1), armor_dark)

	# Broad right shoulder plate.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 11),
			Vector2(27, 12),
			Vector2(30, 16),
			Vector2(29, 19),
			Vector2(22, 18),
			Vector2(20, 14)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 12),
			Vector2(26, 13),
			Vector2(29, 16),
			Vector2(28, 18),
			Vector2(23, 17),
			Vector2(21, 14)
		]),
		armor_mid
	)

	draw_line(
		Vector2(23, 13),
		Vector2(26, 14),
		armor_light,
		2.0
	)
	draw_rect(Rect2(27, 16, 2, 2), armor_dark)

	# --------------------------------------------------
	# HELMET AND VISOR - REFINED
	# --------------------------------------------------

	# Dark silhouette with a narrower, rounded crown.
	draw_rect(Rect2(10, 5, 13, 11), outline)
	draw_rect(Rect2(12, 3, 9, 3), outline)

	# Main steel helmet.
	draw_rect(Rect2(11, 6, 11, 9), armor_mid)
	draw_rect(Rect2(13, 4, 7, 3), armor_mid)

	# Cel-shaded crown.
	draw_rect(Rect2(12, 6, 4, 4), armor_light)
	draw_rect(Rect2(13, 4, 5, 1), armor_highlight)
	draw_rect(Rect2(20, 6, 2, 7), armor_dark)

	# Narrow visor slit.
	draw_rect(Rect2(11, 10, 11, 3), outline)
	draw_rect(Rect2(12, 11, 9, 1), visor)

	# Subtle reflection inside the visor.
	draw_rect(Rect2(13, 11, 3, 1), armor_dark)

	# Lower faceplate.
	draw_rect(Rect2(12, 13, 9, 3), armor_dark)
	draw_rect(Rect2(13, 13, 7, 2), armor_mid)

	# Small highlight on the faceplate.
	draw_rect(Rect2(13, 13, 3, 1), armor_light)

	# Short cheek guards.
	draw_rect(Rect2(9, 11, 3, 5), outline)
	draw_rect(Rect2(10, 12, 2, 3), armor_light)

	draw_rect(Rect2(22, 11, 3, 5), outline)
	draw_rect(Rect2(22, 12, 2, 3), armor_dark)

	# --------------------------------------------------
	# TEAM-COLOURED HELMET PLUME
	# --------------------------------------------------

	# Plume outline.
	draw_rect(Rect2(14, 0, 7, 5), outline)
	draw_rect(Rect2(11, 2, 6, 4), outline)

	# Main plume.
	draw_rect(Rect2(15, 1, 5, 3), team_color)
	draw_rect(Rect2(12, 3, 5, 2), team_color)

	# Highlights.
	draw_rect(Rect2(15, 1, 3, 1), team_highlight)
	draw_rect(Rect2(12, 3, 2, 1), team_highlight)

	# Shadows.
	draw_rect(Rect2(18, 3, 2, 1), team_shadow)
	draw_rect(Rect2(14, 4, 3, 1), team_shadow)

	# --------------------------------------------------
	# SHIELD - LEFT SIDE
	# --------------------------------------------------

	# Shield silhouette with pointed lower edge.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(3, 15),
			Vector2(12, 15),
			Vector2(12, 24),
			Vector2(8, 29),
			Vector2(3, 25)
		]),
		outline
	)

	# Team-coloured shield face.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(4, 16),
			Vector2(11, 16),
			Vector2(11, 23),
			Vector2(8, 27),
			Vector2(4, 24)
		]),
		team_color
	)

	# Shield highlights.
	draw_rect(Rect2(4, 17, 2, 7), team_highlight)
	draw_rect(Rect2(10, 18, 1, 5), team_shadow)

	# Steel shield border.
	draw_line(Vector2(4, 16), Vector2(11, 16), armor_light, 1.0)
	draw_line(Vector2(4, 16), Vector2(4, 24), armor_light, 1.0)
	draw_line(Vector2(4, 24), Vector2(8, 27), armor_dark, 1.0)

	# Central shield emblem.
	draw_rect(Rect2(7, 18, 2, 7), outline)
	draw_rect(Rect2(5, 20, 6, 2), outline)

	draw_rect(Rect2(7, 18, 2, 6), armor_highlight)
	draw_rect(Rect2(5, 20, 6, 2), armor_light)

	# --------------------------------------------------
	# LANCE - RIGHT SIDE
	# --------------------------------------------------

	# Wooden shaft outline.
	draw_rect(Rect2(28, 8, 4, 22), outline)

	# Wooden shaft.
	draw_rect(Rect2(29, 9, 2, 20), leather)
	draw_rect(Rect2(29, 10, 1, 17), leather_light)

	# Spearhead outline.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(30, 0),
			Vector2(32, 7),
			Vector2(31, 11),
			Vector2(28, 11),
			Vector2(28, 7)
		]),
		outline
	)

	# Steel spearhead.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(30, 2),
			Vector2(31, 7),
			Vector2(30, 10),
			Vector2(29, 10),
			Vector2(29, 7)
		]),
		armor_light
	)

	# Spearhead highlight.
	draw_line(
		Vector2(30, 3),
		Vector2(30, 9),
		armor_highlight,
		1.0
	)

	# Metal collar beneath the blade.
	draw_rect(Rect2(28, 10, 4, 3), outline)
	draw_rect(Rect2(29, 11, 2, 1), armor_mid)

	# Right gauntlet wraps around the lance.
	draw_rect(Rect2(25, 19, 7, 6), outline)
	draw_rect(Rect2(26, 20, 5, 4), armor_mid)
	draw_rect(Rect2(26, 20, 2, 2), armor_light)
	draw_rect(Rect2(30, 22, 1, 2), armor_dark)

	# --------------------------------------------------
	# LEG SEPARATION - FINAL FOREGROUND DETAILS
	# --------------------------------------------------

	# Dark gap between the legs.
	draw_rect(Rect2(16, 24, 2, 7), outline)

	# Reinforce individual boot silhouettes.
	draw_rect(Rect2(8, 29, 8, 2), outline)
	draw_rect(Rect2(18, 29, 8, 2), outline)

	# Separate steel toe caps.
	draw_rect(Rect2(9, 28, 6, 1), armor_mid)
	draw_rect(Rect2(19, 28, 6, 1), armor_mid)

	# Highlights on each boot.
	draw_rect(Rect2(9, 28, 3, 1), armor_light)
	draw_rect(Rect2(19, 28, 3, 1), armor_light)

	# --------------------------------------------------
	# ACTED-STATE DIMMING
	# --------------------------------------------------

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
