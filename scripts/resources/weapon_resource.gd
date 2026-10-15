
class_name WeaponResource
extends Resource

enum WeaponType {
	SWORD,
	LANCE,
	AXE,
	BOW,
	ANIMA,
	LIGHT,
	DARK,
	STAFF
}

@export var weapon_name: String = ""
@export var weapon_type: WeaponType = WeaponType.SWORD

@export_range(0, 30) var might: int = 0
@export_range(1, 10) var min_range: int = 1
@export_range(1, 10) var max_range: int = 1

@export_range(0, 100) var hit: int = 0
@export_range(0, 100) var critical: int = 0
@export_range(0, 30) var weight: int = 0
