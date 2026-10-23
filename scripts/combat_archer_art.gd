
class_name CombatArcherArt
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
	var skin := Color("#d9a578")
	var skin_shadow := Color("#a97050")
	var skin_light := Color("#edbd91")
	var hair := Color("#63452f")
	var leather := Color("#79583d")
	var leather_dark := Color("#443328")
	var leather_light := Color("#b18a5e")
	var hood := Color("#52744d")
	var hood_dark := Color("#354d38")
	var hood_light := Color("#79986a")
	var steel_dark := Color("#687e8b")
	var steel_light := Color("#e6f1f4")
	var gold := Color("#c3a15e")
	var cloth_dark := team_color.darkened(0.4)
	var cloth_light := team_color.lightened(0.28)
	var bow_wood := Color("#a97945")
	var bow_dark := Color("#513a2b")
	var bow_light := Color("#d5a76c")

	if facing_left:
		draw_set_transform(Vector2(72, 0), 0.0, Vector2(-1, 1))

	# Ground shadow.
	draw_rect(Rect2(11, 88, 50, 4), Color(0, 0, 0, 0.22))

	# --------------------------------------------------
	# QUIVER AND ARROWS (BEHIND THE BODY)
	# --------------------------------------------------

	# Arrow shafts extending above the shoulder.
	for i in range(4):
		var arrow_x := 46.0 + float(i) * 3.0
		var arrow_top := 13.0 + float(i % 2) * 3.0

		draw_line(
			Vector2(arrow_x, arrow_top),
			Vector2(arrow_x + 4, 42),
			leather_light,
			2.0
		)

		# Feathered fletching.
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(arrow_x - 2, arrow_top + 2),
				Vector2(arrow_x, arrow_top - 3),
				Vector2(arrow_x + 2, arrow_top + 2),
				Vector2(arrow_x + 1, arrow_top + 7)
			]),
			steel_light
		)

		draw_line(
			Vector2(arrow_x, arrow_top),
			Vector2(arrow_x + 1, arrow_top + 5),
			steel_dark,
			1.0
		)

	# Leather quiver.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(45, 33),
			Vector2(57, 34),
			Vector2(61, 57),
			Vector2(51, 64),
			Vector2(43, 55)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(47, 36),
			Vector2(55, 36),
			Vector2(58, 55),
			Vector2(51, 61),
			Vector2(46, 54)
		]),
		leather
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(53, 37),
			Vector2(56, 38),
			Vector2(58, 55),
			Vector2(52, 59)
		]),
		leather_dark
	)

	draw_line(Vector2(47, 39), Vector2(55, 40), leather_light, 2.0)
	draw_rect(Rect2(49, 53, 7, 3), gold)

	# --------------------------------------------------
	# LEGS AND BOOTS
	# --------------------------------------------------

	# Rear leg.
	draw_rect(Rect2(36, 60, 16, 25), outline)
	draw_rect(Rect2(38, 62, 12, 20), leather)
	draw_rect(Rect2(39, 63, 4, 16), leather_light)
	draw_rect(Rect2(47, 65, 3, 15), leather_dark)

	# Front leg.
	draw_rect(Rect2(20, 60, 16, 25), outline)
	draw_rect(Rect2(22, 62, 12, 20), leather)
	draw_rect(Rect2(23, 63, 4, 16), leather_light)
	draw_rect(Rect2(31, 65, 3, 15), leather_dark)

	# Knee guards.
	draw_rect(Rect2(20, 66, 16, 6), outline)
	draw_rect(Rect2(22, 67, 12, 3), leather_dark)

	draw_rect(Rect2(36, 66, 16, 6), outline)
	draw_rect(Rect2(38, 67, 12, 3), leather_dark)

	# Light leather boots.
	draw_rect(Rect2(15, 79, 23, 9), outline)
	draw_rect(Rect2(17, 80, 19, 6), leather_dark)
	draw_rect(Rect2(18, 81, 13, 2), leather_light)

	draw_rect(Rect2(35, 79, 25, 9), outline)
	draw_rect(Rect2(37, 80, 21, 6), leather_dark)
	draw_rect(Rect2(38, 81, 14, 2), leather_light)

	# --------------------------------------------------
	# SPLIT TUNIC
	# --------------------------------------------------

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 47),
			Vector2(47, 47),
			Vector2(52, 69),
			Vector2(42, 72),
			Vector2(35, 64),
			Vector2(27, 72),
			Vector2(17, 69)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 49),
			Vector2(45, 49),
			Vector2(49, 67),
			Vector2(42, 69),
			Vector2(35, 61),
			Vector2(27, 69),
			Vector2(20, 67)
		]),
		team_color
	)

	# Angular cloth shadows.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(39, 50),
			Vector2(45, 50),
			Vector2(49, 67),
			Vector2(42, 69),
			Vector2(35, 61)
		]),
		cloth_dark
	)

	draw_rect(Rect2(23, 53, 5, 12), cloth_light)

	# --------------------------------------------------
	# LIGHT LEATHER TORSO ARMOUR
	# --------------------------------------------------

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(25, 29),
			Vector2(44, 29),
			Vector2(51, 37),
			Vector2(47, 59),
			Vector2(21, 59),
			Vector2(18, 37)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 32),
			Vector2(43, 32),
			Vector2(48, 38),
			Vector2(45, 56),
			Vector2(23, 56),
			Vector2(21, 38)
		]),
		team_color
	)

	# Chest shading.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(38, 33),
			Vector2(43, 33),
			Vector2(47, 39),
			Vector2(44, 55),
			Vector2(35, 55),
			Vector2(40, 43)
		]),
		cloth_dark
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 34),
			Vector2(33, 33),
			Vector2(30, 46),
			Vector2(23, 49),
			Vector2(22, 39)
		]),
		cloth_light
	)

	# Reinforced leather chest panel.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(28, 35),
			Vector2(40, 35),
			Vector2(43, 48),
			Vector2(35, 53),
			Vector2(26, 48)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(29, 37),
			Vector2(39, 37),
			Vector2(41, 47),
			Vector2(35, 50),
			Vector2(28, 47)
		]),
		leather
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(35, 38),
			Vector2(39, 38),
			Vector2(40, 46),
			Vector2(35, 49)
		]),
		leather_dark
	)

	draw_line(Vector2(29, 39), Vector2(29, 45), leather_light, 2.0)

	# Diagonal quiver strap.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(41, 30),
			Vector2(46, 34),
			Vector2(27, 57),
			Vector2(23, 54)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(42, 32),
			Vector2(44, 34),
			Vector2(26, 55),
			Vector2(24, 53)
		]),
		leather_light
	)

	# Belt and buckle.
	draw_rect(Rect2(21, 52, 26, 6), outline)
	draw_rect(Rect2(23, 53, 22, 4), leather_dark)
	draw_rect(Rect2(31, 52, 8, 7), gold)
	draw_rect(Rect2(33, 54, 4, 3), outline)

	# --------------------------------------------------
	# ARMS AND LEATHER BRACERS
	# --------------------------------------------------

	# Rear arm.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(43, 34),
			Vector2(52, 36),
			Vector2(57, 50),
			Vector2(53, 59),
			Vector2(45, 54),
			Vector2(41, 42)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(45, 37),
			Vector2(50, 39),
			Vector2(54, 50),
			Vector2(51, 55),
			Vector2(46, 52),
			Vector2(43, 42)
		]),
		skin
	)

	draw_rect(Rect2(47, 47, 8, 9), leather_dark)
	draw_rect(Rect2(48, 48, 5, 6), leather)
	draw_rect(Rect2(48, 49, 2, 4), leather_light)

	# Front arm.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 34),
			Vector2(16, 36),
			Vector2(12, 49),
			Vector2(16, 59),
			Vector2(25, 57),
			Vector2(28, 43)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 37),
			Vector2(18, 39),
			Vector2(15, 49),
			Vector2(18, 56),
			Vector2(23, 54),
			Vector2(25, 43)
		]),
		skin
	)

	# Front bracer.
	draw_rect(Rect2(14, 47, 11, 10), leather_dark)
	draw_rect(Rect2(16, 48, 7, 7), leather)
	draw_rect(Rect2(16, 49, 3, 5), leather_light)

	# Small shoulder guards.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 29),
			Vector2(15, 32),
			Vector2(12, 40),
			Vector2(24, 43),
			Vector2(29, 34)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(23, 31),
			Vector2(17, 34),
			Vector2(15, 39),
			Vector2(23, 40),
			Vector2(27, 34)
		]),
		leather
	)

	draw_line(Vector2(17, 35), Vector2(23, 33), leather_light, 2.0)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(43, 30),
			Vector2(50, 32),
			Vector2(55, 40),
			Vector2(46, 43),
			Vector2(40, 35)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(44, 32),
			Vector2(49, 34),
			Vector2(52, 39),
			Vector2(46, 40),
			Vector2(42, 35)
		]),
		leather_dark
	)

	draw_rect(Rect2(45, 33, 4, 2), leather_light)

	# --------------------------------------------------
	# NECK AND FACE
	# --------------------------------------------------

	draw_rect(Rect2(29, 26, 13, 9), outline)
	draw_rect(Rect2(31, 27, 9, 7), skin_shadow)

	# Head silhouette.
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

	draw_rect(Rect2(27, 18, 7, 4), skin_light)

	# Eyes and brow.
	draw_rect(Rect2(29, 22, 5, 2), outline)
	draw_rect(Rect2(40, 21, 3, 2), outline)

	# Nose and mouth.
	draw_rect(Rect2(37, 25, 3, 2), skin_shadow)
	draw_rect(Rect2(34, 29, 6, 1), skin_shadow)

	# Hair visible beneath hood.
	draw_rect(Rect2(25, 17, 7, 5), hair)
	draw_rect(Rect2(27, 18, 4, 2), leather_light)

	# --------------------------------------------------
	# GREEN HOOD AND CLOAK COLLAR
	# --------------------------------------------------

	# Hood silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(22, 19),
			Vector2(20, 12),
			Vector2(25, 5),
			Vector2(35, 3),
			Vector2(45, 7),
			Vector2(50, 16),
			Vector2(46, 23),
			Vector2(43, 17),
			Vector2(36, 13),
			Vector2(28, 16),
			Vector2(25, 23)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24, 17),
			Vector2(23, 12),
			Vector2(27, 7),
			Vector2(35, 5),
			Vector2(44, 9),
			Vector2(47, 16),
			Vector2(45, 20),
			Vector2(42, 15),
			Vector2(36, 11),
			Vector2(28, 14),
			Vector2(26, 20)
		]),
		hood
	)

	# Hood shadow.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(36, 6),
			Vector2(44, 9),
			Vector2(47, 16),
			Vector2(45, 20),
			Vector2(42, 15),
			Vector2(36, 11)
		]),
		hood_dark
	)

	# Hood highlight.
	draw_line(Vector2(27, 10), Vector2(35, 7), hood_light, 2.0)
	draw_line(Vector2(25, 13), Vector2(25, 17), hood_light, 2.0)

	# --------------------------------------------------
	# CLOAK COLLAR — CORRECTED POLYGONS
	# --------------------------------------------------

	# Left collar panel.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 27),
			Vector2(35, 32),
			Vector2(35, 35),
			Vector2(27, 39),
			Vector2(20, 34)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(26, 29),
			Vector2(33, 33),
			Vector2(27, 36),
			Vector2(23, 34)
		]),
		hood
	)

	# Right collar panel.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(44, 27),
			Vector2(50, 34),
			Vector2(43, 39),
			Vector2(35, 35),
			Vector2(35, 32)
		]),
		outline
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(44, 29),
			Vector2(47, 34),
			Vector2(42, 36),
			Vector2(37, 33)
		]),
		hood
	)

	# Shadow on the right collar.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(44, 30),
			Vector2(47, 34),
			Vector2(42, 36),
			Vector2(39, 34)
		]),
		hood_dark
	)

	# --------------------------------------------------
	# WOODEN RECURVE BOW
	# --------------------------------------------------

	# Bow limbs and dark outer outline.
	draw_polyline(
		PackedVector2Array([
			Vector2(60, 9),
			Vector2(66, 15),
			Vector2(69, 28),
			Vector2(65, 43),
			Vector2(69, 58),
			Vector2(66, 74),
			Vector2(60, 82)
		]),
		outline,
		7.0
	)

	# Wooden limbs.
	draw_polyline(
		PackedVector2Array([
			Vector2(60, 9),
			Vector2(66, 15),
			Vector2(69, 28),
			Vector2(65, 43),
			Vector2(69, 58),
			Vector2(66, 74),
			Vector2(60, 82)
		]),
		bow_wood,
		4.0
	)

	# Wood highlights.
	draw_line(Vector2(61, 12), Vector2(65, 17), bow_light, 1.0)
	draw_line(Vector2(66, 19), Vector2(68, 28), bow_light, 1.0)
	draw_line(Vector2(68, 59), Vector2(66, 72), bow_light, 1.0)

	# Reinforced grip.
	draw_rect(Rect2(61, 37, 9, 13), outline)
	draw_rect(Rect2(63, 39, 5, 9), leather)
	draw_rect(Rect2(63, 40, 2, 7), leather_light)

	# Bowstring.
	draw_line(
		Vector2(60, 9),
		Vector2(56, 45),
		steel_light,
		1.0
	)

	draw_line(
		Vector2(56, 45),
		Vector2(60, 82),
		steel_light,
		1.0
	)

	# Hand gripping bow.
	draw_rect(Rect2(57, 43, 11, 10), outline)
	draw_rect(Rect2(59, 44, 8, 7), skin)
	draw_rect(Rect2(64, 47, 3, 4), skin_shadow)

	# Bow tip bindings.
	draw_rect(Rect2(58, 8, 5, 4), bow_dark)
	draw_rect(Rect2(58, 79, 5, 4), bow_dark)

	# Restore normal drawing transform.
	draw_set_transform(Vector2.ZERO)
