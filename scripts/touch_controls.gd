extends Control

var fingers: Dictionary = {}
var counts := {"move_left": 0, "move_right": 0, "jump": 0, "attack": 0, "touch_pause": 0, "restart": 0}
var hold_actions := ["move_left", "move_right", "jump", "attack"]

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
        var old_action: String = fingers[event.index]
        var new_action := _action_at(event.position)
        if old_action != new_action:
            _release_finger(event.index)
            if new_action != "":
                _press_finger(event.index, event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _press_finger(-1, event.position)
        elif fingers.has(-1):
            _release_finger(-1)

func _press_finger(index: int, point: Vector2) -> void:
    var action := _action_at(point)
    if action == "":
        return
    fingers[index] = action
    _change_count(action, 1)
    get_viewport().set_input_as_handled()

func _release_finger(index: int) -> void:
    var action: String = fingers[index]
    _change_count(action, -1)
    fingers.erase(index)
    get_viewport().set_input_as_handled()

func _change_count(action: String, amount: int) -> void:
    counts[action] = maxi(0, int(counts[action]) + amount)
    if counts[action] > 0:
        Input.action_press(action)
    else:
        Input.action_release(action)
    queue_redraw()

func _positions(size: Vector2) -> Dictionary:
    return {"move_left": Vector2(78, size.y - 92), "move_right": Vector2(192, size.y - 92), "jump": Vector2(size.x - 190, size.y - 92), "attack": Vector2(size.x - 80, size.y - 92), "touch_pause": Vector2(size.x - 48, 48), "restart": Vector2(size.x - 112, 48)}

func _action_at(point: Vector2) -> String:
    var buttons := _positions(get_viewport_rect().size)
    for action in buttons:
        var radius := 28.0 if action == "touch_pause" or action == "restart" else (54.0 if action.begins_with("move") else 60.0)
        if point.distance_to(buttons[action]) <= radius:
            return action
    return ""

func _draw() -> void:
    var buttons := _positions(get_viewport_rect().size)
    _draw_button(buttons["move_left"], "◀", counts["move_left"] > 0, 52)
    _draw_button(buttons["move_right"], "▶", counts["move_right"] > 0, 52)
    _draw_button(buttons["jump"], "JUMP", counts["jump"] > 0, 58)
    _draw_button(buttons["attack"], "HIT", counts["attack"] > 0, 58)
    _draw_button(buttons["restart"], "↻", counts["restart"] > 0, 24)
    _draw_button(buttons["touch_pause"], "Ⅱ", counts["touch_pause"] > 0, 24)

func _draw_button(center: Vector2, label: String, active: bool, radius: float) -> void:
    var fill := Color(0.55, 0.75, 0.66, 0.72 if active else 0.30)
    draw_circle(center, radius, fill)
    draw_arc(center, radius, 0.0, TAU, 40, Color(0.85, 0.92, 0.86, 0.72), 2.5)
    var font := ThemeDB.fallback_font
    var font_size := 16 if radius > 30 else 18
    var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    draw_string(font, center + Vector2(-width / 2.0, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
