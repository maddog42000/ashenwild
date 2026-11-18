extends RefCounted
class_name CustomMapRuntime

const TILE_SIZE := 24.0

static func build(host: Node, level_root: Node2D, data: Dictionary) -> Vector2:
	var width: int = int(data.get("width", 0))
	var height: int = int(data.get("height", 0))
	var tiles: Array = data.get("tiles", [])
	var world_width: float = float(width) * TILE_SIZE
	host.call("_make_scenery", world_width, true)
	_add_world_bounds(host, level_root, world_width, float(height) * TILE_SIZE)
	_build_terrain(host, level_root, tiles, width, height)
	_build_objects(host, level_root, data.get("objects", []))
	var spawn_data: Dictionary = data.get("spawn", {"x": 2, "y": height - 4})
	var spawn_x: int = clampi(int(spawn_data.get("x", 2)), 0, width - 1)
	var spawn_y: int = clampi(int(spawn_data.get("y", height - 4)), 0, height - 2)
	var spawn := Vector2(float(spawn_x) * TILE_SIZE + TILE_SIZE * 0.5, float(spawn_y + 1) * TILE_SIZE - 22.0)
	return spawn

static func _add_world_bounds(host: Node, level_root: Node2D, world_width: float, world_height: float) -> void:
	for wall_x in [0.0, world_width]:
		var wall := StaticBody2D.new()
		wall.name = "CustomMapBoundary"
		wall.position = Vector2(wall_x, world_height * 0.5)
		wall.collision_layer = 1
		wall.collision_mask = 1
		var shape := RectangleShape2D.new()
		shape.size = Vector2(24.0, world_height + 48.0)
		var collider := CollisionShape2D.new()
		collider.shape = shape
		wall.add_child(collider)
		level_root.add_child(wall)
	host.call("_make_hazard", Vector2(world_width * 0.5, world_height + 42.0), Vector2(world_width, 72.0))

static func _build_terrain(host: Node, level_root: Node2D, tiles: Array, width: int, height: int) -> void:
	for y in range(height):
		var x: int = 0
		while x < width:
			var terrain_id: int = int(tiles[y][x])
			if terrain_id == 0:
				x += 1
				continue
			var start_x: int = x
			while x < width and int(tiles[y][x]) == terrain_id:
				x += 1
			var run_width: int = x - start_x
			var center := Vector2((float(start_x) + float(run_width) * 0.5) * TILE_SIZE, (float(y) + 0.5) * TILE_SIZE)
			var size := Vector2(float(run_width) * TILE_SIZE, TILE_SIZE)
			if terrain_id == 3:
				_add_one_way(level_root, center, size)
			else:
				var tint := Color(0.28, 0.32, 0.34) if terrain_id == 1 else Color(0.22, 0.42, 0.32)
				host.call("_platform", center, size, tint)

static func _add_one_way(level_root: Node2D, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "CustomOneWayPlatform"
	body.position = center
	body.set_meta("platform_size", size)
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("platforms")
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.one_way_collision = true
	collider.one_way_collision_margin = 6.0
	body.add_child(collider)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5), Vector2(-size.x * 0.5, size.y * 0.5)
	])
	visual.color = Color(0.26, 0.47, 0.39)
	body.add_child(visual)
	var cap := Line2D.new()
	cap.points = PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5)])
	cap.width = 3.0
	cap.default_color = Color(0.62, 0.78, 0.58)
	body.add_child(cap)
	level_root.add_child(body)

static func _build_objects(host: Node, level_root: Node2D, objects: Array) -> void:
	for entry in objects:
		if not entry is Dictionary:
			continue
		var x: int = int(entry.get("x", 0))
		var y: int = int(entry.get("y", 0))
		var at := Vector2((float(x) + 0.5) * TILE_SIZE, (float(y) + 0.5) * TILE_SIZE)
		match str(entry.get("type", "")):
			"hazard":
				host.call("_make_hazard", at + Vector2(0, 10), Vector2(22, 22))
			"enemy":
				host.call("_make_enemy", at + Vector2(0, 8))
			"shard":
				host.call("_make_collectible", at)
			"checkpoint":
				host.call("_make_checkpoint", at + Vector2(0, 12))
			"exit":
				host.call("_make_exit", at + Vector2(0, 12))
			"crystal":
				_add_crystal(level_root, at)

static func _add_crystal(level_root: Node2D, at: Vector2) -> void:
	var crystal := Polygon2D.new()
	crystal.name = "DecorativeCrystal"
	crystal.position = at
	crystal.polygon = PackedVector2Array([
		Vector2(0, -11), Vector2(8, -1), Vector2(4, 10), Vector2(-4, 10), Vector2(-8, -1)
	])
	crystal.color = Color(0.32, 0.70, 0.93)
	level_root.add_child(crystal)
