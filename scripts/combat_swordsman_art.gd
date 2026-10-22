class_name CombatSwordsmanArt
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
	var leather := Color("#665044")
	var leather_light := Color("#9b7860")
	var leather_dark := Color("#382e30")
	var skin := Color("#d9a578")
	var skin_shadow := Color("#a97050")
	var skin_light := Color("#edbd91")
	var hair := Color("#49372f")
	var steel := Color("#c5d5df")
	var steel_dark := Color("#657b8b")
	var steel_light := Color("#edf5f8")
	var gold := Color("#b69a57")
	var cloth_dark := team_color.darkened(0.4)
	var cloth_light := team_color.lightened(0.3)

	# Draw using a consistent character coordinate system.
	# Mirroring makes the player face left.
	if facing_left:
		draw_set_transform(Vector2(72, 0), 0.0, Vector2(-1, 1))

	# Ground shadow.
	draw_rect(Rect2(12, 88, 49, 4), Color(0, 0, 0, 0.22))

	# Rear leg.
	draw_rect(Rect2(36, 61, 15, 23), outline)
	draw_rect(Rect2(38, 63, 11, 18), leather)
	draw_rect(Rect2(38, 64, 3, 14), leather_light)
	draw_rect(Rect2(46, 65, 3, 15), leather_dark)

	# Rear boot.
	draw_rect(Rect2(34, 78, 19, 9), outline)
	draw_rect(Rect2(37, 79, 14, 6), leather)
	draw_rect(Rect2(38, 80, 9, 2), leather_light)

	# Front leg.
	draw_rect(Rect2(19, 61, 16, 24), outline)
	draw_rect(Rect2(21, 63, 12, 19), leather)
	draw_rect(Rect2(22, 64, 4, 15), leather_light)
	draw_rect(Rect2(30, 66, 3, 14), leather_dark)

	# Front boot.
	draw_rect(Rect2(14, 79, 23, 9), outline)
	draw_rect(Rect2(17, 80, 18, 6), leather)
	draw_rect(Rect2(18, 81, 12, 2), leather_light)

	# Flowing rear tunic.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 47),
			Vector2(49, 46),
			Vector2(54, 68),
			Vector2(42, 73),
			Vector2(36, 65),
			Vector2(19, 70)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 49),
			Vector2(47, 48),
			Vector2(51, 66),
			Vector2(42, 70),
			Vector2(35, 62),
			Vector2(22, 67)
		]),
		cloth_dark
	)

	draw_rect(Rect2(23, 53, 6, 13), team_color)

	# Torso silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 29),
			Vector2(45, 29),
			Vector2(52, 36),
			Vector2(48, 61),
			Vector2(21, 61),
			Vector2(18, 37)
		]),
		outline
	)

	# Main tunic.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 32),
			Vector2(44, 32),
			Vector2(49, 38),
			Vector2(46, 58),
			Vector2(23, 58),
			Vector2(21, 38)
		]),
		team_color
	)

	# Hard-edged cel shading.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(39, 33),
			Vector2(44, 33),
			Vector2(48, 39),
			Vector2(45, 57),
			Vector2(36, 57),
			Vector2(40, 44)
		]),
		cloth_dark
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 34),
			Vector2(34, 33),
			Vector2(31, 48),
			Vector2(23, 51),
			Vector2(22, 39)
		]),
		cloth_light
	)

	# Leather belt and metal buckle.
	draw_rect(Rect2(22, 52, 26, 6), outline)
	draw_rect(Rect2(24, 53, 22, 4), leather)
	draw_rect(Rect2(32, 52, 8, 7), gold)
	draw_rect(Rect2(34, 54, 4, 3), outline)

	# Rear arm.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(45, 34),
			Vector2(53, 35),
			Vector2(58, 50),
			Vector2(53, 57),
			Vector2(46, 52),
			Vector2(43, 39)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(47, 37),
			Vector2(52, 38),
			Vector2(55, 49),
			Vector2(52, 53),
			Vector2(48, 50)
		]),
		cloth_dark
	)

	# Rear hand.
	draw_rect(Rect2(49, 52, 8, 8), outline)
	draw_rect(Rect2(50, 53, 6, 6), skin_shadow)
	draw_rect(Rect2(50, 53, 3, 4), skin)

	# Front arm.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 34),
			Vector2(27, 35),
			Vector2(23, 50),
			Vector2(28, 55),
			Vector2(23, 60),
			Vector2(16, 54),
			Vector2(14, 45)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 38),
			Vector2(25, 38),
			Vector2(21, 49),
			Vector2(25, 55),
			Vector2(21, 57),
			Vector2(17, 52),
			Vector2(16, 45)
		]),
		team_color
	)

	draw_rect(Rect2(17, 42, 3, 9), cloth_light)

	# Front hand.
	draw_rect(Rect2(19, 55, 10, 8), outline)
	draw_rect(Rect2(21, 56, 7, 6), skin)
	draw_rect(Rect2(25, 58, 3, 4), skin_shadow)

	# Shoulder armour.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 29),
			Vector2(12, 33),
			Vector2(10, 41),
			Vector2(22, 44),
			Vector2(29, 34)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 31),
			Vector2(14, 34),
			Vector2(13, 39),
			Vector2(22, 41),
			Vector2(27, 34)
		]),
		steel
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 35),
			Vector2(27, 34),
			Vector2(22, 41),
			Vector2(17, 40)
		]),
		steel_dark
	)

	draw_line(Vector2(15, 35), Vector2(21, 32), steel_light, 2.0)

	# Rear shoulder plate.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(44, 30),
			Vector2(51, 31),
			Vector2(57, 39),
			Vector2(47, 43),
			Vector2(40, 35)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(45, 32),
			Vector2(50, 33),
			Vector2(54, 38),
			Vector2(47, 40),
			Vector2(43, 35)
		]),
		steel_dark
	)

	draw_rect(Rect2(45, 33, 5, 2), steel_light)

	# Neck.
	draw_rect(Rect2(29, 27, 13, 8), outline)
	draw_rect(Rect2(31, 28, 9, 6), skin_shadow)

	# Head and jaw silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 12),
			Vector2(43, 11),
			Vector2(48, 18),
			Vector2(46, 28),
			Vector2(40, 34),
			Vector2(29, 33),
			Vector2(24, 26)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 15),
			Vector2(42, 14),
			Vector2(45, 19),
			Vector2(44, 27),
			Vector2(39, 31),
			Vector2(30, 30),
			Vector2(26, 25)
		]),
		skin
	)

	# Facial cel shading.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(39, 15),
			Vector2(44, 19),
			Vector2(43, 27),
			Vector2(39, 30),
			Vector2(36, 29),
			Vector2(40, 23)
		]),
		skin_shadow
	)

	draw_rect(Rect2(27, 17, 7, 5), skin_light)
	draw_rect(Rect2(30, 26, 6, 2), skin_light)

	# Eyes and brow.
	draw_rect(Rect2(29, 22, 5, 2), outline)
	draw_rect(Rect2(40, 21, 3, 2), outline)
	draw_rect(Rect2(30, 21, 5, 1), hair)

	# Nose and mouth.
	draw_rect(Rect2(37, 25, 3, 2), skin_shadow)
	draw_rect(Rect2(34, 29, 6, 1), skin_shadow)

	# Swept hairstyle silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 17),
			Vector2(20, 12),
			Vector2(25, 7),
			Vector2(36, 5),
			Vector2(44, 8),
			Vector2(49, 15),
			Vector2(45, 20),
			Vector2(40, 15),
			Vector2(32, 17),
			Vector2(27, 22)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 14),
			Vector2(27, 9),
			Vector2(36, 7),
			Vector2(43, 10),
			Vector2(46, 15),
			Vector2(42, 17),
			Vector2(38, 13),
			Vector2(29, 16),
			Vector2(26, 19)
		]),
		hair
	)

	# Hair highlights.
	draw_line(Vector2(28, 11), Vector2(37, 9), hair.lightened(0.3), 2.0)
	draw_line(Vector2(37, 9), Vector2(43, 13), hair.lightened(0.15), 2.0)

	# Sword blade, held upright beside the body.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(53, 49),
			Vector2(52, 15),
			Vector2(58, 4),
			Vector2(64, 15),
			Vector2(62, 49)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(55, 47),
			Vector2(54, 16),
			Vector2(58, 7),
			Vector2(61, 16),
			Vector2(60, 47)
		]),
		steel
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(59, 11),
			Vector2(61, 16),
			Vector2(60, 47),
			Vector2(58, 47)
		]),
		steel_dark
	)

	draw_line(Vector2(55, 16), Vector2(58, 8), steel_light, 2.0)
	draw_line(Vector2(55, 19), Vector2(55, 44), steel_light, 1.0)

	# Crossguard.
	draw_rect(Rect2(48, 47, 19, 6), outline)
	draw_rect(Rect2(50, 49, 15, 2), gold)

	# Grip.
	draw_rect(Rect2(55, 52, 7, 15), outline)
	draw_rect(Rect2(57, 53, 3, 12), leather)
	draw_rect(Rect2(57, 55, 3, 2), leather_light)
	draw_rect(Rect2(57, 60, 3, 2), leather_light)

	# Pommel.
	draw_rect(Rect2(53, 65, 11, 6), outline)
	draw_rect(Rect2(55, 66, 7, 3), steel_dark)
	draw_rect(Rect2(55, 66, 4, 1), steel_light)

	# Sword hand in front of the grip.
	draw_rect(Rect2(51, 53, 11, 9), outline)
	draw_rect(Rect2(53, 54, 8, 6), skin)
	draw_rect(Rect2(58, 57, 3, 3), skin_shadow)

	draw_set_transform(Vector2.ZERO)
