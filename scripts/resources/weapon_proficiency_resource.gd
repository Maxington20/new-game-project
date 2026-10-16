
class_name WeaponProficiencyResource
extends Resource

@export_group("Physical Weapons")
@export_range(0, 255) var sword_exp: int = 0
@export_range(0, 255) var lance_exp: int = 0
@export_range(0, 255) var axe_exp: int = 0
@export_range(0, 255) var bow_exp: int = 0

@export_group("Magic and Staves")
@export_range(0, 255) var anima_exp: int = 0
@export_range(0, 255) var light_exp: int = 0
@export_range(0, 255) var dark_exp: int = 0
@export_range(0, 255) var staff_exp: int = 0


func get_experience(
	weapon_type: WeaponResource.WeaponType
) -> int:
	match weapon_type:
		WeaponResource.WeaponType.SWORD:
			return sword_exp
		WeaponResource.WeaponType.LANCE:
			return lance_exp
		WeaponResource.WeaponType.AXE:
			return axe_exp
		WeaponResource.WeaponType.BOW:
			return bow_exp
		WeaponResource.WeaponType.ANIMA:
			return anima_exp
		WeaponResource.WeaponType.LIGHT:
			return light_exp
		WeaponResource.WeaponType.DARK:
			return dark_exp
		WeaponResource.WeaponType.STAFF:
			return staff_exp

	return 0


func set_experience(
	weapon_type: WeaponResource.WeaponType,
	amount: int
) -> void:
	amount = clampi(amount, 0, 255)

	match weapon_type:
		WeaponResource.WeaponType.SWORD:
			sword_exp = amount
		WeaponResource.WeaponType.LANCE:
			lance_exp = amount
		WeaponResource.WeaponType.AXE:
			axe_exp = amount
		WeaponResource.WeaponType.BOW:
			bow_exp = amount
		WeaponResource.WeaponType.ANIMA:
			anima_exp = amount
		WeaponResource.WeaponType.LIGHT:
			light_exp = amount
		WeaponResource.WeaponType.DARK:
			dark_exp = amount
		WeaponResource.WeaponType.STAFF:
			staff_exp = amount


func add_experience(
	weapon_type: WeaponResource.WeaponType,
	amount: int
) -> void:
	if amount <= 0:
		return

	var current: int = get_experience(weapon_type)
	set_experience(weapon_type, current + amount)
