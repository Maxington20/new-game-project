
class_name UnitResource
extends Resource

@export var character_name: String = "Unnamed"
@export var unit_class: UnitClassResource

@export_group("Progression")
@export_range(1, 20) var level: int = 1
@export var experience: int = 0
