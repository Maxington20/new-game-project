
class_name RunUnitState
extends Resource

@export var character: UnitResource
@export var current_hp: int = 0
@export var is_alive: bool = true


static func create(definition: UnitResource) -> RunUnitState:
	var character_copy: UnitResource = RunCharacterFactory.create_character(definition)

	if character_copy == null:
		return null

	var state := RunUnitState.new()
	state.character = character_copy
	state.current_hp = character_copy.stats.max_hp
	state.is_alive = true

	return state


func apply_damage(amount: int) -> void:
	if not is_alive or character == null:
		return

	current_hp = maxi(0, current_hp - maxi(0, amount))

	if current_hp == 0:
		is_alive = false


func heal(amount: int) -> void:
	if not is_alive or character == null or character.stats == null:
		return

	current_hp = mini(
		character.stats.max_hp,
		current_hp + maxi(0, amount)
	)
