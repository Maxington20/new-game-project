
class_name TerrainResource
extends Resource

enum TerrainType {
	PLAINS,
	FOREST,
	MOUNTAIN,
	WALL,
	FORT,
	LAVA,
	SWAMP,
	ROAD
}

@export var terrain_type: TerrainType = TerrainType.PLAINS

@export_group("Movement")
@export_range(1, 10) var movement_cost: int = 1
@export var impassable: bool = false

@export_group("Combat")
@export var defense_bonus: int = 0
@export var avoid_bonus: int = 0

@export_group("Healing")
@export_range(0.0, 1.0, 0.05) var turn_start_heal_percent: float = 0.0

@export_group("Damage")
@export_range(0, 100) var damage_on_enter: int = 0
@export_range(0, 100) var damage_on_turn_start: int = 0
