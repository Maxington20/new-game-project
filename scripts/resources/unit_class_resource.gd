
class_name UnitClassResource
extends Resource

@export var class_name_display: String = ""

@export var max_hp: int = 20
@export var strength: int = 5
@export var skill: int = 5
@export var speed: int = 5
@export var defense: int = 5
@export var resistance: int = 0

@export var movement_range: int = 5

@export_range(1, 10) var min_attack_range: int = 1
@export_range(1, 10) var max_attack_range: int = 1
