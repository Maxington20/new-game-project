class_name BattleAnimationOverlay
extends Control

signal battle_animation_finished

@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Background/Ground

@onready var enemy_sprite: ColorRect = $EnemySprite
@onready var player_sprite: ColorRect = $PlayerSprite

@onready var enemy_info: VBoxContainer = $EnemyInfo
@onready var player_info: VBoxContainer = $PlayerInfo

@onready var enemy_name: Label = $EnemyInfo/NameLabel
@onready var enemy_weapon: Label = $EnemyInfo/WeaponLabel
@onready var enemy_hp_bar: ProgressBar = $EnemyInfo/HPBar
@onready var enemy_hp_label: Label = $EnemyInfo/HPLabel

@onready var player_name: Label = $PlayerInfo/NameLabel
@onready var player_weapon: Label = $PlayerInfo/WeaponLabel
@onready var player_hp_bar: ProgressBar = $PlayerInfo/HPBar
@onready var player_hp_label: Label = $PlayerInfo/HPLabel

@onready var combat_text: Label = $CombatText

const BACKGROUND_COLOR := Color("#344d68")
const GROUND_COLOR := Color("#657e56")

const PLAYER_COLOR := Color("#4682b4")
const ENEMY_COLOR := Color("#c74b50")

const SPRITE_SIZE := Vector2(72, 96)
const ATTACK_DISTANCE: float = 48.0
const WEAPON_EXPERIENCE_PER_STRIKE: int = 1

var player_unit: Unit = null
var enemy_unit: Unit = null
var is_playing: bool = false
var pending_rank_ups: Array[Dictionary] = []
var rank_notice: PanelContainer
var rank_name: Label
var rank_weapon: Label
var rank_before: Label
var rank_after: Label
var player_participated: bool = false
var player_defeated_enemy: bool = false
var exp_notice: PanelContainer
var exp_name: Label
var exp_gain: Label
var exp_bar: ProgressBar
var exp_total: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	background.color = BACKGROUND_COLOR
	ground.color = GROUND_COLOR

	enemy_sprite.color = ENEMY_COLOR
	player_sprite.color = PLAYER_COLOR

	enemy_hp_bar.show_percentage = false
	player_hp_bar.show_percentage = false

	combat_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_text.add_theme_font_size_override("font_size", 24)

	_build_rank_notification()
	_build_exp_notification()
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		layout_battle_screen()


func layout_battle_screen() -> void:
	var screen_size: Vector2 = size
	var center_x: float = screen_size.x / 2.0
	var center_y: float = screen_size.y / 2.0

	background.position = Vector2.ZERO
	background.size = screen_size

	ground.position = Vector2(0, center_y + 80)
	ground.size = Vector2(
		screen_size.x,
		maxf(0.0, screen_size.y - ground.position.y)
	)

	enemy_sprite.size = SPRITE_SIZE
	player_sprite.size = SPRITE_SIZE

	enemy_sprite.position = Vector2(
		center_x - 160,
		center_y - 16
	)

	player_sprite.position = Vector2(
		center_x + 88,
		center_y - 16
	)

	enemy_info.position = Vector2(
		24,
		screen_size.y - 125
	)

	enemy_info.size = Vector2(220, 100)

	player_info.position = Vector2(
		screen_size.x - 244,
		screen_size.y - 125
	)

	player_info.size = Vector2(220, 100)

	combat_text.position = Vector2(
		center_x - 200,
		36
	)

	combat_text.size = Vector2(400, 50)


func setup_battle(attacker: Unit, defender: Unit) -> void:
	if attacker.team == Unit.Team.PLAYER:
		player_unit = attacker
		enemy_unit = defender
	else:
		player_unit = defender
		enemy_unit = attacker

	player_name.text = player_unit.unit_data.character_name
	enemy_name.text = enemy_unit.unit_data.character_name

	player_weapon.text = get_weapon_name(player_unit)
	enemy_weapon.text = get_weapon_name(enemy_unit)

	player_hp_bar.max_value = (
		player_unit.stats.max_hp
	)

	enemy_hp_bar.max_value = (
		enemy_unit.stats.max_hp
	)

	player_hp_bar.value = player_unit.current_hp
	enemy_hp_bar.value = enemy_unit.current_hp

	update_hp_labels()

	combat_text.text = ""
	show()
	layout_battle_screen()


func get_weapon_name(unit: Unit) -> String:
	if unit.equipped_weapon == null:
		return "Unarmed"

	return unit.equipped_weapon.weapon_name


func update_hp_labels() -> void:
	var player_max_hp: int = (
		player_unit.stats.max_hp
	)

	var enemy_max_hp: int = (
		enemy_unit.stats.max_hp
	)

	player_hp_label.text = (
		"HP: " + str(player_unit.current_hp)
		+ "/" + str(player_max_hp)
	)

	enemy_hp_label.text = (
		"HP: " + str(enemy_unit.current_hp)
		+ "/" + str(enemy_max_hp)
	)


func play_battle(attacker: Unit, defender: Unit) -> void:
	if is_playing:
		return

	is_playing = true
	pending_rank_ups.clear()
	player_participated = false
	player_defeated_enemy = false
	setup_battle(attacker, defender)

	await get_tree().create_timer(0.45).timeout

	var attacker_follows: bool = (
		CombatCalculator.can_follow_up(attacker, defender)
	)

	var defender_follows: bool = (
		CombatCalculator.can_counterattack(defender, attacker)
		and CombatCalculator.can_follow_up(defender, attacker)
	)

	await play_strike(attacker, defender)

	if attacker.current_hp > 0 and defender.current_hp > 0:
		if CombatCalculator.can_counterattack(defender, attacker):
			await play_strike(defender, attacker)

	if attacker.current_hp > 0 and defender.current_hp > 0:
		if attacker_follows:
			await play_strike(attacker, defender)
		elif defender_follows:
			await play_strike(defender, attacker)

	await get_tree().create_timer(0.7).timeout
	await _award_and_show_player_exp()
	await _show_pending_rank_ups()

	hide()
	is_playing = false
	battle_animation_finished.emit()


func award_weapon_experience(attacker: Unit) -> void:
	if attacker == null or attacker.unit_data == null:
		return

	var weapon: WeaponResource = attacker.equipped_weapon
	var proficiencies: WeaponProficiencyResource = (
		attacker.unit_data.weapon_proficiencies
	)

	if weapon == null or proficiencies == null:
		return

	var weapon_type: WeaponResource.WeaponType = weapon.weapon_type
	var previous_exp: int = proficiencies.get_experience(weapon_type)

	# A proficiency of zero means this unit cannot use the weapon type.
	# Don't grant proficiency for an otherwise invalid loadout.
	if previous_exp <= 0:
		return

	var previous_rank: String = WeaponProficiencyCalculator.get_rank(
		previous_exp
	)

	proficiencies.add_experience(
		weapon_type,
		WEAPON_EXPERIENCE_PER_STRIKE
	)

	var current_exp: int = proficiencies.get_experience(weapon_type)
	var current_rank: String = WeaponProficiencyCalculator.get_rank(
		current_exp
	)

	print(
		"WEXP: ", attacker.unit_data.character_name,
		" | ", weapon.weapon_name,
		" | ", previous_exp, " -> ", current_exp,
		" | Rank ", current_rank
	)

	if current_rank != previous_rank:
		pending_rank_ups.append({
			"name": attacker.unit_data.character_name,
			"weapon": _weapon_type_name(weapon_type),
			"before": previous_rank,
			"after": current_rank
		})
		print(
			"WEAPON RANK UP: ", attacker.unit_data.character_name,
			" | ", previous_rank, " -> ", current_rank,
			" | ", weapon.weapon_name
		)


func _weapon_type_name(weapon_type: WeaponResource.WeaponType) -> String:
	match weapon_type:
		WeaponResource.WeaponType.SWORD: return "Sword"
		WeaponResource.WeaponType.LANCE: return "Lance"
		WeaponResource.WeaponType.AXE: return "Axe"
		WeaponResource.WeaponType.BOW: return "Bow"
		WeaponResource.WeaponType.ANIMA: return "Anima"
		WeaponResource.WeaponType.LIGHT: return "Light"
		WeaponResource.WeaponType.DARK: return "Dark"
		WeaponResource.WeaponType.STAFF: return "Staff"
	return "Weapon"


func _build_rank_notification() -> void:
	# A centered, self-contained panel built in code; no scene edits required.
	rank_notice = PanelContainer.new()
	rank_notice.name = "WeaponRankNotice"
	rank_notice.custom_minimum_size = Vector2(320, 0)
	rank_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	rank_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rank_notice.grow_vertical = Control.GROW_DIRECTION_BOTH
	rank_notice.mouse_filter = Control.MOUSE_FILTER_STOP
	rank_notice.add_theme_stylebox_override("panel", GameUIStyle.make_panel_style())
	add_child(rank_notice)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	rank_notice.add_child(column)

	var heading := Label.new()
	heading.text = "WEAPON RANK INCREASED!"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(heading, 13, true)
	column.add_child(heading)

	rank_name = Label.new()
	rank_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(rank_name, 22)
	column.add_child(rank_name)

	var separator := HSeparator.new()
	column.add_child(separator)

	rank_weapon = Label.new()
	rank_weapon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(rank_weapon, 14, true)
	column.add_child(rank_weapon)

	var ranks := HBoxContainer.new()
	ranks.alignment = BoxContainer.ALIGNMENT_CENTER
	ranks.add_theme_constant_override("separation", 20)
	column.add_child(ranks)

	rank_before = Label.new()
	rank_before.custom_minimum_size.x = 55
	rank_before.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(rank_before, 28)
	ranks.add_child(rank_before)

	var arrow := Label.new()
	arrow.text = "→"
	GameUIStyle.style_label(arrow, 22, true)
	ranks.add_child(arrow)

	rank_after = Label.new()
	rank_after.custom_minimum_size.x = 55
	rank_after.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(rank_after, 28)
	rank_after.add_theme_color_override("font_color", GameUIStyle.HEALTH)
	ranks.add_child(rank_after)

	rank_notice.hide()


func _show_pending_rank_ups() -> void:
	for rank_up in pending_rank_ups:
		rank_name.text = rank_up["name"]
		rank_weapon.text = rank_up["weapon"]
		rank_before.text = rank_up["before"]
		rank_after.text = rank_up["after"]
		rank_notice.show()
		await get_tree().process_frame
		# Recenter after text and container minimum sizes are resolved.
		rank_notice.position = (size - rank_notice.size) / 2.0
		await get_tree().create_timer(2.0).timeout
		rank_notice.hide()
	pending_rank_ups.clear()


func _build_exp_notification() -> void:
	exp_notice = PanelContainer.new()
	exp_notice.name = "ExperienceNotice"
	exp_notice.custom_minimum_size = Vector2(320, 0)
	exp_notice.mouse_filter = Control.MOUSE_FILTER_STOP
	exp_notice.add_theme_stylebox_override("panel", GameUIStyle.make_panel_style())
	add_child(exp_notice)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	exp_notice.add_child(column)

	var heading := Label.new()
	heading.text = "EXPERIENCE GAINED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(heading, 13, true)
	column.add_child(heading)

	exp_name = Label.new()
	exp_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(exp_name, 22)
	column.add_child(exp_name)

	exp_gain = Label.new()
	exp_gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(exp_gain, 16)
	column.add_child(exp_gain)

	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(280, 16)
	exp_bar.min_value = 0
	exp_bar.max_value = 100
	exp_bar.show_percentage = false
	column.add_child(exp_bar)

	exp_total = Label.new()
	exp_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(exp_total, 13, true)
	column.add_child(exp_total)
	exp_notice.hide()


func _award_and_show_player_exp() -> void:
	if not player_participated or not is_instance_valid(player_unit):
		return
	if not is_instance_valid(enemy_unit):
		return
	if player_unit.unit_data == null or enemy_unit.unit_data == null:
		return

	var data: UnitResource = player_unit.unit_data
	var gained: int = ExperienceCalculator.calculate_experience(
		data.level,
		enemy_unit.unit_data.level,
		true,
		player_defeated_enemy
	)
	var before: int = clampi(data.experience, 0, 99)
	var after: int = mini(99, before + gained)
	var actual_gain: int = after - before
	data.experience = after

	print("EXP: ", data.character_name, " | +", actual_gain,
		" | ", before, " -> ", after)

	exp_name.text = data.character_name
	exp_gain.text = "+" + str(actual_gain) + " EXP"
	exp_total.text = str(before) + " / 100 EXP"
	exp_bar.value = before
	exp_notice.show()
	await get_tree().process_frame
	exp_notice.position = (size - exp_notice.size) / 2.0

	var tween := create_tween()
	tween.tween_property(exp_bar, "value", float(after), 0.7)
	await tween.finished
	exp_total.text = str(after) + " / 100 EXP"
	await get_tree().create_timer(1.0).timeout
	exp_notice.hide()


func play_strike(attacker: Unit, defender: Unit) -> void:
	if not CombatCalculator.can_attack(attacker, defender):
		return

	var attacking_sprite: ColorRect = (
		player_sprite
		if attacker.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	var direction: float = (
		-1.0 if attacker.team == Unit.Team.PLAYER else 1.0
	)

	var starting_position: Vector2 = attacking_sprite.position

	combat_text.text = (
		attacker.unit_data.character_name + " attacks!"
	)

	var forward_tween := create_tween()

	forward_tween.tween_property(
		attacking_sprite,
		"position:x",
		starting_position.x + direction * ATTACK_DISTANCE,
		0.18
	)

	await forward_tween.finished

	var result: Dictionary = CombatCalculator.resolve_strike(
		attacker,
		defender
	)

	if not result["valid"]:
		# Restore the sprite if the strike becomes invalid mid-animation.
		attacking_sprite.position = starting_position
		return

	# A valid player strike counts once toward encounter EXP, even on a miss.
	if attacker.team == Unit.Team.PLAYER:
		player_participated = true

	# Award once for each valid strike, regardless of hit or miss.
	award_weapon_experience(attacker)

	var attacker_name: String = attacker.unit_data.character_name
	var defender_name: String = defender.unit_data.character_name

	if result["hit"]:
		var damage: int = result["damage"]

		if result["critical"]:
			combat_text.text = "CRITICAL HIT!"
		else:
			combat_text.text = str(damage) + " DAMAGE!"

		defender.current_hp = maxi(
			0,
			defender.current_hp - damage
		)

		await animate_hp_bar(defender)

		print(
			attacker_name,
			" hits ",
			defender_name,
			" for ",
			damage,
			" damage. Remaining HP: ",
			defender.current_hp
		)

		if defender.current_hp <= 0:
			if attacker.team == Unit.Team.PLAYER and defender.team == Unit.Team.ENEMY:
				player_defeated_enemy = true
			combat_text.text = (
				defender_name + " defeated!"
			)

	else:
		combat_text.text = "MISS!"

		print(
			attacker_name,
			" attacks ",
			defender_name,
			" - MISS!"
		)

	var return_tween := create_tween()

	return_tween.tween_property(
		attacking_sprite,
		"position",
		starting_position,
		0.18
	)

	await return_tween.finished
	await get_tree().create_timer(0.35).timeout


func animate_hp_bar(unit: Unit) -> void:
	var hp_bar: ProgressBar = (
		player_hp_bar
		if unit.team == Unit.Team.PLAYER
		else enemy_hp_bar
	)

	var tween := create_tween()

	tween.tween_property(
		hp_bar,
		"value",
		float(unit.current_hp),
		0.4
	)

	await tween.finished
	update_hp_labels()


func finish_battle() -> void:
	hide()
	is_playing = false
	battle_animation_finished.emit()
