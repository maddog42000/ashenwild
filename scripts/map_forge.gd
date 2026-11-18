extends Control
## ASHENWILD Map Forge: offline, data-driven tile editor.
signal closed

const MAP_W := 30
const MAP_H := 18
const TILE := 24
const MAP_DIR := "user://custom_maps"
const TILE_NAMES := ["Erase", "Stone", "Moss Platform", "Hazard", "Ash Mite", "Ashen Shard", "Checkpoint", "Exit", "Crystal"]
const TILE_COLORS := [
    Color(0.03, 0.04, 0.06, 0.0), Color(0.31, 0.34, 0.37), Color(0.25, 0.48, 0.37),
    Color(0.88, 0.27, 0.20), Color(0.78, 0.28, 0.25), Color(0.18, 0.91, 0.82),
    Color(0.96, 0.67, 0.24), Color(0.95, 0.79, 0.38), Color(0.35, 0.62, 0.98)
]
var cells: Array = []
var selected_tile := 1
var map_name := "My First Hollow"
var undo_stack: Array = []
var redo_stack: Array = []
var testing := false
var test_player := Vector2(90, 300)
var test_velocity := Vector2.ZERO
var test_message := ""
var name_edit: LineEdit
var status_label: Label
var palette: VBoxContainer
var canvas_rect := Rect2(190, 78, 730, 420)
var mouse_down := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _new_empty()
    _build_ui()
    queue_redraw()

func _new_empty() -> void:
    cells.clear()
    for y in range(MAP_H):
        var line: Array = []
        for x in range(MAP_W):
            line.append(0)
        cells.append(line)
    for x in range(MAP_W):
        cells[MAP_H - 2][x] = 1
    _snapshot()

func _build_ui() -> void:
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.012, 0.018, 0.035, 0.98)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    var title := Label.new()
    title.position = Vector2(24, 12)
    title.text = "ASHENWILD  /  MAP FORGE"
    title.add_theme_font_size_override("font_size", 25)
    title.add_theme_color_override("font_color", Color(0.42, 0.94, 0.84))
    add_child(title)
    name_edit = LineEdit.new()
    name_edit.position = Vector2(500, 14)
    name_edit.size = Vector2(230, 34)
    name_edit.text = map_name
    name_edit.placeholder_text = "Level name"
    add_child(name_edit)
    _button("BACK", Vector2(820, 12), Vector2(110, 38), _close)
    var palette_panel := PanelContainer.new()
    palette_panel.position = Vector2(18, 78)
    palette_panel.size = Vector2(158, 420)
    _style_panel(palette_panel)
    add_child(palette_panel)
    palette = VBoxContainer.new()
    palette.add_theme_constant_override("separation", 5)
    palette_panel.add_child(palette)
    var pal_title := Label.new()
    pal_title.text = "BUILD PIECES"
    pal_title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.40))
    palette.add_child(pal_title)
    for i in range(TILE_NAMES.size()):
        var index := i
        var b := Button.new()
        b.text = "■  " + TILE_NAMES[i]
        b.custom_minimum_size = Vector2(130, 34)
        b.add_theme_color_override("font_color", TILE_COLORS[i] if i > 0 else Color(0.8, 0.8, 0.8))
        b.pressed.connect(func(): selected_tile = index; _refresh_palette(); queue_redraw())
        palette.add_child(b)
    _refresh_palette()
    var canvas_frame := Panel.new()
    canvas_frame.position = canvas_rect.position - Vector2(5, 5)
    canvas_frame.size = canvas_rect.size + Vector2(10, 10)
    _style_panel(canvas_frame)
    canvas_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(canvas_frame)
    var bottom := HBoxContainer.new()
    bottom.position = Vector2(190, 510)
    bottom.size = Vector2(730, 38)
    bottom.add_theme_constant_override("separation", 8)
    add_child(bottom)
    _button_in(bottom, "UNDO", _undo)
    _button_in(bottom, "REDO", _redo)
    _button_in(bottom, "RANDOM MAP", _random_map)
    _button_in(bottom, "SAVE", _save_map)
    _button_in(bottom, "LOAD", _load_map)
    _button_in(bottom, "TEST PLAY", _toggle_test)
    status_label = Label.new()
    status_label.position = Vector2(20, 505)
    status_label.size = Vector2(155, 40)
    status_label.text = "Tap a piece,\nthen paint the grid."
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", Color(0.56, 0.83, 0.77))
    add_child(status_label)

func _style_panel(panel: Panel) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.035, 0.055, 0.075, 0.98)
    sb.border_color = Color(0.27, 0.58, 0.53)
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(8)
    panel.add_theme_stylebox_override("panel", sb)

func _button(label: String, pos: Vector2, sz: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = label
    b.position = pos
    b.size = sz
    b.pressed.connect(action)
    add_child(b)

func _button_in(parent: HBoxContainer, label: String, action: Callable) -> void:
    var b := Button.new()
    b.text = label
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.custom_minimum_size.y = 34
    b.pressed.connect(action)
    parent.add_child(b)

func _refresh_palette() -> void:
    if not is_instance_valid(palette):
        return
    for i in range(1, palette.get_child_count()):
        var b := palette.get_child(i) as Button
        b.button_pressed = false
        b.text = ("▶ " if i - 1 == selected_tile else "  ") + TILE_NAMES[i - 1]

func _snapshot() -> void:
    undo_stack.append(cells.duplicate(true))
    if undo_stack.size() > 40:
        undo_stack.pop_front()
    redo_stack.clear()

func _undo() -> void:
    if undo_stack.size() <= 1:
        return
    redo_stack.append(undo_stack.pop_back())
    cells = undo_stack.back().duplicate(true)
    queue_redraw()

func _redo() -> void:
    if redo_stack.is_empty():
        return
    cells = redo_stack.pop_back().duplicate(true)
    undo_stack.append(cells.duplicate(true))
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if testing:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            mouse_down = true
            _paint_at(event.position)
        else:
            mouse_down = false
    elif event is InputEventMouseMotion and mouse_down:
        _paint_at(event.position)
    elif event is InputEventScreenTouch and event.pressed:
        _paint_at(event.position)
    elif event is InputEventScreenDrag:
        _paint_at(event.position)

func _paint_at(pos: Vector2) -> void:
    if not canvas_rect.has_point(pos):
        return
    var cell := Vector2i(int((pos.x - canvas_rect.position.x) / TILE), int((pos.y - canvas_rect.position.y) / TILE))
    if cell.x < 0 or cell.x >= MAP_W or cell.y < 0 or cell.y >= MAP_H:
        return
    if int(cells[cell.y][cell.x]) == selected_tile:
        return
    _snapshot()
    cells[cell.y][cell.x] = selected_tile
    queue_redraw()

func _draw() -> void:
    draw_rect(canvas_rect, Color(0.025, 0.04, 0.065))
    for y in range(MAP_H):
        for x in range(MAP_W):
            var tile_id := int(cells[y][x])
            var rect := Rect2(canvas_rect.position + Vector2(x, y) * TILE, Vector2(TILE - 1, TILE - 1))
            if tile_id > 0:
                draw_rect(rect, TILE_COLORS[tile_id])
                draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), TILE_COLORS[tile_id].lightened(0.18))
            draw_rect(rect, Color(0.20, 0.37, 0.42, 0.42), false, 1.0)
    if testing:
        draw_circle(canvas_rect.position + test_player, 9, Color(1.0, 0.83, 0.38))
        draw_string(ThemeDB.fallback_font, canvas_rect.position + Vector2(12, 24), "TEST MODE  •  arrows/A-D move, space jumps, ESC returns", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _random_map() -> void:
    _snapshot()
    _new_empty()
    for x in range(MAP_W):
        cells[MAP_H - 2][x] = 1
    var x := 4
    while x < MAP_W - 5:
        var y := randi_range(8, 13)
        var width := randi_range(3, 7)
        for px in range(x, mini(x + width, MAP_W - 2)):
            cells[y][px] = 2 if randf() > 0.25 else 1
        if randf() > 0.45:
            cells[y - 1][mini(x + 1, MAP_W - 2)] = 5
        if randf() > 0.65:
            cells[y][mini(x + width - 1, MAP_W - 2)] = 4
        x += width + randi_range(2, 4)
    cells[MAP_H - 3][2] = 6
    cells[MAP_H - 3][MAP_W - 3] = 7
    map_name = "Generated Hollow %d" % randi_range(100, 999)
    name_edit.text = map_name
    status_label.text = "Generated draft.\nEdit before testing."
    queue_redraw()

func _save_map() -> void:
    map_name = name_edit.text.strip_edges()
    if map_name.is_empty():
        map_name = "Untitled Hollow"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_DIR))
    var safe_name := map_name.to_lower().replace(" ", "_").validate_filename()
    var data := {"version": 1, "name": map_name, "width": MAP_W, "height": MAP_H, "tile_size": TILE, "cells": cells}
    var file := FileAccess.open(MAP_DIR + "/" + safe_name + ".json", FileAccess.WRITE)
    if file == null:
        status_label.text = "Save failed."
        return
    file.store_string(JSON.stringify(data))
    status_label.text = "Saved locally:\n" + safe_name + ".json"

func _load_map() -> void:
    var dir := DirAccess.open(MAP_DIR)
    if dir == null:
        status_label.text = "No saved maps yet."
        return
    dir.list_dir_begin()
    var filename := dir.get_next()
    while filename != "":
        if filename.ends_with(".json"):
            var file := FileAccess.open(MAP_DIR + "/" + filename, FileAccess.READ)
            if file:
                var parsed: Variant = JSON.parse_string(file.get_as_text())
                if parsed is Dictionary and int(parsed.get("version", 0)) == 1 and parsed.get("cells") is Array:
                    var loaded: Array = parsed["cells"]
                    if loaded.size() == MAP_H:
                        cells = loaded
                        map_name = str(parsed.get("name", "Loaded Hollow"))
                        name_edit.text = map_name
                        _snapshot()
                        status_label.text = "Loaded:\n" + filename
                        queue_redraw()
                        dir.list_dir_end()
                        return
        filename = dir.get_next()
    dir.list_dir_end()
    status_label.text = "No valid map found."

func _toggle_test() -> void:
    testing = not testing
    test_player = Vector2(60, (MAP_H - 3) * TILE)
    test_velocity = Vector2.ZERO
    status_label.text = "TEST PLAY active.\nTap Test Play to exit." if testing else "Editor ready.\nChoose a piece."
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not testing:
        return
    var direction := Input.get_axis("ui_left", "ui_right")
    if Input.is_key_pressed(KEY_A):
        direction = -1.0
    elif Input.is_key_pressed(KEY_D):
        direction = 1.0
    test_velocity.x = direction * 190.0
    test_velocity.y += 900.0 * delta
    if Input.is_key_pressed(KEY_SPACE) and _test_grounded():
        test_velocity.y = -360.0
    var next := test_player + test_velocity * delta
    if test_velocity.y >= 0.0:
        var row := int((next.y + 9.0) / TILE)
        var col := int(next.x / TILE)
        if row >= 0 and row < MAP_H and col >= 0 and col < MAP_W and int(cells[row][col]) in [1, 2, 6, 7]:
            next.y = row * TILE - 9.0
            test_velocity.y = 0.0
    test_player = next
    test_player.x = clampf(test_player.x, 8.0, MAP_W * TILE - 8.0)
    queue_redraw()

func _test_grounded() -> bool:
    var row := int((test_player.y + 10.0) / TILE)
    var col := int(test_player.x / TILE)
    return row >= 0 and row < MAP_H and col >= 0 and col < MAP_W and int(cells[row][col]) in [1, 2, 6, 7]

func _close() -> void:
    closed.emit()
    queue_free()
