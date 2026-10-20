
extends Control

func _ready() -> void:
	var popup := TerrainEffectPopup.new()
	add_child(popup)

	await get_tree().process_frame

	await popup.show_damage(
		"Alden",
		18,
		22,
		5
	)

	print("TERRAIN DAMAGE POPUP TEST COMPLETE")
