
class_name CombatFighterArt
extends Control

@export var team_color: Color = Color("#4682b4"):
	set(value):
		team_color = value
		queue_redraw()

@export var facing_left: bool = false:
	set(value):
		facing_left = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(72, 96)
	size = Vector2(72, 96)
	queue_redraw()


func _draw() -> void:
	var outline := Color("#292b35")
	var skin := Color("#d6a075")
	var skin_shadow := Color("#a66e4f")
	var skin_light := Color("#efc196")
	var hair := Color("#49352b")
	var leather := Color("#79563e")
	var leather_dark := Color("#453329")
	var leather_light := Color("#ad8055")
	var steel := Color("#b8c8d0")
	var steel_dark := Color("#617581")
	var steel_light := Color("#e5eff2")
	var gold := Color("#c4a263")
	var cloth_dark := team_color.darkened(0.38)
	var cloth_light := team_color.lightened(0.25)

	if facing_left:
		draw_set_transform(Vector2(72, 0), 0.0, Vector2(-1, 1))

	# Ground shadow.
	draw_rect(Rect2(10, 88, 53, 4), Color(0, 0, 0, 0.22))

	# Wide-set legs.
	draw_rect(Rect2(18, 60, 18, 24), outline)
	draw_rect(Rect2(20, 62, 14, 20), leather)
	draw_rect(Rect2(21, 64, 4, 15), leather_light)
	draw_rect(Rect2(31, 65, 3, 16), leather_dark)

	draw_rect(Rect2(38, 60, 17, 24), outline)
	draw_rect(Rect2(40, 62, 13, 20), leather)
	draw_rect(Rect2(41, 64, 4, 15), leather_light)
	draw_rect(Rect2(50, 65, 3, 16), leather_dark)

	# Heavy boots.
	draw_rect(Rect2(12, 79, 26, 9), outline)
	draw_rect(Rect2(15, 80, 21, 6), leather_dark)
	draw_rect(Rect2(16, 81, 15, 2), leather_light)

	draw_rect(Rect2(37, 79, 25, 9), outline)
	draw_rect(Rect2(39, 80, 21, 6), leather_dark)
	draw_rect(Rect2(40, 81, 14, 2), leather_light)

	# Split battle tunic.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(19, 48), Vector2(54, 48),
			Vector2(59, 70), Vector2(44, 73),
			Vector2(36, 65), Vector2(28, 73),
			Vector2(14, 69)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(21, 50), Vector2(52, 50),
			Vector2(56, 68), Vector2(45, 70),
			Vector2(36, 62), Vector2(27, 70),
			Vector2(17, 67)
		]),
		cloth_dark
	)

	draw_rect(Rect2(19, 53, 8, 13), team_color)
	draw_rect(Rect2(44, 53, 8, 14), team_color)

	# Broad torso silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 29), Vector2(49, 29),
			Vector2(57, 36), Vector2(53, 61),
			Vector2(17, 61), Vector2(14, 36)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 32), Vector2(48, 32),
			Vector2(54, 38), Vector2(50, 58),
			Vector2(20, 58), Vector2(17, 38)
		]),
		team_color
	)

	# Angular torso shadows and highlights.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(41, 33), Vector2(48, 33),
			Vector2(53, 39), Vector2(49, 57),
			Vector2(37, 57), Vector2(42, 45)
		]),
		cloth_dark
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 34), Vector2(34, 33),
			Vector2(30, 46), Vector2(20, 50),
			Vector2(18, 39)
		]),
		cloth_light
	)

	# Cross-body leather strap.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(43, 32), Vector2(49, 35),
			Vector2(28, 58), Vector2(22, 55)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(44, 34), Vector2(47, 36),
			Vector2(27, 56), Vector2(24, 54)
		]),
		leather
	)

	# Wide belt.
	draw_rect(Rect2(18, 53, 35, 7), outline)
	draw_rect(Rect2(20, 54, 31, 5), leather_dark)
	draw_rect(Rect2(31, 53, 10, 8), gold)
	draw_rect(Rect2(34, 55, 4, 4), outline)

	# Thick rear arm.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(48, 34), Vector2(59, 36),
			Vector2(65, 53), Vector2(59, 62),
			Vector2(49, 57), Vector2(44, 44)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(50, 37), Vector2(57, 39),
			Vector2(62, 53), Vector2(58, 59),
			Vector2(51, 55), Vector2(47, 44)
		]),
		skin
	)

	draw_rect(Rect2(57, 48, 5, 9), skin_shadow)

	# Left arm and leather bracer.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(19, 34), Vector2(12, 37),
			Vector2(8, 52), Vector2(15, 62),
			Vector2(24, 57), Vector2(27, 42)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(18, 37), Vector2(14, 39),
			Vector2(11, 51), Vector2(16, 59),
			Vector2(22, 55), Vector2(24, 42)
		]),
		skin
	)

	draw_rect(Rect2(10, 49, 12, 9), leather_dark)
	draw_rect(Rect2(12, 50, 8, 6), leather)
	draw_rect(Rect2(12, 51, 3, 4), leather_light)

	# Reinforced shoulder pads.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 28), Vector2(10, 32),
			Vector2(7, 42), Vector2(21, 45),
			Vector2(29, 34)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 31), Vector2(12, 34),
			Vector2(10, 40), Vector2(21, 42),
			Vector2(26, 34)
		]),
		steel_dark
	)

	draw_line(Vector2(13, 35), Vector2(21, 32), steel_light, 2.0)
	draw_rect(Rect2(15, 39, 8, 2), steel)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(47, 29), Vector2(57, 32),
			Vector2(63, 42), Vector2(50, 46),
			Vector2(42, 35)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(47, 32), Vector2(55, 34),
			Vector2(59, 41), Vector2(51, 43),
			Vector2(45, 35)
		]),
		steel_dark
	)

	draw_line(Vector2(47, 33), Vector2(55, 36), steel_light, 2.0)

	# Neck.
	draw_rect(Rect2(29, 26, 14, 9), outline)
	draw_rect(Rect2(31, 27, 10, 7), skin_shadow)

	# Larger, square-jawed head.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 12), Vector2(43, 11),
			Vector2(49, 18), Vector2(47, 28),
			Vector2(41, 34), Vector2(29, 34),
			Vector2(23, 27)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 15), Vector2(42, 14),
			Vector2(46, 19), Vector2(45, 27),
			Vector2(40, 31), Vector2(30, 31),
			Vector2(25, 26)
		]),
		skin
	)

	# Face shadows.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(39, 15), Vector2(45, 19),
			Vector2(44, 27), Vector2(40, 30),
			Vector2(36, 29), Vector2(40, 23)
		]),
		skin_shadow
	)

	draw_rect(Rect2(27, 18, 7, 4), skin_light)

	# Strong brow, eyes, and beard.
	draw_rect(Rect2(28, 21, 7, 2), outline)
	draw_rect(Rect2(40, 21, 4, 2), outline)
	draw_rect(Rect2(29, 27, 13, 5), hair)
	draw_rect(Rect2(32, 26, 7, 2), skin_shadow)
	draw_rect(Rect2(34, 29, 6, 1), outline)

	# Short, rough hair.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 18), Vector2(21, 11),
			Vector2(27, 7), Vector2(34, 9),
			Vector2(39, 6), Vector2(46, 10),
			Vector2(49, 17), Vector2(44, 19),
			Vector2(40, 14), Vector2(30, 16),
			Vector2(25, 21)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 15), Vector2(27, 10),
			Vector2(34, 12), Vector2(39, 9),
			Vector2(44, 12), Vector2(46, 16),
			Vector2(42, 17), Vector2(39, 12),
			Vector2(29, 14), Vector2(25, 18)
		]),
		hair
	)

	draw_line(Vector2(28, 11), Vector2(34, 12), leather_light, 2.0)

	# Axe handle: held upright beside the body.
	draw_rect(Rect2(58, 12, 7, 61), outline)
	draw_rect(Rect2(60, 14, 3, 57), leather)
	draw_rect(Rect2(60, 16, 1, 52), leather_light)
	draw_rect(Rect2(59, 35, 5, 3), leather_dark)
	draw_rect(Rect2(59, 45, 5, 3), leather_dark)

	# Broad steel axe head — blade faces right.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(59, 11),
			Vector2(65, 11),
			Vector2(72, 7),
			Vector2(84, 10),
			Vector2(90, 19),
			Vector2(87, 30),
			Vector2(75, 33),
			Vector2(65, 27),
			Vector2(59, 27)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(65, 13),
			Vector2(73, 10),
			Vector2(82, 12),
			Vector2(87, 19),
			Vector2(84, 28),
			Vector2(75, 30),
			Vector2(65, 25)
		]),
		steel
	)

	# Hard-edged axe shading.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(65, 14),
			Vector2(75, 11),
			Vector2(72, 20),
			Vector2(75, 29),
			Vector2(65, 25)
		]),
		steel_dark
	)

	# Bright cutting edge.
	draw_line(Vector2(83, 13), Vector2(88, 19), steel_light, 2.0)
	draw_line(Vector2(88, 20), Vector2(85, 27), steel_light, 2.0)

	# Axe socket.
	draw_rect(Rect2(57, 13, 9, 15), outline)
	draw_rect(Rect2(59, 15, 5, 11), steel_dark)
	draw_rect(Rect2(59, 15, 2, 9), steel_light)

	# Hand gripping axe shaft.
	draw_rect(Rect2(54, 53, 13, 11), outline)
	draw_rect(Rect2(56, 54, 9, 8), skin)
	draw_rect(Rect2(62, 57, 3, 5), skin_shadow)

	# Reset drawing transform.
	draw_set_transform(Vector2.ZERO)
