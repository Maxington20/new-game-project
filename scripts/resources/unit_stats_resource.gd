class_name UnitStatsResource
extends Resource

@export var max_hp: int = 20
@export var strength: int = 5
@export var skill: int = 5
@export var speed: int = 5
@export var luck: int = 0
@export var defense: int = 5
@export var resistance: int = 0


static func from_class(unit_class: UnitClassResource) -> UnitStatsResource:
	var stats := UnitStatsResource.new()
	if unit_class == null:
		return stats
	stats.max_hp = unit_class.max_hp
	stats.strength = unit_class.strength
	stats.skill = unit_class.skill
	stats.speed = unit_class.speed
	stats.luck = unit_class.luck
	stats.defense = unit_class.defense
	stats.resistance = unit_class.resistance
	return stats
