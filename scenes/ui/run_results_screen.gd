
class_name RunResultsScreen
extends Control

signal finished

var heading_label: Label
var progress_label: Label
var survivors_container: VBoxContainer
var casualties_container: VBoxContainer
var finish_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.85)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 400)
	panel.add_theme_stylebox_override(
		"panel",
		GameUIStyle.make_panel_style()
	)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	heading_label = Label.new()
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(heading_label, 24)
	column.add_child(heading_label)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(progress_label, 16, true)
	column.add_child(progress_label)

	var survivors_heading := Label.new()
	survivors_heading.text = "SURVIVORS"
	GameUIStyle.style_label(survivors_heading, 18)
	column.add_child(survivors_heading)

	survivors_container = VBoxContainer.new()
	column.add_child(survivors_container)

	var casualties_heading := Label.new()
	casualties_heading.text = "FALLEN"
	GameUIStyle.style_label(casualties_heading, 18)
	column.add_child(casualties_heading)

	casualties_container = VBoxContainer.new()
	column.add_child(casualties_container)

	finish_button = Button.new()
	finish_button.text = "Finish Run"
	GameUIStyle.style_button(finish_button)
	finish_button.pressed.connect(
		func(): finished.emit()
	)
	column.add_child(finish_button)


func show_results(summary: RunResultSummary) -> void:
	if summary == null:
		push_error("Cannot display null run summary")
		return

	if not is_node_ready():
		await ready

	heading_label.text = "VICTORY" if summary.is_victory else "DEFEAT"

	progress_label.text = (
		"Encounters Completed: "
		+ str(summary.encounters_completed)
		+ " / "
		+ str(summary.total_encounters)
	)

	_clear_container(survivors_container)
	_clear_container(casualties_container)

	for unit_state in summary.survivors:
		var label := Label.new()
		label.text = unit_state.character.character_name
		GameUIStyle.style_label(label, 14)
		survivors_container.add_child(label)

	for unit_state in summary.casualties:
		var label := Label.new()
		label.text = unit_state.character.character_name
		GameUIStyle.style_label(label, 14, true)
		casualties_container.add_child(label)

	show()


func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
