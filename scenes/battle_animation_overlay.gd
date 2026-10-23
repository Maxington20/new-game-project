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
						return GROUND_COLOR

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

	var enemy_terrain: TerrainResource = battlefield_grid.get_terrain_at(
		enemy_unit.grid_position
	)
	var player_terrain: TerrainResource = battlefield_grid.get_terrain_at(
		player_unit.grid_position
	)

	var enemy_is_grassland: bool = (
		battlefield_grid.biome == BattlefieldGrid.Biome.GRASSLAND
		and (enemy_terrain == null
			or enemy_terrain.terrain_type not in [
				TerrainResource.TerrainType.FOREST,
				TerrainResource.TerrainType.FORT,
				TerrainResource.TerrainType.LAVA
			])
		and not battlefield_grid.is_adjacent_to_lava(
			enemy_unit.grid_position
		)
	)

	var player_is_grassland: bool = (
		battlefield_grid.biome == BattlefieldGrid.Biome.GRASSLAND
		and (player_terrain == null
			or player_terrain.terrain_type not in [
				TerrainResource.TerrainType.FOREST,
				TerrainResource.TerrainType.FORT,
				TerrainResource.TerrainType.LAVA
			])
		and not battlefield_grid.is_adjacent_to_lava(
			player_unit.grid_position
		)
	)

	if enemy_is_grassland and player_is_grassland:
		add_grassland_scenery(0.0, size.x)
		return

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

	# Desert forests use their existing palm-tree scenery.
	if battlefield_grid.biome == BattlefieldGrid.Biome.DESERT:
		add_desert_forest_scenery(center)
		return

	var is_snow: bool = (
		battlefield_grid.biome == BattlefieldGrid.Biome.SNOW
	)

	var outline := Color("#292b35")

	var trunk_base := Color("#765139")
	var trunk_light := Color("#a47a51")
	var trunk_dark := Color("#49382f")

	var foliage_base := Color("#327447")
	var foliage_light := Color("#5b9c62")
	var foliage_dark := Color("#1c4c34")

	if is_snow:
		foliage_base = Color("#38665a")
		foliage_light = Color("#668e80")
		foliage_dark = Color("#24483f")

	var tree_data: Array[Dictionary] = [
		{"offset": -110.0, "height": 75.0},
		{"offset": -55.0, "height": 95.0},
		{"offset": 55.0, "height": 85.0},
		{"offset": 110.0, "height": 70.0}
	]

	for data in tree_data:
		var tree_height: float = float(data["height"])
		var tree_x: float = center.x + float(data["offset"])

		# All shapes are positioned relative to the tree's base.
		var tree := Node2D.new()
		tree.position = Vector2(tree_x + 17.0, ground_y)
		terrain_scenery.add_child(tree)

		# Small ground shadow.
		var ground_shadow := Polygon2D.new()
		ground_shadow.polygon = PackedVector2Array([
			Vector2(-18, -2),
			Vector2(-11, -5),
			Vector2(12, -5),
			Vector2(21, -2),
			Vector2(15, 1),
			Vector2(-14, 1)
		])
		ground_shadow.color = Color(0, 0, 0, 0.22)
		tree.add_child(ground_shadow)

		# Trunk silhouette.
		var trunk_outline := Polygon2D.new()
		trunk_outline.polygon = PackedVector2Array([
			Vector2(-7, -31),
			Vector2(6, -31),
			Vector2(7, -2),
			Vector2(-8, -2)
		])
		trunk_outline.color = outline
		tree.add_child(trunk_outline)

		# Main trunk.
		var trunk := Polygon2D.new()
		trunk.polygon = PackedVector2Array([
			Vector2(-5, -29),
			Vector2(4, -29),
			Vector2(5, -4),
			Vector2(-6, -4)
		])
		trunk.color = trunk_base
		tree.add_child(trunk)

		# Trunk highlight.
		var trunk_highlight := Polygon2D.new()
		trunk_highlight.polygon = PackedVector2Array([
			Vector2(-5, -29),
			Vector2(-2, -29),
			Vector2(-2, -5),
			Vector2(-5, -5)
		])
		trunk_highlight.color = trunk_light
		tree.add_child(trunk_highlight)

		# Trunk shadow.
		var trunk_shadow := Polygon2D.new()
		trunk_shadow.polygon = PackedVector2Array([
			Vector2(2, -29),
			Vector2(4, -29),
			Vector2(5, -4),
			Vector2(1, -4)
		])
		trunk_shadow.color = trunk_dark
		tree.add_child(trunk_shadow)

		# A couple of bark marks.
		for bark_y in [-19.0, -11.0]:
			var bark := Line2D.new()
			bark.width = 1.5
			bark.default_color = trunk_dark
			bark.points = PackedVector2Array([
				Vector2(-3, bark_y),
				Vector2(1, bark_y + 2)
			])
			tree.add_child(bark)

		# Main foliage silhouette.
		# The angular canopy keeps the same approximate
		# height and width as the original tree.
		var top_y: float = -tree_height

		var canopy_outline := Polygon2D.new()
		canopy_outline.polygon = PackedVector2Array([
			Vector2(-16, -18),
			Vector2(-20, -28),
			Vector2(-17, -39),
			Vector2(-21, -47),
			Vector2(-15, -57),
			Vector2(-12, top_y + 12),
			Vector2(-5, top_y + 4),
			Vector2(2, top_y),
			Vector2(10, top_y + 5),
			Vector2(15, top_y + 14),
			Vector2(18, -49),
			Vector2(22, -39),
			Vector2(18, -30),
			Vector2(20, -20),
			Vector2(11, -16),
			Vector2(-8, -16)
		])
		canopy_outline.color = outline
		tree.add_child(canopy_outline)

		# Main foliage fill.
		var canopy := Polygon2D.new()
		canopy.polygon = PackedVector2Array([
			Vector2(-14, -20),
			Vector2(-18, -29),
			Vector2(-15, -39),
			Vector2(-19, -47),
			Vector2(-13, -56),
			Vector2(-10, top_y + 13),
			Vector2(-4, top_y + 6),
			Vector2(2, top_y + 3),
			Vector2(8, top_y + 7),
			Vector2(13, top_y + 15),
			Vector2(16, -48),
			Vector2(20, -39),
			Vector2(16, -30),
			Vector2(18, -22),
			Vector2(10, -18),
			Vector2(-7, -18)
		])
		canopy.color = foliage_base
		tree.add_child(canopy)

		# Hard-edged shaded right side.
		var canopy_shadow := Polygon2D.new()
		canopy_shadow.polygon = PackedVector2Array([
			Vector2(3, top_y + 5),
			Vector2(8, top_y + 7),
			Vector2(13, top_y + 15),
			Vector2(16, -48),
			Vector2(20, -39),
			Vector2(16, -30),
			Vector2(18, -22),
			Vector2(10, -18),
			Vector2(1, -18),
			Vector2(6, -33),
			Vector2(3, -47)
		])
		canopy_shadow.color = foliage_dark
		tree.add_child(canopy_shadow)

		# Upper-left foliage highlight.
		var canopy_highlight := Polygon2D.new()
		canopy_highlight.polygon = PackedVector2Array([
			Vector2(-10, top_y + 14),
			Vector2(-4, top_y + 7),
			Vector2(1, top_y + 5),
			Vector2(4, top_y + 13),
			Vector2(-3, top_y + 23),
			Vector2(-13, top_y + 28),
			Vector2(-15, top_y + 22)
		])
		canopy_highlight.color = foliage_light
		tree.add_child(canopy_highlight)

		# Secondary highlight on the lower foliage.
		var lower_highlight := Polygon2D.new()
		lower_highlight.polygon = PackedVector2Array([
			Vector2(-15, -39),
			Vector2(-9, -44),
			Vector2(-2, -40),
			Vector2(-5, -33),
			Vector2(-13, -30)
		])
		lower_highlight.color = foliage_light
		tree.add_child(lower_highlight)

		# Snow-covered trees get angular snow patches
		# rather than flat rectangular caps.
		if is_snow:
			var snow_shadow := Color("#b7ceda")
			var snow_light := Color("#edf5f8")

			var upper_snow := Polygon2D.new()
			upper_snow.polygon = PackedVector2Array([
				Vector2(-10, top_y + 14),
				Vector2(-4, top_y + 6),
				Vector2(2, top_y + 3),
				Vector2(8, top_y + 8),
				Vector2(11, top_y + 15),
				Vector2(3, top_y + 13),
				Vector2(-2, top_y + 17),
				Vector2(-8, top_y + 19)
			])
			upper_snow.color = snow_light
			tree.add_child(upper_snow)

			var lower_snow := Polygon2D.new()
			lower_snow.polygon = PackedVector2Array([
				Vector2(-17, -47),
				Vector2(-11, -51),
				Vector2(-5, -47),
				Vector2(2, -48),
				Vector2(8, -44),
				Vector2(13, -46),
				Vector2(17, -41),
				Vector2(10, -40),
				Vector2(4, -43),
				Vector2(-4, -40),
				Vector2(-12, -42)
			])
			lower_snow.color = snow_shadow
			tree.add_child(lower_snow)

			var snow_highlight := Polygon2D.new()
			snow_highlight.polygon = PackedVector2Array([
				Vector2(-15, -47),
				Vector2(-11, -50),
				Vector2(-5, -47),
				Vector2(1, -47),
				Vector2(-5, -44),
				Vector2(-12, -45)
			])
			snow_highlight.color = snow_light
			tree.add_child(snow_highlight)



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
	var end_x: float = start_x + section_width

	var outline := Color("#292b35")
	var stone_base := Color("#647381")
	var stone_light := Color("#8999a7")
	var stone_dark := Color("#465460")
	var mortar := Color("#35404c")

	if battlefield_grid.biome == BattlefieldGrid.Biome.DESERT:
		stone_base = Color("#b89a6b")
		stone_light = Color("#dfc69a")
		stone_dark = Color("#8b704e")
		mortar = Color("#806747")

	elif battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
		stone_base = Color("#879eac")
		stone_light = Color("#b6cbd6")
		stone_dark = Color("#607888")
		mortar = Color("#4c6373")

	# Main wall silhouette.
	var wall_outline := Polygon2D.new()
	wall_outline.polygon = PackedVector2Array([
		Vector2(start_x, wall_top - 3),
		Vector2(end_x, wall_top - 3),
		Vector2(end_x, ground_y),
		Vector2(start_x, ground_y)
	])
	wall_outline.color = outline
	terrain_scenery.add_child(wall_outline)

	# Main wall face.
	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([
		Vector2(start_x + 2, wall_top),
		Vector2(end_x - 2, wall_top),
		Vector2(end_x - 2, ground_y),
		Vector2(start_x + 2, ground_y)
	])
	wall.color = stone_base
	terrain_scenery.add_child(wall)

	# Hard-edged light and shadow regions.
	var wall_highlight := Polygon2D.new()
	wall_highlight.polygon = PackedVector2Array([
		Vector2(start_x + 3, wall_top + 3),
		Vector2(end_x - 3, wall_top + 3),
		Vector2(end_x - 3, wall_top + 13),
		Vector2(start_x + 3, wall_top + 17)
	])
	wall_highlight.color = stone_light
	terrain_scenery.add_child(wall_highlight)

	var wall_shadow := Polygon2D.new()
	wall_shadow.polygon = PackedVector2Array([
		Vector2(end_x - 19, wall_top + 16),
		Vector2(end_x - 2, wall_top + 13),
		Vector2(end_x - 2, ground_y),
		Vector2(end_x - 28, ground_y)
	])
	wall_shadow.color = stone_dark
	terrain_scenery.add_child(wall_shadow)

	# Three staggered courses of masonry.
	for row in range(1, 4):
		var y: float = wall_top + float(row) * 30.0

		var horizontal := Line2D.new()
		horizontal.width = 3.0
		horizontal.default_color = mortar
		horizontal.points = PackedVector2Array([
			Vector2(start_x + 2, y),
			Vector2(end_x - 2, y)
		])
		terrain_scenery.add_child(horizontal)

		# Offset the vertical joints between courses.
		var joint_spacing: float = 64.0
		var offset: float = 32.0 if row % 2 == 0 else 0.0
		var joint_x: float = start_x + offset + joint_spacing

		while joint_x < end_x - 3:
			var joint := Line2D.new()
			joint.width = 2.0
			joint.default_color = mortar
			joint.points = PackedVector2Array([
				Vector2(joint_x, y - 29),
				Vector2(joint_x, y)
			])
			terrain_scenery.add_child(joint)

			joint_x += joint_spacing

		# Sparse highlights on individual stones.
		var highlight_x: float = start_x + 13.0 + offset
		while highlight_x < end_x - 24:
			var stone_mark := Polygon2D.new()
			stone_mark.polygon = PackedVector2Array([
				Vector2(highlight_x, y - 23),
				Vector2(highlight_x + 19, y - 23),
				Vector2(highlight_x + 14, y - 20),
				Vector2(highlight_x, y - 20)
			])
			stone_mark.color = stone_light
			terrain_scenery.add_child(stone_mark)
			highlight_x += 128.0

	# Battlements retain the original size, count and spacing.
	var block_width: float = 42.0
	var block_gap: float = 22.0
	var block_count: int = floori(
		section_width / (block_width + block_gap)
	)

	for i in range(block_count):
		var x: float = (
			start_x
			+ float(i) * (block_width + block_gap)
			+ 10.0
		)
		var y: float = wall_top - 24.0

		# Dark battlement silhouette.
		var battlement_outline := Polygon2D.new()
		battlement_outline.polygon = PackedVector2Array([
			Vector2(x - 2, wall_top + 2),
			Vector2(x - 2, y + 2),
			Vector2(x + 2, y - 2),
			Vector2(x + block_width - 3, y - 2),
			Vector2(x + block_width + 2, y + 2),
			Vector2(x + block_width + 2, wall_top + 2)
		])
		battlement_outline.color = outline
		terrain_scenery.add_child(battlement_outline)

		# Main stone block.
		var battlement := Polygon2D.new()
		battlement.polygon = PackedVector2Array([
			Vector2(x, wall_top),
			Vector2(x, y + 3),
			Vector2(x + 3, y),
			Vector2(x + block_width - 4, y),
			Vector2(x + block_width, y + 3),
			Vector2(x + block_width, wall_top)
		])
		battlement.color = stone_base
		terrain_scenery.add_child(battlement)

		# Bright top and left face.
		var battlement_light := Polygon2D.new()
		battlement_light.polygon = PackedVector2Array([
			Vector2(x + 2, y + 4),
			Vector2(x + 4, y + 2),
			Vector2(x + block_width - 5, y + 2),
			Vector2(x + block_width - 8, y + 7),
			Vector2(x + 7, y + 7),
			Vector2(x + 7, wall_top - 2),
			Vector2(x + 2, wall_top - 2)
		])
		battlement_light.color = stone_light
		terrain_scenery.add_child(battlement_light)

		# Dark right face.
		var battlement_shadow := Polygon2D.new()
		battlement_shadow.polygon = PackedVector2Array([
			Vector2(x + block_width - 9, y + 7),
			Vector2(x + block_width - 2, y + 4),
			Vector2(x + block_width - 2, wall_top),
			Vector2(x + block_width - 12, wall_top)
		])
		battlement_shadow.color = stone_dark
		terrain_scenery.add_child(battlement_shadow)

		# Small masonry joint.
		var joint := Line2D.new()
		joint.width = 2.0
		joint.default_color = mortar
		joint.points = PackedVector2Array([
			Vector2(x + 17, wall_top - 1),
			Vector2(x + 17, wall_top - 10)
		])
		terrain_scenery.add_child(joint)

		# Snow caps remain restricted to snowy forts.
		if battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
			var snow_shadow := Polygon2D.new()
			snow_shadow.polygon = PackedVector2Array([
				Vector2(x + 1, y + 1),
				Vector2(x + block_width - 1, y + 1),
				Vector2(x + block_width - 3, y + 8),
				Vector2(x + 26, y + 6),
				Vector2(x + 18, y + 10),
				Vector2(x + 8, y + 6),
				Vector2(x + 2, y + 8)
			])
			snow_shadow.color = Color("#b7ceda")
			terrain_scenery.add_child(snow_shadow)

			var snow_light := Polygon2D.new()
			snow_light.polygon = PackedVector2Array([
				Vector2(x + 2, y + 1),
				Vector2(x + block_width - 3, y + 1),
				Vector2(x + block_width - 7, y + 4),
				Vector2(x + 20, y + 5),
				Vector2(x + 9, y + 4)
			])
			snow_light.color = Color("#edf5f8")
			terrain_scenery.add_child(snow_light)

	# Snow along the exposed sections between battlements.
	if battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
		for i in range(block_count):
			var gap_x: float = (
				start_x
				+ float(i) * (block_width + block_gap)
				+ 10.0
				+ block_width
			)
			var gap_end: float = minf(gap_x + block_gap, end_x)

			if gap_end > gap_x:
				var snow_between := Polygon2D.new()
				snow_between.polygon = PackedVector2Array([
					Vector2(gap_x, wall_top),
					Vector2(gap_end, wall_top),
					Vector2(gap_end - 2, wall_top + 5),
					Vector2(gap_x + 2, wall_top + 5)
				])
				snow_between.color = Color("#dce9f0")
				terrain_scenery.add_child(snow_between)




func add_lava_scenery(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	var end_x: float = start_x + section_width

	var outline := Color("#292b35")
	var rock_base := Color("#51454a")
	var rock_light := Color("#766268")
	var rock_dark := Color("#302c34")
	var lava_dark := Color("#9d3025")
	var lava_base := Color("#f15a24")
	var lava_light := Color("#ffad42")
	var lava_hot := Color("#ffe08a")

	# Four volcanic mountains.
	for i in range(4):
		var mountain_x: float = (
			start_x + section_width * (float(i) + 0.5) / 4.0
		)
		var mountain_width: float = section_width / 3.0
		var mountain_height: float = 90.0 + float(i % 2) * 35.0
		var half_width: float = mountain_width / 2.0
		var peak_y: float = ground_y - mountain_height

		var silhouette := Polygon2D.new()
		silhouette.polygon = PackedVector2Array([
			Vector2(mountain_x - half_width, ground_y),
			Vector2(mountain_x - half_width * 0.67, ground_y - mountain_height * 0.37),
			Vector2(mountain_x - half_width * 0.32, ground_y - mountain_height * 0.62),
			Vector2(mountain_x - 8, peak_y + 9),
			Vector2(mountain_x + 3, peak_y),
			Vector2(mountain_x + 17, peak_y + 12),
			Vector2(mountain_x + half_width * 0.58, ground_y - mountain_height * 0.43),
			Vector2(mountain_x + half_width, ground_y)
		])
		silhouette.color = outline
		terrain_scenery.add_child(silhouette)

		var mountain := Polygon2D.new()
		mountain.polygon = PackedVector2Array([
			Vector2(mountain_x - half_width + 4, ground_y),
			Vector2(mountain_x - half_width * 0.63, ground_y - mountain_height * 0.36),
			Vector2(mountain_x - half_width * 0.29, ground_y - mountain_height * 0.60),
			Vector2(mountain_x - 5, peak_y + 12),
			Vector2(mountain_x + 3, peak_y + 5),
			Vector2(mountain_x + 14, peak_y + 15),
			Vector2(mountain_x + half_width * 0.55, ground_y - mountain_height * 0.41),
			Vector2(mountain_x + half_width - 4, ground_y)
		])
		mountain.color = rock_base
		terrain_scenery.add_child(mountain)

		var lit_face := Polygon2D.new()
		lit_face.polygon = PackedVector2Array([
			Vector2(mountain_x - half_width + 4, ground_y),
			Vector2(mountain_x - half_width * 0.63, ground_y - mountain_height * 0.36),
			Vector2(mountain_x - half_width * 0.29, ground_y - mountain_height * 0.60),
			Vector2(mountain_x - 5, peak_y + 12),
			Vector2(mountain_x - 15, ground_y - mountain_height * 0.34),
			Vector2(mountain_x - half_width * 0.18, ground_y)
		])
		lit_face.color = rock_light
		terrain_scenery.add_child(lit_face)

		var shaded_face := Polygon2D.new()
		shaded_face.polygon = PackedVector2Array([
			Vector2(mountain_x + 3, peak_y + 5),
			Vector2(mountain_x + 14, peak_y + 15),
			Vector2(mountain_x + half_width * 0.55, ground_y - mountain_height * 0.41),
			Vector2(mountain_x + half_width - 4, ground_y),
			Vector2(mountain_x + 5, ground_y - 5),
			Vector2(mountain_x - 4, ground_y - mountain_height * 0.42)
		])
		shaded_face.color = rock_dark
		terrain_scenery.add_child(shaded_face)

		var fracture := Line2D.new()
		fracture.width = 2.0
		fracture.default_color = outline
		fracture.points = PackedVector2Array([
			Vector2(mountain_x - 5, peak_y + 23),
			Vector2(mountain_x + 3, peak_y + 37),
			Vector2(mountain_x - 2, peak_y + 49)
		])
		terrain_scenery.add_child(fracture)

		var mineral := Polygon2D.new()
		mineral.polygon = PackedVector2Array([
			Vector2(mountain_x + 7, ground_y - 19),
			Vector2(mountain_x + 12, ground_y - 31),
			Vector2(mountain_x + 14, ground_y - 23),
			Vector2(mountain_x + 10, ground_y - 12)
		])
		mineral.color = lava_dark
		terrain_scenery.add_child(mineral)

	# Three distinct lava pools.
	# Each has its own outline, size, angle, and molten pattern.
	# Coordinates are local to the pool's origin.
	var pool_data: Array[Dictionary] = [
		{
			"fraction": 0.12,
			"offset_y": 20.0,
			"scale": 0.82,
			"outline": PackedVector2Array([
				Vector2(0, 8), Vector2(7, 3),
				Vector2(15, 4), Vector2(21, 0),
				Vector2(35, 2), Vector2(43, 6),
				Vector2(53, 5), Vector2(62, 10),
				Vector2(57, 15), Vector2(43, 17),
				Vector2(28, 14), Vector2(17, 17),
				Vector2(5, 14)
			]),
			"molten": PackedVector2Array([
				Vector2(5, 9), Vector2(13, 6),
				Vector2(21, 7), Vector2(25, 4),
				Vector2(34, 5), Vector2(42, 9),
				Vector2(52, 8), Vector2(57, 11),
				Vector2(49, 13), Vector2(36, 12),
				Vector2(27, 11), Vector2(17, 14),
				Vector2(8, 12)
			]),
			"flow": PackedVector2Array([
				Vector2(10, 9), Vector2(18, 8),
				Vector2(25, 9), Vector2(32, 7),
				Vector2(40, 10), Vector2(35, 11),
				Vector2(25, 10), Vector2(17, 12)
			]),
			"hotspot": PackedVector2Array([
				Vector2(24, 8), Vector2(30, 7),
				Vector2(33, 9), Vector2(27, 10)
			])
		},
		{
			"fraction": 0.42,
			"offset_y": 25.0,
			"scale": 1.0,
			"outline": PackedVector2Array([
				Vector2(0, 12), Vector2(9, 6),
				Vector2(19, 7), Vector2(28, 2),
				Vector2(40, 4), Vector2(48, 0),
				Vector2(59, 4), Vector2(66, 10),
				Vector2(82, 12), Vector2(90, 18),
				Vector2(82, 23), Vector2(70, 21),
				Vector2(60, 18), Vector2(49, 20),
				Vector2(40, 16), Vector2(27, 19),
				Vector2(18, 16), Vector2(7, 18)
			]),
			"molten": PackedVector2Array([
				Vector2(6, 12), Vector2(13, 9),
				Vector2(21, 10), Vector2(29, 5),
				Vector2(39, 7), Vector2(48, 4),
				Vector2(57, 8), Vector2(64, 13),
				Vector2(80, 15), Vector2(84, 18),
				Vector2(72, 18), Vector2(61, 15),
				Vector2(49, 17), Vector2(39, 13),
				Vector2(27, 16), Vector2(17, 13),
				Vector2(9, 15)
			]),
			"flow": PackedVector2Array([
				Vector2(13, 12), Vector2(25, 11),
				Vector2(34, 8), Vector2(43, 10),
				Vector2(51, 8), Vector2(60, 12),
				Vector2(74, 16), Vector2(63, 15),
				Vector2(52, 11), Vector2(42, 13),
				Vector2(32, 11), Vector2(23, 14)
			]),
			"hotspot": PackedVector2Array([
				Vector2(44, 9), Vector2(51, 7),
				Vector2(55, 10), Vector2(48, 11)
			])
		},
		{
			"fraction": 0.75,
			"offset_y": 18.0,
			"scale": 0.92,
			"outline": PackedVector2Array([
				Vector2(0, 7), Vector2(12, 3),
				Vector2(21, 5), Vector2(32, 2),
				Vector2(41, 6), Vector2(50, 4),
				Vector2(63, 8), Vector2(70, 13),
				Vector2(62, 18), Vector2(50, 16),
				Vector2(41, 19), Vector2(30, 15),
				Vector2(20, 17), Vector2(10, 13),
				Vector2(2, 13)
			]),
			"molten": PackedVector2Array([
				Vector2(6, 8), Vector2(13, 6),
				Vector2(22, 8), Vector2(32, 5),
				Vector2(41, 9), Vector2(50, 7),
				Vector2(61, 10), Vector2(65, 13),
				Vector2(57, 15), Vector2(49, 13),
				Vector2(40, 16), Vector2(30, 12),
				Vector2(20, 14), Vector2(11, 11)
			]),
			"flow": PackedVector2Array([
				Vector2(10, 9), Vector2(19, 10),
				Vector2(30, 7), Vector2(40, 11),
				Vector2(50, 9), Vector2(59, 12),
				Vector2(49, 11), Vector2(40, 14),
				Vector2(29, 10), Vector2(20, 12)
			]),
			"hotspot": PackedVector2Array([
				Vector2(29, 8), Vector2(35, 7),
				Vector2(39, 10), Vector2(33, 11)
			])
		}
	]

	for data in pool_data:
		var pool_origin := Vector2(
			start_x + section_width * float(data["fraction"]),
			ground_y + float(data["offset_y"])
		)
		var pool_scale: float = float(data["scale"])

		# Scale around the origin and keep the entire pool
		# within the terrain section.
		var pool := Node2D.new()
		pool.position = pool_origin
		pool.scale = Vector2(pool_scale, pool_scale)
		terrain_scenery.add_child(pool)

		# Dark, irregular outer crust.
		var crust := Polygon2D.new()
		crust.polygon = data["outline"]
		crust.color = outline
		pool.add_child(crust)

		# Dark red lava edge visible inside the crust.
		var deep_lava := Polygon2D.new()
		deep_lava.polygon = data["outline"]
		deep_lava.color = lava_dark
		deep_lava.scale = Vector2(0.91, 0.72)
		deep_lava.position = Vector2(3.0, 3.0)
		pool.add_child(deep_lava)

		# Main orange molten region.
		var molten := Polygon2D.new()
		molten.polygon = data["molten"]
		molten.color = lava_base
		pool.add_child(molten)

		# Bright, irregular flow.
		var hot_flow := Polygon2D.new()
		hot_flow.polygon = data["flow"]
		hot_flow.color = lava_light
		pool.add_child(hot_flow)

		# Small yellow-white hotspot.
		var hotspot := Polygon2D.new()
		hotspot.polygon = data["hotspot"]
		hotspot.color = lava_hot
		pool.add_child(hotspot)

		# A few dark fragments of cooling crust.
		var crust_fragment := Polygon2D.new()
		crust_fragment.polygon = PackedVector2Array([
			Vector2(12, 4),
			Vector2(18, 2),
			Vector2(23, 5),
			Vector2(19, 7)
		])
		crust_fragment.color = rock_dark
		pool.add_child(crust_fragment)

	# Five angular volcanic rocks, preserving the original spacing.
	for i in range(5):
		var rock_width: float = 20.0 + float(i % 3) * 8.0
		var rock_height: float = 12.0 + float(i % 2) * 6.0
		var rock_x: float = (
			start_x + 25.0
			+ float(i) * (section_width - 50.0) / 5.0
		)
		var rock_y: float = ground_y

		var rock_outline := Polygon2D.new()
		rock_outline.polygon = PackedVector2Array([
			Vector2(rock_x - 2, rock_y),
			Vector2(rock_x + 2, rock_y - rock_height * 0.55),
			Vector2(rock_x + rock_width * 0.42, rock_y - rock_height - 2),
			Vector2(rock_x + rock_width * 0.77, rock_y - rock_height * 0.75),
			Vector2(rock_x + rock_width + 2, rock_y - 3),
			Vector2(rock_x + rock_width + 2, rock_y)
		])
		rock_outline.color = outline
		terrain_scenery.add_child(rock_outline)

		var rock_fill := Polygon2D.new()
		rock_fill.polygon = PackedVector2Array([
			Vector2(rock_x + 1, rock_y - 2),
			Vector2(rock_x + 4, rock_y - rock_height * 0.54),
			Vector2(rock_x + rock_width * 0.42, rock_y - rock_height + 1),
			Vector2(rock_x + rock_width * 0.75, rock_y - rock_height * 0.7),
			Vector2(rock_x + rock_width - 1, rock_y - 3),
			Vector2(rock_x + rock_width - 1, rock_y - 1)
		])
		rock_fill.color = rock_base
		terrain_scenery.add_child(rock_fill)

		var rock_highlight := Polygon2D.new()
		rock_highlight.polygon = PackedVector2Array([
			Vector2(rock_x + 4, rock_y - rock_height * 0.54),
			Vector2(rock_x + rock_width * 0.42, rock_y - rock_height + 1),
			Vector2(rock_x + rock_width * 0.5, rock_y - rock_height * 0.55),
			Vector2(rock_x + rock_width * 0.3, rock_y - 2),
			Vector2(rock_x + 2, rock_y - 2)
		])
		rock_highlight.color = rock_light
		terrain_scenery.add_child(rock_highlight)

		var rock_shadow := Polygon2D.new()
		rock_shadow.polygon = PackedVector2Array([
			Vector2(rock_x + rock_width * 0.5, rock_y - rock_height * 0.55),
			Vector2(rock_x + rock_width * 0.75, rock_y - rock_height * 0.7),
			Vector2(rock_x + rock_width - 1, rock_y - 3),
			Vector2(rock_x + rock_width - 1, rock_y - 1),
			Vector2(rock_x + rock_width * 0.55, rock_y - 1)
		])
		rock_shadow.color = rock_dark
		terrain_scenery.add_child(rock_shadow)


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

	var outline := Color("#292b35")
	var distant_base := Color("#729c6a")
	var distant_light := Color("#91b285")
	var distant_dark := Color("#567d56")
	var near_base := Color("#527f4d")
	var near_light := Color("#709c62")
	var near_dark := Color("#365d3d")

	# Distant rolling hills: same silhouette, richer shading.
	var distant_points := PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x, ground_y - 15),
		Vector2(start_x + section_width * 0.2, ground_y - 55),
		Vector2(start_x + section_width * 0.45, ground_y - 30),
		Vector2(start_x + section_width * 0.7, ground_y - 65),
		Vector2(start_x + section_width, ground_y - 20),
		Vector2(start_x + section_width, ground_y)
	])

	var distant_outline := Polygon2D.new()
	distant_outline.polygon = distant_points
	distant_outline.color = outline.darkened(0.05)
	terrain_scenery.add_child(distant_outline)

	var distant_hills := Polygon2D.new()
	distant_hills.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x, ground_y - 12),
		Vector2(start_x + section_width * 0.2, ground_y - 51),
		Vector2(start_x + section_width * 0.45, ground_y - 27),
		Vector2(start_x + section_width * 0.7, ground_y - 61),
		Vector2(start_x + section_width, ground_y - 17),
		Vector2(start_x + section_width, ground_y)
	])
	distant_hills.color = distant_base
	terrain_scenery.add_child(distant_hills)

	var distant_highlight := Polygon2D.new()
	distant_highlight.polygon = PackedVector2Array([
		Vector2(start_x + section_width * 0.06, ground_y - 20),
		Vector2(start_x + section_width * 0.2, ground_y - 51),
		Vector2(start_x + section_width * 0.35, ground_y - 35),
		Vector2(start_x + section_width * 0.24, ground_y - 37)
	])
	distant_highlight.color = distant_light
	terrain_scenery.add_child(distant_highlight)

	var distant_shadow := Polygon2D.new()
	distant_shadow.polygon = PackedVector2Array([
		Vector2(start_x + section_width * 0.7, ground_y - 61),
		Vector2(start_x + section_width, ground_y - 17),
		Vector2(start_x + section_width, ground_y),
		Vector2(start_x + section_width * 0.78, ground_y),
		Vector2(start_x + section_width * 0.79, ground_y - 34)
	])
	distant_shadow.color = distant_dark
	terrain_scenery.add_child(distant_shadow)

	# Near hills retain the original placement and height.
	var near_outline := Polygon2D.new()
	near_outline.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x + section_width * 0.15, ground_y - 20),
		Vector2(start_x + section_width * 0.4, ground_y - 35),
		Vector2(start_x + section_width * 0.65, ground_y - 15),
		Vector2(start_x + section_width, ground_y - 30),
		Vector2(start_x + section_width, ground_y)
	])
	near_outline.color = outline
	terrain_scenery.add_child(near_outline)

	var near_hills := Polygon2D.new()
	near_hills.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(start_x + section_width * 0.15, ground_y - 17),
		Vector2(start_x + section_width * 0.4, ground_y - 31),
		Vector2(start_x + section_width * 0.65, ground_y - 12),
		Vector2(start_x + section_width, ground_y - 26),
		Vector2(start_x + section_width, ground_y)
	])
	near_hills.color = near_base
	terrain_scenery.add_child(near_hills)

	var near_highlight := Polygon2D.new()
	near_highlight.polygon = PackedVector2Array([
		Vector2(start_x + section_width * 0.15, ground_y - 17),
		Vector2(start_x + section_width * 0.4, ground_y - 31),
		Vector2(start_x + section_width * 0.51, ground_y - 23),
		Vector2(start_x + section_width * 0.35, ground_y - 19)
	])
	near_highlight.color = near_light
	terrain_scenery.add_child(near_highlight)

	var near_shadow := Polygon2D.new()
	near_shadow.polygon = PackedVector2Array([
		Vector2(start_x + section_width * 0.65, ground_y - 12),
		Vector2(start_x + section_width, ground_y - 26),
		Vector2(start_x + section_width, ground_y),
		Vector2(start_x + section_width * 0.7, ground_y)
	])
	near_shadow.color = near_dark
	terrain_scenery.add_child(near_shadow)

	# Four bushes, retaining their original positions and footprint.
	for i in range(4):
		var bush_x: float = (
			start_x + 25.0
			+ float(i) * (section_width - 50.0) / 4.0
		)
		var bush_y: float = ground_y - 12.0

		# Irregular, dark-outlined silhouette.
		var bush_outline := Polygon2D.new()
		bush_outline.polygon = PackedVector2Array([
			Vector2(bush_x, bush_y + 12),
			Vector2(bush_x - 1, bush_y + 7),
			Vector2(bush_x + 3, bush_y + 5),
			Vector2(bush_x + 5, bush_y + 1),
			Vector2(bush_x + 10, bush_y),
			Vector2(bush_x + 14, bush_y + 3),
			Vector2(bush_x + 19, bush_y + 1),
			Vector2(bush_x + 23, bush_y + 5),
			Vector2(bush_x + 25, bush_y + 9),
			Vector2(bush_x + 24, bush_y + 12)
		])
		bush_outline.color = outline
		terrain_scenery.add_child(bush_outline)

		var bush_base := Polygon2D.new()
		bush_base.polygon = PackedVector2Array([
			Vector2(bush_x + 2, bush_y + 10),
			Vector2(bush_x + 3, bush_y + 7),
			Vector2(bush_x + 6, bush_y + 6),
			Vector2(bush_x + 7, bush_y + 3),
			Vector2(bush_x + 10, bush_y + 2),
			Vector2(bush_x + 14, bush_y + 5),
			Vector2(bush_x + 19, bush_y + 3),
			Vector2(bush_x + 22, bush_y + 6),
			Vector2(bush_x + 23, bush_y + 10)
		])
		bush_base.color = Color("#427943")
		terrain_scenery.add_child(bush_base)

		# Hard-edged shadow along the lower right.
		var bush_shadow := Polygon2D.new()
		bush_shadow.polygon = PackedVector2Array([
			Vector2(bush_x + 14, bush_y + 5),
			Vector2(bush_x + 19, bush_y + 3),
			Vector2(bush_x + 22, bush_y + 6),
			Vector2(bush_x + 23, bush_y + 10),
			Vector2(bush_x + 12, bush_y + 10)
		])
		bush_shadow.color = Color("#285432")
		terrain_scenery.add_child(bush_shadow)

		# Small highlights on the upper foliage.
		var bush_highlight := Polygon2D.new()
		bush_highlight.polygon = PackedVector2Array([
			Vector2(bush_x + 5, bush_y + 6),
			Vector2(bush_x + 7, bush_y + 3),
			Vector2(bush_x + 10, bush_y + 2),
			Vector2(bush_x + 13, bush_y + 5),
			Vector2(bush_x + 10, bush_y + 7)
		])
		bush_highlight.color = Color("#79aa65")
		terrain_scenery.add_child(bush_highlight)


func setup_sky_scenery() -> void:
	sky_scenery = Control.new()
	sky_scenery.name = "SkyScenery"
	sky_scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(sky_scenery)
	background.move_child(sky_scenery, 0)





func update_sky_scenery() -> void:
	for child in sky_scenery.get_children():
		sky_scenery.remove_child(child)
		child.queue_free()

	if battlefield_grid == null:
		return

	var half_width: float = size.x / 2.0

	match battlefield_grid.biome:
		BattlefieldGrid.Biome.GRASSLAND:
			# Subtle middle-distance atmosphere.
			# Keep the colour close to the existing sky so the
			# transition doesn't look like a hard horizontal band.
			var middle_sky := Polygon2D.new()
			middle_sky.polygon = PackedVector2Array([
				Vector2(0, size.y * 0.43),
				Vector2(size.x * 0.16, size.y * 0.42),
				Vector2(size.x * 0.34, size.y * 0.45),
				Vector2(size.x * 0.52, size.y * 0.43),
				Vector2(size.x * 0.74, size.y * 0.46),
				Vector2(size.x, size.y * 0.44),
				Vector2(size.x, size.y),
				Vector2(0, size.y)
			])
			middle_sky.color = Color("#39536c")
			sky_scenery.add_child(middle_sky)

			# A lighter atmospheric layer immediately above the hills.
			# The hills themselves hide the lower edge.
			var horizon_sky := Polygon2D.new()
			horizon_sky.polygon = PackedVector2Array([
				Vector2(0, size.y * 0.63),
				Vector2(size.x * 0.2, size.y * 0.61),
				Vector2(size.x * 0.42, size.y * 0.64),
				Vector2(size.x * 0.65, size.y * 0.62),
				Vector2(size.x * 0.84, size.y * 0.64),
				Vector2(size.x, size.y * 0.61),
				Vector2(size.x, size.y),
				Vector2(0, size.y)
			])
			horizon_sky.color = Color("#415e75")
			sky_scenery.add_child(horizon_sky)

			# Preserve all four original cloud positions.
			add_pixel_cloud(Vector2(half_width * 0.25, size.y * 0.16))
			add_pixel_cloud(Vector2(half_width * 0.65, size.y * 0.28))
			add_pixel_cloud(Vector2(half_width * 1.25, size.y * 0.19))
			add_pixel_cloud(Vector2(half_width * 1.7, size.y * 0.12))

		BattlefieldGrid.Biome.DESERT:
			add_desert_sky_details()

		BattlefieldGrid.Biome.SNOW:
			pass




func add_pixel_cloud(position: Vector2) -> void:
	var outline := Color("#344657")
	var shadow := Color("#8fa9bb")
	var base := Color("#cbdce6")
	var light := Color("#f0f6f8")

	var cloud := Control.new()
	cloud.position = position
	cloud.scale = Vector2(1.45, 1.45)
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_scenery.add_child(cloud)

	# Main irregular silhouette.
	var silhouette := Polygon2D.new()
	silhouette.polygon = PackedVector2Array([
		Vector2(0, 24),
		Vector2(2, 17),
		Vector2(9, 14),
		Vector2(15, 15),
		Vector2(18, 8),
		Vector2(25, 4),
		Vector2(34, 3),
		Vector2(40, 7),
		Vector2(45, 12),
		Vector2(51, 10),
		Vector2(59, 13),
		Vector2(63, 19),
		Vector2(70, 21),
		Vector2(72, 27),
		Vector2(67, 31),
		Vector2(7, 31),
		Vector2(0, 28)
	])
	silhouette.color = outline
	cloud.add_child(silhouette)

	# Main cloud body, inset slightly from the outline.
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(3, 25),
		Vector2(5, 19),
		Vector2(11, 17),
		Vector2(17, 18),
		Vector2(21, 10),
		Vector2(27, 7),
		Vector2(33, 6),
		Vector2(38, 9),
		Vector2(44, 16),
		Vector2(51, 13),
		Vector2(57, 16),
		Vector2(61, 22),
		Vector2(68, 23),
		Vector2(69, 28),
		Vector2(5, 28)
	])
	body.color = base
	cloud.add_child(body)

	# Hard-edged underside shadow.
	var underside := Polygon2D.new()
	underside.polygon = PackedVector2Array([
		Vector2(5, 23),
		Vector2(15, 22),
		Vector2(23, 25),
		Vector2(32, 21),
		Vector2(43, 25),
		Vector2(53, 22),
		Vector2(68, 25),
		Vector2(69, 28),
		Vector2(5, 28)
	])
	underside.color = shadow
	cloud.add_child(underside)

	# Large upper-left highlight.
	var upper_highlight := Polygon2D.new()
	upper_highlight.polygon = PackedVector2Array([
		Vector2(21, 14),
		Vector2(25, 9),
		Vector2(32, 7),
		Vector2(37, 10),
		Vector2(41, 16),
		Vector2(34, 17),
		Vector2(28, 14)
	])
	upper_highlight.color = light
	cloud.add_child(upper_highlight)

	# Secondary illuminated lobe.
	var side_highlight := Polygon2D.new()
	side_highlight.polygon = PackedVector2Array([
		Vector2(7, 21),
		Vector2(11, 18),
		Vector2(16, 19),
		Vector2(20, 23),
		Vector2(13, 24)
	])
	side_highlight.color = light
	cloud.add_child(side_highlight)

	# Right-hand shadow gives the cloud additional volume.
	var right_shadow := Polygon2D.new()
	right_shadow.polygon = PackedVector2Array([
		Vector2(50, 15),
		Vector2(57, 16),
		Vector2(61, 22),
		Vector2(68, 23),
		Vector2(69, 28),
		Vector2(56, 27),
		Vector2(58, 22)
	])
	right_shadow.color = shadow
	cloud.add_child(right_shadow)


func setup_ground_details() -> void:
	ground_details = Control.new()
	ground_details.name = "GroundDetails"
	ground_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground_details.z_index = 0
	background.add_child(ground_details)






func update_ground_details() -> void:
	for child in ground_details.get_children():
		ground_details.remove_child(child)
		child.queue_free()

	if battlefield_grid == null:
		return

	var half_width: float = size.x / 2.0

	var enemy_terrain: TerrainResource = battlefield_grid.get_terrain_at(
		enemy_unit.grid_position
	)
	var player_terrain: TerrainResource = battlefield_grid.get_terrain_at(
		player_unit.grid_position
	)

	var enemy_is_natural: bool = (
		enemy_terrain == null
		or enemy_terrain.terrain_type == TerrainResource.TerrainType.FOREST
	)

	var player_is_natural: bool = (
		player_terrain == null
		or player_terrain.terrain_type == TerrainResource.TerrainType.FOREST
	)

	# Only combine ordinary grassland and forest ground.
	# Keep forts, lava, scorched ground, desert and snow separate.
	var use_shared_shading: bool = (
		battlefield_grid.biome == BattlefieldGrid.Biome.GRASSLAND
		and enemy_is_natural
		and player_is_natural
		and not battlefield_grid.is_adjacent_to_lava(
			enemy_unit.grid_position
		)
		and not battlefield_grid.is_adjacent_to_lava(
			player_unit.grid_position
		)
	)

	if use_shared_shading:
		# Draw the large shading polygons once across the full screen.
		add_grassland_ground_shading(0.0, size.x)

		# Keep each side's terrain-specific small details.
		add_unit_ground_details(
			enemy_unit, 0.0, half_width, false
		)
		add_unit_ground_details(
			player_unit, half_width, half_width, false
		)
		return

	# All other terrain combinations retain their original behaviour.
	add_unit_ground_details(enemy_unit, 0.0, half_width)
	add_unit_ground_details(player_unit, half_width, half_width)



func add_unit_ground_details(
	unit: Unit,
	start_x: float,
	section_width: float,
	draw_shading: bool = true
) -> void:
	var terrain: TerrainResource = battlefield_grid.get_terrain_at(
		unit.grid_position
	)

	# Scorched ground takes priority over ordinary terrain details.
	if terrain == null or terrain.terrain_type != TerrainResource.TerrainType.LAVA:
		if battlefield_grid.is_adjacent_to_lava(unit.grid_position):
			add_scorched_ground_details(start_x, section_width)
			return

	if terrain != null:
		match terrain.terrain_type:
			TerrainResource.TerrainType.FOREST:
				add_forest_ground_details(
					start_x, section_width, draw_shading
				)
				return

			TerrainResource.TerrainType.FORT:
				add_fort_ground_details(start_x, section_width)
				return

			TerrainResource.TerrainType.LAVA:
				add_lava_ground_details(start_x, section_width)
				return

	match battlefield_grid.biome:
		BattlefieldGrid.Biome.GRASSLAND:
			add_grassland_ground_details(
				start_x, section_width, draw_shading
			)

		BattlefieldGrid.Biome.DESERT:
			add_desert_ground_details(start_x, section_width)

		BattlefieldGrid.Biome.SNOW:
			add_snow_ground_details(start_x, section_width)



func add_scorched_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	var end_x: float = start_x + section_width
	var bottom_y: float = size.y

	var rock_light := Color("#60544d")
	var rock_dark := Color("#483e3b")
	var crack_dark := Color("#292725")
	var crack_edge := Color("#78675b")
	var ash_color := Color("#89796b")
	var ember_color := Color("#b96938")
	var ember_light := Color("#e39a4b")

	# Broad, subtle patches of exposed rock.
	var upper_facet := Polygon2D.new()
	upper_facet.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 12),
		Vector2(start_x + section_width * 0.26, ground_y + 7),
		Vector2(start_x + section_width * 0.61, ground_y + 19),
		Vector2(end_x, ground_y + 10),
		Vector2(end_x, ground_y + 39),
		Vector2(start_x + section_width * 0.48, ground_y + 34),
		Vector2(start_x, ground_y + 43)
	])
	upper_facet.color = rock_light
	ground_details.add_child(upper_facet)

	var lower_facet := Polygon2D.new()
	lower_facet.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 119),
		Vector2(start_x + section_width * 0.28, ground_y + 111),
		Vector2(start_x + section_width * 0.67, ground_y + 124),
		Vector2(end_x, ground_y + 115),
		Vector2(end_x, bottom_y),
		Vector2(start_x, bottom_y)
	])
	lower_facet.color = rock_dark
	ground_details.add_child(lower_facet)

	# Nine varied cracks, preserving the original distribution.
	for i in range(9):
		var x: float = (
			start_x + 20.0
			+ float(i) * (section_width - 40.0) / 9.0
		)
		var y: float = ground_y + 20.0 + float((i * 37) % 85)

		var length: float = 13.0 + float((i * 7) % 12)
		var bend: float = float((i * 5) % 9) - 4.0
		var direction: float = -1.0 if i % 2 == 0 else 1.0

		var points := PackedVector2Array([
			Vector2(x - length * 0.5, y),
			Vector2(x - length * 0.15, y + direction * 3.0),
			Vector2(x + bend, y + direction),
			Vector2(x + length * 0.5, y + direction * 5.0)
		])

		# Narrow illuminated stone edge beside the fracture.
		var edge := Line2D.new()
		edge.width = 2.0
		edge.default_color = crack_edge
		for point in points:
			edge.add_point(point + Vector2(0, 2))
		ground_details.add_child(edge)

		var crack := Line2D.new()
		crack.width = 2.5
		crack.default_color = crack_dark
		crack.points = points
		ground_details.add_child(crack)

		# Occasional short branches, not identical on every crack.
		if i % 3 == 1:
			var branch := Line2D.new()
			branch.width = 2.0
			branch.default_color = crack_dark
			branch.points = PackedVector2Array([
				points[2],
				points[2] + Vector2(3, 5),
				points[2] + Vector2(1, 9)
			])
			ground_details.add_child(branch)

	# Fourteen sparse ash deposits with irregular silhouettes.
	for i in range(14):
		var x: float = (
			start_x + 12.0
			+ float((i * 53) % int(maxf(section_width - 24.0, 1.0)))
		)
		var y: float = ground_y + 12.0 + float((i * 29) % 100)
		var width: float = 5.0 + float(i % 3) * 3.0

		var ash := Polygon2D.new()
		ash.polygon = PackedVector2Array([
			Vector2(x, y + 2),
			Vector2(x + 2, y),
			Vector2(x + width - 2, y),
			Vector2(x + width, y + 2),
			Vector2(x + width * 0.55, y + 3)
		])
		ash.color = ash_color
		ground_details.add_child(ash)

	# Five isolated embers, with small hot centres.
	for i in range(5):
		var x: float = (
			start_x + 35.0
			+ float(i) * (section_width - 70.0) / 5.0
		)
		var y: float = ground_y + 28.0 + float((i * 41) % 90)

		var ember := Polygon2D.new()
		ember.polygon = PackedVector2Array([
			Vector2(x - 2, y + 1),
			Vector2(x + 2, y - 1),
			Vector2(x + 6, y),
			Vector2(x + 4, y + 3),
			Vector2(x, y + 3)
		])
		ember.color = ember_color
		ground_details.add_child(ember)

		if i % 2 == 0:
			var hot_center := Polygon2D.new()
			hot_center.polygon = PackedVector2Array([
				Vector2(x + 1, y),
				Vector2(x + 4, y + 1),
				Vector2(x + 2, y + 2)
			])
			hot_center.color = ember_light
			ground_details.add_child(hot_center)


func add_grassland_ground_details(
		start_x: float,
		section_width: float,
		draw_shading: bool = true
	) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	if draw_shading:
		add_grassland_ground_shading(start_x, section_width)
	var grass_dark := Color("#355c32")
	var grass_base := Color("#56804a")
	var grass_light := Color("#a3c17e")
	var flower_yellow := Color("#eadb84")
	var flower_light := Color("#fff0b3")
	var flower_center := Color("#a97838")
	var soil_dark := Color("#465c3e")
	var soil_base := Color("#526b46")
	var soil_light := Color("#81906a")

	# Preserve the existing deterministic positions and density.
	for i in range(14):
		var x: float = (
			start_x + 15.0
			+ float(i) * (section_width - 30.0) / 14.0
		)
		var y: float = ground_y + 18.0 + float((i * 17) % 65)

		# Small three-blade grass tufts.
		if i % 3 != 0:
			var primary_color: Color = (
				grass_dark if i % 2 == 0 else grass_base
			)

			# Left blade.
			var left_blade := Polygon2D.new()
			left_blade.polygon = PackedVector2Array([
				Vector2(x, y),
				Vector2(x - 6, y - 7),
				Vector2(x - 2, y - 5),
				Vector2(x + 1, y)
			])
			left_blade.color = primary_color
			ground_details.add_child(left_blade)

			# Tall central blade.
			var center_blade := Polygon2D.new()
			center_blade.polygon = PackedVector2Array([
				Vector2(x - 1, y),
				Vector2(x, y - 10),
				Vector2(x + 2, y - 5),
				Vector2(x + 2, y)
			])
			center_blade.color = grass_light
			ground_details.add_child(center_blade)

			# Right blade.
			var right_blade := Polygon2D.new()
			right_blade.polygon = PackedVector2Array([
				Vector2(x, y),
				Vector2(x + 6, y - 8),
				Vector2(x + 5, y - 3),
				Vector2(x + 2, y)
			])
			right_blade.color = grass_dark
			ground_details.add_child(right_blade)

		# Keep the same occasional flowers.
		if i % 5 == 0:
			var flower_x: float = x + 7.0
			var flower_y: float = y - 4.0

			# Tiny dark silhouette.
			var flower_outline := Polygon2D.new()
			flower_outline.polygon = PackedVector2Array([
				Vector2(flower_x, flower_y - 4),
				Vector2(flower_x + 3, flower_y - 2),
				Vector2(flower_x + 4, flower_y + 1),
				Vector2(flower_x + 1, flower_y + 3),
				Vector2(flower_x - 2, flower_y + 1),
				Vector2(flower_x - 2, flower_y - 2)
			])
			flower_outline.color = flower_center
			ground_details.add_child(flower_outline)

			var flower_petals := Polygon2D.new()
			flower_petals.polygon = PackedVector2Array([
				Vector2(flower_x, flower_y - 3),
				Vector2(flower_x + 2, flower_y - 1),
				Vector2(flower_x + 3, flower_y + 1),
				Vector2(flower_x, flower_y + 2),
				Vector2(flower_x - 1, flower_y)
			])
			flower_petals.color = flower_yellow
			ground_details.add_child(flower_petals)

			var flower_highlight := Polygon2D.new()
			flower_highlight.polygon = PackedVector2Array([
				Vector2(flower_x, flower_y - 3),
				Vector2(flower_x + 2, flower_y - 1),
				Vector2(flower_x, flower_y)
			])
			flower_highlight.color = flower_light
			ground_details.add_child(flower_highlight)

		# Sparse, angular patches of exposed soil.
		if i % 4 == 0:
			var soil := Polygon2D.new()
			soil.polygon = PackedVector2Array([
				Vector2(x - 9, y + 9),
				Vector2(x - 6, y + 7),
				Vector2(x + 1, y + 7),
				Vector2(x + 3, y + 9),
				Vector2(x, y + 11),
				Vector2(x - 7, y + 11)
			])
			soil.color = soil_dark
			ground_details.add_child(soil)

			var soil_fill := Polygon2D.new()
			soil_fill.polygon = PackedVector2Array([
				Vector2(x - 7, y + 9),
				Vector2(x - 5, y + 8),
				Vector2(x, y + 8),
				Vector2(x + 1, y + 9),
				Vector2(x - 1, y + 10),
				Vector2(x - 6, y + 10)
			])
			soil_fill.color = soil_base
			ground_details.add_child(soil_fill)

			var soil_highlight := Line2D.new()
			soil_highlight.width = 1.0
			soil_highlight.default_color = soil_light
			soil_highlight.points = PackedVector2Array([
				Vector2(x - 6, y + 8),
				Vector2(x - 2, y + 8)
			])
			ground_details.add_child(soil_highlight)

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



func add_forest_ground_details(
		start_x: float,
		section_width: float,
		draw_shading: bool = true
	) -> void:
	var ground_y: float = size.y / 2.0 + 80.0

	var leaf_green := Color("#78a365")
	var leaf_green_shadow := Color("#426b3d")
	var leaf_brown := Color("#b18a57")
	var leaf_brown_shadow := Color("#715039")

	var earth_outline := Color("#203b2b")
	var earth_base := Color("#426346")
	var earth_highlight := Color("#62805a")

	var grass_dark := Color("#244e30")
	var grass_light := Color("#81a66b")

	# Add the broad shading first so individual details sit on top.
	if draw_shading:
		add_forest_ground_shading(start_x, section_width)

	# Preserve the original 18 positions and spacing.
	for i in range(18):
		var x: float = (
			start_x + 12.0
			+ float(i) * (section_width - 24.0) / 18.0
		)
		var y: float = ground_y + 15.0 + float((i * 23) % 70)

		# Fallen leaves: small angular shapes with a shaded edge.
		if i % 2 == 0:
			var is_green: bool = i % 4 == 0

			var leaf_shadow := Polygon2D.new()
			leaf_shadow.polygon = PackedVector2Array([
				Vector2(x - 4, y),
				Vector2(x - 1, y - 3),
				Vector2(x + 4, y - 2),
				Vector2(x + 6, y + 1),
				Vector2(x + 1, y + 3)
			])
			leaf_shadow.color = (
				leaf_green_shadow if is_green else leaf_brown_shadow
			)
			ground_details.add_child(leaf_shadow)

			var leaf := Polygon2D.new()
			leaf.polygon = PackedVector2Array([
				Vector2(x - 3, y),
				Vector2(x, y - 3),
				Vector2(x + 4, y - 1),
				Vector2(x + 1, y + 1)
			])
			leaf.color = leaf_green if is_green else leaf_brown
			ground_details.add_child(leaf)

		# Exposed earth with an irregular silhouette and lighter face.
		if i % 5 == 0:
			var earth := Polygon2D.new()
			earth.polygon = PackedVector2Array([
				Vector2(x - 8, y + 8),
				Vector2(x - 5, y + 6),
				Vector2(x + 3, y + 6),
				Vector2(x + 7, y + 9),
				Vector2(x + 3, y + 11),
				Vector2(x - 6, y + 11)
			])
			earth.color = earth_outline
			ground_details.add_child(earth)

			var earth_fill := Polygon2D.new()
			earth_fill.polygon = PackedVector2Array([
				Vector2(x - 6, y + 8),
				Vector2(x - 4, y + 7),
				Vector2(x + 3, y + 7),
				Vector2(x + 5, y + 9),
				Vector2(x - 5, y + 9)
			])
			earth_fill.color = earth_base
			ground_details.add_child(earth_fill)

			var earth_light := Polygon2D.new()
			earth_light.polygon = PackedVector2Array([
				Vector2(x - 4, y + 7),
				Vector2(x + 2, y + 7),
				Vector2(x, y + 8),
				Vector2(x - 5, y + 8)
			])
			earth_light.color = earth_highlight
			ground_details.add_child(earth_light)

		# Three-blade grass tufts.
		if i % 3 == 0:
			var left_blade := Polygon2D.new()
			left_blade.polygon = PackedVector2Array([
				Vector2(x, y),
				Vector2(x - 5, y - 7),
				Vector2(x - 2, y - 5),
				Vector2(x + 1, y)
			])
			left_blade.color = grass_dark
			ground_details.add_child(left_blade)

			var center_blade := Polygon2D.new()
			center_blade.polygon = PackedVector2Array([
				Vector2(x - 1, y),
				Vector2(x, y - 10),
				Vector2(x + 2, y - 5),
				Vector2(x + 2, y)
			])
			center_blade.color = grass_light
			ground_details.add_child(center_blade)

			var right_blade := Polygon2D.new()
			right_blade.polygon = PackedVector2Array([
				Vector2(x, y),
				Vector2(x + 6, y - 8),
				Vector2(x + 5, y - 3),
				Vector2(x + 2, y)
			])
			right_blade.color = grass_dark
			ground_details.add_child(right_blade)



func add_fort_ground_details(start_x: float, section_width: float) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	var end_x: float = start_x + section_width
	var bottom_y: float = size.y

	var outline := Color("#414954")
	var stone_base := Color("#707986")
	var stone_light := Color("#8999a7")
	var stone_dark := Color("#596572")
	var mortar := Color("#505966")

	if battlefield_grid.biome == BattlefieldGrid.Biome.DESERT:
		outline = Color("#67543f")
		stone_base = Color("#b89a6b")
		stone_light = Color("#dfc69a")
		stone_dark = Color("#947650")
		mortar = Color("#806747")

	elif battlefield_grid.biome == BattlefieldGrid.Biome.SNOW:
		outline = Color("#526675")
		stone_base = Color("#a8bac5")
		stone_light = Color("#dce9f0")
		stone_dark = Color("#8399a8")
		mortar = Color("#667b89")

	# A dark seam separates the vertical wall from the courtyard.
	var wall_base_shadow := Polygon2D.new()
	wall_base_shadow.polygon = PackedVector2Array([
		Vector2(start_x, ground_y),
		Vector2(end_x, ground_y),
		Vector2(end_x, ground_y + 9),
		Vector2(start_x, ground_y + 9)
	])
	wall_base_shadow.color = outline
	ground_details.add_child(wall_base_shadow)

	# Main courtyard surface with subtle directional shading.
	var courtyard := Polygon2D.new()
	courtyard.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 9),
		Vector2(end_x, ground_y + 9),
		Vector2(end_x, bottom_y),
		Vector2(start_x, bottom_y)
	])
	courtyard.color = stone_base
	ground_details.add_child(courtyard)

	# A slightly lighter region near the wall.
	var upper_light := Polygon2D.new()
	upper_light.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 10),
		Vector2(end_x, ground_y + 10),
		Vector2(end_x, ground_y + 46),
		Vector2(start_x, ground_y + 37)
	])
	upper_light.color = stone_light.darkened(0.12)
	ground_details.add_child(upper_light)

	# A darker foreground gives the paving some depth.
	var foreground_shadow := Polygon2D.new()
	foreground_shadow.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 139),
		Vector2(start_x + section_width * 0.4, ground_y + 132),
		Vector2(end_x, ground_y + 143),
		Vector2(end_x, bottom_y),
		Vector2(start_x, bottom_y)
	])
	foreground_shadow.color = stone_dark
	ground_details.add_child(foreground_shadow)

	# Perspective paving:
	# Narrower rows near the wall, larger rows toward the viewer.
	var row_heights: Array[float] = [
		23.0,
		29.0,
		36.0,
		45.0,
		54.0
	]

	var y: float = ground_y + 9.0
	var row_index: int = 0

	while y < bottom_y:
		var row_height: float = row_heights[
			mini(row_index, row_heights.size() - 1)
		]

		var next_y: float = minf(y + row_height, bottom_y)

		# Horizontal joints become more prominent in the foreground.
		var horizontal := Line2D.new()
		horizontal.width = 2.0
		horizontal.default_color = mortar
		horizontal.points = PackedVector2Array([
			Vector2(start_x, y),
			Vector2(end_x, y)
		])
		ground_details.add_child(horizontal)

		# Larger slabs in rows closer to the viewer.
		var slab_width: float = 72.0 + float(row_index) * 15.0
		var offset: float = (
			0.0 if row_index % 2 == 0 else slab_width * 0.5
		)

		var x: float = start_x - slab_width + offset
		var slab_index: int = 0

		while x < end_x:
			var slab_left: float = maxf(x, start_x)
			var slab_right: float = minf(x + slab_width, end_x)

			if slab_right > slab_left:
				# Vertical mortar joint.
				if x > start_x and x < end_x:
					var joint := Line2D.new()
					joint.width = 2.0
					joint.default_color = mortar
					joint.points = PackedVector2Array([
						Vector2(x, y),
						Vector2(x, next_y)
					])
					ground_details.add_child(joint)

				# Hard-edged highlight on selected paving stones.
				# Keep these sparse to avoid a noisy checkerboard.
				if (row_index + slab_index) % 3 == 0:
					var highlight := Polygon2D.new()
					highlight.polygon = PackedVector2Array([
						Vector2(slab_left + 4, y + 4),
						Vector2(slab_right - 5, y + 4),
						Vector2(slab_right - 12, y + 7),
						Vector2(slab_left + 4, y + 7)
					])
					highlight.color = stone_light
					ground_details.add_child(highlight)

				# Occasional dark facets add variation to the slabs.
				if (row_index * 3 + slab_index) % 5 == 0:
					var facet := Polygon2D.new()
					facet.polygon = PackedVector2Array([
						Vector2(slab_right - 17, next_y - 12),
						Vector2(slab_right - 4, next_y - 17),
						Vector2(slab_right - 4, next_y - 4),
						Vector2(slab_right - 13, next_y - 4)
					])
					facet.color = stone_dark
					ground_details.add_child(facet)

			x += slab_width
			slab_index += 1

		y = next_y
		row_index += 1


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
	var end_x: float = start_x + section_width
	var bottom_y: float = size.y

	var rock_light := Color("#65504c")
	var rock_dark := Color("#493b3c")
	var crack_dark := Color("#30282d")
	var crack_edge := Color("#775650")
	var lava_red := Color("#a93d29")
	var lava_orange := Color("#f36a2a")
	var lava_yellow := Color("#ffba54")
	var ash_color := Color("#76534c")

	# Wide, low-contrast facets suggest uneven volcanic stone.
	var upper_facet := Polygon2D.new()
	upper_facet.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 11),
		Vector2(start_x + section_width * 0.23, ground_y + 5),
		Vector2(start_x + section_width * 0.52, ground_y + 16),
		Vector2(start_x + section_width * 0.79, ground_y + 8),
		Vector2(end_x, ground_y + 14),
		Vector2(end_x, ground_y + 40),
		Vector2(start_x + section_width * 0.55, ground_y + 34),
		Vector2(start_x, ground_y + 42)
	])
	upper_facet.color = rock_light
	ground_details.add_child(upper_facet)

	var lower_facet := Polygon2D.new()
	lower_facet.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 115),
		Vector2(start_x + section_width * 0.24, ground_y + 109),
		Vector2(start_x + section_width * 0.62, ground_y + 123),
		Vector2(end_x, ground_y + 112),
		Vector2(end_x, bottom_y),
		Vector2(start_x, bottom_y)
	])
	lower_facet.color = rock_dark
	ground_details.add_child(lower_facet)

	# Twelve cracks, varied in direction, length, and branching.
	for i in range(12):
		var x: float = (
			start_x + 18.0
			+ float(i) * (section_width - 36.0) / 12.0
		)
		var y: float = ground_y + 20.0 + float((i * 19) % 65)

		var length: float = 17.0 + float((i * 11) % 15)
		var direction: float = -1.0 if i % 2 == 0 else 1.0
		var bend: float = float((i * 7) % 11) - 5.0

		var points := PackedVector2Array([
			Vector2(x - length * 0.5, y + 1),
			Vector2(x - length * 0.2, y + direction * 4),
			Vector2(x + bend, y - direction * 2),
			Vector2(x + length * 0.22, y + direction * 3),
			Vector2(x + length * 0.5, y + direction)
		])

		# Light-catching fracture edge.
		var edge := Line2D.new()
		edge.width = 2.0
		edge.default_color = crack_edge
		for point in points:
			edge.add_point(point + Vector2(0, 2))
		ground_details.add_child(edge)

		# Dark fractured rock.
		var crack := Line2D.new()
		crack.width = 3.0
		crack.default_color = crack_dark
		crack.points = points
		ground_details.add_child(crack)

		# Four cracks reveal molten rock beneath the crust.
		if i % 3 == 0:
			var molten_shadow := Line2D.new()
			molten_shadow.width = 3.0
			molten_shadow.default_color = lava_red
			molten_shadow.points = PackedVector2Array([
				points[1], points[2], points[3]
			])
			ground_details.add_child(molten_shadow)

			var molten_flow := Line2D.new()
			molten_flow.width = 1.5
			molten_flow.default_color = lava_orange
			molten_flow.points = PackedVector2Array([
				points[1], points[2], points[3]
			])
			ground_details.add_child(molten_flow)

			# Only some fissures get a brighter hotspot.
			if i % 2 == 0:
				var hotspot := Polygon2D.new()
				hotspot.polygon = PackedVector2Array([
					points[2] + Vector2(-2, 0),
					points[2] + Vector2(2, -1),
					points[2] + Vector2(4, 1),
					points[2] + Vector2(0, 2)
				])
				hotspot.color = lava_yellow
				ground_details.add_child(hotspot)

		# Occasional fractured side branches.
		elif i % 4 == 1:
			var branch := Line2D.new()
			branch.width = 2.0
			branch.default_color = crack_dark
			branch.points = PackedVector2Array([
				points[2],
				points[2] + Vector2(-3, 6),
				points[2] + Vector2(1, 10)
			])
			ground_details.add_child(branch)

		# Three sparse deposits of volcanic ash.
		if i % 4 == 0:
			var ash := Polygon2D.new()
			ash.polygon = PackedVector2Array([
				Vector2(x - 8, y + 12),
				Vector2(x - 4, y + 9),
				Vector2(x + 3, y + 10),
				Vector2(x + 7, y + 13),
				Vector2(x, y + 14),
				Vector2(x - 6, y + 14)
			])
			ash.color = ash_color
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




func add_grassland_ground_shading(
	start_x: float,
	section_width: float
) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	var bottom_y: float = size.y

	# Slightly darker foreground creates depth without clutter.
	var foreground := Polygon2D.new()
	foreground.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 115),
		Vector2(start_x + section_width * 0.25, ground_y + 108),
		Vector2(start_x + section_width * 0.55, ground_y + 119),
		Vector2(start_x + section_width, ground_y + 110),
		Vector2(start_x + section_width, bottom_y),
		Vector2(start_x, bottom_y)
	])
	foreground.color = Color("#5b7552")
	ground_details.add_child(foreground)
	ground_details.move_child(foreground, 0)

	# One understated illuminated patch near the horizon.
	var light_patch := Polygon2D.new()
	light_patch.polygon = PackedVector2Array([
		Vector2(start_x + section_width * 0.08, ground_y + 5),
		Vector2(start_x + section_width * 0.45, ground_y + 3),
		Vector2(start_x + section_width * 0.65, ground_y + 20),
		Vector2(start_x + section_width * 0.34, ground_y + 26),
		Vector2(start_x + section_width * 0.05, ground_y + 19)
	])
	light_patch.color = Color("#738a60")
	ground_details.add_child(light_patch)
	ground_details.move_child(light_patch, 0)




func add_forest_ground_shading(
	start_x: float,
	section_width: float
) -> void:
	var ground_y: float = size.y / 2.0 + 80.0
	var bottom_y: float = size.y

	# Same foreground colour and shape as grassland.
	var foreground := Polygon2D.new()
	foreground.polygon = PackedVector2Array([
		Vector2(start_x, ground_y + 115),
		Vector2(start_x + section_width * 0.25, ground_y + 108),
		Vector2(start_x + section_width * 0.55, ground_y + 119),
		Vector2(start_x + section_width, ground_y + 110),
		Vector2(start_x + section_width, bottom_y),
		Vector2(start_x, bottom_y)
	])
	foreground.color = Color("#5b7552")
	ground_details.add_child(foreground)

	# Same subtle illuminated patch as grassland.
	var light_patch := Polygon2D.new()
	light_patch.polygon = PackedVector2Array([
		Vector2(start_x + section_width * 0.08, ground_y + 5),
		Vector2(start_x + section_width * 0.45, ground_y + 3),
		Vector2(start_x + section_width * 0.65, ground_y + 20),
		Vector2(start_x + section_width * 0.34, ground_y + 26),
		Vector2(start_x + section_width * 0.05, ground_y + 19)
	])
	light_patch.color = Color("#738a60")
	ground_details.add_child(light_patch)
