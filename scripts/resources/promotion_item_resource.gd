
class_name PromotionItemResource
extends Resource

@export var item_name: String = ""
@export_multiline var description: String = ""

@export var eligible_classes: Array[UnitClassResource] = []


func can_promote_class(unit_class: UnitClassResource) -> bool:
	if unit_class == null:
		return false

	if unit_class.promoted_class == null:
		return false

	return eligible_classes.has(unit_class)
