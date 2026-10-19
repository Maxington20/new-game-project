class_name UnitResource
extends Resource

@export_group("Identity")
@export var character_id: String = ""

@export var character_name: String = "Unnamed"
@export var unit_class: UnitClassResource

@export_group("Progression")
@export var level: int = 1
@export var experience: int = 0

@export_group("Character Stats")
@export var stats: UnitStatsResource

@export_group("Growth Rates")
@export var growth_rates: UnitGrowthResource

@export_group("Equipment")
@export var equipped_weapon: WeaponResource

@export_group("Inventory")
@export var inventory: Array[WeaponResource] = []

@export_group("Weapon Proficiencies")
@export var weapon_proficiencies: WeaponProficiencyResource
