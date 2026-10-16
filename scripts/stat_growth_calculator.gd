class_name StatGrowthCalculator
extends RefCounted

const STAT_NAMES: Array[String] = [
    "max_hp", "strength", "skill", "speed", "luck", "defense", "resistance"
]

# Rolls each growth independently and applies the results to character stats.
# Returns a dictionary of stat-name -> points gained (0 or 1).
# This does NOT change character level/EXP or current battle HP.
static func roll_and_apply(unit_data: UnitResource) -> Dictionary:
    var increases: Dictionary = {}
    for stat_name in STAT_NAMES:
        increases[stat_name] = 0

    if unit_data == null or unit_data.growth_rates == null:
        return increases

    if unit_data.stats == null:
        if unit_data.unit_class == null:
            return increases
        unit_data.stats = UnitStatsResource.from_class(unit_data.unit_class)

    for stat_name in STAT_NAMES:
        var chance: int = clampi(int(unit_data.growth_rates.get(stat_name)), 0, 100)
        if randi_range(0, 99) < chance:
            unit_data.stats.set(stat_name, int(unit_data.stats.get(stat_name)) + 1)
            increases[stat_name] = 1

    return increases
