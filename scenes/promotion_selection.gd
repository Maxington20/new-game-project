
class_name PromotionSelection
extends Control

signal promotion_selected(promotion_class: UnitClassResource)

var _options: Array[UnitClassResource] = []

var _title_label: Label
var _options_container: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_interface()
	hide()


func _build_interface() -> void:
	# Darken the battlefield behind the selection screen.
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.65)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	# Center the panel on screen.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	# Heading.
	var heading := Label.new()
	heading.text = "PROMOTION!"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(heading, 18)
	content.add_child(heading)

	# Character name.
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(_title_label, 17)
	content.add_child(_title_label)

	content.add_child(HSeparator.new())

	var instruction := Label.new()
	instruction.text = "Choose a class"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(instruction, 14, true)
	content.add_child(instruction)

	# Promotion buttons.
	_options_container = VBoxContainer.new()
	_options_container.add_theme_constant_override("separation", 8)
	content.add_child(_options_container)


func show_choices(
	character_name: String,
	options: Array[UnitClassResource]
) -> void:
	if options.is_empty():
		push_error("Cannot show promotion selection without options")
		return

	_options = options.duplicate()
	_title_label.text = character_name + "  Lv 10"

	for child in _options_container.get_children():
		_options_container.remove_child(child)
		child.queue_free()

	for promotion_class in _options:
		var button := Button.new()
		button.text = promotion_class.class_name_display
		button.custom_minimum_size = Vector2(320, 48)
		button.focus_mode = Control.FOCUS_NONE

		GameUIStyle.style_button(button)

		button.pressed.connect(
			_on_promotion_pressed.bind(promotion_class)
		)

		_options_container.add_child(button)

	show()


func _on_promotion_pressed(
	promotion_class: UnitClassResource
) -> void:
	if not _options.has(promotion_class):
		return

	hide()
	promotion_selected.emit(promotion_class)
