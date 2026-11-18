extends Node
## Persistent player profile for ASHENWILD.
## All saved data lives in user:// and is intentionally small/versioned.

const SAVE_PATH := "user://ashenwild_profile.json"
const PROFILE_VERSION := 1
const MIN_DIFFICULTY_FACTOR := 0.86
const MAX_DIFFICULTY_FACTOR := 1.12

var carried_embers: int = 0
var banked_embers: int = 0
var total_deaths: int = 0
var successful_regions: int = 0
var adaptive_pressure: float = 0.0
var death_drop_amount: int = 0
var death_drop_position: Vector2 = Vector2.ZERO
var death_drop_active: bool = false

func _ready() -> void:
    load_profile()

func begin_run() -> void:
    # Currency and profile history intentionally persist across title returns.
    # Starting a new campaign must not erase banked progression.
    pass

func award_embers(amount: int) -> void:
    if amount <= 0:
        return
    carried_embers += amount
    save_profile()

func bank_carried() -> int:
    var amount := carried_embers
    banked_embers += amount
    carried_embers = 0
    save_profile()
    return amount

func record_death(at_position: Vector2) -> int:
    # A second death before recovery replaces the previous unclaimed stash.
    death_drop_amount = carried_embers
    death_drop_position = at_position
    death_drop_active = death_drop_amount > 0
    carried_embers = 0
    total_deaths += 1
    adaptive_pressure = clampf(adaptive_pressure - 0.08, -0.14, 0.12)
    save_profile()
    return death_drop_amount

func recover_death_drop() -> int:
    if not death_drop_active or death_drop_amount <= 0:
        return 0
    var recovered := death_drop_amount
    carried_embers += recovered
    death_drop_amount = 0
    death_drop_active = false
    death_drop_position = Vector2.ZERO
    save_profile()
    return recovered

func record_region_clear() -> void:
    successful_regions += 1
    adaptive_pressure = clampf(adaptive_pressure + 0.025, -0.14, 0.12)
    save_profile()

func get_enemy_speed_multiplier() -> float:
    return clampf(1.0 + adaptive_pressure, MIN_DIFFICULTY_FACTOR, MAX_DIFFICULTY_FACTOR)

func get_profile_summary() -> Dictionary:
    return {
        "carried_embers": carried_embers,
        "banked_embers": banked_embers,
        "total_deaths": total_deaths,
        "successful_regions": successful_regions,
        "enemy_speed_multiplier": get_enemy_speed_multiplier(),
        "death_drop_active": death_drop_active,
        "death_drop_amount": death_drop_amount
    }

func save_profile() -> void:
    var data := {
        "version": PROFILE_VERSION,
        "carried_embers": carried_embers,
        "banked_embers": banked_embers,
        "total_deaths": total_deaths,
        "successful_regions": successful_regions,
        "adaptive_pressure": adaptive_pressure,
        "death_drop_amount": death_drop_amount,
        "death_drop_position": [death_drop_position.x, death_drop_position.y],
        "death_drop_active": death_drop_active
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("ASHENWILD profile could not be saved: %s" % FileAccess.get_open_error())
        return
    file.store_string(JSON.stringify(data))
    file.close()

func load_profile() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("ASHENWILD profile could not be loaded: %s" % FileAccess.get_open_error())
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        push_warning("ASHENWILD profile is invalid; starting with a fresh profile.")
        return
    var data: Dictionary = parsed
    if int(data.get("version", 0)) != PROFILE_VERSION:
        push_warning("ASHENWILD profile version is not supported; starting with a fresh profile.")
        return
    carried_embers = maxi(0, int(data.get("carried_embers", 0)))
    banked_embers = maxi(0, int(data.get("banked_embers", 0)))
    total_deaths = maxi(0, int(data.get("total_deaths", 0)))
    successful_regions = maxi(0, int(data.get("successful_regions", 0)))
    adaptive_pressure = clampf(float(data.get("adaptive_pressure", 0.0)), -0.14, 0.12)
    death_drop_amount = maxi(0, int(data.get("death_drop_amount", 0)))
    death_drop_active = bool(data.get("death_drop_active", false)) and death_drop_amount > 0
    var position_data: Variant = data.get("death_drop_position", [0.0, 0.0])
    if position_data is Array and position_data.size() >= 2:
        death_drop_position = Vector2(float(position_data[0]), float(position_data[1]))
    else:
        death_drop_position = Vector2.ZERO
