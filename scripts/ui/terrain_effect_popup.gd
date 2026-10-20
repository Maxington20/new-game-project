
class_name TerrainEffectPopup
extends Control

var panel: PanelContainer
var title_label: Label
var name_label: Label
var hp_label: Label
var hp_bar: ProgressBar
var amount_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()
	hide()


func _build_ui() -> void:
	# Darken the battlefield behind the popup.
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.65)
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(background)

	# Center the popup.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	panel.add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	# Title.
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(title_label, 18)
	column.add_child(title_label)

	column.add_child(HSeparator.new())

	# Unit name.
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(name_label, 17)
	column.add_child(name_label)

	# Current HP.
	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(hp_label, 15)
	column.add_child(hp_label)

	# Animated HP bar.
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(260, 20)
	hp_bar.min_value = 0
	hp_bar.show_percentage = false
	column.add_child(hp_bar)

	# Amount healed or damaged.
	amount_label = Label.new()
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(amount_label, 18)
	column.add_child(amount_label)


func show_healing(
	unit_name: String,
	previous_hp: int,
	max_hp: int,
	healing: int
) -> void:
	var new_hp: int = mini(previous_hp + healing, max_hp)

	title_label.text = "FORT HEALING"
	name_label.text = unit_name

	hp_bar.max_value = max_hp
	hp_bar.value = previous_hp

	hp_label.text = (
		str(previous_hp) + " / " + str(max_hp) + " HP"
	)

	amount_label.text = "+" + str(healing) + " HP"
	amount_label.add_theme_color_override(
		"font_color",
		GameUIStyle.HEALTH
	)

	show()

	# Briefly display the original HP.
	await get_tree().create_timer(0.5).timeout

	# Animate the HP bar.
	var tween := create_tween()
	tween.tween_property(
		hp_bar,
		"value",
		float(new_hp),
		0.8
	)

	tween.parallel().tween_method(
		func(value: float) -> void:
			hp_label.text = (
				str(roundi(value))
				+ " / " + str(max_hp) + " HP"
			),
		float(previous_hp),
		float(new_hp),
		0.8
	)

	await tween.finished

	hp_label.text = (
		str(new_hp) + " / " + str(max_hp) + " HP"
	)

	# Let the player see the result.
	await get_tree().create_timer(1.3).timeout

	hide()



func show_damage(
	unit_name: String,
	previous_hp: int,
	max_hp: int,
	damage: int
) -> void:
	var new_hp: int = maxi(previous_hp - damage, 0)

	title_label.text = "TERRAIN DAMAGE"
	name_label.text = unit_name

	hp_bar.max_value = max_hp
	hp_bar.value = previous_hp

	hp_label.text = (
		str(previous_hp) + " / " + str(max_hp) + " HP"
	)

	amount_label.text = "-" + str(damage) + " HP"
	amount_label.add_theme_color_override(
		"font_color",
		Color("#e76e6e")
	)

	show()

	# Briefly display the original HP.
	await get_tree().create_timer(0.5).timeout

	# Animate HP decreasing.
	var tween := create_tween()

	tween.tween_property(
		hp_bar,
		"value",
		float(new_hp),
		0.8
	)

	tween.parallel().tween_method(
		func(value: float) -> void:
			hp_label.text = (
				str(roundi(value))
				+ " / " + str(max_hp) + " HP"
			),
		float(previous_hp),
		float(new_hp),
		0.8
	)

	await tween.finished

	hp_label.text = (
		str(new_hp) + " / " + str(max_hp) + " HP"
	)

	# Hold the final result.
	await get_tree().create_timer(1.3).timeout

	hide()
