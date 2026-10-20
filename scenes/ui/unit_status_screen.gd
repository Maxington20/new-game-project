
class_name UnitStatusScreen
extends Control

signal closed

const PANEL_WIDTH: float = 520.0
const PANEL_HEIGHT: float = 620.0

const PLAYER_PORTRAIT_COLOR := Color("#42658b")
const ENEMY_PORTRAIT_COLOR := Color("#a3454c")

const PAGE_STATS: int = 0
const PAGE_EQUIPMENT: int = 1
const PAGE_PROFICIENCIES: int = 2
const PAGE_COUNT: int = 3

const WEAPON_TYPES: Array[WeaponResource.WeaponType] = [
	WeaponResource.WeaponType.SWORD,
	WeaponResource.WeaponType.LANCE,
	WeaponResource.WeaponType.AXE,
	WeaponResource.WeaponType.BOW,
	WeaponResource.WeaponType.ANIMA,
	WeaponResource.WeaponType.LIGHT,
	WeaponResource.WeaponType.DARK,
	WeaponResource.WeaponType.STAFF
]

var inspected_unit: Unit = null
var current_page: int = PAGE_STATS

var battlefield_grid: BattlefieldGrid = null

var background: ColorRect
var main_panel: PanelContainer
var portrait_style: StyleBoxFlat

var page_label: Label
var portrait_letter: Label
var name_label: Label
var class_label: Label
var hp_label: Label
var hp_bar: ProgressBar

var page_content: VBoxContainer
var previous_button: Button
var next_button: Button


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

	var panel_frame := Control.new()
	panel_frame.custom_minimum_size = Vector2(
		PANEL_WIDTH,
		PANEL_HEIGHT
	)
	panel_frame.size = Vector2(
		PANEL_WIDTH,
		PANEL_HEIGHT
	)
	center.add_child(panel_frame)

	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	main_panel.add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)
	panel_frame.add_child(main_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	main_panel.add_child(content)

	# Header
	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "UNIT STATUS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(title, 18)
	header.add_child(title)

	page_label = Label.new()
	GameUIStyle.style_label(page_label, 12, true)
	header.add_child(page_label)

	# Character summary
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 16)
	content.add_child(summary)

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(88, 94)

	portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = PLAYER_PORTRAIT_COLOR
	portrait_style.set_corner_radius_all(6)

	portrait.add_theme_stylebox_override(
		"panel",
		portrait_style
	)
	summary.add_child(portrait)

	portrait_letter = Label.new()
	portrait_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_letter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_letter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(portrait_letter, 36)
	portrait.add_child(portrait_letter)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 5)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(details)

	name_label = Label.new()
	GameUIStyle.style_label(name_label, 22)
	details.add_child(name_label)

	class_label = Label.new()
	GameUIStyle.style_label(class_label, 12, true)
	details.add_child(class_label)

	hp_label = Label.new()
	GameUIStyle.style_label(hp_label, 14)
	details.add_child(hp_label)

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
	hp_bar.add_theme_stylebox_override("background", hp_background)
	details.add_child(hp_bar)

	add_separator(content)

	# Fixed content area, no scrolling.
	page_content = VBoxContainer.new()
	page_content.custom_minimum_size.y = 345
	page_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_content.add_theme_constant_override("separation", 8)
	content.add_child(page_content)

	add_separator(content)

	# Navigation footer
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	content.add_child(navigation)

	previous_button = Button.new()
	previous_button.text = "← Previous"
	GameUIStyle.style_button(previous_button)
	previous_button.pressed.connect(previous_page)
	navigation.add_child(previous_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(spacer)

	next_button = Button.new()
	next_button.text = "Next →"
	GameUIStyle.style_button(next_button)
	next_button.pressed.connect(next_page)
	navigation.add_child(next_button)

	var close_button := Button.new()
	close_button.text = "Close"
	GameUIStyle.style_button(close_button)
	close_button.pressed.connect(close_screen)
	navigation.add_child(close_button)


func add_separator(parent: VBoxContainer) -> void:
	var separator := HSeparator.new()
	separator.add_theme_color_override(
		"separator",
		GameUIStyle.BORDER
	)
	parent.add_child(separator)


func add_text(
	parent: Node,
	value: String,
	font_size: int = 14,
	muted: bool = false
) -> Label:
	var label := Label.new()
	label.text = value
	GameUIStyle.style_label(label, font_size, muted)
	parent.add_child(label)
	return label


func add_stat(
	stat_grid: GridContainer,
	stat_name: String,
	stat_value: String
) -> void:
	var label := add_text(stat_grid, stat_name, 13, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value := add_text(stat_grid, stat_value, 14)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func create_stat_grid(parent: Node) -> GridContainer:
	var stat_grid := GridContainer.new()
	stat_grid.columns = 4
	stat_grid.add_theme_constant_override("h_separation", 24)
	stat_grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(stat_grid)
	return stat_grid


func clear_page() -> void:
	for child in page_content.get_children():
		page_content.remove_child(child)
		child.queue_free()


func show_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or unit.current_hp <= 0:
		return

	if unit.unit_data == null or unit.unit_data.unit_class == null:
		return

	inspected_unit = unit
	current_page = PAGE_STATS

	var data: UnitResource = unit.unit_data
	var unit_class: UnitClassResource = data.unit_class

	# Change portrait colour based on team.
	if unit.team == Unit.Team.ENEMY:
		portrait_style.bg_color = ENEMY_PORTRAIT_COLOR
	else:
		portrait_style.bg_color = PLAYER_PORTRAIT_COLOR

	portrait_letter.text = unit.get_class_letter()
	name_label.text = data.character_name

	class_label.text = (
		unit_class.class_name_display
		+ " · Lv " + str(data.level)
		+ " · EXP " + str(data.experience)
	)

	hp_label.text = (
		"HP " + str(unit.current_hp)
		+ " / " + str(unit.stats.max_hp)
	)

	hp_bar.max_value = unit.stats.max_hp
	hp_bar.value = unit.current_hp

	refresh_page()
	show()
	move_to_front()


func refresh_page() -> void:
	if not is_instance_valid(inspected_unit):
		return

	clear_page()

	page_label.text = (
		"Page " + str(current_page + 1)
		+ " / " + str(PAGE_COUNT)
	)

	previous_button.disabled = current_page == 0
	next_button.disabled = current_page == PAGE_COUNT - 1

	match current_page:
		PAGE_STATS:
			build_stats_page()
		PAGE_EQUIPMENT:
			build_equipment_page()
		PAGE_PROFICIENCIES:
			build_proficiencies_page()



func build_stats_page() -> void:
	var stats: UnitStatsResource = inspected_unit.unit_data.stats
	var unit_class: UnitClassResource = (
		inspected_unit.unit_data.unit_class
	)

	var stat_grid := create_stat_grid(page_content)

	add_stat(stat_grid, "STR", str(stats.strength))
	add_stat(stat_grid, "SKL", str(stats.skill))
	add_stat(stat_grid, "SPD", str(stats.speed))
	add_stat(stat_grid, "LCK", str(stats.luck))
	add_stat(stat_grid, "DEF", str(stats.defense))
	add_stat(stat_grid, "RES", str(stats.resistance))
	add_stat(stat_grid, "MOV", str(unit_class.movement_range))
	add_stat(stat_grid, "CON", str(unit_class.constitution))

	add_separator(page_content)

	var weapon: WeaponResource = inspected_unit.equipped_weapon

	if weapon == null:
		add_text(page_content, "Equipped: None")
	else:
		var attack: int = inspected_unit.stats.strength + weapon.might
		var attack_speed: int = (
			CombatCalculator.get_attack_speed(inspected_unit)
		)

		add_text(page_content, "Equipped: " + weapon.weapon_name)
		add_text(
			page_content,
			"ATK " + str(attack) + "  ·  AS " + str(attack_speed),
			13,
			true
		)

	add_separator(page_content)
	build_terrain_section()



func build_terrain_section() -> void:
	var terrain: TerrainResource = get_inspected_unit_terrain()

	add_text(page_content, "TERRAIN", 15)

	if terrain == null:
		add_text(
			page_content,
			"Plains  ·  DEF +0  ·  AVO +0",
			13
		)
		return

	var terrain_name: String = (
		TerrainResource.TerrainType.keys()[terrain.terrain_type]
	).capitalize()

	add_text(
		page_content,
		terrain_name
		+ "  ·  DEF +" + str(terrain.defense_bonus)
		+ "  ·  AVO +" + str(terrain.avoid_bonus),
		13
	)

	var effects: Array[String] = []

	if terrain.turn_start_heal_percent > 0.0:
		effects.append(
			"Heals %d%% HP each turn" %
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

	if not effects.is_empty():
		add_text(
			page_content,
			"  ·  ".join(effects),
			12,
			true
		)


func build_equipment_page() -> void:
	var weapon: WeaponResource = inspected_unit.equipped_weapon

	add_text(page_content, "EQUIPPED WEAPON", 15)

	if weapon == null:
		add_text(page_content, "No weapon equipped.", 14, true)
		return

	var weapon_type: String = get_weapon_type_name(
		weapon.weapon_type
	)

	var range_text: String = str(weapon.min_range)

	if weapon.min_range != weapon.max_range:
		range_text += "-" + str(weapon.max_range)

	add_text(page_content, weapon.weapon_name, 20)
	add_text(
		page_content,
		weapon_type + " · Range " + range_text,
		13,
		true
	)

	add_separator(page_content)

	var stat_grid := create_stat_grid(page_content)

	add_stat(stat_grid, "Might", str(weapon.might))
	add_stat(stat_grid, "Hit", str(weapon.hit))
	add_stat(stat_grid, "Critical", str(weapon.critical))
	add_stat(stat_grid, "Weight", str(weapon.weight))

	var unit_class: UnitClassResource = (
		inspected_unit.unit_data.unit_class
	)

	var attack: int = inspected_unit.stats.strength + weapon.might
	var attack_speed: int = (
		CombatCalculator.get_attack_speed(inspected_unit)
	)

	add_stat(stat_grid, "Attack", str(attack))
	add_stat(stat_grid, "Atk Speed", str(attack_speed))

	add_separator(page_content)

	add_text(
		page_content,
		get_weapon_triangle_description(weapon.weapon_type),
		12,
		true
	)


func build_proficiencies_page() -> void:
	add_text(page_content, "WEAPON PROFICIENCIES", 15)

	var proficiencies: WeaponProficiencyResource = (
		inspected_unit.unit_data.weapon_proficiencies
	)

	if proficiencies == null:
		add_text(
			page_content,
			"No weapon proficiency data assigned.",
			13,
			true
		)
	else:
		for weapon_type in WEAPON_TYPES:
			add_proficiency_row(proficiencies, weapon_type)

	add_separator(page_content)

	add_text(page_content, "SUPPORT RELATIONSHIPS", 15)
	add_text(
		page_content,
		"No support relationships available yet.",
		12,
		true
	)


func add_proficiency_row(
	proficiencies: WeaponProficiencyResource,
	weapon_type: WeaponResource.WeaponType
) -> void:
	var experience: int = proficiencies.get_experience(
		weapon_type
	)

	var rank: String = WeaponProficiencyCalculator.get_rank(
		experience
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	page_content.add_child(row)

	var weapon_name := add_text(
		row,
		get_weapon_type_name(weapon_type),
		12
	)
	weapon_name.custom_minimum_size.x = 65

	var rank_label := add_text(row, rank, 13)
	rank_label.custom_minimum_size.x = 22
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var progress := ProgressBar.new()
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.custom_minimum_size.y = 9
	progress.show_percentage = false
	progress.min_value = 0
	progress.max_value = 100

	var progress_background := StyleBoxFlat.new()
	progress_background.bg_color = GameUIStyle.BACKGROUND
	progress_background.set_corner_radius_all(4)

	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = GameUIStyle.HEALTH
	progress_fill.set_corner_radius_all(4)

	progress.add_theme_stylebox_override(
		"background",
		progress_background
	)
	progress.add_theme_stylebox_override(
		"fill",
		progress_fill
	)

	var current_threshold: int = get_current_rank_threshold(
		experience
	)

	var next_threshold: int = (
		WeaponProficiencyCalculator.get_next_rank_threshold(
			experience
		)
	)

	if experience <= 0:
		progress.value = 0
	elif rank == "S":
		progress.value = 100
	else:
		var required: int = next_threshold - current_threshold
		var gained: int = experience - current_threshold

		progress.value = (
			float(gained) / float(required)
		) * 100.0

	row.add_child(progress)


func get_current_rank_threshold(experience: int) -> int:
	if experience >= WeaponProficiencyCalculator.RANK_S:
		return WeaponProficiencyCalculator.RANK_S

	if experience >= WeaponProficiencyCalculator.RANK_A:
		return WeaponProficiencyCalculator.RANK_A

	if experience >= WeaponProficiencyCalculator.RANK_B:
		return WeaponProficiencyCalculator.RANK_B

	if experience >= WeaponProficiencyCalculator.RANK_C:
		return WeaponProficiencyCalculator.RANK_C

	if experience >= WeaponProficiencyCalculator.RANK_D:
		return WeaponProficiencyCalculator.RANK_D

	if experience >= WeaponProficiencyCalculator.RANK_E:
		return WeaponProficiencyCalculator.RANK_E

	return 0


func get_weapon_type_name(
	weapon_type: WeaponResource.WeaponType
) -> String:
	match weapon_type:
		WeaponResource.WeaponType.SWORD:
			return "Sword"
		WeaponResource.WeaponType.LANCE:
			return "Lance"
		WeaponResource.WeaponType.AXE:
			return "Axe"
		WeaponResource.WeaponType.BOW:
			return "Bow"
		WeaponResource.WeaponType.ANIMA:
			return "Anima"
		WeaponResource.WeaponType.LIGHT:
			return "Light"
		WeaponResource.WeaponType.DARK:
			return "Dark"
		WeaponResource.WeaponType.STAFF:
			return "Staff"

	return "Unknown"


func get_weapon_triangle_description(
	weapon_type: WeaponResource.WeaponType
) -> String:
	match weapon_type:
		WeaponResource.WeaponType.SWORD:
			return "Sword beats Axe, loses to Lance."
		WeaponResource.WeaponType.LANCE:
			return "Lance beats Sword, loses to Axe."
		WeaponResource.WeaponType.AXE:
			return "Axe beats Lance, loses to Sword."
		_:
			return "No physical weapon triangle advantage."


func previous_page() -> void:
	if current_page <= 0:
		return

	current_page -= 1
	refresh_page()


func next_page() -> void:
	if current_page >= PAGE_COUNT - 1:
		return

	current_page += 1
	refresh_page()


func close_screen() -> void:
	if not visible:
		return

	hide()
	inspected_unit = null
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return

	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_ESCAPE:
			close_screen()
			get_viewport().set_input_as_handled()

		KEY_LEFT:
			previous_page()
			get_viewport().set_input_as_handled()

		KEY_RIGHT:
			next_page()
			get_viewport().set_input_as_handled()
			
			

func get_inspected_unit_terrain() -> TerrainResource:
	if not is_instance_valid(inspected_unit):
		return null

	if battlefield_grid == null:
		return null

	return battlefield_grid.get_terrain_at(
		inspected_unit.grid_position
	)
