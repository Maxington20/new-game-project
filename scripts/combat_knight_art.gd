
class_name CombatKnightArt
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
	var outline := Color("#252c37")
	var steel_dark := Color("#536879")
	var steel_mid := Color("#8ca4b3")
	var steel_light := Color("#cbdce4")
	var steel_highlight := Color("#edf5f7")
	var leather := Color("#6a4b37")
	var leather_light := Color("#a17b54")
	var gold := Color("#c8a65e")
	var gold_shadow := Color("#84683e")
	var cloth_dark := team_color.darkened(0.42)
	var cloth_light := team_color.lightened(0.28)

	if facing_left:
		draw_set_transform(
			Vector2(72, 0),
			0.0,
			Vector2(-1, 1)
		)

	# Ground shadow.
	draw_rect(
		Rect2(9, 88, 54, 4),
		Color(0, 0, 0, 0.22)
	)

	# --------------------------------------------------
	# HEAVY LEGS AND GREAVES
	# --------------------------------------------------

	# Rear leg.
	draw_rect(Rect2(37, 59, 19, 26), outline)
	draw_rect(Rect2(39, 61, 15, 22), steel_dark)
	draw_rect(Rect2(40, 62, 8, 17), steel_mid)
	draw_rect(Rect2(41, 63, 3, 13), steel_light)

	# Rear knee plate.
	draw_rect(Rect2(36, 64, 21, 8), outline)
	draw_rect(Rect2(38, 65, 17, 5), steel_mid)
	draw_rect(Rect2(39, 65, 10, 2), steel_light)

	# Front leg.
	draw_rect(Rect2(17, 59, 20, 26), outline)
	draw_rect(Rect2(19, 61, 16, 22), steel_dark)
	draw_rect(Rect2(20, 62, 9, 17), steel_mid)
	draw_rect(Rect2(21, 63, 4, 13), steel_light)

	# Front knee plate.
	draw_rect(Rect2(16, 64, 22, 8), outline)
	draw_rect(Rect2(18, 65, 18, 5), steel_mid)
	draw_rect(Rect2(19, 65, 10, 2), steel_light)

	# Armoured boots.
	draw_rect(Rect2(11, 79, 28, 9), outline)
	draw_rect(Rect2(14, 80, 23, 6), steel_dark)
	draw_rect(Rect2(15, 80, 17, 3), steel_mid)
	draw_rect(Rect2(16, 81, 10, 1), steel_highlight)

	draw_rect(Rect2(35, 79, 29, 9), outline)
	draw_rect(Rect2(37, 80, 25, 6), steel_dark)
	draw_rect(Rect2(38, 80, 17, 3), steel_mid)
	draw_rect(Rect2(39, 81, 10, 1), steel_highlight)

	# --------------------------------------------------
	# ARMOURED WAIST AND TABARD
	# --------------------------------------------------

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20, 48),
			Vector2(51, 48),
			Vector2(57, 69),
			Vector2(45, 73),
			Vector2(36, 66),
			Vector2(26, 73),
			Vector2(14, 69)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 50),
			Vector2(49, 50),
			Vector2(54, 67),
			Vector2(45, 70),
			Vector2(36, 63),
			Vector2(26, 70),
			Vector2(17, 67)
		]),
		team_color
	)

	# Dark folds.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(40, 51),
			Vector2(49, 51),
			Vector2(53, 67),
			Vector2(45, 69),
			Vector2(37, 62)
		]),
		cloth_dark
	)

	draw_rect(Rect2(22, 54, 5, 12), cloth_light)

	# Central decorative tabard stripe.
	draw_rect(Rect2(32, 57, 8, 11), gold_shadow)
	draw_rect(Rect2(34, 57, 4, 10), gold)

	# --------------------------------------------------
	# BROAD ARMOURED TORSO
	# --------------------------------------------------

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(21, 28),
			Vector2(48, 28),
			Vector2(58, 37),
			Vector2(53, 59),
			Vector2(17, 59),
			Vector2(12, 37)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 31),
			Vector2(47, 31),
			Vector2(54, 38),
			Vector2(50, 56),
			Vector2(20, 56),
			Vector2(16, 38)
		]),
		steel_mid
	)

	# Main chest plate shadow.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(39, 32),
			Vector2(47, 32),
			Vector2(53, 39),
			Vector2(49, 55),
			Vector2(36, 55),
			Vector2(41, 44)
		]),
		steel_dark
	)

	# Chest plate highlight.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 33),
			Vector2(35, 32),
			Vector2(32, 46),
			Vector2(21, 50),
			Vector2(17, 39)
		]),
		steel_light
	)

	# Central chest ridge.
	draw_line(
		Vector2(35, 34),
		Vector2(35, 51),
		steel_highlight,
		2.0
	)

	# Team-coloured chest emblem.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(29, 37),
			Vector2(35, 34),
			Vector2(41, 37),
			Vector2(39, 44),
			Vector2(35, 48),
			Vector2(31, 44)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(31, 38),
			Vector2(35, 36),
			Vector2(39, 38),
			Vector2(37, 43),
			Vector2(35, 45),
			Vector2(33, 43)
		]),
		team_color
	)

	draw_rect(Rect2(34, 37, 2, 6), cloth_light)

	# Layered waist plates.
	draw_rect(Rect2(19, 51, 33, 9), outline)
	draw_rect(Rect2(21, 52, 29, 6), steel_dark)
	draw_rect(Rect2(23, 53, 25, 3), steel_mid)

	draw_rect(Rect2(31, 52, 9, 8), outline)
	draw_rect(Rect2(33, 53, 5, 5), gold)
	draw_rect(Rect2(34, 54, 3, 3), gold_shadow)

	# --------------------------------------------------
	# REAR ARM AND GAUNTLET
	# --------------------------------------------------

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(48, 35),
			Vector2(60, 37),
			Vector2(65, 52),
			Vector2(60, 63),
			Vector2(49, 58),
			Vector2(44, 44)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(50, 38),
			Vector2(57, 40),
			Vector2(62, 52),
			Vector2(58, 59),
			Vector2(51, 55),
			Vector2(47, 44)
		]),
		steel_dark
	)

	draw_rect(Rect2(55, 46, 6, 10), steel_mid)
	draw_rect(Rect2(55, 46, 2, 8), steel_light)

	# Rear gauntlet.
	draw_rect(Rect2(54, 54, 12, 11), outline)
	draw_rect(Rect2(56, 55, 8, 8), steel_mid)
	draw_rect(Rect2(57, 56, 3, 6), steel_light)

	# --------------------------------------------------
	# FRONT ARM AND GAUNTLET
	# --------------------------------------------------

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(18, 35),
			Vector2(10, 38),
			Vector2(6, 52),
			Vector2(12, 63),
			Vector2(23, 59),
			Vector2(27, 44)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(18, 38),
			Vector2(13, 40),
			Vector2(9, 52),
			Vector2(13, 60),
			Vector2(21, 56),
			Vector2(24, 44)
		]),
		steel_dark
	)

	draw_rect(Rect2(11, 46, 8, 10), steel_mid)
	draw_rect(Rect2(12, 47, 3, 8), steel_light)

	# Front gauntlet.
	draw_rect(Rect2(9, 55, 15, 11), outline)
	draw_rect(Rect2(11, 56, 11, 8), steel_mid)
	draw_rect(Rect2(12, 57, 5, 6), steel_light)

	# --------------------------------------------------
	# MASSIVE SHOULDER PLATES
	# --------------------------------------------------

	# Front pauldron.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(21, 27),
			Vector2(11, 29),
			Vector2(4, 37),
			Vector2(6, 46),
			Vector2(22, 48),
			Vector2(31, 34)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(21, 30),
			Vector2(12, 32),
			Vector2(7, 38),
			Vector2(9, 43),
			Vector2(21, 45),
			Vector2(28, 34)
		]),
		steel_mid
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(19, 31),
			Vector2(12, 33),
			Vector2(8, 38),
			Vector2(13, 39),
			Vector2(23, 35)
		]),
		steel_light
	)

	draw_line(
		Vector2(9, 42),
		Vector2(21, 44),
		steel_dark,
		2.0
	)

	draw_rect(Rect2(12, 40, 4, 2), gold)

	# Rear pauldron.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(46, 27),
			Vector2(57, 29),
			Vector2(66, 38),
			Vector2(63, 47),
			Vector2(49, 48),
			Vector2(40, 34)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(47, 30),
			Vector2(56, 32),
			Vector2(63, 39),
			Vector2(60, 44),
			Vector2(50, 45),
			Vector2(43, 34)
		]),
		steel_dark
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(47, 31),
			Vector2(55, 33),
			Vector2(60, 38),
			Vector2(53, 38)
		]),
		steel_light
	)

	draw_rect(Rect2(55, 41, 4, 2), gold)

	# --------------------------------------------------
	# NECK GUARD AND FULL HELMET
	# --------------------------------------------------

	# Armoured collar.
	draw_rect(Rect2(26, 25, 19, 12), outline)
	draw_rect(Rect2(28, 27, 15, 8), steel_dark)
	draw_rect(Rect2(29, 28, 7, 4), steel_light)

	# Helmet silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 12),
			Vector2(27, 6),
			Vector2(36, 3),
			Vector2(45, 7),
			Vector2(49, 14),
			Vector2(48, 27),
			Vector2(43, 33),
			Vector2(27, 33),
			Vector2(22, 27)
		]),
		outline
	)

	# Main helmet shell.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 13),
			Vector2(29, 9),
			Vector2(36, 6),
			Vector2(43, 9),
			Vector2(46, 15),
			Vector2(45, 26),
			Vector2(41, 30),
			Vector2(29, 30),
			Vector2(25, 26)
		]),
		steel_mid
	)

	# Helmet shadow.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(37, 7),
			Vector2(43, 10),
			Vector2(46, 15),
			Vector2(45, 26),
			Vector2(41, 30),
			Vector2(36, 29)
		]),
		steel_dark
	)

	# Helmet highlights.
	draw_line(
		Vector2(29, 11),
		Vector2(35, 8),
		steel_highlight,
		2.0
	)

	draw_rect(Rect2(27, 14, 4, 10), steel_light)

	# Helmet brow.
	draw_rect(Rect2(25, 17, 22, 5), outline)
	draw_rect(Rect2(27, 18, 18, 2), steel_light)

	# Dark horizontal visor.
	draw_rect(Rect2(27, 22, 18, 5), outline)
	draw_rect(Rect2(29, 23, 14, 2), Color("#192330"))

	# Narrow eye glint.
	draw_rect(Rect2(30, 23, 5, 1), steel_highlight)

	# Central nose guard.
	draw_rect(Rect2(34, 18, 5, 12), outline)
	draw_rect(Rect2(35, 19, 3, 10), steel_light)
	draw_rect(Rect2(37, 21, 1, 7), steel_dark)

	# Lower helmet cheek plates.
	draw_rect(Rect2(26, 27, 7, 6), outline)
	draw_rect(Rect2(27, 28, 5, 4), steel_dark)

	draw_rect(Rect2(40, 27, 7, 6), outline)
	draw_rect(Rect2(41, 28, 5, 4), steel_dark)

	# Helmet crest in team colour.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(32, 6),
			Vector2(31, 2),
			Vector2(35, 0),
			Vector2(41, 2),
			Vector2(44, 7),
			Vector2(38, 5)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(33, 5),
			Vector2(33, 2),
			Vector2(36, 1),
			Vector2(40, 3),
			Vector2(42, 6),
			Vector2(38, 4)
		]),
		team_color
	)

	# --------------------------------------------------
	# LONG STEEL LANCE
	# --------------------------------------------------

	# Lance shaft.
	draw_rect(Rect2(58, 14, 7, 59), outline)
	draw_rect(Rect2(60, 15, 3, 56), leather)
	draw_rect(Rect2(60, 17, 1, 50), leather_light)

	# Reinforced shaft bands.
	draw_rect(Rect2(59, 35, 5, 3), gold_shadow)
	draw_rect(Rect2(59, 46, 5, 3), gold_shadow)
	draw_rect(Rect2(59, 35, 3, 1), gold)
	draw_rect(Rect2(59, 46, 3, 1), gold)

	# Spearhead silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(57, 17),
			Vector2(55, 10),
			Vector2(61, 0),
			Vector2(67, 10),
			Vector2(65, 17)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(59, 15),
			Vector2(57, 10),
			Vector2(61, 3),
			Vector2(65, 10),
			Vector2(63, 15)
		]),
		steel_mid
	)

	# Blade facet.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(61, 3),
			Vector2(65, 10),
			Vector2(63, 15),
			Vector2(61, 15)
		]),
		steel_dark
	)

	draw_line(
		Vector2(60, 11),
		Vector2(61, 4),
		steel_highlight,
		1.0
	)

	# Spearhead socket.
	draw_rect(Rect2(57, 15, 9, 7), outline)
	draw_rect(Rect2(59, 16, 5, 5), steel_dark)
	draw_rect(Rect2(59, 16, 2, 4), steel_light)

	# Hand gripping lance.
	draw_rect(Rect2(54, 52, 13, 12), outline)
	draw_rect(Rect2(56, 54, 9, 8), steel_mid)
	draw_rect(Rect2(57, 55, 4, 6), steel_light)
	draw_rect(Rect2(62, 56, 2, 5), steel_dark)

	# Gauntlet knuckle details.
	draw_rect(Rect2(56, 53, 8, 2), steel_highlight)
	draw_rect(Rect2(57, 60, 7, 2), steel_dark)

	# Restore normal drawing transform.
	draw_set_transform(Vector2.ZERO)
