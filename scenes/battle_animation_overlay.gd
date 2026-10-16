
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

var player_unit: Unit = null
var enemy_unit: Unit = null
var is_playing: bool = false


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
	print("PlayerInfo: ", get_node_or_null("PlayerInfo"))
	print("HPLabel direct lookup: ", get_node_or_null("PlayerInfo/HPLabel"))
	print("Cached player_hp_label: ", player_hp_label)
	print("Actual PlayerInfo children:")
	for child in get_node("PlayerInfo").get_children():
		print("  [", child.name, "]")
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

	# Maximum HP comes from the unit's class resource.
	player_hp_bar.max_value = (
		player_unit.unit_data.unit_class.max_hp
	)

	enemy_hp_bar.max_value = (
		enemy_unit.unit_data.unit_class.max_hp
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
		player_unit.unit_data.unit_class.max_hp
	)

	var enemy_max_hp: int = (
		enemy_unit.unit_data.unit_class.max_hp
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

	hide()
	is_playing = false
	battle_animation_finished.emit()


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
		return

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
