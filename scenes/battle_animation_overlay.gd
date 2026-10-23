class_name BattleAnimationOverlay
extends Control

signal battle_animation_finished

@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Background/Ground

@onready var enemy_sprite: ColorRect = $EnemySprite
@onready var player_sprite: ColorRect = $PlayerSprite

@onready var enemy_info: PanelContainer = $EnemyInfo
@onready var player_info: PanelContainer = $PlayerInfo

@onready var enemy_name: Label = $EnemyInfo/Content/Header/NameLabel
@onready var enemy_level: Label = $EnemyInfo/Content/Header/LevelLabel
@onready var enemy_weapon: Label = $EnemyInfo/Content/WeaponLabel
@onready var enemy_hp_bar: ProgressBar = $EnemyInfo/Content/HPBar
@onready var enemy_hp_label: Label = $EnemyInfo/Content/HPLabel

@onready var player_name: Label = $PlayerInfo/Content/Header/NameLabel
@onready var player_level: Label = $PlayerInfo/Content/Header/LevelLabel
@onready var player_weapon: Label = $PlayerInfo/Content/WeaponLabel
@onready var player_hp_bar: ProgressBar = $PlayerInfo/Content/HPBar
@onready var player_hp_label: Label = $PlayerInfo/Content/HPLabel

@onready var combat_text: Label = $CombatText

const BACKGROUND_COLOR := Color("#344d68")
const GROUND_COLOR := Color("#657e56")

const PLAYER_COLOR := Color("#4682b4")
const ENEMY_COLOR := Color("#c74b50")

const DESERT_SKY_COLOR := Color("#b9a6a0")
const SNOW_SKY_COLOR := Color("#91afc4")

const SPRITE_SIZE := Vector2(72, 96)
const ATTACK_DISTANCE: float = 48.0
const WEAPON_EXPERIENCE_PER_STRIKE: int = 1

var battlefield_grid: BattlefieldGrid = null
var terrain_scenery: Control
var enemy_terrain_ground: ColorRect
var player_terrain_ground: ColorRect
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
var level_notice: PanelContainer
var level_title: Label
var level_stats_column: VBoxContainer
var promotion_picker: PromotionSelection
var sky_scenery: Control
var ground_details: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	background.color = BACKGROUND_COLOR
	ground.color = GROUND_COLOR
	
	setup_terrain_backgrounds()
	setup_sky_scenery()
	setup_terrain_scenery()
	setup_ground_details()
	
	enemy_sprite.color = ENEMY_COLOR
	player_sprite.color = PLAYER_COLOR
	setup_combat_swordsman_art()

	enemy_hp_bar.show_percentage = false
	player_hp_bar.show_percentage = false
	style_battle_status_panels()

	combat_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_text.add_theme_font_size_override("font_size", 24)
	
	combat_text.add_theme_color_override(
		"font_outline_color",
		Color("#1a1a2e")
	)
	combat_text.add_theme_constant_override("outline_size", 4)
	
	combat_text.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.6)
	)
	combat_text.add_theme_constant_override(
		"shadow_offset_x",
		2
	)
	combat_text.add_theme_constant_override(
		"shadow_offset_y",
		2
	)

	_build_rank_notification()
	_build_exp_notification()
	_build_level_notification()
	promotion_picker = PromotionSelection.new()
	promotion_picker.name = "PromotionSelection"
	add_child(promotion_picker)
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
	
	var ground_y: float = center_y + 80
	var ground_height: float = maxf(0.0, screen_size.y - ground_y)

	enemy_terrain_ground.position = Vector2(0, ground_y)
	enemy_terrain_ground.size = Vector2(center_x, ground_height)

	player_terrain_ground.position = Vector2(center_x, ground_y)
	player_terrain_ground.size = Vector2(center_x, ground_height)

	enemy_sprite.size = SPRITE_SIZE
	player_sprite.size = SPRITE_SIZE

	enemy_sprite.position = Vector2(
		center_x - 160,
		ground_y - SPRITE_SIZE.y + 10
	)

	player_sprite.position = Vector2(
		center_x + 88,
		ground_y - SPRITE_SIZE.y + 10
	)

	enemy_info.position = Vector2(
	24,
	screen_size.y - 160
	)
	enemy_info.size = Vector2(260, 136)

	player_info.position = Vector2(
		screen_size.x - 284,
		screen_size.y - 160
	)
	player_info.size = Vector2(260, 136)

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
		
	enemy_terrain_ground.color = get_battle_terrain_color(enemy_unit)
	player_terrain_ground.color = get_battle_terrain_color(player_unit)
	background.color = get_battle_sky_color()
	
	update_terrain_scenery()
	update_sky_scenery()
	update_ground_details()
	
	player_name.text = player_unit.unit_data.character_name
	enemy_name.text = enemy_unit.unit_data.character_name
	
	player_level.text = "Lv. " + str(player_unit.unit_data.level)
	enemy_level.text = "Lv. " + str(enemy_unit.unit_data.level)
	
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
	
	player_sprite.modulate.a = 1.0
	enemy_sprite.modulate.a = 1.0
	
	player_sprite.color = PLAYER_COLOR
	enemy_sprite.color = ENEMY_COLOR
	update_combat_character_art()
	player_sprite.rotation = 0.0
	enemy_sprite.rotation = 0.0
	
	combat_text.text = ""
	modulate.a = 0.0
	show()

	# Restore both sprites to their default battle positions.
	layout_battle_screen()

	var fade_tween := create_tween()
	fade_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await fade_tween.finished


func get_weapon_name(unit: Unit) -> String:
	if unit.equipped_weapon == null:
		return "Unarmed"

	return unit.equipped_weapon.weapon_name


func update_hp_labels() -> void:
	var player_max_hp: int = (
		player_unit.stats.max_hp
	)
	
	player_level.text = "Lv. " + str(player_unit.unit_data.level)

	var enemy_max_hp: int = (
		enemy_unit.stats.max_hp
	)
	
	enemy_level.text = "Lv. " + str(enemy_unit.unit_data.level)

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
	await setup_battle(attacker, defender)

	var attacker_follows: bool = (
		CombatCalculator.can_follow_up(attacker, defender)
	)

	var defender_follows: bool = (
		CombatCalculator.can_counterattack(defender, attacker)
		and CombatCalculator.can_follow_up(defender, attacker)
	)
	
	await get_tree().create_timer(0.45).timeout
	await play_strike(attacker, defender)

	if attacker.current_hp > 0 and defender.current_hp > 0:
		if CombatCalculator.can_counterattack(defender, attacker):
			await get_tree().create_timer(0.2).timeout
			await play_strike(defender, attacker)

	if attacker.current_hp > 0 and defender.current_hp > 0:
		if attacker_follows:
			await get_tree().create_timer(0.2).timeout
			await play_strike(attacker, defender)
		elif defender_follows:
			await get_tree().create_timer(0.2).timeout
			await play_strike(defender, attacker)

	
	await get_tree().create_timer(0.7).timeout
	await _award_and_show_player_exp()
	await _show_pending_rank_ups()

	var fade_tween := create_tween()
	fade_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await fade_tween.finished

	hide()
	modulate.a = 1.0
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
	var progression: Dictionary = LevelProgression.add_experience(data, gained)
	var actual_gain: int = int(progression["experience_gained"])
	var before_exp: int = int(progression["previous_experience"])
	var levels_gained: int = int(progression["levels_gained"])
	var after_exp: int = int(progression["new_experience"])

	print("EXP: ", data.character_name, " | +", actual_gain,
		" | Lv ", progression["previous_level"], " -> ", data.level,
		" | EXP ", before_exp, " -> ", after_exp)

	exp_name.text = data.character_name
	exp_gain.text = "+" + str(actual_gain) + " EXP"
	exp_bar.value = before_exp
	exp_total.text = str(before_exp) + " / 100 EXP"
	exp_notice.show()
	await get_tree().process_frame
	exp_notice.position = (size - exp_notice.size) / 2.0

	var remaining: int = actual_gain
	var position: int = before_exp
	var level_index: int = 0
	while remaining > 0:
		var step: int = mini(remaining, 100 - position)
		var destination: int = position + step
		var tween := create_tween()
		tween.tween_property(exp_bar, "value", float(destination), 0.55 * float(step) / 100.0 + 0.15)
		await tween.finished
		exp_total.text = str(destination) + " / 100 EXP"
		remaining -= step
		position = destination

		if position >= 100:
			# Hold the full EXP bar before displaying the level-up.
			await get_tree().create_timer(0.4).timeout
			if level_index < levels_gained:
				var old_stats: Dictionary = _snapshot_stats(data.stats)
				var increases: Dictionary = StatGrowthCalculator.roll_and_apply(data)
				var hp_increase: int = int(increases.get("max_hp", 0))
				if hp_increase > 0:
					player_unit.current_hp += hp_increase
					player_hp_bar.max_value = player_unit.stats.max_hp
					player_hp_bar.value = player_unit.current_hp
					update_hp_labels()
				var new_level: int = int(progression["previous_level"]) + level_index + 1
				await _show_level_up(data.character_name, new_level, old_stats, increases)

				# Detect an available promotion after the level-up panel closes.
				if new_level == PromotionCalculator.MIN_PROMOTION_LEVEL:
					if player_unit.run_state != null:
						var permanent_progression: PermanentProgression = \
							ProgressionSaveSystem.load_progression()
						var achievement_catalogue: AchievementCatalogue = load(
							"res://resources/achievements/achievement_catalogue.tres"
						)
						if permanent_progression != null and achievement_catalogue != null:
							var choices: Array[UnitClassResource] = \
								PromotionChoiceProvider.get_choices(
									player_unit.run_state,
									permanent_progression,
									achievement_catalogue
								)
							if not choices.is_empty():
								print(
									"PROMOTION AVAILABLE: ",
									data.character_name,
									" | Options: ",
									choices.size()
								)
												# Wait for the player's choice before combat continues.
								exp_notice.hide()
								promotion_picker.show_choices(data.character_name, choices)
								var selected_class: UnitClassResource = await promotion_picker.promotion_selected
								var promotion_result: Dictionary = player_unit.promote_with_choice(
									selected_class,
									permanent_progression,
									achievement_catalogue
								)
								if not bool(promotion_result.get("success", false)):
									push_error("Promotion failed: " + str(promotion_result))
								else:
									player_hp_bar.max_value = player_unit.stats.max_hp
									player_hp_bar.value = player_unit.current_hp
									update_hp_labels()
									print("PROMOTION APPLIED: ", data.character_name,
										" -> ", data.unit_class.class_name_display,
										" | Lv ", data.level,
										" | EXP ", data.experience,
										" | HP ", player_unit.current_hp, "/", player_unit.stats.max_hp)
								exp_notice.show()

				level_index += 1

			# Only reveal the remaining EXP after the level-up panel closes.
			position = 0
			exp_bar.value = 0
			exp_total.text = "0 / 100 EXP"
			if remaining > 0:
				await get_tree().create_timer(0.3).timeout

	# Preserve the actual EXP calculated by LevelProgression.
	exp_bar.value = after_exp
	exp_total.text = str(after_exp) + " / 100 EXP"
	await get_tree().create_timer(1.5 if levels_gained > 0 else 0.65).timeout
	exp_notice.hide()

func _snapshot_stats(stats: UnitStatsResource) -> Dictionary:
	var values: Dictionary = {}
	if stats == null:
		return values
	for stat_name in StatGrowthCalculator.STAT_NAMES:
		values[stat_name] = int(stats.get(stat_name))
	return values


func _build_level_notification() -> void:
	level_notice = PanelContainer.new()
	level_notice.name = "LevelUpNotice"
	level_notice.custom_minimum_size = Vector2(350, 0)
	level_notice.mouse_filter = Control.MOUSE_FILTER_STOP
	level_notice.add_theme_stylebox_override("panel", GameUIStyle.make_panel_style())
	add_child(level_notice)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	level_notice.add_child(column)

	var heading := Label.new()
	heading.text = "LEVEL UP!"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(heading, 18)
	column.add_child(heading)

	level_title = Label.new()
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(level_title, 17)
	column.add_child(level_title)

	column.add_child(HSeparator.new())
	level_stats_column = VBoxContainer.new()
	level_stats_column.add_theme_constant_override("separation", 6)
	column.add_child(level_stats_column)
	level_notice.hide()


func _show_level_up(character_name: String, new_level: int,
		old_stats: Dictionary, increases: Dictionary) -> void:
	for child in level_stats_column.get_children():
		level_stats_column.remove_child(child)
		child.queue_free()

	level_title.text = character_name + "  Lv " + str(new_level)
	var stat_labels: Dictionary = {
		"max_hp": "HP", "strength": "STR", "skill": "SKL",
		"speed": "SPD", "luck": "LCK", "defense": "DEF",
		"resistance": "RES"
	}
	var reveal_rows: Array[HBoxContainer] = []
	for stat_name in StatGrowthCalculator.STAT_NAMES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		level_stats_column.add_child(row)
		var label := Label.new()
		label.text = str(stat_labels[stat_name])
		label.custom_minimum_size.x = 65
		GameUIStyle.style_label(label, 14, true)
		row.add_child(label)
		var old_value: int = int(old_stats.get(stat_name, 0))
		var amount: int = int(increases.get(stat_name, 0))
		var value := Label.new()
		value.text = str(old_value + amount)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		GameUIStyle.style_label(value, 14)
		row.add_child(value)
		var gain := Label.new()
		gain.text = "+" + str(amount) if amount > 0 else "—"
		gain.custom_minimum_size.x = 38
		gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		GameUIStyle.style_label(gain, 14, amount == 0)
		if amount > 0:
			gain.add_theme_color_override("font_color", GameUIStyle.HEALTH)
		row.add_child(gain)
		row.hide()
		reveal_rows.append(row)

	exp_notice.hide()
	level_notice.show()
	await get_tree().process_frame
	level_notice.position = (size - level_notice.size) / 2.0
	for row in reveal_rows:
		row.show()
		await get_tree().create_timer(0.16).timeout
	await get_tree().create_timer(2.5).timeout
	level_notice.hide()
	exp_notice.show()





func play_strike(attacker: Unit, defender: Unit) -> void:
	if not CombatCalculator.can_attack(attacker, defender):
		return

	var attacking_sprite: ColorRect = (
		player_sprite
		if attacker.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	var defending_sprite: ColorRect = (
		player_sprite
		if defender.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	var direction: float = (
		-1.0 if attacker.team == Unit.Team.PLAYER else 1.0
	)

	var starting_position: Vector2 = attacking_sprite.position

	# Identify the attacker's class-specific artwork.
	var swordsman_art: CombatSwordsmanArt = (
		attacking_sprite.get_node_or_null("SwordsmanArt")
		as CombatSwordsmanArt
	)

	var is_swordsman: bool = (
		swordsman_art != null and swordsman_art.visible
	)

	var fighter_art: CombatFighterArt = (
		attacking_sprite.get_node_or_null("FighterArt")
		as CombatFighterArt
	)

	var is_fighter: bool = (
		fighter_art != null and fighter_art.visible
	)

	var knight_art: CombatKnightArt = (
		attacking_sprite.get_node_or_null("KnightArt")
		as CombatKnightArt
	)

	var is_knight: bool = (
		knight_art != null and knight_art.visible
	)

	var archer_art: CombatArcherArt = (
		attacking_sprite.get_node_or_null("ArcherArt")
		as CombatArcherArt
	)

	var is_archer: bool = (
		archer_art != null and archer_art.visible
	)

	combat_text.text = ""
	combat_text.modulate.a = 0.0
	combat_text.add_theme_color_override("font_color", Color.WHITE)

	combat_text.text = (
		attacker.unit_data.character_name + " attacks!"
	)

	var announcement_tween := create_tween()
	announcement_tween.tween_property(
		combat_text,
		"modulate:a",
		1.0,
		0.12
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Class-specific attack wind-ups.
	if is_swordsman:
		await animate_swordsman_windup(swordsman_art, direction)
	elif is_fighter:
		await animate_fighter_windup(fighter_art, direction)
	elif is_knight:
		await animate_knight_windup(knight_art, direction)
	elif is_archer:
		await animate_archer_draw(archer_art, direction)

	if is_archer:
		# The archer stays in place and fires across the battlefield.
		await animate_archer_release(archer_art, direction)
		await animate_archer_arrow(
			attacking_sprite,
			defending_sprite,
			direction
		)
	else:
		# Melee classes move toward their opponent.
		var forward_tween := create_tween()

		forward_tween.tween_property(
			attacking_sprite,
			"position:x",
			starting_position.x + direction * ATTACK_DISTANCE,
			0.12
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

		# Play the appropriate attack animation during the lunge.
		if is_swordsman:
			animate_swordsman_slash(swordsman_art, direction)
		elif is_fighter:
			animate_fighter_chop(fighter_art, direction)
		elif is_knight:
			animate_knight_thrust(knight_art, direction)

		await forward_tween.finished

	# Determine the defender's terrain.
	var defender_terrain: TerrainResource = null

	if battlefield_grid != null:
		defender_terrain = battlefield_grid.get_terrain_at(
			defender.grid_position
		)

	# Resolve the actual combat strike.
	var result: Dictionary = CombatCalculator.resolve_strike(
		attacker,
		defender,
		defender_terrain
	)

	if not result["valid"]:
		attacking_sprite.position = starting_position

		if is_swordsman:
			swordsman_art.rotation = 0.0
			swordsman_art.position = Vector2.ZERO

		if is_fighter:
			fighter_art.rotation = 0.0
			fighter_art.position = Vector2.ZERO

		if is_knight:
			knight_art.rotation = 0.0
			knight_art.position = Vector2.ZERO

		if is_archer:
			archer_art.rotation = 0.0
			archer_art.position = Vector2.ZERO

		return

	# Melee attackers return to their starting positions.
	# Archers never leave their starting positions.
	if not is_archer:
		var return_tween := create_tween()

		return_tween.tween_property(
			attacking_sprite,
			"position",
			starting_position,
			0.22
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# A valid player strike counts toward encounter EXP, even on a miss.
	if attacker.team == Unit.Team.PLAYER:
		player_participated = true

	# Award weapon experience once per valid strike.
	award_weapon_experience(attacker)

	var defender_name: String = defender.unit_data.character_name

	if result["hit"]:
		var damage: int = result["damage"]

		animate_hit_flash(defender)
		animate_hit_knockback(defender)

		if result["critical"]:
			combat_text.add_theme_color_override(
				"font_color",
				Color("#ffd166")
			)

			combat_text.text = (
				"CRITICAL HIT! " + str(damage) + " DAMAGE!"
			)

			animate_critical_flash()
			animate_critical_shake()
		else:
			combat_text.add_theme_color_override(
				"font_color",
				Color.WHITE
			)

			combat_text.text = str(damage) + " DAMAGE!"

		if result["critical"]:
			await get_tree().create_timer(0.18).timeout

		defender.current_hp = maxi(
			0,
			defender.current_hp - damage
		)

		await animate_hp_bar(defender)

		if defender.current_hp <= 0:
			if (
				attacker.team == Unit.Team.PLAYER
				and defender.team == Unit.Team.ENEMY
			):
				player_defeated_enemy = true

			combat_text.add_theme_color_override(
				"font_color",
				Color.WHITE
			)

			combat_text.text = (
				defender_name + " defeated!"
			)

			await get_tree().create_timer(0.15).timeout

			animate_defeat_shake()
			await animate_defeat(defender)

			await get_tree().create_timer(0.35).timeout

	else:
		combat_text.add_theme_color_override(
			"font_color",
			Color("#fff176")
		)

		combat_text.text = "MISS!"

		await animate_dodge(defender)

	# Fade out the combat result text.
	var text_fade := create_tween()

	text_fade.tween_property(
		combat_text,
		"modulate:a",
		0.0,
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await text_fade.finished
	await get_tree().create_timer(0.25).timeout


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




func animate_hit_flash(unit: Unit) -> void:
	var sprite: ColorRect = (
		player_sprite
		if unit.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	# Find the visible character artwork.
	var art: CanvasItem = null

	for child in sprite.get_children():
		if child is CanvasItem and child.visible:
			art = child
			break

	if art == null:
		return

	# Flash the actual character artwork.
	var original_modulate: Color = art.modulate

	var flash_tween := create_tween()

	flash_tween.tween_property(
		art,
		"modulate",
		Color(1.0, 0.35, 0.35, 1.0),
		0.07
	)

	flash_tween.tween_property(
		art,
		"modulate",
		original_modulate,
		0.09
	)

	flash_tween.tween_property(
		art,
		"modulate",
		Color(1.0, 0.35, 0.35, 1.0),
		0.07
	)

	flash_tween.tween_property(
		art,
		"modulate",
		original_modulate,
		0.12
	)

	await flash_tween.finished



func animate_hit_knockback(unit: Unit) -> void:
	var sprite: ColorRect = (
		player_sprite
		if unit.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	var starting_position: Vector2 = sprite.position
	
	var shake_tween := create_tween()

	shake_tween.tween_property(
		sprite,
		"position:y",
		starting_position.y - 5.0,
		0.06
	)

	shake_tween.tween_property(
		sprite,
		"position:y",
		starting_position.y + 4.0,
		0.06
	)

	shake_tween.tween_property(
		sprite,
		"position:y",
		starting_position.y,
		0.08
	)

	# The player is on the right; the enemy is on the left.
	var direction: float = (
		1.0 if unit.team == Unit.Team.PLAYER else -1.0
	)

	var tween := create_tween()

	tween.tween_property(
		sprite,
		"position:x",
		starting_position.x + direction * 18.0,
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		sprite,
		"position:x",
		starting_position.x,
		0.16
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished

func animate_critical_shake() -> void:
	var starting_position: Vector2 = position

	var tween := create_tween()
	tween.tween_property(
		self, "position", starting_position + Vector2(-6, 0), 0.04
	)
	tween.tween_property(
		self, "position", starting_position + Vector2(6, 0), 0.04
	)
	tween.tween_property(
		self, "position", starting_position + Vector2(-3, 0), 0.04
	)
	tween.tween_property(
		self, "position", starting_position, 0.06
	)

	await tween.finished

func animate_defeat_shake() -> void:
	var starting_position: Vector2 = position

	var tween := create_tween()

	tween.tween_property(
		self, "position", starting_position + Vector2(-3, 0), 0.05
	)

	tween.tween_property(
		self, "position", starting_position + Vector2(3, 0), 0.05
	)

	tween.tween_property(
		self, "position", starting_position, 0.08
	)

	await tween.finished

func animate_critical_flash() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.65)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	add_child(flash)

	var tween := create_tween()
	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		0.25
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished
	flash.queue_free()



func animate_dodge(unit: Unit) -> void:
	var sprite: ColorRect = (
		player_sprite
		if unit.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	var starting_position: Vector2 = sprite.position
	var starting_rotation: float = sprite.rotation
	var starting_alpha: float = sprite.modulate.a

	# Dodge away from the attacker.
	var direction: float = (
		1.0 if unit.team == Unit.Team.PLAYER else -1.0
	)

	
	var tween := create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		sprite,
		"modulate:a",
		0.5,
		0.10
	)
	
	tween.tween_property(
		sprite,
		"position:x",
		starting_position.x + direction * 32.0,
		0.10
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		sprite,
		"rotation",
		starting_rotation + direction * 0.12,
		0.10
	)

	tween.chain().tween_property(
		sprite,
		"position:x",
		starting_position.x,
		0.20
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		sprite,
		"rotation",
		starting_rotation,
		0.20
	)
	
	tween.tween_property(
		sprite,
		"modulate:a",
		starting_alpha,
		0.20
	)

	await tween.finished




func finish_battle() -> void:
	hide()
	is_playing = false
	battle_animation_finished.emit()



func setup_terrain_backgrounds() -> void:
	enemy_terrain_ground = ColorRect.new()
	enemy_terrain_ground.name = "EnemyTerrainGround"
	enemy_terrain_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(enemy_terrain_ground)

	player_terrain_ground = ColorRect.new()
	player_terrain_ground.name = "PlayerTerrainGround"
	player_terrain_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(player_terrain_ground)

	# The new terrain sections replace the original ground visually.
	ground.hide()




func get_battle_terrain_color(unit: Unit) -> Color:
	if battlefield_grid == null:
		return GROUND_COLOR

	var terrain: TerrainResource = battlefield_grid.get_terrain_at(
		unit.grid_position
	)
	
	# Ground surrounding lava is scorched, regardless of biome.
	# Lava itself keeps its own volcanic appearance.
	if terrain == null or terrain.terrain_type != TerrainResource.TerrainType.LAVA:
		if battlefield_grid.is_adjacent_to_lava(unit.grid_position):
			return Color("#514943")

	# Special terrain takes priority over the map's biome.
	if terrain != null:
		match terrain.terrain_type:
			TerrainResource.TerrainType.FOREST:
				match battlefield_grid.biome:
					BattlefieldGrid.Biome.SNOW:
						return Color("#d8e3e9")

					BattlefieldGrid.Biome.DESERT:
						return Color("#c5aa7e")

					_:
						return Color("#285c32")

			TerrainResource.TerrainType.FORT:
				match battlefield_grid.biome:
					BattlefieldGrid.Biome.DESERT:
						return Color("#b89a6b")

					BattlefieldGrid.Biome.SNOW:
						return Color("#a8bac5")

					_:
						return Color("#707986")

			TerrainResource.TerrainType.LAVA:
				return Color("#51413b")

	# Ordinary ground reflects the battlefield's biome.
	match battlefield_grid.biome:
		BattlefieldGrid.Biome.DESERT:
			return Color("#c5aa7e")

		BattlefieldGrid.Biome.SNOW:
			return Color("#d8e3e9")

		_:
			return GROUND_COLOR



func setup_terrain_scenery() -> void:
	terrain_scenery = Control.new()
	terrain_scenery.name = "TerrainScenery"
	terrain_scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	terrain_scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(terrain_scenery)





func update_terrain_scenery() -> void:
	for child in terrain_scenery.get_children():
		child.queue_free()

	if battlefield_grid == null:
		return

	var half_width: float = size.x / 2.0

	add_unit_terrain_scenery(enemy_unit, 0.0, half_width)
	add_unit_terrain_scenery(player_unit, half_width, half_width)


func add_unit_terrain_scenery(
	unit: Unit,
	start_x: float,
	section_width: float
) -> void:
	var terrain: TerrainResource = battlefield_grid.get_terrain_at(
		unit.grid_position
	)
	
	# Scorched terrain replaces ordinary biome scenery.
	# Lava tiles retain their volcanic scenery.
	if terrain == null or terrain.terrain_type != TerrainResource.TerrainType.LAVA:
		if battlefield_grid.is_adjacent_to_lava(unit.grid_position):
			return

	if terrain != null:
		match terrain.terrain_type:
			TerrainResource.TerrainType.FOREST:
				add_forest_scenery(
					Vector2(start_x + section_width / 2.0, size.y * 0.52)
				)
				return

			TerrainResource.TerrainType.FORT:
				add_fort_scenery(start_x, section_width)
				return

			TerrainResource.TerrainType.LAVA:
				add_lava_scenery(start_x, section_width)
				return

	# Ordinary terrain uses the map's biome.
	match battlefield_grid.biome:
		BattlefieldGrid.Biome.GRASSLAND:
			add_grassland_scenery(start_x, section_width)

		BattlefieldGrid.Biome.DESERT:
			add_desert_scenery(start_x, section_width)

		BattlefieldGrid.Biome.SNOW:
			add_snow_scenery(start_x, section_width)


func add_forest_scenery(center: Vector2) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	
	if battlefield_grid.biome == BattlefieldGrid.Biome.DESERT:
		add_desert_forest_scenery(center)
		return
	
	var tree_data: Array[Dictionary] = [
		{"offset": -110.0, "height": 75.0},
		{"offset": -55.0, "height": 95.0},
		{"offset": 55.0, "height": 85.0},
		{"offset": 110.0, "height": 70.0}
	]

	var is_snow: bool = battlefield_grid.biome == BattlefieldGrid.Biome.SNOW

	for data in tree_data:
		var tree_height: float = data["height"]
		var tree_x: float = center.x + data["offset"]

		var tree_position := Vector2(
			tree_x,
			ground_y - tree_height
		)

		var tree := ColorRect.new()
		tree.color = Color("#244d40") if is_snow else Color("#174527")
		tree.size = Vector2(34, tree_height - 10.0)
		tree.position = tree_position
		tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(tree)

		var highlight := ColorRect.new()
		highlight.color = Color("#73988b") if is_snow else Color("#327a43")
		highlight.size = Vector2(22, tree_height * 0.55)
		highlight.position = Vector2(6, 5)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tree.add_child(highlight)

		var trunk := ColorRect.new()
		trunk.color = Color("#765139")
		trunk.size = Vector2(10, 25)
		trunk.position = Vector2(12, tree_height - 25.0)
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tree.add_child(trunk)

		if is_snow:
			var snow_cap := ColorRect.new()
			snow_cap.color = Color("#f0f6fa")
			snow_cap.size = Vector2(34, 9)
			snow_cap.position = Vector2.ZERO
			snow_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tree.add_child(snow_cap)

			var snow_patch := ColorRect.new()
			snow_patch.color = Color("#d8e6ed")
			snow_patch.size = Vector2(22, 5)
			snow_patch.position = Vector2(6, 22)
			snow_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tree.add_child(snow_patch)

func add_desert_forest_scenery(center: Vector2) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var tree_data: Array[Dictionary] = [
		{"offset": -110.0, "height": 75.0},
		{"offset": -55.0, "height": 95.0},
		{"offset": 55.0, "height": 85.0},
		{"offset": 110.0, "height": 70.0}
	]

	for data in tree_data:
		var tree_x: float = center.x + data["offset"]
		var tree_height: float = data["height"]

		# Narrow sandy-brown trunk.
		var trunk := ColorRect.new()
		trunk.color = Color("#94704b")
		trunk.size = Vector2(10, tree_height)
		trunk.position = Vector2(tree_x + 12, ground_y - tree_height)
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(trunk)

		# Palm leaves spread outward from the top.
		var leaf_color := Color("#647b3f")
		var leaf_highlight := Color("#91a65c")
		var crown := Vector2(tree_x + 17, ground_y - tree_height + 6)

		var leaves: Array[PackedVector2Array] = [
			PackedVector2Array([
				crown, crown + Vector2(-42, -12),
				crown + Vector2(-34, 4)
			]),
			PackedVector2Array([
				crown, crown + Vector2(42, -12),
				crown + Vector2(34, 4)
			]),
			PackedVector2Array([
				crown, crown + Vector2(-26, -28),
				crown + Vector2(-10, -12)
			]),
			PackedVector2Array([
				crown, crown + Vector2(26, -28),
				crown + Vector2(10, -12)
			])
		]

		for i in range(leaves.size()):
			var leaf := Polygon2D.new()
			leaf.polygon = leaves[i]
			leaf.color = leaf_highlight if i >= 2 else leaf_color
			terrain_scenery.add_child(leaf)

func add_fort_scenery(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	var wall_height: float = 125.0
	var wall_top: float = ground_y - wall_height

	var wall_color := Color("#4c5865")
	var battlement_color := Color("#788797")
	var mortar_color := Color("#35404c")

	# Desert forts use sandstone instead of grey stone.
	if battlefield_grid.biome == BattlefieldGrid.Biome.DESERT:
		wall_color = Color("#b89a6b")
		battlement_color = Color("#dfc69a")
		mortar_color = Color("#806747")

	# Main stone wall.
	var wall := ColorRect.new()
	wall.color = wall_color
	wall.position = Vector2(start_x, wall_top)
	wall.size = Vector2(section_width, wall_height)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	terrain_scenery.add_child(wall)

	# Stone blocks along the top of the wall.
	var block_width: float = 42.0
	var block_gap: float = 22.0
	var block_count: int = floori(section_width / (block_width + block_gap))

	for i in range(block_count):
		var battlement := ColorRect.new()
		battlement.color = battlement_color
		battlement.position = Vector2(
			start_x + i * (block_width + block_gap) + 10.0,
			wall_top - 24.0
		)
		battlement.size = Vector2(block_width, 24)
		battlement.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(battlement)
		
		# Snow collects on top of each battlement.
		if battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
			var snow_cap := ColorRect.new()
			snow_cap.color = Color("#edf5f9")
			snow_cap.position = battlement.position
			snow_cap.size = Vector2(block_width, 7)
			snow_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			terrain_scenery.add_child(snow_cap)
	# Snow settles along the exposed top of the main wall.
	if battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
		for i in range(block_count):
			var snow_between := ColorRect.new()
			snow_between.color = Color("#dce9f0")
			snow_between.position = Vector2(
				start_x + i * (block_width + block_gap) + 10.0 + block_width,
				wall_top
			)
			snow_between.size = Vector2(
				minf(block_gap, start_x + section_width - snow_between.position.x),
				5.0
			)
			snow_between.mouse_filter = Control.MOUSE_FILTER_IGNORE
			terrain_scenery.add_child(snow_between)

	# Horizontal mortar lines.
	for row in range(1, 4):
		var mortar := ColorRect.new()
		mortar.color = mortar_color
		mortar.position = Vector2(
			start_x,
			wall_top + row * 30.0
		)
		mortar.size = Vector2(section_width, 3)
		mortar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(mortar)



func add_lava_scenery(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	# Dark volcanic mountains in the background.
	var mountain_color := Color("#42383e")

	for i in range(4):
		var mountain := Polygon2D.new()

		var mountain_x: float = start_x + section_width * (float(i) + 0.5) / 4.0
		var mountain_width: float = section_width / 3.0
		var mountain_height: float = 90.0 + float(i % 2) * 35.0

		mountain.polygon = PackedVector2Array([
			Vector2(mountain_x - mountain_width / 2.0, ground_y),
			Vector2(mountain_x, ground_y - mountain_height),
			Vector2(mountain_x + mountain_width / 2.0, ground_y)
		])

		mountain.color = mountain_color
		terrain_scenery.add_child(mountain)

	# Glowing lava pools along the ground.
	var pool_positions: Array[float] = [0.12, 0.42, 0.75]

	for fraction in pool_positions:
		var pool := ColorRect.new()
		pool.color = Color("#ff6b22")
		pool.position = Vector2(
			start_x + section_width * fraction,
			ground_y + 18.0
		)
		pool.size = Vector2(75, 14)
		pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(pool)

		var glow := ColorRect.new()
		glow.color = Color("#ffb347")
		glow.position = Vector2(8, 3)
		glow.size = Vector2(48, 5)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pool.add_child(glow)

	# Small volcanic rocks near the ground.
	for i in range(5):
		var rock := ColorRect.new()
		rock.color = Color("#302c32")
		rock.size = Vector2(20 + (i % 3) * 8, 12 + (i % 2) * 6)
		rock.position = Vector2(
			start_x + 25.0 + i * (section_width - 50.0) / 5.0,
			ground_y - rock.size.y
		)
		rock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(rock)


func add_desert_scenery(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	# Distant sand dunes.
	var dune_color := Color("#d8be91")
	var dune_shadow := Color("#b99a6e")

	var dune := Polygon2D.new()
	dune.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x, ground_y - 20),
		Vector2(start_x + section_width * 0.25, ground_y - 65),
		Vector2(start_x + section_width * 0.55, ground_y - 30),
		Vector2(start_x + section_width * 0.8, ground_y - 55),
		Vector2(start_x + section_width, ground_y - 15),
		Vector2(start_x + section_width, ground_y)
	])
	dune.color = dune_color
	terrain_scenery.add_child(dune)

	# A smaller dune in front.
	var foreground_dune := Polygon2D.new()
	foreground_dune.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x + section_width * 0.15, ground_y - 15),
		Vector2(start_x + section_width * 0.4, ground_y - 35),
		Vector2(start_x + section_width * 0.7, ground_y - 10),
		Vector2(start_x + section_width, ground_y),
	])
	foreground_dune.color = dune_shadow
	terrain_scenery.add_child(foreground_dune)

	# Small rocks along the ground.
	for i in range(4):
		var rock := ColorRect.new()
		rock.color = Color("#897760")
		rock.size = Vector2(12 + (i % 2) * 6, 6 + (i % 3) * 3)
		rock.position = Vector2(
			start_x + 30.0 + i * (section_width - 60.0) / 4.0,
			ground_y - rock.size.y
		)
		rock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(rock)


func add_grassland_scenery(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var distant_hill_color := Color("#729c6a")
	var near_hill_color := Color("#527f4d")
	var bush_dark := Color("#315d35")
	var bush_light := Color("#4e8a4c")

	# Distant rolling hills.
	var distant_hills := Polygon2D.new()
	distant_hills.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x, ground_y - 15),
		Vector2(start_x + section_width * 0.2, ground_y - 55),
		Vector2(start_x + section_width * 0.45, ground_y - 30),
		Vector2(start_x + section_width * 0.7, ground_y - 65),
		Vector2(start_x + section_width, ground_y - 20),
		Vector2(start_x + section_width, ground_y)
	])
	distant_hills.color = distant_hill_color
	terrain_scenery.add_child(distant_hills)

	# Nearer, darker hills.
	var near_hills := Polygon2D.new()
	near_hills.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x + section_width * 0.15, ground_y - 20),
		Vector2(start_x + section_width * 0.4, ground_y - 35),
		Vector2(start_x + section_width * 0.65, ground_y - 15),
		Vector2(start_x + section_width, ground_y - 30),
		Vector2(start_x + section_width, ground_y)
	])
	near_hills.color = near_hill_color
	terrain_scenery.add_child(near_hills)

	# Small bushes along the ground.
	for i in range(4):
		var bush := ColorRect.new()
		bush.color = bush_dark
		bush.size = Vector2(24, 12)
		bush.position = Vector2(
			start_x + 25.0 + i * (section_width - 50.0) / 4.0,
			ground_y - 12.0
		)
		bush.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain_scenery.add_child(bush)

		var highlight := ColorRect.new()
		highlight.color = bush_light
		highlight.size = Vector2(14, 5)
		highlight.position = Vector2(5, 2)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bush.add_child(highlight)

func setup_sky_scenery() -> void:
	sky_scenery = Control.new()
	sky_scenery.name = "SkyScenery"
	sky_scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(sky_scenery)
	background.move_child(sky_scenery, 0)




func update_sky_scenery() -> void:
	for child in sky_scenery.get_children():
		child.queue_free()

	if battlefield_grid == null:
		return

	var half_width: float = size.x / 2.0

	match battlefield_grid.biome:
		BattlefieldGrid.Biome.GRASSLAND:
			add_pixel_cloud(Vector2(half_width * 0.25, size.y * 0.16))
			add_pixel_cloud(Vector2(half_width * 0.65, size.y * 0.28))
			add_pixel_cloud(Vector2(half_width * 1.25, size.y * 0.19))
			add_pixel_cloud(Vector2(half_width * 1.7, size.y * 0.12))

		BattlefieldGrid.Biome.DESERT:
			add_desert_sky_details()

		BattlefieldGrid.Biome.SNOW:
			pass



func add_pixel_cloud(position: Vector2) -> void:
	var cloud_color := Color("#c7d7df")
	var cloud_highlight := Color("#e6edf1")

	var cloud := Control.new()
	cloud.position = position
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_scenery.add_child(cloud)

	var blocks: Array[Rect2] = [
		Rect2(8, 8, 56, 16),
		Rect2(16, 0, 32, 16),
		Rect2(0, 16, 72, 12)
	]

	for block in blocks:
		var rect := ColorRect.new()
		rect.color = cloud_color
		rect.position = block.position
		rect.size = block.size
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.add_child(rect)

	var highlight := ColorRect.new()
	highlight.color = cloud_highlight
	highlight.position = Vector2(20, 4)
	highlight.size = Vector2(24, 8)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud.add_child(highlight)

func setup_ground_details() -> void:
	ground_details = Control.new()
	ground_details.name = "GroundDetails"
	ground_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground_details.z_index = 0
	background.add_child(ground_details)




func update_ground_details() -> void:
	for child in ground_details.get_children():
		child.queue_free()

	if battlefield_grid == null:
		return

	var half_width: float = size.x / 2.0

	add_unit_ground_details(enemy_unit, 0.0, half_width)
	add_unit_ground_details(player_unit, half_width, half_width)



func add_unit_ground_details(
	unit: Unit,
	start_x: float,
	section_width: float
) -> void:
	var terrain: TerrainResource = battlefield_grid.get_terrain_at(
		unit.grid_position
	)
	
	# Scorched ground takes priority over ordinary terrain details.
	# Lava tiles retain their existing lava decorations.
	if terrain == null or terrain.terrain_type != TerrainResource.TerrainType.LAVA:
		if battlefield_grid.is_adjacent_to_lava(unit.grid_position):
			add_scorched_ground_details(start_x, section_width)
			return

	# Special terrain will get its own ground decorations later.
	if terrain != null:
		match terrain.terrain_type:
			TerrainResource.TerrainType.FOREST:
				add_forest_ground_details(start_x, section_width)
				return

			TerrainResource.TerrainType.FORT:
				add_fort_ground_details(start_x, section_width)
				return

			TerrainResource.TerrainType.LAVA:
				add_lava_ground_details(start_x, section_width)
				return

	match battlefield_grid.biome:
		BattlefieldGrid.Biome.GRASSLAND:
			add_grassland_ground_details(start_x, section_width)

		BattlefieldGrid.Biome.DESERT:
			add_desert_ground_details(start_x, section_width)

		BattlefieldGrid.Biome.SNOW:
			add_snow_ground_details(start_x, section_width)

func add_scorched_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var crack_color := Color("#292725")
	var ash_color := Color("#75665b")

	# Short, irregular cracks across the scorched ground.
	for i in range(9):
		var x: float = start_x + 20.0 + float(i) * (section_width - 40.0) / 9.0
		var y: float = ground_y + 20.0 + float((i * 37) % 85)

		var crack := ColorRect.new()
		crack.color = crack_color
		crack.position = Vector2(x, y)
		crack.size = Vector2(18, 3)
		crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground_details.add_child(crack)

		var branch := ColorRect.new()
		branch.color = crack_color
		branch.position = Vector2(x + 12, y + 3)
		branch.size = Vector2(3, 9)
		branch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground_details.add_child(branch)

	# Scattered patches of pale volcanic ash.
	for i in range(14):
		var ash := ColorRect.new()
		ash.color = ash_color
		ash.size = Vector2(5 + (i % 3) * 3, 2)
		ash.position = Vector2(
			start_x + 12.0 + float((i * 53) % int(maxf(section_width - 24.0, 1.0))),
			ground_y + 12.0 + float((i * 29) % 100)
		)
		ash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground_details.add_child(ash)
		
		# Occasional glowing embers among the scorched earth.
	var ember_color := Color("#a65a32")

	for i in range(5):
		var ember_x: float = (
			start_x + 35.0
			+ float(i) * (section_width - 70.0) / 5.0
		)
		var ember_y: float = ground_y + 28.0 + float((i * 41) % 90)

		var ember := ColorRect.new()
		ember.color = ember_color
		ember.position = Vector2(ember_x, ember_y)
		ember.size = Vector2(5, 2)
		ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground_details.add_child(ember)

		# A smaller glowing fragment beside some embers.
		if i % 2 == 0:
			var fragment := ColorRect.new()
			fragment.color = Color("#c47a42")
			fragment.position = Vector2(ember_x + 7, ember_y + 3)
			fragment.size = Vector2(2, 2)
			fragment.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(fragment)

func add_grassland_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var grass_dark := Color("#355c32")
	var grass_light := Color("#91ad70")
	var flower_yellow := Color("#eadb84")
	var soil_color := Color("#526b46")

	# Scatter details in a predictable pattern.
	for i in range(14):
		var x: float = start_x + 15.0 + float(i) * (section_width - 30.0) / 14.0
		var y: float = ground_y + 18.0 + float((i * 17) % 65)

		# Small grass tufts.
		if i % 3 != 0:
			var grass := Line2D.new()
			grass.width = 2.0
			grass.default_color = grass_dark if i % 2 == 0 else grass_light
			grass.points = PackedVector2Array([
				Vector2(x - 4, y - 5),
				Vector2(x, y),
				Vector2(x + 4, y - 7)
			])
			ground_details.add_child(grass)

		# Occasional tiny flowers.
		if i % 5 == 0:
			var flower := ColorRect.new()
			flower.color = flower_yellow
			flower.position = Vector2(x + 5, y - 5)
			flower.size = Vector2(4, 4)
			flower.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(flower)

		# Sparse patches of exposed soil.
		if i % 4 == 0:
			var soil := ColorRect.new()
			soil.color = soil_color
			soil.position = Vector2(x - 9, y + 8)
			soil.size = Vector2(10, 2)
			soil.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(soil)


func add_desert_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var ripple_dark := Color("#9b805b")
	var ripple_light := Color("#e4cea3")
	var pebble_color := Color("#776650")

	for i in range(16):
		var x: float = start_x + 12.0 + float(i) * (section_width - 24.0) / 16.0
		var y: float = ground_y + 18.0 + float((i * 19) % 65)

		# Short horizontal marks suggest wind-shaped sand.
		if i % 3 != 0:
			var ripple := Line2D.new()
			ripple.width = 2.0
			ripple.default_color = ripple_dark if i % 2 == 0 else ripple_light
			ripple.points = PackedVector2Array([
				Vector2(x - 7.0, y),
				Vector2(x + 3.0, y),
				Vector2(x + 7.0, y - 2.0)
			])
			ground_details.add_child(ripple)

		# Occasional small stones.
		if i % 5 == 0:
			var pebble := ColorRect.new()
			pebble.color = pebble_color
			pebble.position = Vector2(x + 5.0, y + 6.0)
			pebble.size = Vector2(5.0, 3.0)
			pebble.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(pebble)

		# Tiny bright patches break up the flat sand colour.
		if i % 4 == 0:
			var highlight := ColorRect.new()
			highlight.color = ripple_light
			highlight.position = Vector2(x - 9.0, y + 10.0)
			highlight.size = Vector2(9.0, 2.0)
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(highlight)



func add_desert_sky_details() -> void:
	var haze_color := Color("#b7a6a0", 0.28)
	var cloud_color := Color("#dfc8ae", 0.65)
	var cloud_highlight := Color("#f0ddc2", 0.75)

	# Thin atmospheric haze bands.
	for i in range(4):
		var haze := ColorRect.new()
		haze.color = haze_color
		haze.position = Vector2(
			0.0,
			size.y * (0.24 + float(i) * 0.11)
		)
		haze.size = Vector2(size.x, 6.0 + float(i % 2) * 4.0)
		haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky_scenery.add_child(haze)

	# A few thin, stretched-out clouds.
	var cloud_positions: Array[Vector2] = [
		Vector2(size.x * 0.12, size.y * 0.15),
		Vector2(size.x * 0.48, size.y * 0.23),
		Vector2(size.x * 0.78, size.y * 0.12)
	]

	for cloud_position in cloud_positions:
		var cloud := Control.new()
		cloud.position = cloud_position
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky_scenery.add_child(cloud)

		var main := ColorRect.new()
		main.color = cloud_color
		main.position = Vector2.ZERO
		main.size = Vector2(110, 8)
		main.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.add_child(main)

		var upper := ColorRect.new()
		upper.color = cloud_highlight
		upper.position = Vector2(24, -5)
		upper.size = Vector2(55, 5)
		upper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.add_child(upper)

		var tail := ColorRect.new()
		tail.color = cloud_color
		tail.position = Vector2(70, 8)
		tail.size = Vector2(55, 4)
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.add_child(tail)


func get_battle_sky_color() -> Color:
	if battlefield_grid == null:
		return BACKGROUND_COLOR

	match battlefield_grid.biome:
		BattlefieldGrid.Biome.DESERT:
			return DESERT_SKY_COLOR

		BattlefieldGrid.Biome.SNOW:
			return SNOW_SKY_COLOR

		_:
			return BACKGROUND_COLOR


func add_forest_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var leaf_green := Color("#497b3e")
	var leaf_brown := Color("#99734b")
	var earth_dark := Color("#24472e")
	var grass_light := Color("#63925a")

	for i in range(18):
		var x: float = start_x + 12.0 + float(i) * (section_width - 24.0) / 18.0
		var y: float = ground_y + 15.0 + float((i * 23) % 70)

		# Fallen leaves.
		if i % 2 == 0:
			var leaf := ColorRect.new()
			leaf.color = leaf_green if i % 4 == 0 else leaf_brown
			leaf.position = Vector2(x, y)
			leaf.size = Vector2(6, 3)
			leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(leaf)

		# Small patches of exposed earth.
		if i % 5 == 0:
			var earth := ColorRect.new()
			earth.color = earth_dark
			earth.position = Vector2(x - 8, y + 7)
			earth.size = Vector2(14, 3)
			earth.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(earth)

		# Sparse forest grass.
		if i % 3 == 0:
			var grass := Line2D.new()
			grass.width = 2.0
			grass.default_color = grass_light
			grass.points = PackedVector2Array([
				Vector2(x - 4, y - 5),
				Vector2(x, y),
				Vector2(x + 4, y - 7)
			])
			ground_details.add_child(grass)

func add_fort_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var mortar_color := Color("#505966")
	var stone_light := Color("#89939e")
	var stone_dark := Color("#606a76")

	# Desert forts use sandstone-coloured masonry.
	if battlefield_grid.biome == BattlefieldGrid.Biome.DESERT:
		mortar_color = Color("#806747")
		stone_light = Color("#dfc69a")
		stone_dark = Color("#a8895e")
	
	# Snowy forts use cold, frost-covered stone.
	if battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
		mortar_color = Color("#667b89")
		stone_light = Color("#dce9f0")
		stone_dark = Color("#9fb5c3")
	
	var tile_width: float = 48.0
	var tile_height: float = 24.0

	var row_index := 0
	var y: float = ground_y + 12.0

	while y < size.y:
		# Horizontal mortar line.
		var horizontal := ColorRect.new()
		horizontal.color = mortar_color
		horizontal.position = Vector2(start_x, y)
		horizontal.size = Vector2(section_width, 2)
		horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground_details.add_child(horizontal)

		# Offset alternating rows to create a brick pattern.
		var offset: float = 0.0 if row_index % 2 == 0 else tile_width / 2.0
		var x: float = start_x + offset

		while x < start_x + section_width:
			var vertical := ColorRect.new()
			vertical.color = mortar_color
			vertical.position = Vector2(x, y)
			vertical.size = Vector2(2, tile_height)
			vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(vertical)

			x += tile_width

		y += tile_height
		row_index += 1

	# Subtle stone highlights and weathering.
	for i in range(12):
		var x: float = start_x + 14.0 + float((i * 43) % int(maxf(section_width - 28.0, 1.0)))
		var detail_y: float = ground_y + 20.0 + float((i * 29) % 85)

		var detail := ColorRect.new()
		detail.color = stone_light if i % 3 == 0 else stone_dark
		detail.position = Vector2(x, detail_y)
		detail.size = Vector2(12, 3)
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground_details.add_child(detail)

func style_battle_status_panels() -> void:
	
	enemy_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for panel in [enemy_info, player_info]:
		panel.add_theme_stylebox_override(
			"panel",
			GameUIStyle.make_panel_style()
		)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for label in [enemy_name, player_name]:
		GameUIStyle.style_label(label, 18)

	for label in [enemy_weapon, player_weapon]:
		GameUIStyle.style_label(label, 14, true)

	for label in [enemy_hp_label, player_hp_label]:
		GameUIStyle.style_label(label, 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	for label in [enemy_level, player_level]:
		GameUIStyle.style_label(label, 13, true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	for hp_bar in [enemy_hp_bar, player_hp_bar]:
		hp_bar.show_percentage = false
		hp_bar.custom_minimum_size.y = 12

		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = GameUIStyle.HEALTH
		fill_style.set_corner_radius_all(3)

		var background_style := StyleBoxFlat.new()
		background_style.bg_color = GameUIStyle.BACKGROUND
		background_style.set_corner_radius_all(3)

		hp_bar.add_theme_stylebox_override("fill", fill_style)
		hp_bar.add_theme_stylebox_override("background", background_style)


func add_lava_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var crack_dark := Color("#392a2b")
	var lava_orange := Color("#ff762b")
	var lava_yellow := Color("#ffb347")
	var ash_color := Color("#68413a")

	for i in range(12):
		var x: float = start_x + 18.0 + float(i) * (section_width - 36.0) / 12.0
		var y: float = ground_y + 20.0 + float((i * 19) % 65)

		# Jagged cracks across the volcanic ground.
		var crack := Line2D.new()
		crack.width = 3.0
		crack.default_color = crack_dark
		crack.points = PackedVector2Array([
			Vector2(x - 10.0, y),
			Vector2(x - 3.0, y + 4.0),
			Vector2(x + 5.0, y - 2.0),
			Vector2(x + 13.0, y + 3.0)
		])
		ground_details.add_child(crack)

		# Some cracks have molten lava showing through.
		if i % 3 == 0:
			var fissure := Line2D.new()
			fissure.width = 2.0
			fissure.default_color = lava_orange
			fissure.points = crack.points
			ground_details.add_child(fissure)

			var hotspot := ColorRect.new()
			hotspot.color = lava_yellow
			hotspot.position = Vector2(x + 3.0, y - 3.0)
			hotspot.size = Vector2(5.0, 3.0)
			hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(hotspot)

		# Small scattered patches of volcanic ash.
		if i % 4 == 0:
			var ash := ColorRect.new()
			ash.color = ash_color
			ash.position = Vector2(x - 8.0, y + 10.0)
			ash.size = Vector2(12.0, 3.0)
			ash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(ash)



func add_snow_scenery(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	# Distant snow-covered hills.
	var hills := Polygon2D.new()
	hills.color = Color("#b2c9d7")
	hills.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x, ground_y - 20.0),
		Vector2(start_x + section_width * 0.22, ground_y - 75.0),
		Vector2(start_x + section_width * 0.48, ground_y - 35.0),
		Vector2(start_x + section_width * 0.76, ground_y - 90.0),
		Vector2(start_x + section_width, ground_y - 25.0),
		Vector2(start_x + section_width, ground_y)
	])
	terrain_scenery.add_child(hills)



func add_snow_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var snow_highlight := Color("#f0f6fa")
	var snow_shadow := Color("#b8cad6")
	var ice_color := Color("#a8d0df")

	for i in range(12):
		var x: float = start_x + 18.0 + float(i) * (section_width - 36.0) / 12.0
		var y: float = ground_y + 18.0 + float((i * 23) % 65)

		# Small wind-shaped snowdrifts.
		if i % 2 == 0:
			var drift := Line2D.new()
			drift.width = 3.0
			drift.default_color = snow_highlight
			drift.points = PackedVector2Array([
				Vector2(x - 12.0, y + 2.0),
				Vector2(x - 4.0, y),
				Vector2(x + 6.0, y),
				Vector2(x + 12.0, y + 2.0)
			])
			ground_details.add_child(drift)

			var shadow := ColorRect.new()
			shadow.color = snow_shadow
			shadow.position = Vector2(x - 5.0, y + 5.0)
			shadow.size = Vector2(12.0, 2.0)
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(shadow)

		# Occasional small patches of exposed ice.
		if i % 4 == 1:
			var ice := ColorRect.new()
			ice.color = ice_color
			ice.position = Vector2(x - 8.0, y + 6.0)
			ice.size = Vector2(16.0, 4.0)
			ice.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(ice)

			var reflection := ColorRect.new()
			reflection.color = snow_highlight
			reflection.position = Vector2(3.0, 1.0)
			reflection.size = Vector2(6.0, 1.0)
			reflection.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ice.add_child(reflection)

		# Tiny scattered snow flecks.
		if i % 3 == 0:
			var fleck := ColorRect.new()
			fleck.color = snow_highlight
			fleck.position = Vector2(x + 9.0, y + 12.0)
			fleck.size = Vector2(4.0, 2.0)
			fleck.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ground_details.add_child(fleck)





func animate_defeat(unit: Unit) -> void:
	var sprite: ColorRect = (
		player_sprite
		if unit.team == Unit.Team.PLAYER
		else enemy_sprite
	)

	# Find the visible character artwork.
	var art: CanvasItem = null

	for child in sprite.get_children():
		if child is CanvasItem and child.visible:
			art = child
			break

	# Give the character one final red flash before disappearing.
	if art != null:
		var original_modulate: Color = art.modulate

		var flash_tween := create_tween()

		flash_tween.tween_property(
			art,
			"modulate",
			Color(1.0, 0.25, 0.25, 1.0),
			0.10
		)

		flash_tween.tween_property(
			art,
			"modulate",
			original_modulate,
			0.12
		)

		await flash_tween.finished

	# Fade and sink the defeated character.
	var starting_position: Vector2 = sprite.position

	var defeat_tween := create_tween()
	defeat_tween.set_parallel(true)

	defeat_tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		0.55
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	defeat_tween.tween_property(
		sprite,
		"position:y",
		starting_position.y + 28.0,
		0.55
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await defeat_tween.finished

	# Restore the position for the next battle.
	# The alpha is restored by setup_battle().
	sprite.position = starting_position





func setup_combat_swordsman_art() -> void:
	for sprite in [player_sprite, enemy_sprite]:
		var is_player: bool = sprite == player_sprite
		var color: Color = (
			PLAYER_COLOR if is_player else ENEMY_COLOR
		)

		var swordsman_art := CombatSwordsmanArt.new()
		swordsman_art.name = "SwordsmanArt"
		swordsman_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swordsman_art.team_color = color
		swordsman_art.facing_left = is_player
		swordsman_art.visible = false
		sprite.add_child(swordsman_art)

		var fighter_art := CombatFighterArt.new()
		fighter_art.name = "FighterArt"
		fighter_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fighter_art.team_color = color
		fighter_art.facing_left = is_player
		fighter_art.visible = false
		sprite.add_child(fighter_art)

		var knight_art := CombatKnightArt.new()
		knight_art.name = "KnightArt"
		knight_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		knight_art.team_color = color
		knight_art.facing_left = is_player
		knight_art.visible = false
		sprite.add_child(knight_art)

		var archer_art := CombatArcherArt.new()
		archer_art.name = "ArcherArt"
		archer_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		archer_art.team_color = color
		archer_art.facing_left = is_player
		archer_art.visible = false
		sprite.add_child(archer_art)






func update_combat_character_art() -> void:
	var combat_sprites := [
		{"sprite": player_sprite, "unit": player_unit},
		{"sprite": enemy_sprite, "unit": enemy_unit}
	]

	for entry in combat_sprites:
		var sprite: ColorRect = entry["sprite"]
		var unit: Unit = entry["unit"]

		var swordsman_art: CombatSwordsmanArt = sprite.get_node(
			"SwordsmanArt"
		)

		var fighter_art: CombatFighterArt = sprite.get_node(
			"FighterArt"
		)

		var knight_art: CombatKnightArt = sprite.get_node(
			"KnightArt"
		)

		var archer_art: CombatArcherArt = sprite.get_node(
			"ArcherArt"
		)

		var class_name_text := ""

		if (
			unit != null
			and unit.unit_data != null
			and unit.unit_data.unit_class != null
		):
			class_name_text = (
				unit.unit_data.unit_class.class_name_display.to_lower()
			)

		var is_swordsman := class_name_text == "swordsman"
		var is_fighter := class_name_text == "fighter"
		var is_knight := class_name_text == "knight"
		var is_archer := class_name_text == "archer"

		swordsman_art.visible = is_swordsman
		fighter_art.visible = is_fighter
		knight_art.visible = is_knight
		archer_art.visible = is_archer

		if is_swordsman or is_fighter or is_knight or is_archer:
			sprite.color = Color.TRANSPARENT
		else:
			sprite.color = (
				PLAYER_COLOR if sprite == player_sprite else ENEMY_COLOR
			)



func animate_swordsman_windup(
	art: CombatSwordsmanArt,
	direction: float
) -> void:
	art.pivot_offset = SPRITE_SIZE * 0.5
	art.position = Vector2.ZERO
	art.rotation = 0.0

	var windup_tween := create_tween()
	windup_tween.set_parallel(true)

	# Lean backward in preparation for the slash.
	windup_tween.tween_property(
		art,
		"rotation",
		-direction * 0.22,
		0.14
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	windup_tween.tween_property(
		art,
		"position:x",
		-direction * 6.0,
		0.14
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await windup_tween.finished


func animate_swordsman_slash(
	art: CombatSwordsmanArt,
	direction: float
) -> void:
	var slash_tween := create_tween()
	slash_tween.set_parallel(true)

	# Snap forward into the strike.
	slash_tween.tween_property(
		art,
		"rotation",
		direction * 0.32,
		0.11
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	slash_tween.tween_property(
		art,
		"position:x",
		direction * 8.0,
		0.11
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Recover to the original standing pose.
	slash_tween.chain().tween_property(
		art,
		"rotation",
		0.0,
		0.20
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	slash_tween.tween_property(
		art,
		"position",
		Vector2.ZERO,
		0.20
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)




func animate_fighter_windup(
	art: CombatFighterArt,
	direction: float
) -> void:
	art.pivot_offset = SPRITE_SIZE * 0.5
	art.position = Vector2.ZERO
	art.rotation = 0.0

	var windup_tween := create_tween()
	windup_tween.set_parallel(true)

	# The fighter leans back farther than the swordsman,
	# lifting the axe in preparation for a heavy chop.
	windup_tween.tween_property(
		art,
		"rotation",
		-direction * 0.38,
		0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	windup_tween.tween_property(
		art,
		"position",
		Vector2(-direction * 7.0, -4.0),
		0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await windup_tween.finished


func animate_fighter_chop(
	art: CombatFighterArt,
	direction: float
) -> void:
	var chop_tween := create_tween()
	chop_tween.set_parallel(true)

	# A forceful downward chop.
	# The larger rotation and vertical drop distinguish
	# the fighter from the swordsman's quick slash.
	chop_tween.tween_property(
		art,
		"rotation",
		direction * 0.48,
		0.14
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	chop_tween.tween_property(
		art,
		"position",
		Vector2(direction * 10.0, 7.0),
		0.14
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Slower recovery makes the weapon feel heavier.
	chop_tween.chain().tween_property(
		art,
		"rotation",
		0.0,
		0.30
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	chop_tween.tween_property(
		art,
		"position",
		Vector2.ZERO,
		0.30
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
	

func animate_knight_windup(
	art: CombatKnightArt,
	direction: float
) -> void:
	art.pivot_offset = SPRITE_SIZE * 0.5
	art.position = Vector2.ZERO
	art.rotation = 0.0

	var windup_tween := create_tween()

	# Draw straight backward to prepare the thrust.
	windup_tween.tween_property(
		art,
		"position:x",
		-direction * 16.0,
		0.22
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await windup_tween.finished


func animate_knight_thrust(
	art: CombatKnightArt,
	direction: float
) -> void:
	var thrust_tween := create_tween()

	# Explosive straight-line thrust.
	thrust_tween.tween_property(
		art,
		"position:x",
		direction * 28.0,
		0.09
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Brief pause at full extension.
	thrust_tween.tween_interval(0.08)

	# Controlled withdrawal.
	thrust_tween.tween_property(
		art,
		"position:x",
		0.0,
		0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func animate_archer_draw(
	art: CombatArcherArt,
	direction: float
) -> void:
	art.position = Vector2.ZERO
	art.rotation = 0.0

	var draw_tween := create_tween()

	# Pull backward as though drawing the bowstring.
	draw_tween.tween_property(
		art,
		"position:x",
		-direction * 7.0,
		0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hold the drawn bow for a moment.
	draw_tween.tween_interval(0.12)

	await draw_tween.finished


func animate_archer_release(
	art: CombatArcherArt,
	direction: float
) -> void:
	var release_tween := create_tween()

	# Snap forward as the bowstring releases.
	release_tween.tween_property(
		art,
		"position:x",
		direction * 3.0,
		0.06
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	release_tween.tween_property(
		art,
		"position",
		Vector2.ZERO,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await release_tween.finished


func animate_archer_arrow(
	attacking_sprite: ColorRect,
	defending_sprite: ColorRect,
	direction: float
) -> void:
	# Determine arrow positions in the overlay's local coordinates.
	var start_point: Vector2 = (
		attacking_sprite.position
		+ Vector2(
			SPRITE_SIZE.x * 0.5 + direction * 26.0,
			SPRITE_SIZE.y * 0.46
		)
	)

	var end_point: Vector2 = (
		defending_sprite.position
		+ Vector2(
			SPRITE_SIZE.x * 0.5 - direction * 12.0,
			SPRITE_SIZE.y * 0.46
		)
	)

	# Create a temporary node for the projectile.
	var arrow := Node2D.new()
	arrow.name = "CombatArrow"
	arrow.position = start_point
	arrow.z_index = 10
	add_child(arrow)

	# Wooden shaft.
	var shaft := Polygon2D.new()
	shaft.color = Color("#8b5a35")
	shaft.polygon = PackedVector2Array([
		Vector2(-direction * 18.0, -2.0),
		Vector2(direction * 12.0, -2.0),
		Vector2(direction * 12.0, 2.0),
		Vector2(-direction * 18.0, 2.0)
	])
	arrow.add_child(shaft)

	# Metal arrowhead.
	var head := Polygon2D.new()
	head.color = Color("#d5dce4")
	head.polygon = PackedVector2Array([
		Vector2(direction * 12.0, -5.0),
		Vector2(direction * 24.0, 0.0),
		Vector2(direction * 12.0, 5.0)
	])
	arrow.add_child(head)

	# Upper feather.
	var upper_feather := Polygon2D.new()
	upper_feather.color = Color("#e8e0c9")
	upper_feather.polygon = PackedVector2Array([
		Vector2(-direction * 18.0, 0.0),
		Vector2(-direction * 24.0, -7.0),
		Vector2(-direction * 12.0, -2.0)
	])
	arrow.add_child(upper_feather)

	# Lower feather.
	var lower_feather := Polygon2D.new()
	lower_feather.color = Color("#c9b99a")
	lower_feather.polygon = PackedVector2Array([
		Vector2(-direction * 18.0, 0.0),
		Vector2(-direction * 24.0, 7.0),
		Vector2(-direction * 12.0, 2.0)
	])
	arrow.add_child(lower_feather)

	# Fly straight toward the defender.
	var flight_tween := create_tween()

	flight_tween.tween_property(
		arrow,
		"position",
		end_point,
		0.28
	).set_trans(Tween.TRANS_LINEAR)

	await flight_tween.finished

	# Remove the projectile when it reaches the defender.
	arrow.queue_free()
