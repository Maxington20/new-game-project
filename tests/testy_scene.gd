
extends Node

func _ready() -> void:
	var lava: TerrainResource = load(
		"res://resources/terrain/lava.tres"
	)

	print("=== TERRAIN DAMAGE TEST ===")

	print(
		"Enter lava at 20 HP: ",
		TerrainEffectCalculator.calculate_terrain_damage(
			20, lava, true
		)
	)

	print(
		"Enter lava at 3 HP: ",
		TerrainEffectCalculator.calculate_terrain_damage(
			3, lava, true
		)
	)

	print(
		"Start turn on lava: ",
		TerrainEffectCalculator.calculate_terrain_damage(
			20, lava, false
		)
	)

	print(
		"Defeated unit: ",
		TerrainEffectCalculator.calculate_terrain_damage(
			0, lava, true
		)
	)

	print("=== TEST COMPLETE ===")
