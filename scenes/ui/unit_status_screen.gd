
class_name UnitStatusScreen
extends Control

signal closed

const PANEL_WIDTH: float = 460.0
const PANEL_HEIGHT: float = 430.0

var inspected_unit: Unit = null

var background: ColorRect
var main_panel: PanelContainer
var name_label: Label
var class_label: Label
var portrait_letter: Label
var hp_label: Label
var hp_bar: ProgressBar
var stats_grid: GridContainer
var weapon_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	build_interface()
	hide()


func build_interface() -> void:
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.65)
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(
		PANEL_WIDTH,
		PANEL_HEIGHT
	)
	main_panel.add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)
	center.add_child(main_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	main_panel.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "UNIT STATUS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(title, 18)
	header.add_child(title)

	var page_label := Label.new()
	page_label.text = "Page 1 / 3"
	GameUIStyle.style_label(page_label, 12, true)
	header.add_child(page_label)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 16)
	content.add_child(summary)

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(88, 94)

	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = GameUIStyle.PANEL_LIGHT
	portrait_style.set_corner_radius_all(6)

	portrait.add_theme_stylebox_override(
		"panel",
		portrait_style
	)
	summary.add_child(portrait)

	portrait_letter = Label.new()
	portrait_letter.text = "?"
	portrait_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_letter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_letter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(portrait_letter, 36)
	portrait.add_child(portrait_letter)

	var character_details := VBoxContainer.new()
	character_details.add_theme_constant_override(
		"separation",
		5
	)
	character_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(character_details)

	name_label = Label.new()
	GameUIStyle.style_label(name_label, 22)
	character_details.add_child(name_label)

	class_label = Label.new()
	GameUIStyle.style_label(class_label, 12, true)
	character_details.add_child(class_label)

	hp_label = Label.new()
	GameUIStyle.style_label(hp_label, 14)
	character_details.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 10)
	hp_bar.show_percentage = false

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = GameUIStyle.HEALTH
	hp_fill.set_corner_radius_all(4)

	var hp_background := StyleBoxFlat.new()
	hp_background.bg_color = GameUIStyle.BACKGROUND
	hp_background.set_corner_radius_all(4)

	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_bar.add_theme_stylebox_override(
		"background",
		hp_background
	)
	character_details.add_child(hp_bar)

	add_separator(content)

	stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 12)
	content.add_child(stats_grid)

	add_separator(content)

	weapon_label = Label.new()
	GameUIStyle.style_label(weapon_label, 13)
	content.add_child(weapon_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(footer)

	var close_button := Button.new()
	close_button.text = "Close"
	GameUIStyle.style_button(close_button)
	close_button.pressed.connect(close_screen)
	footer.add_child(close_button)


func add_separator(parent: VBoxContainer) -> void:
	var separator := HSeparator.new()
	separator.add_theme_color_override(
		"separator",
		GameUIStyle.BORDER
	)
	parent.add_child(separator)


func add_stat(stat_name: String, stat_value: int) -> void:
	var label := Label.new()
	label.text = stat_name
	GameUIStyle.style_label(label, 13, true)
	stats_grid.add_child(label)

	var value := Label.new()
	value.text = str(stat_value)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(value, 14)
	stats_grid.add_child(value)


func show_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or unit.current_hp <= 0:
		return

	if unit.unit_data == null or unit.unit_data.unit_class == null:
		return

	inspected_unit = unit

	var data: UnitResource = unit.unit_data
	var unit_class: UnitClassResource = data.unit_class

	portrait_letter.text = unit.get_class_letter()
	name_label.text = data.character_name

	class_label.text = (
		unit_class.class_name_display
		+ " · Lv " + str(data.level)
		+ " · EXP " + str(data.experience)
	)

	hp_label.text = (
		"HP " + str(unit.current_hp)
		+ " / " + str(unit_class.max_hp)
	)

	hp_bar.max_value = unit_class.max_hp
	hp_bar.value = unit.current_hp

	# Remove old stat rows immediately before rebuilding.
	for child in stats_grid.get_children():
		stats_grid.remove_child(child)
		child.queue_free()

	add_stat("STR", unit_class.strength)
	add_stat("SKL", unit_class.skill)
	add_stat("SPD", unit_class.speed)
	add_stat("LCK", unit_class.luck)
	add_stat("DEF", unit_class.defense)
	add_stat("RES", unit_class.resistance)
	add_stat("MOV", unit_class.movement_range)
	add_stat("CON", unit_class.constitution)

	if unit.equipped_weapon != null:
		weapon_label.text = (
            "Equipped: "
			+ unit.equipped_weapon.weapon_name
			+ "  |  ATK "
			+ str(
				unit_class.strength
				+ unit.equipped_weapon.might
			)
			+ "  |  AS "
			+ str(CombatCalculator.get_attack_speed(unit))
		)
	else:
		weapon_label.text = "Equipped: None"

	show()
	move_to_front()


func close_screen() -> void:
	if not visible:
		return

	hide()
	inspected_unit = null
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				close_screen()
				get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			close_screen()
			accept_event()
