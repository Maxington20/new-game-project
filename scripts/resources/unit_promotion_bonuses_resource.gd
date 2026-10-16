class_name UnitPromotionBonusesResource
extends Resource

# Fixed stat increases granted when a unit promotes into a class.
# These are bonuses, not growth percentages or stat caps.
@export_range(0, 60, 1) var max_hp: int = 0
@export_range(0, 30, 1) var strength: int = 0
@export_range(0, 30, 1) var skill: int = 0
@export_range(0, 30, 1) var speed: int = 0
@export_range(0, 30, 1) var luck: int = 0
@export_range(0, 30, 1) var defense: int = 0
@export_range(0, 30, 1) var resistance: int = 0
