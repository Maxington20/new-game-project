class_name WeaponPromotionBonusResource
extends Resource

# Added weapon experience on promotion. Zero means no bonus.
@export_range(0, 255) var sword_exp: int = 0
@export_range(0, 255) var lance_exp: int = 0
@export_range(0, 255) var axe_exp: int = 0
@export_range(0, 255) var bow_exp: int = 0
@export_range(0, 255) var anima_exp: int = 0
@export_range(0, 255) var light_exp: int = 0
@export_range(0, 255) var dark_exp: int = 0
@export_range(0, 255) var staff_exp: int = 0

# Minimum experience after promotion. 1 unlocks E rank.
@export_range(0, 255) var sword_minimum: int = 0
@export_range(0, 255) var lance_minimum: int = 0
@export_range(0, 255) var axe_minimum: int = 0
@export_range(0, 255) var bow_minimum: int = 0
@export_range(0, 255) var anima_minimum: int = 0
@export_range(0, 255) var light_minimum: int = 0
@export_range(0, 255) var dark_minimum: int = 0
@export_range(0, 255) var staff_minimum: int = 0
