extends Control

const STICK_OUTER_RADIUS := 96.0
const STICK_KNOB_RADIUS := 36.0
const STICK_TOUCH_RADIUS := 132.0
const STICK_DEAD_ZONE := 18.0

var fingers: Dictionary = {}
var active_sticks: Dictionary = {}
var counts := {"move_left": 0, "move_right": 0, "jump": 0, "attack": 0, "bow_fire": 0, "shield": 0, "touch_pause": 0, "restart": 0}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    for action in counts:
        if not InputMap.has_action(action):
            InputMap.add_action(action)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _press_finger(event.index, event.position)
        elif fingers.has(event.index):
            _release_finger(event.index)
    elif event is InputEventScreenDrag and fingers.has(event.index):
        _drag_finger(event.index, event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _press_finger(-1, event.position)
        elif fingers.has(-1):
            _release_finger(-1)
    elif event is InputEventMouseMotion and fingers.has(-1) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _drag_finger(-1, event.position)

func _press_finger(index: int, point: Vector2) -> void:
    if fingers.has(index):
        return
    var scale := _ui_scale(get_viewport_rect().size)
    var center: Vector2 = _positions(get_viewport_rect().size)["stick"]
    if point.distance_to(center) <= STICK_TOUCH_RADIUS * scale:
        fingers[index] = {"kind": "stick", "action": ""}
        active_sticks[index] = center
        _update_stick(index, point)
        get_viewport().set_input_as_handled()
        return
    var action := _action_at(point)
    if action == "":
        return
    fingers[index] = {"kind": "button", "action": action}
    _change_count(action, 1)
    get_viewport().set_input_as_handled()

func _drag_finger(index: int, point: Vector2) -> void:
    var finger: Dictionary = fingers[index]
    if finger["kind"] == "stick":
        _update_stick(index, point)
        get_viewport().set_input_as_handled()
        return
    var old_action: String = finger["action"]
    var new_action := _action_at(point)
    if old_action != new_action:
        if old_action != "":
            _change_count(old_action, -1)
        if new_action != "":
            _change_count(new_action, 1)
        finger["action"] = new_action
        fingers[index] = finger
    get_viewport().set_input_as_handled()

func _update_stick(index: int, point: Vector2) -> void:
    var size := get_viewport_rect().size
    var center: Vector2 = _positions(size)["stick"]
    var scale := _ui_scale(size)
    var offset := point - center
    var maximum := STICK_OUTER_RADIUS * 0.68 * scale
    if offset.length() > maximum:
        offset = offset.normalized() * maximum
    active_sticks[index] = center + offset

    var next_action := ""
    if offset.x < -STICK_DEAD_ZONE * scale:
        next_action = "move_left"
    elif offset.x > STICK_DEAD_ZONE * scale:
        next_action = "move_right"
    var finger: Dictionary = fingers[index]
    var previous_action: String = finger["action"]
    if previous_action != next_action:
        if previous_action != "":
            _change_count(previous_action, -1)
        if next_action != "":
            _change_count(next_action, 1)
        finger["action"] = next_action
        fingers[index] = finger
    queue_redraw()

func _release_finger(index: int) -> void:
    if not fingers.has(index):
        return
    var finger: Dictionary = fingers[index]
    if finger["kind"] == "stick":
        var action: String = finger["action"]
        if action != "":
            _change_count(action, -1)
        active_sticks.erase(index)
    else:
        var action: String = finger["action"]
        if action != "":
            _change_count(action, -1)
    fingers.erase(index)
    queue_redraw()
    get_viewport().set_input_as_handled()

func _change_count(action: String, amount: int) -> void:
    counts[action] = maxi(0, int(counts[action]) + amount)
    if counts[action] > 0:
        Input.action_press(action)
    else:
        Input.action_release(action)
    queue_redraw()

func _ui_scale(size: Vector2) -> float:
    return clampf(minf(size.x / 960.0, size.y / 540.0), 0.75, 1.3)

func _positions(size: Vector2) -> Dictionary:
    var scale := _ui_scale(size)
    var lower_y := size.y - 122.0 * scale
    return {
        "stick": Vector2(145.0 * scale, lower_y),
        "jump": Vector2(size.x - 285.0 * scale, lower_y),
        "attack": Vector2(size.x - 88.0 * scale, lower_y),
        "bow_fire": Vector2(size.x - 175.0 * scale, lower_y - 132.0 * scale),
        "shield": Vector2(size.x - 76.0 * scale, lower_y - 226.0 * scale),
        "touch_pause": Vector2(size.x - 62.0 * scale, 52.0 * scale),
        "restart": Vector2(size.x - 148.0 * scale, 52.0 * scale)
    }

func _action_at(point: Vector2) -> String:
    var size := get_viewport_rect().size
    var scale := _ui_scale(size)
    var buttons := _positions(size)
    for action in ["jump", "attack", "bow_fire", "shield", "restart", "touch_pause"]:
        var radius := _hit_radius(action) * scale
        if point.distance_to(buttons[action]) <= radius:
            return action
    return ""

func _hit_radius(action: String) -> float:
    match action:
        "jump": return 88.0
        "attack": return 76.0
        "bow_fire": return 54.0
        "shield": return 64.0
        "touch_pause", "restart": return 36.0
    return 0.0

func _draw() -> void:
    var size := get_viewport_rect().size
    var scale := _ui_scale(size)
    var positions := _positions(size)
    var center: Vector2 = positions["stick"]
    var knob_position := center
    if not active_sticks.is_empty():
        knob_position = active_sticks.values()[active_sticks.size() - 1]
    var stick_fill := Color(0.39, 0.66, 0.60, 0.22)
    var stick_edge := Color(0.86, 0.96, 0.88, 0.60)
    draw_circle(center, STICK_OUTER_RADIUS * scale, stick_fill)
    draw_arc(center, STICK_OUTER_RADIUS * scale, 0.0, TAU, 48, stick_edge, 3.0 * scale)
    draw_arc(center, STICK_OUTER_RADIUS * 0.68 * scale, 0.0, TAU, 40, Color(0.86, 0.96, 0.88, 0.23), 1.5 * scale)
    var left_color := Color(0.95, 1.0, 0.94, 0.98) if counts["move_left"] > 0 else Color(0.85, 0.94, 0.88, 0.58)
    var right_color := Color(0.95, 1.0, 0.94, 0.98) if counts["move_right"] > 0 else Color(0.85, 0.94, 0.88, 0.58)
    var font := ThemeDB.fallback_font
    draw_string(font, center + Vector2(-66.0 * scale, 8.0 * scale), "◀", HORIZONTAL_ALIGNMENT_LEFT, -1, int(27.0 * scale), left_color)
    draw_string(font, center + Vector2(48.0 * scale, 8.0 * scale), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, int(27.0 * scale), right_color)
    var knob_active := not active_sticks.is_empty()
    draw_circle(knob_position, STICK_KNOB_RADIUS * scale, Color(0.69, 0.86, 0.77, 0.84 if knob_active else 0.42))
    draw_arc(knob_position, STICK_KNOB_RADIUS * scale, 0.0, TAU, 36, Color(0.95, 1.0, 0.94, 0.72), 2.2 * scale)

    _draw_button(positions["jump"], "JUMP", counts["jump"] > 0, 80.0 * scale)
    _draw_button(positions["attack"], "ATTACK", counts["attack"] > 0, 70.0 * scale)
    _draw_button(positions["bow_fire"], "BOW", counts["bow_fire"] > 0, 51.0 * scale)
    _draw_button(positions["shield"], "SHIELD", counts["shield"] > 0, 61.0 * scale)
    _draw_button(positions["restart"], "↻", counts["restart"] > 0, 34.0 * scale)
    _draw_button(positions["touch_pause"], "Ⅱ", counts["touch_pause"] > 0, 34.0 * scale)

func _draw_button(center: Vector2, label: String, active: bool, radius: float) -> void:
    var fill := Color(0.62, 0.82, 0.70, 0.86 if active else 0.46)
    var edge := Color(0.94, 1.0, 0.92, 0.84)
    draw_circle(center, radius, fill)
    draw_arc(center, radius, 0.0, TAU, 48, edge, 3.0)
    var font := ThemeDB.fallback_font
    var font_size := maxi(16, int(19.0 * _ui_scale(get_viewport_rect().size)))
    var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    draw_string(font, center + Vector2(-width / 2.0, 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
