
extends Node2D

enum InteractionState {
	IDLE,
	UNIT_SELECTED,
	UNIT_MOVING,
	AWAITING_ACTION,
	TARGETING,
	COMBAT_FORECAST
}

@onready var grid = $Grid
@onready var turn_system: BattleTurnSystem = $BattleTurnSystem
@onready var phase_label: Label = $CanvasLayer/TurnUI/PhaseLabel
@onready var action_menu: UnitActionMenu = $CanvasLayer/UnitActionMenu
@onready var combat_dialog: ConfirmationDialog = $CanvasLayer/CombatForecastDialog

var interaction_state: InteractionState = InteractionState.IDLE
var selected_unit: Unit = null

var original_cell: Vector2i = Vector2i(-1, -1)
var movement_path: Array[Vector2i] = []
var current_paths: Dictionary = {}

var available_targets: Array[Unit] = []
var pending_target: Unit = null

var is_phase_transitioning: bool = false


func _ready() -> void:
	grid.cell_selected.connect(_on_cell_selected)
	turn_system.phase_changed.connect(_on_phase_changed)

	action_menu.attack_selected.connect(_on_attack_selected)
	action_menu.wait_selected.connect(_on_wait_selected)
	action_menu.cancel_selected.connect(_on_cancel_selected)

	combat_dialog.confirmed.connect(_on_combat_confirmed)
	combat_dialog.canceled.connect(_on_combat_cancelled)

	var battle_units: Array[Unit] = []

	for child in get_children():
		if child is Unit:
			battle_units.append(child)

	turn_system.initialize(battle_units)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if interaction_state == InteractionState.TARGETING:
				get_viewport().set_input_as_handled()
				open_action_menu()


func _on_cell_selected(cell: Vector2i) -> void:
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

		InteractionState.UNIT_MOVING:
			return

		InteractionState.AWAITING_ACTION:
			return

		InteractionState.TARGETING:
			handle_attack_target(cell)

		InteractionState.COMBAT_FORECAST:
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
	for child in get_children():
		if child is Unit:
			if child.current_hp > 0 and child.grid_position == cell:
				return child

	return null


func get_occupied_cells(excluded_unit: Unit) -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []

	for child in get_children():
		if child is Unit:
			if child != excluded_unit and child.current_hp > 0:
				occupied.append(child.grid_position)

	return occupied


func get_attack_targets(unit: Unit) -> Array[Unit]:
	var targets: Array[Unit] = []

	for child in get_children():
		if not child is Unit:
			continue

		var target: Unit = child

		if target.team == unit.team or target.current_hp <= 0:
			continue

		if is_in_attack_range(unit, target):
			targets.append(target)

	return targets


func is_in_attack_range(attacker: Unit, defender: Unit) -> bool:
	var distance: int = (
		absi(attacker.grid_position.x - defender.grid_position.x)
		+ absi(attacker.grid_position.y - defender.grid_position.y)
	)

	return (
		distance >= attacker.min_attack_range
		and distance <= attacker.max_attack_range
	)


func calculate_damage(attacker: Unit, defender: Unit) -> int:
	if attacker.unit_data == null or defender.unit_data == null:
		return 0

	var attacker_class: UnitClassResource = attacker.unit_data.unit_class
	var defender_class: UnitClassResource = defender.unit_data.unit_class

	if attacker_class == null or defender_class == null:
		return 0

	return maxi(
		0,
		attacker_class.strength - defender_class.defense
	)


func select_unit(unit: Unit) -> void:
	selected_unit = unit
	original_cell = unit.grid_position
	movement_path.clear()
	available_targets.clear()
	pending_target = null

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

	grid.attack_cells = grid.get_potential_attack_cells(
		movement_cells,
		unit.min_attack_range,
		unit.max_attack_range
	)

	grid.queue_redraw()


func deselect_unit() -> void:
	selected_unit = null
	pending_target = null

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


func open_action_menu() -> void:
	interaction_state = InteractionState.AWAITING_ACTION
	pending_target = null

	available_targets = get_attack_targets(selected_unit)

	grid.selected_cell = selected_unit.grid_position
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()
	grid.queue_redraw()

	var menu_position := (
		selected_unit.global_position + Vector2(40, 0)
	)

	action_menu.open_menu(
		menu_position,
		not available_targets.is_empty()
	)


func _on_attack_selected() -> void:
	if interaction_state != InteractionState.AWAITING_ACTION:
		return

	if available_targets.is_empty():
		return

	interaction_state = InteractionState.TARGETING
	action_menu.close_menu()

	grid.selected_cell = selected_unit.grid_position
	grid.highlighted_cells.clear()
	grid.attack_cells.clear()

	for target in available_targets:
		grid.attack_cells.append(target.grid_position)

	grid.queue_redraw()


func handle_attack_target(cell: Vector2i) -> void:
	var target := get_unit_at(cell)

	if target == null or target not in available_targets:
		return

	pending_target = target
	show_combat_forecast()


func show_combat_forecast() -> void:
	if selected_unit == null or pending_target == null:
		return

	interaction_state = InteractionState.COMBAT_FORECAST

	var attacker: Unit = selected_unit
	var defender: Unit = pending_target

	var attack_damage: int = calculate_damage(attacker, defender)
	var defender_survives: bool = defender.current_hp > attack_damage

	var can_counter: bool = (
		defender_survives
		and is_in_attack_range(defender, attacker)
	)

	var counter_damage: int = 0

	if can_counter:
		counter_damage = calculate_damage(defender, attacker)

	var attacker_name: String = attacker.unit_data.character_name
	var defender_name: String = defender.unit_data.character_name

	var forecast: String = (
		attacker_name + " attacks " + defender_name
		+ "\n\n"
		+ attacker_name + " HP: " + str(attacker.current_hp)
		+ "\n"
		+ defender_name + " HP: " + str(defender.current_hp)
		+ "\n\n"
		+ "Your damage: " + str(attack_damage)
	)

	if can_counter:
		forecast += (
            "\n"
			+ "Enemy counterattack: " + str(counter_damage)
		)
	else:
		forecast += "\nEnemy counterattack: None"

	forecast += "\n\nConfirm attack?"

	combat_dialog.dialog_text = forecast
	combat_dialog.popup_centered()


func _on_combat_confirmed() -> void:
	if interaction_state != InteractionState.COMBAT_FORECAST:
		return

	if selected_unit == null or pending_target == null:
		return

	var attacker: Unit = selected_unit
	var defender: Unit = pending_target

	var attack_damage: int = calculate_damage(attacker, defender)

	apply_damage(defender, attack_damage)

	if defender.current_hp > 0:
		if is_in_attack_range(defender, attacker):
			var counter_damage: int = calculate_damage(defender, attacker)
			apply_damage(attacker, counter_damage)

	complete_unit_action()


func _on_combat_cancelled() -> void:
	if interaction_state != InteractionState.COMBAT_FORECAST:
		return

	pending_target = null
	interaction_state = InteractionState.TARGETING


func apply_damage(unit: Unit, damage: int) -> void:
	unit.current_hp = maxi(0, unit.current_hp - damage)

	var unit_name: String = unit.unit_data.character_name

	print(
		unit_name,
		" takes ",
		damage,
		" damage. HP remaining: ",
		unit.current_hp
	)

	if unit.current_hp <= 0:
		unit.hide()
		print(unit_name, " has been defeated!")


func _on_wait_selected() -> void:
	if interaction_state != InteractionState.AWAITING_ACTION:
		return

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
	# Enemy AI will be added later.
	await get_tree().create_timer(1.5).timeout
	turn_system.end_phase()
