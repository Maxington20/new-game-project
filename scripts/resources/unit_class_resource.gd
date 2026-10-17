class_name UnitClassResource
extends Resource

@export_group("Identity")
@export var class_name_display: String = ""

@export_group("Promotion")
@export var stat_caps: UnitStatCapsResource
@export var weapon_promotion_bonuses: WeaponPromotionBonusResource
@export var promoted_class: UnitClassResource
@export var promotion_bonuses: UnitPromotionBonusesResource

@export_group("Base Stats")
@export var max_hp: int = 20
@export var strength: int = 5
@export var skill: int = 5
@export var speed: int = 5
@export var defense: int = 5
@export var resistance: int = 0
@export var movement_range: int = 5
@export var min_attack_range: int = 1
@export var max_attack_range: int = 1
@export var constitution: int = 5
@export var luck: int = 0

# Defaults are permissive to preserve existing class resources until configured.
# Set these explicitly for every class before relying on FE7 restrictions.
@export_group("Allowed Weapons")
@export var allow_swords: bool = true
@export var allow_lances: bool = true
@export var allow_axes: bool = true
@export var allow_bows: bool = true
@export var allow_anima: bool = true
@export var allow_light: bool = true
@export var allow_dark: bool = true
@export var allow_staves: bool = true

func can_use_weapon_type(weapon_type: WeaponResource.WeaponType) -> bool:
	match weapon_type:
		WeaponResource.WeaponType.SWORD: return allow_swords
		WeaponResource.WeaponType.LANCE: return allow_lances
		WeaponResource.WeaponType.AXE: return allow_axes
		WeaponResource.WeaponType.BOW: return allow_bows
		WeaponResource.WeaponType.ANIMA: return allow_anima
		WeaponResource.WeaponType.LIGHT: return allow_light
		WeaponResource.WeaponType.DARK: return allow_dark
		WeaponResource.WeaponType.STAFF: return allow_staves
	return false
