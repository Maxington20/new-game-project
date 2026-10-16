
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

@onready var grid = $Grid
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


func _ready() -> void:
	grid.cell_selected.connect(_on_cell_selected)
	turn_system.phase_changed.connect(_on_phase_changed)

	action_menu.attack_selected.connect(_on_attack_selected)
	action_menu.wait_selected.connect(_on_wait_selected)
	action_menu.cancel_selected.connect(_on_cancel_selected)

	combat_dialog.hide()
	_build_forecast_overlay()

	weapon_menu = PopupPanel.new()
	weapon_menu.name = "WeaponSelectionMenu"
	weapon_menu.add_theme_stylebox_override("panel", GameUIStyle.make_panel_style())
	$CanvasLayer.add_child(weapon_menu)
	weapon_menu.popup_hide.connect(_on_weapon_menu_hidden)

	weapon_menu_buttons = VBoxContainer.new()
	weapon_menu_buttons.add_theme_constant_override("separation", 10)
	weapon_menu.add_child(weapon_menu_buttons)

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
	fields["Damage"].text = (
		str(CombatCalculator.calculate_damage(unit, opponent)) + " x" + str(strikes)
	)
	fields["Hit"].text = str(CombatCalculator.get_displayed_hit(unit, opponent)) + "%"
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

	var result: Dictionary = grid.get_reachable_cells(
		unit.grid_position,
		unit.movement_range,
		occupied
	)

	current_paths = result["previous"]

	var movement_cells: Array[Vector2i] = []

	for cell in result["distances"].keys():
		movement_cells.append(cell)

	grid.selected_cell = unit.grid_position
	grid.highlighted_cells.clear()

	for cell in movement_cells:
		if cell != unit.grid_position:
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

	selected_unit.move_along_path(movement_path)
	await selected_unit.movement_finished

	open_action_menu()


func _get_attackable_weapons(unit: Unit) -> Array[WeaponResource]:
	var result: Array[WeaponResource] = []
	if unit == null or unit.unit_data == null:
		return result

	var original: WeaponResource = unit.equipped_weapon
	for weapon in unit.unit_data.inventory:
		if weapon == null or weapon in result:
			continue
		unit.equipped_weapon = weapon
		if not get_attack_targets(unit).is_empty():
			result.append(weapon)
	unit.equipped_weapon = original
	return result


func _restore_previous_weapon() -> void:
	if selected_unit != null and previous_weapon != null:
		selected_unit.equipped_weapon = previous_weapon
	previous_weapon = null


func open_action_menu() -> void:
	interaction_state = InteractionState.AWAITING_ACTION
	pending_target = null
	available_targets.clear()
	weapon_choices = _get_attackable_weapons(selected_unit)

	grid.selected_cell = selected_unit.grid_position
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	grid.queue_redraw()

	var menu_position := (
		selected_unit.global_position + Vector2(40, 0)
	)

	action_menu.open_menu(
		menu_position,
		not weapon_choices.is_empty()
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
		button.text = weapon.weapon_name
		button.custom_minimum_size = Vector2(180, 38)
		GameUIStyle.style_button(button)
		button.pressed.connect(_on_weapon_chosen.bind(index))
		weapon_menu_buttons.add_child(button)

	var popup_position := Vector2i(
		selected_unit.global_position + Vector2(40, 0)
	)
	var popup_height: int = 32 + weapon_choices.size() * 38 + maxi(0, weapon_choices.size() - 1) * 10
	weapon_menu.popup(Rect2i(popup_position, Vector2i(220, popup_height)))
	if weapon_menu_buttons.get_child_count() > 0:
		(weapon_menu_buttons.get_child(0) as Button).grab_focus()

func _on_weapon_chosen(index: int) -> void:
	if interaction_state != InteractionState.CHOOSING_WEAPON:
		return
	if index < 0 or index >= weapon_choices.size():
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

	if not CombatCalculator.can_attack(attacker, defender):
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
	if team == Unit.Team.PLAYER:
		phase_label.text = "Player Phase"
		is_phase_transitioning = false
	else:
		phase_label.text = "Enemy Phase"
		is_phase_transitioning = true
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

		var occupied: Array[Vector2i] = (
			get_occupied_cells(enemy)
		)

		var action: Dictionary = enemy_ai.choose_action(
			enemy,
			players,
			grid,
			occupied
		)

		if action.is_empty():
			turn_system.mark_unit_acted(enemy)
			continue

		var path: Array[Vector2i] = action["path"]
		var target: Unit = action["target"]

		if not path.is_empty():
			enemy.move_along_path(path)
			await enemy.movement_finished

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

		if enemy.current_hp > 0:
			turn_system.mark_unit_acted(enemy)

		await get_tree().create_timer(0.35).timeout

	turn_system.end_phase()
