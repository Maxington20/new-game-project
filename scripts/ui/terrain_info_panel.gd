
class_name TerrainInfoPanel
extends PanelContainer

var title_label: Label
var movement_label: Label
var defense_label: Label
var avoid_label: Label
var effects_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(190, 0)

	add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	title_label = Label.new()
	GameUIStyle.style_label(title_label, 16)
	column.add_child(title_label)

	column.add_child(HSeparator.new())

	movement_label = _add_info_label(column)
	defense_label = _add_info_label(column)
	avoid_label = _add_info_label(column)

	column.add_child(HSeparator.new())

	effects_label = _add_info_label(column)
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	hide()


func _add_info_label(parent: VBoxContainer) -> Label:
	var label := Label.new()
	GameUIStyle.style_label(label, 13)
	parent.add_child(label)
	return label


func show_terrain(
	terrain: TerrainResource,
	is_blocked: bool = false
) -> void:
	if is_blocked:
		title_label.text = "WALL"
		movement_label.text = "Movement: Impassable"
		defense_label.text = "Defense: —"
		avoid_label.text = "Avoid: —"
		effects_label.text = "Blocks movement"

	elif terrain == null:
		title_label.text = "PLAINS"
		movement_label.text = "Movement: 1"
		defense_label.text = "Defense: +0"
		avoid_label.text = "Avoid: +0"
		effects_label.text = "No special effects"

	else:
		title_label.text = TerrainResource.TerrainType.keys()[
			terrain.terrain_type
		]

		movement_label.text = (
			"Movement: Impassable"
			if terrain.impassable
			else "Movement: " + str(terrain.movement_cost)
		)

		defense_label.text = "Defense: +" + str(terrain.defense_bonus)
		avoid_label.text = "Avoid: +" + str(terrain.avoid_bonus)

		var effects: Array[String] = []

		if terrain.turn_start_heal_percent > 0.0:
			effects.append(
				"Heals %d%% each turn" %
				roundi(terrain.turn_start_heal_percent * 100.0)
			)

		if terrain.damage_on_enter > 0:
			effects.append(
				"%d damage on entry" % terrain.damage_on_enter
			)

		if terrain.damage_on_turn_start > 0:
			effects.append(
				"%d damage each turn" % terrain.damage_on_turn_start
			)

		effects_label.text = (
			"\n".join(effects)
			if not effects.is_empty()
			else "No special effects"
		)

	show()
