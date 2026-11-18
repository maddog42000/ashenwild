extends RefCounted
class_name MapForgeData

const FORMAT_VERSION := 2
const MAP_DIR := "user://custom_maps"
const MIN_WIDTH := 16
const MAX_WIDTH := 100
const MIN_HEIGHT := 12
const MAX_HEIGHT := 60
const MAX_OBJECTS := 500
const TERRAIN_TYPES := ["stone", "moss", "one_way"]
const OBJECT_TYPES := ["hazard", "enemy", "shard", "checkpoint", "exit", "crystal"]

static func make_new(map_name: String, width: int, height: int) -> Dictionary:
	var safe_width: int = clampi(width, MIN_WIDTH, MAX_WIDTH)
	var safe_height: int = clampi(height, MIN_HEIGHT, MAX_HEIGHT)
	var tiles: Array = []
	for y in range(safe_height):
		var row: Array = []
		for x in range(safe_width):
			row.append(0)
		tiles.append(row)
	return {
		"version": FORMAT_VERSION,
		"id": "",
		"name": map_name.strip_edges() if not map_name.strip_edges().is_empty() else "Untitled Hollow",
		"description": "",
		"width": safe_width,
		"height": safe_height,
		"tile_size": 24,
		"tiles": tiles,
		"objects": [],
		"spawn": {"x": 2, "y": safe_height - 3},
		"created_at": Time.get_datetime_string_from_system(true),
		"modified_at": Time.get_datetime_string_from_system(true)
	}

static func validate(data: Dictionary) -> String:
	var width: int = int(data.get("width", 0))
	var height: int = int(data.get("height", 0))
	if int(data.get("version", 0)) not in [1, FORMAT_VERSION]:
		return "Unsupported map format."
	if width < MIN_WIDTH or width > MAX_WIDTH or height < MIN_HEIGHT or height > MAX_HEIGHT:
		return "Map dimensions are outside the supported range."
	var grid: Variant = data.get("tiles", data.get("cells", null))
	if not grid is Array or grid.size() != height:
		return "Tile grid height is invalid."
	for row_value in grid:
		if not row_value is Array or row_value.size() != width:
			return "Tile grid width is invalid."
		for tile_value in row_value:
			if not tile_value is int or int(tile_value) < 0 or int(tile_value) > 3:
				return "Tile grid contains an unknown terrain value."
	var objects_value: Variant = data.get("objects", [])
	if not objects_value is Array or objects_value.size() > MAX_OBJECTS:
		return "Object list is invalid or too large."
	for object_value in objects_value:
		if not object_value is Dictionary:
			return "An object entry is invalid."
		var object_type: String = str(object_value.get("type", ""))
		var ox: int = int(object_value.get("x", -1))
		var oy: int = int(object_value.get("y", -1))
		if object_type not in OBJECT_TYPES or ox < 0 or ox >= width or oy < 0 or oy >= height:
			return "An object is outside the map or has an unknown type."
	var spawn_value: Variant = data.get("spawn", {})
	if not spawn_value is Dictionary:
		return "Player spawn data is invalid."
	var sx: int = int(spawn_value.get("x", -1))
	var sy: int = int(spawn_value.get("y", -1))
	if sx < 0 or sx >= width or sy < 0 or sy >= height:
		return "Player spawn is outside the map."
	for object_value in objects_value:
		if str(object_value.get("type", "")) in ["hazard", "enemy"] and int(object_value.get("x", -1)) == sx and int(object_value.get("y", -1)) == sy:
			return "Player spawn overlaps a hazard or enemy."
	return ""

static func validate_playable(data: Dictionary) -> String:
	var error_text: String = validate(data)
	if not error_text.is_empty():
		return error_text
	for item in data.get("objects", []):
		if str(item.get("type", "")) == "exit":
			return ""
	var spawn: Dictionary = data.get("spawn", {})
	var spawn_x: int = int(spawn.get("x", 0))
	var spawn_y: int = int(spawn.get("y", 0))
	var tiles: Array = data.get("tiles", [])
	if spawn_y + 1 >= int(data.get("height", 0)) or int(tiles[spawn_y + 1][spawn_x]) not in [1, 2, 3]:
		return "Place a solid or one-way tile directly beneath the player spawn."
	return "Place at least one exit before testing."

static func normalize(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var cells_value: Variant = result.get("cells", null)
	if not result.has("tiles") and cells_value is Array:
		var old_cells: Array = cells_value
		var width: int = int(result.get("width", 0))
		var height: int = int(result.get("height", 0))
		if old_cells.size() != height:
			return result
		for row_value in old_cells:
			if not row_value is Array or row_value.size() != width:
				return result
			for tile_value in row_value:
				if not tile_value is int or int(tile_value) < 0 or int(tile_value) > 8:
					return result
		var terrain: Array = []
		var objects: Array = []
		for y in range(old_cells.size()):
			var row: Array = []
			for x in range(old_cells[y].size()):
				var old_id: int = int(old_cells[y][x])
				row.append(old_id if old_id in [1, 2] else 0)
				var kind := ""
				match old_id:
					3: kind = "hazard"
					4: kind = "enemy"
					5: kind = "shard"
					6: kind = "checkpoint"
					7: kind = "exit"
					8: kind = "crystal"
				if not kind.is_empty():
					objects.append({"type": kind, "x": x, "y": y})
			terrain.append(row)
		result["tiles"] = terrain
		result["objects"] = objects
		result["spawn"] = {"x": 2, "y": int(result.get("height", 18)) - 3}
	result.erase("cells")
	result["version"] = FORMAT_VERSION
	return result

static func list_maps() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var directory := DirAccess.open(MAP_DIR)
	if directory == null:
		return entries
	directory.list_dir_begin()
	var filename: String = directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(".json"):
			var file := FileAccess.open(MAP_DIR.path_join(filename), FileAccess.READ)
			if file != null:
				var parsed: Variant = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary:
					var normalized: Dictionary = normalize(parsed)
					if validate(normalized).is_empty():
						if str(normalized.get("id", "")).is_empty():
							normalized["id"] = filename.get_basename()
						normalized["file_name"] = filename
						entries.append(normalized)
		filename = directory.get_next()
	directory.list_dir_end()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("modified_at", "")) > str(b.get("modified_at", ""))
	)
	return entries

static func save_map(data: Dictionary) -> Dictionary:
	var normalized: Dictionary = normalize(data)
	var error_text: String = validate(normalized)
	if not error_text.is_empty():
		return {"ok": false, "error": error_text}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_DIR))
	var map_id: String = str(normalized.get("id", ""))
	if map_id.is_empty():
		map_id = _new_id()
		while FileAccess.file_exists(MAP_DIR.path_join(map_id + ".json")):
			map_id = _new_id()
		normalized["id"] = map_id
		normalized["created_at"] = Time.get_datetime_string_from_system(true)
	elif map_id.validate_filename() != map_id:
		return {"ok": false, "error": "The map identifier is invalid."}
	if str(normalized.get("created_at", "")).is_empty():
		normalized["created_at"] = Time.get_datetime_string_from_system(true)
	normalized["modified_at"] = Time.get_datetime_string_from_system(true)
	var path: String = MAP_DIR.path_join(map_id + ".json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open the map file for writing."}
	file.store_string(JSON.stringify(normalized, "\t"))
	file.close()
	return {"ok": true, "data": normalized, "path": path}

static func load_map(map_id: String) -> Dictionary:
	if map_id.is_empty() or map_id.validate_filename() != map_id:
		return {"ok": false, "error": "Invalid map identifier."}
	var path: String = MAP_DIR.path_join(map_id + ".json")
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "That map no longer exists."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read the selected map."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "error": "The map file is corrupted or unreadable."}
	var normalized: Dictionary = normalize(parsed)
	if str(normalized.get("id", "")).is_empty():
		normalized["id"] = map_id
	var error_text: String = validate(normalized)
	if not error_text.is_empty():
		return {"ok": false, "error": error_text}
	return {"ok": true, "data": normalized}

static func delete_map(map_id: String) -> bool:
	if map_id.is_empty() or map_id.validate_filename() != map_id:
		return false
	var path: String = MAP_DIR.path_join(map_id + ".json")
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

static func duplicate_map(data: Dictionary, new_name: String) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	copy["id"] = ""
	copy["name"] = new_name
	copy["created_at"] = Time.get_datetime_string_from_system(true)
	copy["modified_at"] = copy["created_at"]
	return save_map(copy)

static func generate(map_name: String, width: int, height: int, style: String, seed_value: int) -> Dictionary:
	var result: Dictionary = make_new(map_name, width, height)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	result["seed"] = rng.seed
	var tiles: Array = result["tiles"]
	var floor_y: int = height - 3
	for x in range(width):
		tiles[floor_y][x] = 1
		tiles[floor_y + 1][x] = 1
	var segment_width: int = 4
	match style:
		"Ruined Castle": segment_width = 5
		"Underground Caves": segment_width = 4
		"Forest Ruins": segment_width = 6
		"Challenge Course": segment_width = 3
	var x_pos: int = 5
	var platform_row: int = floor_y - 4
	while x_pos < width - 7:
		var run_length: int = rng.randi_range(segment_width, segment_width + 2)
		var row_y: int = clampi(platform_row + rng.randi_range(-1, 1), 3, floor_y - 3)
		for px in range(x_pos, mini(x_pos + run_length, width - 3)):
			tiles[row_y][px] = 2 if style in ["Forest Ruins", "Underground Caves"] else 1
		if rng.randf() > 0.45:
			var object_y: int = row_y - 1
			result["objects"].append({"type": "shard", "x": x_pos + 1, "y": object_y})
		if style == "Challenge Course" or rng.randf() > 0.58:
			result["objects"].append({"type": "enemy", "x": x_pos + mini(run_length - 1, 2), "y": row_y - 1})
		x_pos += run_length + rng.randi_range(2, 4)
		platform_row = clampi(platform_row + rng.randi_range(-1, 1), floor_y - 6, floor_y - 3)
	var checkpoint_x: int = maxi(4, int(width * 0.48))
	result["objects"].append({"type": "checkpoint", "x": checkpoint_x, "y": floor_y - 1})
	result["objects"].append({"type": "exit", "x": width - 3, "y": floor_y - 1})
	result["objects"].append({"type": "hazard", "x": int(width * 0.32), "y": floor_y - 1})
	if style in ["Underground Caves", "Ruined Castle"]:
		for i in range(3):
			result["objects"].append({"type": "crystal", "x": rng.randi_range(7, width - 5), "y": rng.randi_range(3, floor_y - 2)})
	if style == "Forest Ruins":
		for i in range(5):
			result["objects"].append({"type": "crystal", "x": rng.randi_range(4, width - 5), "y": rng.randi_range(3, floor_y - 2)})
	result["spawn"] = {"x": 2, "y": floor_y - 1}
	return result

static func _new_id() -> String:
	var stamp: int = int(Time.get_unix_time_from_system())
	var salt: int = randi_range(10000, 99999)
	return "%d_%d" % [stamp, salt]
