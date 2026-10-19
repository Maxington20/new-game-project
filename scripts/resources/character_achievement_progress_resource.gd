
class_name CharacterAchievementProgress
extends Resource

@export var character_id: String = ""
@export var counters: Dictionary = {}


func get_progress(achievement_id: String) -> int:
	return int(counters.get(achievement_id, 0))


func add_progress(achievement_id: String, amount: int = 1) -> void:
	if achievement_id.strip_edges().is_empty():
		return

	if amount <= 0:
		return

	counters[achievement_id] = get_progress(achievement_id) + amount


func has_completed(achievement_id: String, required_amount: int) -> bool:
	if required_amount <= 0:
		return false

	return get_progress(achievement_id) >= required_amount
