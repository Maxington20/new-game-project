class_name UnitActionMenu
extends PanelContainer

signal attack_selected
signal wait_selected
signal cancel_selected

@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

func _ready() -> void:
	add_theme_stylebox_override("panel", GameUIStyle.make_panel_style())
	GameUIStyle.style_button(attack_button)
	GameUIStyle.style_button(wait_button)
	GameUIStyle.style_button(cancel_button)
	$VBoxContainer.add_theme_constant_override("separation", 10)

	attack_button.pressed.connect(func(): attack_selected.emit())
	wait_button.pressed.connect(func(): wait_selected.emit())
	cancel_button.pressed.connect(func(): cancel_selected.emit())
	hide()

func open_menu(screen_position: Vector2, can_attack: bool) -> void:
	attack_button.visible = can_attack
	custom_minimum_size = Vector2.ZERO
	size = Vector2.ZERO
	position = screen_position
	show()
	reset_size.call_deferred()
	if can_attack:
		attack_button.grab_focus()
	else:
		wait_button.grab_focus()

func close_menu() -> void:
	hide()
