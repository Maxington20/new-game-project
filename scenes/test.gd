
extends Node

func _ready() -> void:
	var definition: UnitResource = load(
		"res://resources/characters/brienne.tres"
	)

	var state: RunUnitState = RunUnitState.create(definition)

	var unit := Unit.new()
	unit.run_state = state
	add_child(unit)

	print("Starting HP: ", unit.current_hp)
	print("Starting alive: ", state.is_alive)

	unit.current_hp = 0

	print("HP after defeat: ", unit.current_hp)
	print("Alive after defeat: ", state.is_alive)

	unit.current_hp = 20

	print("HP after attempted resurrection: ", unit.current_hp)
	print("Run HP after attempted resurrection: ", state.current_hp)
	print("Still defeated: ", not state.is_alive)

	unit.queue_free()
