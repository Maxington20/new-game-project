
extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var label := Label.new()
	label.text = "TACTICAL ROGUELITE\nMAIN MENU"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUIStyle.style_label(label, 24)
	center.add_child(label)

	print("MAIN MENU")
	print("Active run: ", RunManager.has_active_run())
