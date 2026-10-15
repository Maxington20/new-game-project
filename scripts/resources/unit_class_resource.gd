
class_name UnitClassResource
extends Resource

@export var class_name_display: String = "Swordsman"

@export_group("Base Stats")
@export var max_hp: int = 20
@export var strength: int = 5
@export var skill: int = 5
@export var speed: int = 5
@export var defense: int = 3
@export var resistance: int = 1

@export_group("Movement")
@export_range(1, 15) var movement_range: int = 5
