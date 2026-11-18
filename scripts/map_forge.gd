extends Control
## Map Forge editor. The instance stays alive during Test Map so the edit session is preserved.
signal closed
signal map_test_requested(map_data: Dictionary)

const TILE := 24.0
const PALETTE := ["STONE", "MOSS", "ONE-WAY", "HAZARD", "ASH MITE", "SHARD", "CHECKPOINT", "EXIT", "CRYSTAL", "SPAWN", "ERASE"]
const TERRAIN := {"STONE": 1, "MOSS": 2, "ONE-WAY": 3}
const OBJECTS := {"HAZARD": "hazard", "ASH MITE": "enemy", "SHARD": "shard", "CHECKPOINT": "checkpoint", "EXIT": "exit", "CRYSTAL": "crystal"}
const COLORS := {
	"STONE": Color(0.55, 0.58, 0.59), "MOSS": Color(0.39, 0.70, 0.45),
	"ONE-WAY": Color(0.72, 0.77, 0.57), "HAZARD": Color(0.95, 0.31, 0.20),
	"ASH MITE": Color(0.88, 0.35, 0.29), "SHARD": Color(0.23, 0.95, 0.84),
	"CHECKPOINT": Color(1.0, 0.68, 0.32), "EXIT": Color(1.0, 0.86, 0.54),
	"CRYSTAL": Color(0.39, 0.70, 1.0), "SPAWN": Color(1.0, 0.91, 0.62),
	"ERASE": Color(0.72, 0.74, 0.76)
}

var data: Dictionary
var active_kind := "STONE"
var select_mode := false
var grid_visible := true
var canvas_rect := Rect2()
var cell_size := 16.0
var selected_cell := Vector2i(-1, -1)
var selected_object := -1
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var painting := false
var name_field: LineEdit
var description_field: LineEdit
var status: Label
var palette_grid: GridContainer
var paint_tool_button: Button
var select_tool_button: Button
var maps_list: ItemList
var maps: Array[Dictionary] = []
var style_picker: OptionButton
var seed_field: LineEdit
var width_field: SpinBox
var height_field: SpinBox
var delete_dialog: ConfirmationDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	data = MapForgeData.make_new("Untitled Hollow", 40, 20)
	_record()
	_build_ui()
	_layout()
	_refresh_maps()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()
		queue_redraw()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.012, 0.019, 0.032, 0.98)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var header := PanelContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 12
	header.offset_top = 8
	header.offset_right = -12
	header.offset_bottom = 56
	add_child(header)
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 10)
	header.add_child(head_row)
	var heading := Label.new()
	heading.text = "ASHENWILD  /  MAP FORGE"
	heading.add_theme_font_size_override("font_size", 21)
	heading.add_theme_color_override("font_color", Color(0.42, 0.94, 0.84))
	head_row.add_child(heading)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(gap)
	name_field = LineEdit.new()
	name_field.text = str(data["name"])
	name_field.placeholder_text = "Map name"
	name_field.custom_minimum_size = Vector2(190, 38)
	name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(name_field)
	var back := _button("BACK", _close)
	back.custom_minimum_size.x = 84
	head_row.add_child(back)

	var side := PanelContainer.new()
	side.name = "EditorSidebar"
	side.position = Vector2(12, 66)
	add_child(side)
	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(side_scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 5)
	side_scroll.add_child(stack)
	stack.add_child(_label("TOOLS & PIECES"))
	var tool_row := HBoxContainer.new()
	paint_tool_button = _button("PAINT", func(): _set_select_mode(false))
	select_tool_button = _button("SELECT", func(): _set_select_mode(true))
	paint_tool_button.toggle_mode = true
	select_tool_button.toggle_mode = true
	paint_tool_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_tool_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tool_row.add_child(paint_tool_button)
	tool_row.add_child(select_tool_button)
	stack.add_child(tool_row)
	palette_grid = GridContainer.new()
	palette_grid.columns = 2
	palette_grid.add_theme_constant_override("h_separation", 4)
	palette_grid.add_theme_constant_override("v_separation", 4)
	stack.add_child(palette_grid)
	for kind in PALETTE:
		var b := _button(kind, _choose_kind.bind(kind))
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(68, 34)
		b.add_theme_font_size_override("font_size", 10)
		b.add_theme_color_override("font_color", COLORS[kind])
		palette_grid.add_child(b)
	stack.add_child(_label("RANDOM GENERATOR"))
	style_picker = OptionButton.new()
	for style in ["Basic Platforming", "Ruined Castle", "Underground Caves", "Forest Ruins", "Challenge Course"]:
		style_picker.add_item(style)
	stack.add_child(style_picker)
	seed_field = LineEdit.new()
	seed_field.text = "20261118"
	seed_field.placeholder_text = "Seed"
	stack.add_child(seed_field)
	description_field = LineEdit.new()
	description_field.placeholder_text = "Description (optional)"
	stack.add_child(description_field)
	var dimension_row := HBoxContainer.new()
	width_field = SpinBox.new()
	width_field.min_value = MapForgeData.MIN_WIDTH
	width_field.max_value = MapForgeData.MAX_WIDTH
	width_field.value = 40
	width_field.prefix = "W "
	width_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	height_field = SpinBox.new()
	height_field.min_value = MapForgeData.MIN_HEIGHT
	height_field.max_value = MapForgeData.MAX_HEIGHT
	height_field.value = 20
	height_field.prefix = "H "
	height_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dimension_row.add_child(width_field)
	dimension_row.add_child(height_field)
	stack.add_child(dimension_row)
	stack.add_child(_button("NEW BLANK MAP", _new_map))
	stack.add_child(_label("MY MAPS"))
	maps_list = ItemList.new()
	maps_list.custom_minimum_size = Vector2(130, 94)
	maps_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	maps_list.item_selected.connect(_on_map_selected)
	stack.add_child(maps_list)
	var map_actions := GridContainer.new()
	map_actions.columns = 2
	map_actions.add_child(_button("LOAD", _load_map))
	map_actions.add_child(_button("RENAME", _rename_map))
	map_actions.add_child(_button("DUPLICATE", _duplicate_map))
	map_actions.add_child(_button("DELETE", _ask_delete))
	stack.add_child(map_actions)
	status = _label("Choose a piece, then tap or drag on the canvas.")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 11)
	stack.add_child(status)

	var toolbar := PanelContainer.new()
	toolbar.name = "EditorToolbar"
	add_child(toolbar)
	var tool_rows := VBoxContainer.new()
	tool_rows.add_theme_constant_override("separation", 4)
	toolbar.add_child(tool_rows)
	var row_a := HBoxContainer.new()
	var row_b := HBoxContainer.new()
	tool_rows.add_child(row_a)
	tool_rows.add_child(row_b)
	_add_toolbar_button(row_a, "UNDO", _undo)
	_add_toolbar_button(row_a, "REDO", _redo)
	_add_toolbar_button(row_a, "GRID", _toggle_grid)
	_add_toolbar_button(row_a, "CLEAR", _clear_map)
	_add_toolbar_button(row_a, "RANDOMIZE", _randomize)
	_add_toolbar_button(row_b, "SAVE", _save_map)
	_add_toolbar_button(row_b, "LOAD", _load_map)
	_add_toolbar_button(row_b, "DUPLICATE", _duplicate_map)
	_add_toolbar_button(row_b, "DELETE", _ask_delete)
	_add_toolbar_button(row_b, "TEST MAP", _test_map)

	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "Delete saved map?"
	delete_dialog.dialog_text = "This permanently deletes the selected map."
	delete_dialog.confirmed.connect(_delete_map)
	add_child(delete_dialog)
	_refresh_palette()

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var sidebar_width: float = clampf(viewport_size.x * 0.205, 164.0, 208.0)
	var side := get_node("EditorSidebar") as PanelContainer
	side.position = Vector2(12, 66)
	side.size = Vector2(sidebar_width, maxf(170.0, viewport_size.y - 190.0))
	var toolbar := get_node("EditorToolbar") as PanelContainer
	toolbar.position = Vector2(12 + sidebar_width + 10, viewport_size.y - 116)
	toolbar.size = Vector2(maxf(220.0, viewport_size.x - toolbar.position.x - 12), 104)
	canvas_rect = Rect2(toolbar.position.x, 66, maxf(150.0, viewport_size.x - toolbar.position.x - 12), maxf(110.0, toolbar.position.y - 76))
	cell_size = minf(canvas_rect.size.x / float(data["width"]), canvas_rect.size.y / float(data["height"]))
	cell_size = maxf(5.0, cell_size)

func _draw() -> void:
	if canvas_rect.size.x <= 0:
		return
	draw_rect(canvas_rect, Color(0.018, 0.027, 0.043))
	var width: int = int(data["width"])
	var height: int = int(data["height"])
	var grid_size := Vector2(width, height) * cell_size
	var origin := canvas_rect.position + (canvas_rect.size - grid_size) * 0.5
	var tiles: Array = data["tiles"]
	for y in range(height):
		for x in range(width):
			var rect := Rect2(origin + Vector2(x, y) * cell_size, Vector2(cell_size, cell_size))
			match int(tiles[y][x]):
				1: _draw_stone(rect)
				2: _draw_moss(rect)
				3: _draw_one_way(rect)
			if grid_visible:
				draw_rect(rect, Color(0.42, 0.60, 0.62, 0.35), false, 1.0)
	for obj in data["objects"]:
		var center := origin + (Vector2(float(obj["x"]), float(obj["y"])) + Vector2(0.5, 0.5)) * cell_size
		_draw_object(center, str(obj["type"]), cell_size * 0.4)
	var spawn: Dictionary = data["spawn"]
	var spawn_center := origin + (Vector2(float(spawn["x"]), float(spawn["y"])) + Vector2(0.5, 0.5)) * cell_size
	draw_circle(spawn_center, maxf(4.0, cell_size * 0.34), Color(0.95, 0.86, 0.52, 0.3))
	draw_colored_polygon(PackedVector2Array([
		spawn_center + Vector2(0, -cell_size * 0.38), spawn_center + Vector2(cell_size * 0.3, 0),
		spawn_center + Vector2(0, cell_size * 0.38), spawn_center + Vector2(-cell_size * 0.3, 0)
	]), COLORS["SPAWN"])
	if selected_cell.x >= 0:
		draw_rect(Rect2(origin + Vector2(selected_cell) * cell_size, Vector2.ONE * cell_size), Color(1.0, 0.92, 0.53), false, 2.0)
	draw_rect(canvas_rect, Color(0.35, 0.58, 0.56), false, 2.0)
	draw_string(ThemeDB.fallback_font, canvas_rect.position + Vector2(8, 18), "%s   %d × %d   seed %s" % [str(data["name"]), width, height, str(data.get("seed", "—"))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.76, 0.88, 0.82))

func _draw_stone(rect: Rect2) -> void:
	draw_rect(rect.grow(-1), Color(0.25, 0.29, 0.32))
	draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, maxf(2, rect.size.y * 0.22))), Color(0.49, 0.51, 0.52))
	draw_line(rect.position + Vector2(rect.size.x * 0.58, rect.size.y * 0.28), rect.position + Vector2(rect.size.x * 0.47, rect.size.y * 0.76), Color(0.12, 0.15, 0.18), 1)

func _draw_moss(rect: Rect2) -> void:
	draw_rect(rect.grow(-1), Color(0.22, 0.34, 0.27))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, maxf(2, rect.size.y * 0.25))), Color(0.38, 0.65, 0.40))
	for i in range(3):
		var px: float = rect.position.x + rect.size.x * (0.18 + float(i) * 0.28)
		draw_line(Vector2(px, rect.position.y + rect.size.y * 0.2), Vector2(px - 1, rect.position.y + rect.size.y * 0.43), Color(0.15, 0.48, 0.28), 1)

func _draw_one_way(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.32), Vector2(rect.size.x, rect.size.y * 0.58)), Color(0.38, 0.38, 0.30))
	draw_line(rect.position + Vector2(0, rect.size.y * 0.24), rect.position + Vector2(rect.size.x, rect.size.y * 0.24), Color(0.77, 0.84, 0.59), 2)

func _draw_object(center: Vector2, kind: String, radius: float) -> void:
	match kind:
		"hazard":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, radius), center + Vector2(0, -radius), center + Vector2(radius, radius)]), COLORS["HAZARD"])
		"enemy":
			draw_circle(center, radius, COLORS["ASH MITE"])
			draw_circle(center + Vector2(-radius * 0.3, -radius * 0.1), maxf(1, radius * 0.14), Color.WHITE)
			draw_circle(center + Vector2(radius * 0.3, -radius * 0.1), maxf(1, radius * 0.14), Color.WHITE)
		"shard":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.6, 0), center + Vector2(0, radius), center + Vector2(-radius * 0.6, 0)]), COLORS["SHARD"])
		"checkpoint":
			draw_line(center + Vector2(-radius * 0.4, radius), center + Vector2(-radius * 0.4, -radius), Color(0.82, 0.75, 0.56), 2)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.4, -radius), center + Vector2(radius, -radius * 0.6), center + Vector2(-radius * 0.4, 0)]), COLORS["CHECKPOINT"])
		"exit":
			draw_arc(center, radius, PI, TAU, 16, COLORS["EXIT"], 3)
			draw_line(center + Vector2(-radius, 0), center + Vector2(-radius, radius), COLORS["EXIT"], 2)
			draw_line(center + Vector2(radius, 0), center + Vector2(radius, radius), COLORS["EXIT"], 2)
		"crystal":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.55, 0), center + Vector2(0, radius), center + Vector2(-radius * 0.55, 0)]), COLORS["CRYSTAL"])

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var ctrl: bool = event.ctrl_pressed or event.meta_pressed
		if ctrl and event.keycode == KEY_Z: _undo()
		elif ctrl and event.keycode == KEY_Y: _redo()
		elif ctrl and event.keycode == KEY_S: _save_map()
		elif event.keycode == KEY_G: _toggle_grid()
		elif event.keycode == KEY_DELETE: _erase_cell()
		elif event.keycode == KEY_ESCAPE: _close()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if canvas_rect.has_point(event.position):
				painting = true
				_paint(event.position)
		else:
			painting = false
	elif event is InputEventMouseMotion and painting:
		_paint(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and canvas_rect.has_point(event.position):
			painting = true
			_paint(event.position)
		elif not event.pressed:
			painting = false
	elif event is InputEventScreenDrag and painting:
		_paint(event.position)

func _paint(position: Vector2) -> void:
	if not canvas_rect.has_point(position):
		return
	var origin := canvas_rect.position + (canvas_rect.size - Vector2(data["width"], data["height"]) * cell_size) * 0.5
	var cell := Vector2i(floori((position.x - origin.x) / cell_size), floori((position.y - origin.y) / cell_size))
	if cell.x < 0 or cell.x >= int(data["width"]) or cell.y < 0 or cell.y >= int(data["height"]):
		return
	selected_cell = cell
	if select_mode:
		selected_object = _object_at(cell)
		queue_redraw()
		return
	if _cell_already_matches(cell):
		return
	_record()
	if TERRAIN.has(active_kind):
		data["tiles"][cell.y][cell.x] = int(TERRAIN[active_kind])
		_remove_objects(cell)
	elif active_kind == "ERASE":
		data["tiles"][cell.y][cell.x] = 0
		_remove_objects(cell)
	elif active_kind == "SPAWN":
		data["spawn"] = {"x": cell.x, "y": cell.y}
	else:
		var kind: String = str(OBJECTS.get(active_kind, ""))
		if not kind.is_empty():
			_remove_objects(cell)
			data["objects"].append({"type": kind, "x": cell.x, "y": cell.y})
	queue_redraw()

func _cell_already_matches(cell: Vector2i) -> bool:
	if TERRAIN.has(active_kind):
		return int(data["tiles"][cell.y][cell.x]) == int(TERRAIN[active_kind])
	if active_kind == "ERASE":
		return int(data["tiles"][cell.y][cell.x]) == 0 and _object_at(cell) < 0
	if active_kind == "SPAWN":
		return int(data["spawn"]["x"]) == cell.x and int(data["spawn"]["y"]) == cell.y
	return false

func _object_at(cell: Vector2i) -> int:
	for i in range(data["objects"].size() - 1, -1, -1):
		var obj: Dictionary = data["objects"][i]
		if int(obj["x"]) == cell.x and int(obj["y"]) == cell.y:
			return i
	return -1

func _remove_objects(cell: Vector2i) -> void:
	for i in range(data["objects"].size() - 1, -1, -1):
		if int(data["objects"][i]["x"]) == cell.x and int(data["objects"][i]["y"]) == cell.y:
			data["objects"].remove_at(i)

func _erase_cell() -> void:
	if selected_cell.x < 0:
		return
	_choose_kind("ERASE")
	_paint(canvas_rect.position + (canvas_rect.size - Vector2(data["width"], data["height"]) * cell_size) * 0.5 + (Vector2(selected_cell) + Vector2(0.5, 0.5)) * cell_size)

func _choose_kind(kind: String) -> void:
	active_kind = kind
	select_mode = false
	_refresh_palette()
	status.text = "Selected piece: %s" % kind

func _set_select_mode(enabled: bool) -> void:
	select_mode = enabled
	paint_tool_button.button_pressed = not enabled
	select_tool_button.button_pressed = enabled
	status.text = "Tap a cell to inspect its object." if enabled else "Paint mode active."

func _refresh_palette() -> void:
	for child in palette_grid.get_children():
		if child is Button:
			child.button_pressed = child.text == active_kind
			child.modulate = Color.WHITE if child.text == active_kind else Color(0.78, 0.82, 0.84)
	if is_instance_valid(paint_tool_button):
		paint_tool_button.button_pressed = not select_mode
	if is_instance_valid(select_tool_button):
		select_tool_button.button_pressed = select_mode

func _record() -> void:
	undo_stack.append(data.duplicate(true))
	if undo_stack.size() > 60:
		undo_stack.pop_front()
	redo_stack.clear()

func _undo() -> void:
	if undo_stack.size() <= 1:
		return
	redo_stack.append(data.duplicate(true))
	data = undo_stack.pop_back().duplicate(true)
	_sync_fields()
	queue_redraw()

func _redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(data.duplicate(true))
	data = redo_stack.pop_back().duplicate(true)
	_sync_fields()
	queue_redraw()

func _sync_fields() -> void:
	name_field.text = str(data["name"])
	description_field.text = str(data.get("description", ""))
	width_field.value = int(data["width"])
	height_field.value = int(data["height"])
	_layout()

func _new_map() -> void:
	_record()
	data = MapForgeData.make_new(name_field.text, int(width_field.value), int(height_field.value))
	selected_cell = Vector2i(-1, -1)
	_sync_fields()
	status.text = "Blank map created. Add terrain, a spawn and an exit."
	queue_redraw()

func _clear_map() -> void:
	_record()
	data = MapForgeData.make_new(str(data["name"]), int(data["width"]), int(data["height"]))
	data["id"] = str(data.get("id", ""))
	_sync_fields()
	status.text = "Map cleared."
	queue_redraw()

func _randomize() -> void:
	_record()
	var style: String = style_picker.get_item_text(style_picker.selected)
	var seed_value: int = int(seed_field.text) if seed_field.text.is_valid_int() else 0
	data = MapForgeData.generate(name_field.text, int(width_field.value), int(height_field.value), style, seed_value)
	_sync_fields()
	status.text = "Generated %s. Edit the layout, then save." % style
	queue_redraw()

func _save_map() -> void:
	data["name"] = name_field.text.strip_edges()
	data["description"] = description_field.text.strip_edges()
	if str(data["name"]).is_empty():
		status.text = "Enter a map name before saving."
		return
	var result: Dictionary = MapForgeData.save_map(data)
	if not result.get("ok", false):
		status.text = "Save failed: %s" % str(result.get("error", "Unknown error"))
		return
	data = result["data"]
	_record()
	_refresh_maps()
	status.text = "Saved locally: %s" % str(data["name"])
	queue_redraw()

func _refresh_maps() -> void:
	maps = MapForgeData.list_maps()
	maps_list.clear()
	for entry in maps:
		maps_list.add_item("%s  [%s×%s]" % [str(entry["name"]), str(entry["width"]), str(entry["height"])])
		maps_list.set_item_metadata(maps_list.item_count - 1, str(entry["id"]))

func _selected_map() -> Dictionary:
	var selected: PackedInt32Array = maps_list.get_selected_items()
	if selected.is_empty() or selected[0] >= maps.size():
		return {}
	return maps[selected[0]]

func _on_map_selected(index: int) -> void:
	if index >= 0 and index < maps.size():
		status.text = "Selected %s. Press LOAD to open it." % str(maps[index]["name"])

func _load_map() -> void:
	var entry := _selected_map()
	if entry.is_empty():
		status.text = "Select a saved map first."
		return
	var result: Dictionary = MapForgeData.load_map(str(entry["id"]))
	if not result.get("ok", false):
		status.text = "Load failed: %s" % str(result.get("error", "Invalid map"))
		return
	_record()
	data = result["data"]
	_sync_fields()
	status.text = "Loaded %s." % str(data["name"])
	queue_redraw()

func _rename_map() -> void:
	var entry := _selected_map()
	if entry.is_empty():
		status.text = "Select a saved map to rename."
		return
	var result: Dictionary = MapForgeData.load_map(str(entry["id"]))
	if not result.get("ok", false):
		status.text = str(result.get("error", "Could not load map."))
		return
	var renamed: Dictionary = result["data"]
	renamed["name"] = name_field.text.strip_edges()
	if str(renamed["name"]).is_empty():
		status.text = "Enter the new name first."
		return
	var saved: Dictionary = MapForgeData.save_map(renamed)
	if saved.get("ok", false):
		_refresh_maps()
		status.text = "Map renamed."
	else:
		status.text = str(saved.get("error", "Rename failed."))

func _duplicate_map() -> void:
	var source: Dictionary = data
	var entry := _selected_map()
	if not entry.is_empty():
		var loaded: Dictionary = MapForgeData.load_map(str(entry["id"]))
		if not loaded.get("ok", false):
			status.text = str(loaded.get("error", "Could not load source map."))
			return
		source = loaded["data"]
	var result: Dictionary = MapForgeData.duplicate_map(source, str(source["name"]) + " Copy")
	if result.get("ok", false):
		data = result["data"]
		_sync_fields()
		_refresh_maps()
		_record()
		status.text = "Duplicate created."
		queue_redraw()
	else:
		status.text = str(result.get("error", "Duplicate failed."))

func _ask_delete() -> void:
	if _selected_map().is_empty():
		status.text = "Select a saved map to delete."
		return
	delete_dialog.popup_centered()

func _delete_map() -> void:
	var entry := _selected_map()
	if entry.is_empty():
		return
	if MapForgeData.delete_map(str(entry["id"])):
		_refresh_maps()
		status.text = "Map deleted."
	else:
		status.text = "Delete failed."

func _test_map() -> void:
	data["name"] = name_field.text.strip_edges()
	var error_text: String = MapForgeData.validate_playable(data)
	if not error_text.is_empty():
		status.text = "Cannot test: %s" % error_text
		return
	var saved: Dictionary = MapForgeData.save_map(data)
	if not saved.get("ok", false):
		status.text = "Could not preserve edit state: %s" % str(saved.get("error", "Save failed."))
		return
	data = saved["data"]
	visible = false
	map_test_requested.emit(data.duplicate(true))

func return_from_test() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_maps()
	status.text = "Returned from test. Your edit session is intact."
	queue_redraw()

func _toggle_grid() -> void:
	grid_visible = not grid_visible
	status.text = "Grid %s." % ("shown" if grid_visible else "hidden")
	queue_redraw()

func _add_toolbar_button(parent: HBoxContainer, label_text: String, action: Callable) -> void:
	var button := _button(label_text, action)
	button.custom_minimum_size = Vector2(88, 38)
	parent.add_child(button)

func _button(label_text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size.y = 34
	button.pressed.connect(action)
	return button

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.93, 0.72, 0.42))
	return label

func _refresh_palette() -> void:
	if not is_instance_valid(palette_grid):
		return
	for child in palette_grid.get_children():
		if child is Button:
			child.button_pressed = child.text == active_kind
			child.modulate = Color.WHITE if child.text == active_kind else Color(0.78, 0.82, 0.84)

func return_from_test() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_maps()
	status.text = "Returned from test. Your editor session is intact."
	queue_redraw()

func _close() -> void:
	closed.emit()
	queue_free()
