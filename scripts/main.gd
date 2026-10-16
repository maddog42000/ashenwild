extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const LEVEL_END_X := 1510.0

var player: CharacterBody2D
var checkpoint_position := Vector2(120, 418)
var shards := 0
var paused := false
var completed := false
var health_label: Label
var shard_label: Label
var message_label: Label
var pause_panel: ColorRect
var controls: Control

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_actions()
    _build_level()
    _build_hud()
    player = PLAYER_SCENE.instantiate()
    player.global_position = Vector2(120, 418)
    add_child(player)
    player.health_changed.connect(_on_health_changed)
    player.died.connect(_on_player_died)
    _on_health_changed(player.health, player.MAX_HEALTH)
    var camera := Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.limit_left = 0
    camera.limit_right = 1600
    camera.limit_top = 0
    camera.limit_bottom = 540
    player.add_child(camera)
    camera.make_current()
    _setup_touch_controls()
    _refresh_hud()
    _show_message("THE FORGOTTEN HOLLOW  •  Find the teal shard, then reach the gate", 3.0)

func _setup_actions() -> void:
    var definitions := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_J, KEY_X], "pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R]}
    for action in definitions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for keycode in definitions[action]:
            var event := InputEventKey.new()
            event.physical_keycode = keycode
            InputMap.action_add_event(action, event)

func _setup_touch_controls() -> void:
    controls = Control.new()
    controls.set_script(load("res://scripts/touch_controls.gd"))
    controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls.process_mode = Node.PROCESS_MODE_ALWAYS
    var layer := CanvasLayer.new()
    layer.name = "TouchControlsLayer"
    add_child(layer)
    layer.add_child(controls)

func _build_level() -> void:
    var bg := Node2D.new()
    bg.name = "Atmosphere"
    bg.set_script(load("res://scripts/scenery.gd"))
    add_child(bg)
    move_child(bg, 0)

    # A small progression of safe ground, a gap, two elevated routes, and an exit.
    _platform(Vector2(250, 462), Vector2(500, 50), Color(0.19, 0.24, 0.24))
    _platform(Vector2(1100, 462), Vector2(800, 50), Color(0.19, 0.24, 0.24))
    _platform(Vector2(355, 366), Vector2(190, 24), Color(0.31, 0.37, 0.34))
    _platform(Vector2(620, 302), Vector2(180, 24), Color(0.31, 0.37, 0.34))
    _platform(Vector2(1030, 372), Vector2(200, 24), Color(0.31, 0.37, 0.34))

    _make_checkpoint(Vector2(905, 418))
    _make_collectible(Vector2(620, 250))
    _make_exit(Vector2(1480, 420))
    var enemy := ENEMY_SCENE.instantiate()
    enemy.position = Vector2(780, 417)
    add_child(enemy)
    _make_hazard(Vector2(610, 635), Vector2(230, 70))
    _make_decorations()

func _platform(center: Vector2, size: Vector2, tint: Color) -> void:
    var body := StaticBody2D.new()
    body.position = center
    body.collision_layer = 1
    body.collision_mask = 1
    var shape := RectangleShape2D.new()
    shape.size = size
    var collider := CollisionShape2D.new()
    collider.shape = shape
    body.add_child(collider)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([Vector2(-size.x / 2, -size.y / 2), Vector2(size.x / 2, -size.y / 2), Vector2(size.x / 2, size.y / 2), Vector2(-size.x / 2, size.y / 2)])
    visual.color = tint
    body.add_child(visual)
    var top_line := Line2D.new()
    top_line.points = PackedVector2Array([Vector2(-size.x / 2, -size.y / 2), Vector2(size.x / 2, -size.y / 2)])
    top_line.width = 4.0
    top_line.default_color = Color(0.48, 0.62, 0.52)
    body.add_child(top_line)
    add_child(body)

func _make_decorations() -> void:
    for x in [110.0, 450.0, 730.0, 1110.0, 1370.0]:
        var glow := Polygon2D.new()
        glow.position = Vector2(x, 420)
        glow.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(-5, -20), Vector2(0, -28), Vector2(5, -20), Vector2(7, 0)])
        glow.color = Color(0.20, 0.73, 0.56, 0.85)
        add_child(glow)
        var dot := Polygon2D.new()
        dot.position = Vector2(x, 400)
        dot.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
        dot.color = Color(0.72, 0.92, 0.52)
        add_child(dot)

func _new_trigger(name: String, at: Vector2, size: Vector2) -> Area2D:
    var area := Area2D.new()
    area.name = name
    area.position = at
    var shape := RectangleShape2D.new()
    shape.size = size
    var collider := CollisionShape2D.new()
    collider.shape = shape
    area.add_child(collider)
    add_child(area)
    return area

func _make_checkpoint(at: Vector2) -> void:
    var flag := Polygon2D.new()
    flag.position = at + Vector2(0, -22)
    flag.polygon = PackedVector2Array([Vector2(-3, -30), Vector2(3, -30), Vector2(3, 24), Vector2(-3, 24)])
    flag.color = Color(0.67, 0.69, 0.57)
    add_child(flag)
    var banner := Polygon2D.new()
    banner.position = at + Vector2(16, -43)
    banner.polygon = PackedVector2Array([Vector2(-12, -9), Vector2(15, -4), Vector2(-12, 8)])
    banner.color = Color(0.28, 0.72, 0.59)
    add_child(banner)
    var area := _new_trigger("Checkpoint", at, Vector2(54, 80))
    area.body_entered.connect(_on_checkpoint_entered)

func _make_collectible(at: Vector2) -> void:
    var glow := Polygon2D.new()
    glow.name = "GlowShard"
    glow.position = at
    glow.polygon = PackedVector2Array([Vector2(0, -17), Vector2(11, -2), Vector2(0, 18), Vector2(-11, -2)])
    glow.color = Color(0.27, 0.93, 0.80)
    add_child(glow)
    var area := _new_trigger("Collectible", at, Vector2(42, 50))
    area.body_entered.connect(_on_collectible_entered.bind(area, glow))

func _make_exit(at: Vector2) -> void:
    var arch := Polygon2D.new()
    arch.position = at
    arch.polygon = PackedVector2Array([Vector2(-42, 30), Vector2(-42, -32), Vector2(-30, -55), Vector2(30, -55), Vector2(42, -32), Vector2(42, 30), Vector2(27, 30), Vector2(27, -27), Vector2(18, -40), Vector2(-18, -40), Vector2(-27, -27), Vector2(-27, 30)])
    arch.color = Color(0.42, 0.48, 0.40)
    add_child(arch)
    var core := Polygon2D.new()
    core.position = at + Vector2(0, -10)
    core.polygon = PackedVector2Array([Vector2(-17, 22), Vector2(-17, -9), Vector2(-11, -24), Vector2(11, -24), Vector2(17, -9), Vector2(17, 22)])
    core.color = Color(0.16, 0.54, 0.48, 0.70)
    add_child(core)
    var area := _new_trigger("Exit", at, Vector2(80, 100))
    area.body_entered.connect(_on_exit_entered)

func _make_hazard(at: Vector2, size: Vector2) -> void:
    var area := _new_trigger("PitHazard", at, size)
    area.body_entered.connect(_on_hazard_entered)
    for x in [-80.0, -50.0, -20.0, 10.0, 40.0, 70.0, 100.0]:
        var spike := Polygon2D.new()
        spike.position = at + Vector2(x, -25)
        spike.polygon = PackedVector2Array([Vector2(-13, 25), Vector2(0, 0), Vector2(13, 25)])
        spike.color = Color(0.68, 0.34, 0.29)
        add_child(spike)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)
    health_label = Label.new()
    health_label.position = Vector2(20, 14)
    health_label.add_theme_font_size_override("font_size", 28)
    health_label.add_theme_color_override("font_color", Color(0.95, 0.83, 0.68))
    layer.add_child(health_label)
    shard_label = Label.new()
    shard_label.position = Vector2(22, 54)
    shard_label.add_theme_font_size_override("font_size", 18)
    shard_label.add_theme_color_override("font_color", Color(0.49, 0.91, 0.79))
    layer.add_child(shard_label)
    message_label = Label.new()
    message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    message_label.position = Vector2(-300, 18)
    message_label.size = Vector2(600, 50)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size", 18)
    message_label.add_theme_color_override("font_color", Color(0.91, 0.91, 0.79))
    layer.add_child(message_label)
    pause_panel = ColorRect.new()
    pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pause_panel.color = Color(0.02, 0.03, 0.05, 0.78)
    pause_panel.visible = false
    layer.add_child(pause_panel)
    var pause_label := Label.new()
    pause_label.text = "PAUSED\nTap the pause icon or press P to continue"
    pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    pause_label.position = Vector2(-240, -45)
    pause_label.size = Vector2(480, 100)
    pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_label.add_theme_font_size_override("font_size", 26)
    pause_panel.add_child(pause_label)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("pause"):
        _toggle_pause()
    if Input.is_action_just_pressed("restart"):
        _restart_level()
    if Input.is_action_just_pressed("touch_pause"):
        _toggle_pause()

func _toggle_pause() -> void:
    if completed:
        return
    paused = not paused
    get_tree().paused = paused
    pause_panel.visible = paused

func _restart_level() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_health_changed(current: int, maximum: int) -> void:
    health_label.text = "HEALTH  " + "◆".repeat(current) + "◇".repeat(maximum - current)

func _refresh_hud() -> void:
    if is_instance_valid(shard_label):
        shard_label.text = "TEAL SHARDS: " + str(shards) + "/1"

func _show_message(text: String, seconds: float) -> void:
    message_label.text = text
    message_label.visible = true
    await get_tree().create_timer(seconds).timeout
    if is_instance_valid(message_label) and not completed:
        message_label.visible = false

func _on_checkpoint_entered(body: Node2D) -> void:
    if body != player:
        return
    checkpoint_position = Vector2(905, 418)
    player.respawn_position = checkpoint_position
    _show_message("CHECKPOINT KINDLED", 2.0)

func _on_collectible_entered(body: Node2D, area: Area2D, visual: Node2D) -> void:
    if body != player or not is_instance_valid(area):
        return
    shards = 1
    area.queue_free()
    visual.queue_free()
    _refresh_hud()
    _show_message("TEAL SHARD FOUND", 2.0)

func _on_exit_entered(body: Node2D) -> void:
    if body != player or completed:
        return
    if shards < 1:
        _show_message("The sealed gate needs the teal shard", 2.0)
        return
    completed = true
    player.set_physics_process(false)
    get_tree().paused = true
    pause_panel.visible = true
    pause_panel.get_child(0).text = "HOLLOW CLEARED\\nTap ↻ or press R to replay"

func _on_hazard_entered(body: Node2D) -> void:
    if body == player:
        player._die()

func _on_player_died() -> void:
    get_tree().create_timer(0.65).timeout.connect(func(): player.respawn(checkpoint_position))
