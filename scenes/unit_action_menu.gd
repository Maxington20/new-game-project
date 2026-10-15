
class_name UnitActionMenu
extends PanelContainer

signal wait_selected
signal cancel_selected

@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton


func _ready() -> void:
	wait_button.pressed.connect(
		func(): wait_selected.emit()
	)

	cancel_button.pressed.connect(
		func(): cancel_selected.emit()
	)

	hide()


func open_menu(screen_position: Vector2) -> void:
	position = screen_position
	show()
	wait_button.grab_focus()


func close_menu() -> void:
	hide()
