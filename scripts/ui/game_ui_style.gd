class_name GameUIStyle
extends RefCounted

const BACKGROUND := Color("#172c41")
const PANEL := Color("#243b57")
const PANEL_LIGHT := Color("#42658b")
const BORDER := Color("#57718b")
const TEXT := Color("#f2f5f9")
const MUTED_TEXT := Color("#aebed0")
const HEALTH := Color("#70c978")

static func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

static func make_button_style(hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_LIGHT if hovered else PANEL
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", make_button_style())
	button.add_theme_stylebox_override("hover", make_button_style(true))
	button.add_theme_stylebox_override("pressed", make_button_style(true))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)

static func style_label(label: Label, font_size: int = 14, muted: bool = false) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", MUTED_TEXT if muted else TEXT)

static func style_popup_menu(menu: PopupMenu) -> void:
	var popup_theme := Theme.new()
	popup_theme.set_stylebox("panel", "PopupMenu", make_panel_style())
	popup_theme.set_stylebox("hover", "PopupMenu", make_button_style(true))
	popup_theme.set_color("font_color", "PopupMenu", TEXT)
	popup_theme.set_color("font_hover_color", "PopupMenu", TEXT)
	popup_theme.set_color("font_disabled_color", "PopupMenu", MUTED_TEXT)
	popup_theme.set_constant("v_separation", "PopupMenu", 8)
	menu.theme = popup_theme
