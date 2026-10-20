
extends Node2D

enum InteractionState {
	IDLE,
	UNIT_SELECTED,
	UNIT_MOVING,
	AWAITING_ACTION,
	CHOOSING_WEAPON,
	TARGETING,
	COMBAT_FORECAST,
	COMBAT_RESOLVING
}

const DEFAULT_ENCOUNTERS: EncounterCollection = preload(
	"res://resources/encounters/default_encounters.tres"
)

var grid: BattlefieldGrid = null
@onready var turn_system: BattleTurnSystem = $BattleTurnSystem
@onready var enemy_ai: EnemyAI = $EnemyAI

@onready var phase_label: Label = (
	$CanvasLayer/TurnUI/PhaseLabel
)

@onready var action_menu: UnitActionMenu = (
	$CanvasLayer/UnitActionMenu
)

@onready var combat_dialog: ConfirmationDialog = (
	$CanvasLayer/CombatForecastDialog
)

@onready var battle_overlay: BattleAnimationOverlay = (
	$CanvasLayer/BattleAnimationOverlay
)

@onready var unit_status_screen: UnitStatusScreen = (
	$CanvasLayer/UnitStatusScreen
)

signal encounter_victory

var terrain_effect_popup: TerrainEffectPopup
var victory_triggered: bool = false

signal encounter_defeat

var defeat_triggered: bool = false

var results_screen: RunResultsScreen = null

var interaction_state: InteractionState = InteractionState.IDLE
var selected_unit: Unit = null

var original_cell: Vector2i = Vector2i(-1, -1)
var movement_path: Array[Vector2i] = []
var current_paths: Dictionary = {}

var available_targets: Array[Unit] = []
var pending_target: Unit = null
var previous_weapon: WeaponResource = null
var weapon_choices: Array[WeaponResource] = []
var weapon_menu: PopupPanel
var weapon_menu_buttons: VBoxContainer
var forecast_overlay: Control
var forecast_attacker_fields: Dictionary = {}
var forecast_defender_fields: Dictionary = {}

var is_phase_transitioning: bool = false

var active_run: RunState = null


func _deploy_run_army() -> void:
	if active_run == null:
		return

	var spawn_positions: Array[Vector2i] = [
		Vector2i(3, 4),
		Vector2i(3, 6),
		Vector2i(2, 5),
		Vector2i(2, 7),
		Vector2i(4, 5),
		Vector2i(4, 7),
		Vector2i(1, 4),
		Vector2i(1, 6)
	]

	# Remove the scene's placeholder player units.
	for unit in get_all_units():
		if unit.team == Unit.Team.PLAYER:
			remove_child(unit)
			unit.queue_free()

	var deployable: Array[RunUnitState] = (
		BattlefieldDeployment.get_deployable_units(active_run)
	)

	for index in range(mini(deployable.size(), spawn_positions.size())):
		var unit: Unit = BattlefieldDeployment.create_unit(
			deployable[index],
			spawn_positions[index]
		)

		if unit == null:
			continue

		add_child(unit)

		print(
			"DEPLOYED: ",
			unit.unit_data.character_name,
			" | HP: ",
			unit.current_hp,
			"/",
			unit.unit_data.stats.max_hp
		)



func _ready() -> void:
	turn_system.phase_changed.connect(_on_phase_changed)

	action_menu.attack_selected.connect(_on_attack_selected)
	action_menu.wait_selected.connect(_on_wait_selected)
	action_menu.cancel_selected.connect(_on_cancel_selected)

	encounter_victory.connect(_on_encounter_victory)
	encounter_defeat.connect(_on_encounter_defeat)

	combat_dialog.hide()
	_build_forecast_overlay()

	weapon_menu = PopupPanel.new()
	weapon_menu.name = "WeaponSelectionMenu"
	weapon_menu.add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)
	$CanvasLayer.add_child(weapon_menu)

	weapon_menu.popup_hide.connect(_on_weapon_menu_hidden)
	weapon_menu.window_input.connect(_on_weapon_popup_input)

	weapon_menu_buttons = VBoxContainer.new()
	weapon_menu_buttons.add_theme_constant_override(
		"separation",
		10
	)
	weapon_menu.add_child(weapon_menu_buttons)

	terrain_effect_popup = TerrainEffectPopup.new()
	$CanvasLayer.add_child(terrain_effect_popup)

	active_run = RunManager.get_active_run()

	var encounter := _load_current_encounter()

	if encounter == null:
		return

	if not _load_encounter_map(encounter):
		return

	battle_overlay.battlefield_grid = grid

	grid.cell_selected.connect(_on_cell_selected)

	_deploy_run_army()

	if not _deploy_encounter_enemies(encounter):
		return

	# Connect terrain-entry events for both player and enemy units.
	for unit in get_all_units():
		unit.terrain_cell_entered.connect(
			_on_unit_terrain_cell_entered
		)

	turn_system.initialize(get_all_units())



func _build_forecast_overlay() -> void:
	forecast_overlay = Control.new()
	forecast_overlay.name = "StyledCombatForecast"
	forecast_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	forecast_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$CanvasLayer.add_child(forecast_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	forecast_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forecast_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 520
	panel.add_theme_stylebox_override("panel", GameUIStyle.make_panel_style())
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = "COMBAT FORECAST"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(heading, 18)
	header.add_child(heading)
	var preview := Label.new()
	preview.text = "Preview"
	GameUIStyle.style_label(preview, 12, true)
	header.add_child(preview)

	var sides := HBoxContainer.new()
	sides.add_theme_constant_override("separation", 10)
	column.add_child(sides)
	forecast_attacker_fields = _build_forecast_side(sides)
	forecast_defender_fields = _build_forecast_side(sides)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	column.add_child(footer)

	var confirm := Button.new()
	confirm.text = "Confirm Attack"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_button(confirm)
	confirm.pressed.connect(_on_combat_confirmed)
	footer.add_child(confirm)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_button(cancel)
	cancel.pressed.connect(_on_combat_cancelled)
	footer.add_child(cancel)

	forecast_overlay.hide()


func _build_forecast_side(parent: HBoxContainer) -> Dictionary:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = GameUIStyle.PANEL
	card_style.set_corner_radius_all(6)
	card_style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	card.add_child(content)

	var banner := PanelContainer.new()
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = GameUIStyle.PANEL_LIGHT
	banner_style.set_corner_radius_all(4)
	banner_style.set_content_margin_all(9)
	banner.add_theme_stylebox_override("panel", banner_style)
	content.add_child(banner)
	var name := Label.new()
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(name, 15)
	banner.add_child(name)

	var weapon := Label.new()
	weapon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(weapon, 12, true)
	content.add_child(weapon)

	var triangle := Label.new()
	triangle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(triangle, 11, true)
	content.add_child(triangle)

	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", GameUIStyle.BORDER)
	content.add_child(separator)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	content.add_child(stats)

	var fields := {
		"name": name,
		"weapon": weapon,
		"triangle": triangle,
		"banner_style": banner_style
	}
	for stat_name in ["HP", "Damage", "Hit", "Crit", "Atk Speed"]:
		fields[stat_name] = _add_forecast_stat(stats, stat_name)
	return fields


func _add_forecast_stat(parent: VBoxContainer, stat_name: String) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var caption := Label.new()
	caption.text = stat_name
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUIStyle.style_label(caption, 13, true)
	row.add_child(caption)
	var value := Label.new()
	value.custom_minimum_size.x = 48
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	GameUIStyle.style_label(value, 14)
	row.add_child(value)
	return value


func _update_forecast_side(fields: Dictionary, unit: Unit, opponent: Unit) -> void:
	fields["name"].text = unit.unit_data.character_name
	fields["weapon"].text = (
		unit.equipped_weapon.weapon_name if unit.equipped_weapon != null else "Unarmed"
	)
	fields["banner_style"].bg_color = (
		Color("#a3454c") if unit.team == Unit.Team.ENEMY
		else GameUIStyle.PANEL_LIGHT
	)
	fields["triangle"].text = get_triangle_label(unit, opponent).strip_edges()
	fields["HP"].text = str(unit.current_hp)

	if not CombatCalculator.can_attack(unit, opponent):
		for stat_name in ["Damage", "Hit", "Crit", "Atk Speed"]:
			fields[stat_name].text = "—"
		return

	var strikes: int = 2 if CombatCalculator.can_follow_up(unit, opponent) else 1

	var opponent_terrain := get_unit_terrain(opponent)

	var defense_bonus := 0
	var avoid_bonus := 0

	if opponent_terrain != null:
		defense_bonus = opponent_terrain.defense_bonus
		avoid_bonus = opponent_terrain.avoid_bonus

	fields["Damage"].text = (
		str(CombatCalculator.calculate_damage(
			unit,
			opponent,
			defense_bonus
		)) + " x" + str(strikes)
	)

	fields["Hit"].text = (
		str(CombatCalculator.get_displayed_hit(
			unit,
			opponent,
			avoid_bonus
		)) + "%"
	)

	fields["Crit"].text = str(CombatCalculator.get_displayed_critical(unit, opponent)) + "%"
	fields["Atk Speed"].text = str(CombatCalculator.get_attack_speed(unit))


func get_all_units() -> Array[Unit]:
	var units: Array[Unit] = []

	for child in get_children():
		if child is Unit:
			units.append(child)

	return units


func get_living_units(team: Unit.Team) -> Array[Unit]:
	var units: Array[Unit] = []

	for unit in get_all_units():
		if unit.team == team and unit.current_hp > 0:
			units.append(unit)

	return units


func _on_weapon_popup_input(event: InputEvent) -> void:
	# PopupPanel is a separate Window; battlefield._input() cannot see its clicks.
	if interaction_state != InteractionState.CHOOSING_WEAPON:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		weapon_menu.hide()
		_restore_previous_weapon()
		open_action_menu()


func _input(event: InputEvent) -> void:
	# UI controls can consume right-clicks before _unhandled_input().
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if unit_status_screen.visible:
		unit_status_screen.close_screen()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_RIGHT:
		return

	if unit_status_screen.visible:
		unit_status_screen.close_screen()
		get_viewport().set_input_as_handled()
		return

	if interaction_state == InteractionState.TARGETING:
		_restore_previous_weapon()
		open_action_menu()
		get_viewport().set_input_as_handled()
		return

	if is_phase_transitioning:
		return

	if turn_system.current_team != Unit.Team.PLAYER:
		return

	if interaction_state == InteractionState.UNIT_MOVING:
		return

	if interaction_state == InteractionState.COMBAT_FORECAST:
		return

	if interaction_state == InteractionState.CHOOSING_WEAPON:
		return

	if interaction_state == InteractionState.COMBAT_RESOLVING:
		return

	var mouse_position: Vector2 = (
		grid.get_global_mouse_position()
	)

	var local_position: Vector2 = (
		grid.to_local(mouse_position)
	)

	var cell_size: int = 32

	var cell := Vector2i(
		floori(local_position.x / cell_size),
		floori(local_position.y / cell_size)
	)

	var unit: Unit = get_unit_at(cell)

	if unit != null:
		unit_status_screen.show_unit(unit)
		get_viewport().set_input_as_handled()


func _on_cell_selected(cell: Vector2i) -> void:
	if unit_status_screen.visible:
		return

	if is_phase_transitioning:
		return

	if turn_system.current_team != Unit.Team.PLAYER:
		return

	match interaction_state:
		InteractionState.IDLE:
			var unit := get_unit_at(cell)

			if unit != null and turn_system.can_unit_act(unit):
				select_unit(unit)

		InteractionState.UNIT_SELECTED:
			handle_movement_selection(cell)

		InteractionState.TARGETING:
			handle_attack_target(cell)

		InteractionState.UNIT_MOVING, \
		InteractionState.AWAITING_ACTION, \
		InteractionState.CHOOSING_WEAPON, \
		InteractionState.COMBAT_FORECAST, \
		InteractionState.COMBAT_RESOLVING:
			return


func handle_movement_selection(cell: Vector2i) -> void:
	if selected_unit == null:
		return

	if cell == selected_unit.grid_position:
		open_action_menu()
		return

	var unit := get_unit_at(cell)

	if unit != null:
		if turn_system.can_unit_act(unit):
			select_unit(unit)
		return

	if cell in grid.highlighted_cells:
		move_selected_unit(cell)
	else:
		deselect_unit()


func get_unit_at(cell: Vector2i) -> Unit:
	for unit in get_all_units():
		if unit.current_hp > 0 and unit.grid_position == cell:
			return unit

	return null


func get_occupied_cells(excluded_unit: Unit) -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []

	for unit in get_all_units():
		if unit != excluded_unit and unit.current_hp > 0:
			occupied.append(unit.grid_position)

	return occupied



func get_friendly_cells(unit: Unit) -> Array[Vector2i]:
	var friendly: Array[Vector2i] = []

	for other in get_all_units():
		if other != unit and other.current_hp > 0:
			if other.team == unit.team:
				friendly.append(other.grid_position)

	return friendly



func get_attack_targets(unit: Unit) -> Array[Unit]:
	var targets: Array[Unit] = []

	for other_unit in get_all_units():
		if CombatCalculator.can_attack(unit, other_unit):
			targets.append(other_unit)

	return targets


func select_unit(unit: Unit) -> void:
	selected_unit = unit
	original_cell = unit.grid_position

	movement_path.clear()
	available_targets.clear()
	pending_target = null
	previous_weapon = null

	interaction_state = InteractionState.UNIT_SELECTED

	
	var occupied := get_occupied_cells(unit)
	var friendly := get_friendly_cells(unit)

	var result: Dictionary = grid.get_reachable_cells(
		unit.grid_position,
		unit.movement_range,
		occupied,
		friendly
	)


	current_paths = result["previous"]

	var movement_cells: Array[Vector2i] = []

	for cell in result["distances"].keys():
		movement_cells.append(cell)

	grid.selected_cell = unit.grid_position
	grid.highlighted_cells.clear()


	for cell in movement_cells:
		if cell != unit.grid_position and cell not in occupied:
			grid.highlighted_cells.append(cell)


	grid.attack_cells.clear()

	if unit.equipped_weapon != null:
		grid.attack_cells = grid.get_potential_attack_cells(
			movement_cells,
			unit.min_attack_range,
			unit.max_attack_range
		)

	grid.queue_redraw()


func deselect_unit() -> void:
	selected_unit = null
	pending_target = null
	previous_weapon = null
	weapon_choices.clear()

	movement_path.clear()
	current_paths.clear()
	available_targets.clear()

	original_cell = Vector2i(-1, -1)
	interaction_state = InteractionState.IDLE

	action_menu.close_menu()

	grid.selected_cell = Vector2i(-1, -1)
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	grid.queue_redraw()



func move_selected_unit(destination: Vector2i) -> void:
	movement_path = grid.reconstruct_path(
		selected_unit.grid_position,
		destination,
		current_paths
	)

	if movement_path.is_empty():
		return

	interaction_state = InteractionState.UNIT_MOVING

	grid.selected_cell = Vector2i(-1, -1)
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	grid.queue_redraw()

	var moving_unit: Unit = selected_unit
	
	moving_unit.took_terrain_damage = false

	moving_unit.move_along_path(movement_path)
	await moving_unit.movement_finished

	# Terrain damage may have defeated the unit during movement.
	if moving_unit.current_hp <= 0:
		deselect_unit()

		_check_encounter_defeat()

		if defeat_triggered:
			return

		if turn_system.are_all_units_done():
			turn_system.end_phase()

		return

	open_action_menu()


func _get_inventory_weapons(unit: Unit) -> Array[WeaponResource]:
	var result: Array[WeaponResource] = []
	if unit == null or unit.unit_data == null:
		return result

	for weapon in unit.unit_data.inventory:
		if weapon != null and weapon not in result:
			result.append(weapon)
	return result


func _weapon_has_target(unit: Unit, weapon: WeaponResource) -> bool:
	if unit == null or unit.unit_data == null:
		return false
	if not UnitInventory.can_equip(unit.unit_data, weapon):
		return false

	var original: WeaponResource = unit.equipped_weapon
	unit.equipped_weapon = weapon
	var has_target: bool = not get_attack_targets(unit).is_empty()
	unit.equipped_weapon = original
	return has_target


func _get_weapon_rank_label(rank: WeaponResource.WeaponRank) -> String:
	match rank:
		WeaponResource.WeaponRank.E: return "E"
		WeaponResource.WeaponRank.D: return "D"
		WeaponResource.WeaponRank.C: return "C"
		WeaponResource.WeaponRank.B: return "B"
		WeaponResource.WeaponRank.A: return "A"
		WeaponResource.WeaponRank.S: return "S"
	return "?"

func _restore_previous_weapon() -> void:
	if selected_unit != null and previous_weapon != null:
		selected_unit.equipped_weapon = previous_weapon
	previous_weapon = null


func open_action_menu() -> void:
	interaction_state = InteractionState.AWAITING_ACTION
	pending_target = null
	available_targets.clear()
	weapon_choices = _get_inventory_weapons(selected_unit)
	var can_attack_now: bool = false
	for weapon in weapon_choices:
		if _weapon_has_target(selected_unit, weapon):
			can_attack_now = true
			break

	grid.selected_cell = selected_unit.grid_position
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	grid.queue_redraw()

	var menu_position := (
		selected_unit.global_position + Vector2(40, 0)
	)

	action_menu.open_menu(
		menu_position,
		can_attack_now,
		not selected_unit.took_terrain_damage
	)


func _on_attack_selected() -> void:
	if interaction_state != InteractionState.AWAITING_ACTION:
		return
	if weapon_choices.is_empty():
		return

	previous_weapon = selected_unit.equipped_weapon
	interaction_state = InteractionState.CHOOSING_WEAPON
	action_menu.close_menu()

	for child in weapon_menu_buttons.get_children():
		weapon_menu_buttons.remove_child(child)
		child.queue_free()

	for index in range(weapon_choices.size()):
		var weapon: WeaponResource = weapon_choices[index]
		var button := Button.new()
		var rank_text: String = _get_weapon_rank_label(weapon.required_rank)
		var eligible: bool = UnitInventory.can_equip(selected_unit.unit_data, weapon)
		var in_range: bool = _weapon_has_target(selected_unit, weapon) if eligible else false
		button.text = weapon.weapon_name + "  [" + rank_text + "]"
		if not eligible:
			button.text += "  - Locked"
		elif not in_range:
			button.text += "  - Out of range"
		button.disabled = not eligible or not in_range
		button.custom_minimum_size = Vector2(180, 38)
		GameUIStyle.style_button(button)
		button.pressed.connect(_on_weapon_chosen.bind(index))
		weapon_menu_buttons.add_child(button)

	var popup_position := Vector2i(
		selected_unit.global_position + Vector2(40, 0)
	)
	var popup_height: int = 32 + weapon_choices.size() * 38 + maxi(0, weapon_choices.size() - 1) * 10
	weapon_menu.popup(Rect2i(popup_position, Vector2i(220, popup_height)))
	for child in weapon_menu_buttons.get_children():
		var button := child as Button
		if button != null and not button.disabled:
			button.grab_focus()
			break

func _on_weapon_chosen(index: int) -> void:
	if interaction_state != InteractionState.CHOOSING_WEAPON:
		return
	if index < 0 or index >= weapon_choices.size():
		return
	var chosen_weapon: WeaponResource = weapon_choices[index]
	if selected_unit == null or selected_unit.unit_data == null:
		return
	if not UnitInventory.can_equip(selected_unit.unit_data, chosen_weapon):
		return
	if not _weapon_has_target(selected_unit, chosen_weapon):
		return

	selected_unit.equipped_weapon = weapon_choices[index]
	weapon_menu.hide()
	available_targets = get_attack_targets(selected_unit)
	if available_targets.is_empty():
		_restore_previous_weapon()
		open_action_menu()
		return

	interaction_state = InteractionState.TARGETING
	grid.selected_cell = selected_unit.grid_position
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	for target in available_targets:
		grid.attack_cells.append(target.grid_position)
	grid.queue_redraw()


func _on_weapon_menu_hidden() -> void:
	# PopupMenu also emits popup_hide when an item is selected.
	# Defer the cancellation check until the item selection signal has
	# had a chance to transition us into TARGETING.
	_handle_weapon_menu_dismissed.call_deferred()


func _handle_weapon_menu_dismissed() -> void:
	if interaction_state != InteractionState.CHOOSING_WEAPON:
		return

	_restore_previous_weapon()
	open_action_menu()


func handle_attack_target(cell: Vector2i) -> void:
	var target := get_unit_at(cell)

	if target == null or target not in available_targets:
		return

	if not CombatCalculator.can_attack(selected_unit, target):
		return

	pending_target = target
	show_combat_forecast()


func get_triangle_label(attacker: Unit, defender: Unit) -> String:
	var advantage: int = (
		CombatCalculator.get_weapon_triangle_advantage(
			attacker,
			defender
		)
	)

	if advantage > 0:
		return " [Advantage +]"
	elif advantage < 0:
		return " [Disadvantage -]"

	return ""


func get_forecast_line(attacker: Unit, defender: Unit) -> String:
	if not CombatCalculator.can_attack(attacker, defender):
		return "Cannot attack"

	var damage: int = CombatCalculator.calculate_damage(
		attacker,
		defender
	)

	var hit: int = CombatCalculator.get_displayed_hit(
		attacker,
		defender
	)

	var critical: int = CombatCalculator.get_displayed_critical(
		attacker,
		defender
	)

	var strikes: int = 1

	if CombatCalculator.can_follow_up(attacker, defender):
		strikes = 2

	return (
		"Damage: " + str(damage)
		+ " x" + str(strikes)
		+ "\nHit: " + str(hit) + "%"
		+ "\nCrit: " + str(critical) + "%"
		+ "\nAttack Speed: "
		+ str(CombatCalculator.get_attack_speed(attacker))
	)


func show_combat_forecast() -> void:
	if selected_unit == null or pending_target == null:
		return

	interaction_state = InteractionState.COMBAT_FORECAST
	_update_forecast_side(forecast_attacker_fields, selected_unit, pending_target)
	_update_forecast_side(forecast_defender_fields, pending_target, selected_unit)
	forecast_overlay.show()


func _on_combat_confirmed() -> void:
	if interaction_state != InteractionState.COMBAT_FORECAST:
		return

	if selected_unit == null or pending_target == null:
		return

	var attacker: Unit = selected_unit
	var defender: Unit = pending_target

	if not UnitInventory.can_equip(attacker.unit_data, attacker.equipped_weapon) or not CombatCalculator.can_attack(attacker, defender):
		pending_target = null
		interaction_state = InteractionState.TARGETING
		return

	interaction_state = InteractionState.COMBAT_RESOLVING
	forecast_overlay.hide()

	grid.selected_cell = Vector2i(-1, -1)
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	grid.queue_redraw()

	await battle_overlay.play_battle(attacker, defender)

	if attacker.current_hp <= 0:
		attacker.hide()

	if defender.current_hp <= 0:
		defender.hide()

	previous_weapon = null

	_check_encounter_victory()

	if victory_triggered:
		deselect_unit()
		return
		
	_check_encounter_defeat()

	if defeat_triggered:
		deselect_unit()
		return

	complete_unit_action()


func _on_combat_cancelled() -> void:
	if interaction_state != InteractionState.COMBAT_FORECAST:
		return

	forecast_overlay.hide()
	pending_target = null
	interaction_state = InteractionState.TARGETING


func _on_wait_selected() -> void:
	if interaction_state != InteractionState.AWAITING_ACTION:
		return

	previous_weapon = null
	complete_unit_action()


func complete_unit_action() -> void:
	var unit: Unit = selected_unit

	if unit != null and unit.current_hp > 0:
		turn_system.mark_unit_acted(unit)

	deselect_unit()

	if turn_system.are_all_units_done():
		turn_system.end_phase()



func _on_cancel_selected() -> void:
	if interaction_state != InteractionState.AWAITING_ACTION:
		return

	if selected_unit == null:
		return

	# Movement cannot be undone after taking terrain damage.
	if selected_unit.took_terrain_damage:
		return

	action_menu.close_menu()

	if movement_path.is_empty():
		select_unit(selected_unit)
		return

	interaction_state = InteractionState.UNIT_MOVING

	var return_path: Array[Vector2i] = movement_path.duplicate()
	return_path.reverse()

	return_path.remove_at(0)
	return_path.append(original_cell)

	selected_unit.move_along_path(return_path)
	await selected_unit.movement_finished

	select_unit(selected_unit)


func _on_phase_changed(team: Unit.Team) -> void:
	is_phase_transitioning = true

	if team == Unit.Team.PLAYER:
		phase_label.text = "Player Phase"
	else:
		phase_label.text = "Enemy Phase"

	await apply_turn_start_terrain_effects(team)

	if team == Unit.Team.PLAYER:
		is_phase_transitioning = false
	else:
		run_enemy_phase()



func run_enemy_phase() -> void:
	await get_tree().create_timer(0.65).timeout

	var enemies: Array[Unit] = get_living_units(
		Unit.Team.ENEMY
	)

	for enemy in enemies:
		if enemy.current_hp <= 0:
			continue

		var players: Array[Unit] = get_living_units(
			Unit.Team.PLAYER
		)

		if players.is_empty():
			break

		var occupied: Array[Vector2i] = get_occupied_cells(enemy)
		var friendly: Array[Vector2i] = get_friendly_cells(enemy)

		var action: Dictionary = enemy_ai.choose_action(
			enemy,
			players,
			grid,
			occupied,
			friendly
		)

		if action.is_empty():
			turn_system.mark_unit_acted(enemy)
			continue

		var path: Array[Vector2i] = action["path"]
		var target: Unit = action["target"]

		if not path.is_empty():
			enemy.move_along_path(path)
			await enemy.movement_finished

		# Terrain damage may have defeated the enemy.
		# Do not allow a defeated enemy to attack.
		if enemy.current_hp <= 0:
			_check_encounter_victory()

			if victory_triggered:
				is_phase_transitioning = false
				return

			continue

		await get_tree().create_timer(0.25).timeout

		if (
			target != null
			and target.current_hp > 0
			and CombatCalculator.can_attack(enemy, target)
		):
			await battle_overlay.play_battle(
				enemy,
				target
			)

			if enemy.current_hp <= 0:
				enemy.hide()

			if target.current_hp <= 0:
				target.hide()

			_check_encounter_victory()

			if victory_triggered:
				is_phase_transitioning = false
				return

			_check_encounter_defeat()

			if defeat_triggered:
				is_phase_transitioning = false
				return

		if enemy.current_hp > 0:
			turn_system.mark_unit_acted(enemy)

		await get_tree().create_timer(0.35).timeout

	turn_system.end_phase()

	
func _check_encounter_victory() -> void:
	if victory_triggered:
		return

	if get_living_units(Unit.Team.ENEMY).is_empty():
		victory_triggered = true
		print("ENCOUNTER VICTORY")
		encounter_victory.emit()
		
		
func _on_encounter_victory() -> void:
	if active_run == null:
		print("VICTORY: Standalone battlefield")
		return

	print("ENCOUNTER COMPLETED: ", active_run.current_encounter)

	if active_run.current_encounter >= RunState.TOTAL_ENCOUNTERS:
		if active_run.complete_run():
			print("RUN COMPLETED")
			print("Run completion state: ", active_run.is_completed)
			_show_run_results()
		return

	if active_run.advance_encounter():
		print("ADVANCED TO ENCOUNTER: ", active_run.current_encounter)

		get_tree().reload_current_scene.call_deferred()
		
		
func _check_encounter_defeat() -> void:
	if defeat_triggered or victory_triggered:
		return

	if not get_living_units(Unit.Team.PLAYER).is_empty():
		return

	defeat_triggered = true
	print("ENCOUNTER DEFEAT")
	encounter_defeat.emit()
	
	
func _on_encounter_defeat() -> void:
	if active_run == null:
		print("DEFEAT: Standalone battlefield")
		return

	if active_run.defeat_run():
		print("RUN DEFEATED")
		print("Run defeat state: ", active_run.is_defeated)
		_show_run_results()
		
		
func _show_run_results() -> void:
	if active_run == null:
		return

	var summary: RunResultSummary = RunResultSummary.from_run(active_run)

	if summary == null:
		push_error("Cannot display results for an unfinished run")
		return

	if results_screen != null:
		return

	var scene: PackedScene = preload(
		"res://scenes/ui/run_results_screen.tscn"
	)

	results_screen = scene.instantiate() as RunResultsScreen

	if results_screen == null:
		push_error("Failed to instantiate run results screen")
		return

	$CanvasLayer.add_child(results_screen)
	results_screen.finished.connect(_on_finish_run_pressed)
	results_screen.show_results(summary)
	
	
func _on_finish_run_pressed() -> void:
	if active_run == null:
		return

	if not active_run.is_completed and not active_run.is_defeated:
		return

	RunManager.end_run()

	get_tree().change_scene_to_file.call_deferred(
		"res://scenes/ui/main_menu.tscn"
	)





func _deploy_encounter_enemies(encounter: EncounterResource) -> bool:
	if encounter == null or not encounter.is_valid():
		push_error("Cannot deploy enemies from an invalid encounter")
		return false

	var enemies := EnemyDeployment.create_encounter_units(encounter)

	for enemy in enemies:
		add_child(enemy)

	print("DEPLOYED ENCOUNTER ENEMIES: ", enemies.size())

	return true

	

func _load_current_encounter() -> EncounterResource:
	var encounter_number: int = 1

	if active_run != null:
		encounter_number = active_run.current_encounter

	var encounter := DEFAULT_ENCOUNTERS.get_encounter(encounter_number)

	if encounter == null:
		push_error(
			"Encounter not found in collection: "
			+ str(encounter_number)
		)
		return null

	if not encounter.is_valid():
		push_error(
			"Invalid encounter configuration: "
			+ str(encounter_number)
		)
		return null

	if encounter.encounter_number != encounter_number:
		push_error(
			"Encounter number mismatch: "
			+ str(encounter_number)
		)
		return null

	print("LOADED ENCOUNTER: ", encounter_number)

	return encounter




func _load_encounter_map(encounter: EncounterResource) -> bool:
	if encounter == null or encounter.battlefield_scene == null:
		push_error("Encounter has no battlefield map")
		return false

	var map_instance := encounter.battlefield_scene.instantiate()

	if not map_instance is BattlefieldGrid:
		push_error("Battlefield map must have a BattlefieldGrid root")
		map_instance.free()
		return false

	# Remove a previously loaded map, if one exists.
	if is_instance_valid(grid):
		remove_child(grid)
		grid.queue_free()

	map_instance.name = "Grid"
	add_child(map_instance)
	move_child(map_instance, 0)

	grid = map_instance as BattlefieldGrid

	print("LOADED BATTLEFIELD MAP: ", encounter.encounter_number)

	return true



func get_unit_terrain(unit: Unit) -> TerrainResource:
	if unit == null or grid == null:
		return null

	return grid.get_terrain_at(unit.grid_position)
	



func apply_turn_start_terrain_effects(team: Unit.Team) -> void:
	for unit in get_living_units(team):
		var terrain: TerrainResource = get_unit_terrain(unit)

		if terrain == null:
			continue

		var healing: int = TerrainEffectCalculator.calculate_turn_start_healing(
			unit.current_hp,
			unit.stats.max_hp,
			terrain
		)

		if healing <= 0:
			continue

		var previous_hp: int = unit.current_hp
		unit.current_hp += healing

		print(
			"TERRAIN HEAL: ",
			unit.unit_data.character_name,
			" +", healing,
			" HP (", unit.current_hp,
			"/", unit.stats.max_hp, ")"
		)

		await terrain_effect_popup.show_healing(
			unit.unit_data.character_name,
			previous_hp,
			unit.stats.max_hp,
			healing
		)



func _on_unit_terrain_cell_entered(
	unit: Unit,
	cell: Vector2i
) -> void:
	var terrain: TerrainResource = grid.get_terrain_at(cell)

	var damage: int = TerrainEffectCalculator.calculate_terrain_damage(
		unit.current_hp,
		terrain,
		true
	)

	if damage > 0:
		var previous_hp: int = unit.current_hp

		unit.current_hp -= damage
		unit.took_terrain_damage = true
		print(
			"TERRAIN DAMAGE: ",
			unit.unit_data.character_name,
			" -", damage,
			" HP | Remaining: ",
			unit.current_hp
		)

		await terrain_effect_popup.show_damage(
			unit.unit_data.character_name,
			previous_hp,
			unit.stats.max_hp,
			damage
		)

		if unit.current_hp <= 0:
			unit.hide()

	# Resume movement after terrain processing finishes.
	unit.terrain_effect_finished.emit.call_deferred()
