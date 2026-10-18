extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/bellows_saint.tscn")

var player: CharacterBody2D
var camera: Camera2D
var level_root: Node2D
var current_level := 1
var level_world_width := 1600.0
var checkpoint_position := Vector2(120, 418)
var shards := 0
var paused := false
var completed := false
var health_label: Label
var shard_label: Label
var message_label: Label
var pause_panel: ColorRect
var controls: Control
var boss: Node2D
var boss_label: Label
var boss_bar: ProgressBar
var boss_defeated := false
var arena_gate_shape: CollisionShape2D
var arena_gate_visual: Polygon2D
var vent_visuals: Array[Polygon2D] = []
var stillheart_collected := false
var stillheart_area: Area2D
var stillheart_visual: Node2D
var message_generation := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_actions()
    _build_hud()
    _build_level(1)
    player = PLAYER_SCENE.instantiate()
    player.position = Vector2(120, 418)
    add_child(player)
    player.health_changed.connect(_on_health_changed)
    player.died.connect(_on_player_died)
    player.fall_damage_taken.connect(_on_fall_damage_taken)
    player.enemy_stomped.connect(_on_enemy_stomped)
    _on_health_changed(player.health, player.MAX_HEALTH)
    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    player.add_child(camera)
    camera.make_current()
    _update_camera_limits()
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

func _build_level(level_id: int) -> void:
    if is_instance_valid(level_root):
        level_root.queue_free()
    level_root = Node2D.new()
    level_root.name = "Level%d" % level_id
    add_child(level_root)
    move_child(level_root, 0)
    current_level = level_id
    shards = 0
    boss = null
    boss_defeated = false
    stillheart_collected = false
    stillheart_area = null
    stillheart_visual = null
    arena_gate_shape = null
    arena_gate_visual = null
    vent_visuals.clear()

    if level_id == 1:
        level_world_width = 3300.0
        _make_scenery(level_world_width, false)
        _platform(Vector2(245, 462), Vector2(490, 50), Color(0.19, 0.24, 0.24))
        _platform(Vector2(935, 462), Vector2(470, 50), Color(0.19, 0.24, 0.24))
        _platform(Vector2(1645, 462), Vector2(550, 50), Color(0.19, 0.24, 0.24))
        _platform(Vector2(2610, 462), Vector2(1380, 50), Color(0.19, 0.24, 0.24))
        _platform(Vector2(590, 354), Vector2(150, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(815, 278), Vector2(150, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1050, 345), Vector2(145, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1280, 278), Vector2(170, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1510, 323), Vector2(170, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1760, 246), Vector2(180, 24), Color(0.31, 0.37, 0.34))
        # Echo Crawl: tap-jump over the low stone while staying under the roof.
        _platform(Vector2(2300, 357), Vector2(520, 16), Color(0.25, 0.29, 0.29))
        _platform(Vector2(2285, 428), Vector2(34, 18), Color(0.48, 0.40, 0.34))
        _platform(Vector2(2650, 345), Vector2(160, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(2760, 275), Vector2(180, 24), Color(0.31, 0.37, 0.34))
        _make_checkpoint(Vector2(760, 418))
        _make_collectible(Vector2(1760, 198))
        _make_exit(Vector2(3180, 420))
        _make_enemy(Vector2(1050, 417))
        _make_enemy(Vector2(1970, 417))
        _make_hazard(Vector2(595, 635), Vector2(220, 70))
        _make_hazard(Vector2(1280, 635), Vector2(220, 70))
        _make_vent(Vector2(600, 520))
        _make_vent(Vector2(1320, 520))
        _make_decorations([120.0, 455.0, 735.0, 1100.0, 1420.0, 1800.0, 2180.0, 2550.0, 2920.0])
    elif level_id == 2:
        level_world_width = 4300.0
        _make_scenery(level_world_width, true)
        _platform(Vector2(250, 462), Vector2(500, 50), Color(0.22, 0.20, 0.22))
        _platform(Vector2(1075, 462), Vector2(650, 50), Color(0.22, 0.20, 0.22))
        _platform(Vector2(1975, 462), Vector2(650, 50), Color(0.22, 0.20, 0.22))
        _platform(Vector2(2925, 462), Vector2(750, 50), Color(0.22, 0.20, 0.22))
        _platform(Vector2(3925, 462), Vector2(750, 50), Color(0.22, 0.20, 0.22))
        _platform(Vector2(625, 356), Vector2(170, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(865, 282), Vector2(160, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(1160, 338), Vector2(180, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(1480, 272), Vector2(190, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(1740, 330), Vector2(170, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(2010, 245), Vector2(190, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(2370, 350), Vector2(180, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(2670, 292), Vector2(180, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(2960, 225), Vector2(180, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(3220, 322), Vector2(180, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(3460, 270), Vector2(170, 24), Color(0.38, 0.30, 0.27))
        # The Cinder Squeeze is a second low-roof tap-jump tunnel.
        _platform(Vector2(3750, 357), Vector2(400, 16), Color(0.33, 0.27, 0.25))
        _platform(Vector2(3760, 428), Vector2(34, 18), Color(0.53, 0.37, 0.30))
        _platform(Vector2(3650, 337), Vector2(150, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(4000, 300), Vector2(170, 24), Color(0.38, 0.30, 0.27))
        _make_checkpoint(Vector2(1850, 418))
        _make_collectible(Vector2(2960, 176))
        _make_exit(Vector2(4160, 420))
        _make_enemy(Vector2(1050, 417))
        _make_enemy(Vector2(2220, 417))
        _make_enemy(Vector2(3000, 417))
        _make_enemy(Vector2(3930, 417))
        _make_hazard(Vector2(625, 635), Vector2(250, 70))
        _make_hazard(Vector2(1625, 635), Vector2(250, 70))
        _make_hazard(Vector2(2425, 635), Vector2(250, 70))
        _make_hazard(Vector2(3425, 635), Vector2(250, 70))
        _make_vent(Vector2(625, 520))
        _make_vent(Vector2(1625, 520))
        _make_vent(Vector2(3425, 520))
        _make_decorations([120.0, 470.0, 830.0, 1250.0, 1550.0, 1900.0, 2260.0, 2620.0, 2980.0, 3310.0, 3650.0, 4080.0])
    else:
        _build_region_three()

    _update_camera_limits()
    _refresh_hud()

func _build_region_three() -> void:
    level_world_width = 2600.0
    _make_scenery(level_world_width, true)
    var stone := Color(0.24, 0.21, 0.22)
    var ledge := Color(0.40, 0.30, 0.27)

    # Short approach with a low bell-throat hop before the checkpoint.
    _platform(Vector2(190, 462), Vector2(380, 50), stone)
    _platform(Vector2(430, 355), Vector2(120, 22), ledge)
    _platform(Vector2(620, 462), Vector2(250, 50), stone)
    _platform(Vector2(720, 357), Vector2(160, 16), ledge)
    _platform(Vector2(695, 428), Vector2(34, 18), Color(0.55, 0.39, 0.30))
    _platform(Vector2(835, 462), Vector2(220, 50), stone)

    # The arena is about 1,420 units wide, with two vented gaps and raised escape ledges.
    _platform(Vector2(1110, 462), Vector2(340, 50), stone)
    _platform(Vector2(1650, 462), Vector2(500, 50), stone)
    _platform(Vector2(2190, 462), Vector2(340, 50), stone)
    _platform(Vector2(1210, 340), Vector2(170, 24), ledge)
    _platform(Vector2(2090, 340), Vector2(170, 24), ledge)
    _platform(Vector2(1650, 357), Vector2(340, 16), Color(0.34, 0.27, 0.25))
    _platform(Vector2(1650, 428), Vector2(34, 18), Color(0.55, 0.39, 0.30))

    _make_checkpoint(Vector2(850, 418))
    _make_collectible(Vector2(620, 300))
    _make_vent(Vector2(1340, 520))
    _make_vent(Vector2(1960, 520))
    _make_exit(Vector2(2470, 420))
    _make_decorations([110.0, 320.0, 540.0, 740.0, 865.0, 1080.0, 1310.0, 1490.0, 1810.0, 1990.0, 2220.0, 2410.0])

    boss = BOSS_SCENE.instantiate() as Node2D
    boss.position = Vector2(1650, 418)
    level_root.add_child(boss)
    boss.connect("health_changed", Callable(self, "_on_boss_health_changed"))
    boss.connect("encounter_started", Callable(self, "_on_boss_started"))
    boss.connect("boss_message", Callable(self, "_on_boss_message"))
    boss.connect("vent_state_changed", Callable(self, "_on_boss_vent_state_changed"))
    boss.connect("defeated", Callable(self, "_on_boss_defeated"))
    _on_boss_health_changed(8, 8)
    _make_boss_gate(Vector2(920, 360), Vector2(995, 418))

func _make_scenery(world_width: float, warmer: bool) -> void:
    var scenery := Node2D.new()
    scenery.name = "Atmosphere"
    scenery.set_script(load("res://scripts/scenery.gd"))
    scenery.world_width = world_width
    scenery.warmer_tone = warmer
    level_root.add_child(scenery)

func _update_camera_limits() -> void:
    if is_instance_valid(camera):
        camera.limit_left = 0
        camera.limit_right = int(level_world_width)
        camera.limit_top = 0
        camera.limit_bottom = 540

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
    level_root.add_child(body)

func _make_decorations(positions: Array) -> void:
    for x in positions:
        var glow := Polygon2D.new()
        glow.position = Vector2(x, 420)
        glow.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(-5, -20), Vector2(0, -28), Vector2(5, -20), Vector2(7, 0)])
        glow.color = Color(0.54, 0.46, 0.30, 0.85) if current_level == 2 else Color(0.20, 0.73, 0.56, 0.85)
        level_root.add_child(glow)
        var dot := Polygon2D.new()
        dot.position = Vector2(x, 400)
        dot.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
        dot.color = Color(0.90, 0.61, 0.34) if current_level == 2 else Color(0.72, 0.92, 0.52)
        level_root.add_child(dot)

func _new_trigger(trigger_name: String, at: Vector2, size: Vector2) -> Area2D:
    var area := Area2D.new()
    area.name = trigger_name
    area.position = at
    var shape := RectangleShape2D.new()
    shape.size = size
    var collider := CollisionShape2D.new()
    collider.shape = shape
    area.add_child(collider)
    level_root.add_child(area)
    return area

func _make_checkpoint(at: Vector2) -> void:
    var flag := Polygon2D.new()
    flag.position = at + Vector2(0, -22)
    flag.polygon = PackedVector2Array([Vector2(-3, -30), Vector2(3, -30), Vector2(3, 24), Vector2(-3, 24)])
    flag.color = Color(0.67, 0.69, 0.57)
    level_root.add_child(flag)
    var banner := Polygon2D.new()
    banner.position = at + Vector2(16, -43)
    banner.polygon = PackedVector2Array([Vector2(-12, -9), Vector2(15, -4), Vector2(-12, 8)])
    banner.color = Color(0.66, 0.43, 0.30) if current_level == 2 else Color(0.28, 0.72, 0.59)
    level_root.add_child(banner)
    var area := _new_trigger("Checkpoint", at, Vector2(54, 80))
    area.body_entered.connect(_on_checkpoint_entered.bind(at))

func _make_collectible(at: Vector2) -> void:
    var glow := Polygon2D.new()
    glow.name = "GlowShard"
    glow.position = at
    glow.polygon = PackedVector2Array([Vector2(0, -17), Vector2(11, -2), Vector2(0, 18), Vector2(-11, -2)])
    glow.color = Color(0.91, 0.62, 0.31) if current_level == 2 else Color(0.27, 0.93, 0.80)
    level_root.add_child(glow)
    var area := _new_trigger("Collectible", at, Vector2(42, 50))
    area.body_entered.connect(_on_collectible_entered.bind(area, glow))

func _make_stillheart(at: Vector2) -> void:
    stillheart_visual = Node2D.new()
    stillheart_visual.name = "Stillheart"
    stillheart_visual.position = at + Vector2(0, -28)
    var halo := Polygon2D.new()
    halo.polygon = PackedVector2Array([Vector2(0, -22), Vector2(17, 0), Vector2(0, 22), Vector2(-17, 0)])
    halo.color = Color(0.96, 0.49, 0.24, 0.38)
    stillheart_visual.add_child(halo)
    var core := Polygon2D.new()
    core.polygon = PackedVector2Array([Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)])
    core.color = Color(1.0, 0.75, 0.39)
    stillheart_visual.add_child(core)
    level_root.add_child(stillheart_visual)
    stillheart_area = _new_trigger("StillheartPickup", at, Vector2(58, 70))
    stillheart_area.body_entered.connect(_on_stillheart_entered.bind(stillheart_area, stillheart_visual))

func _make_exit(at: Vector2) -> void:
    var arch := Polygon2D.new()
    arch.position = at
    arch.polygon = PackedVector2Array([Vector2(-42, 30), Vector2(-42, -32), Vector2(-30, -55), Vector2(30, -55), Vector2(42, -32), Vector2(42, 30), Vector2(27, 30), Vector2(27, -27), Vector2(18, -40), Vector2(-18, -40), Vector2(-27, -27), Vector2(-27, 30)])
    arch.color = Color(0.48, 0.39, 0.34) if current_level == 2 else Color(0.42, 0.48, 0.40)
    level_root.add_child(arch)
    var core := Polygon2D.new()
    core.position = at + Vector2(0, -10)
    core.polygon = PackedVector2Array([Vector2(-17, 22), Vector2(-17, -9), Vector2(-11, -24), Vector2(11, -24), Vector2(17, -9), Vector2(17, 22)])
    core.color = Color(0.71, 0.40, 0.25, 0.78) if current_level == 2 else Color(0.16, 0.54, 0.48, 0.70)
    level_root.add_child(core)
    var area := _new_trigger("Exit", at, Vector2(80, 100))
    area.body_entered.connect(_on_exit_entered)

func _make_enemy(at: Vector2) -> void:
    var enemy := ENEMY_SCENE.instantiate()
    enemy.position = at
    level_root.add_child(enemy)

func _make_boss_gate(gate_at: Vector2, threshold_at: Vector2) -> void:
    var gate := StaticBody2D.new()
    gate.name = "HushvaultArenaGate"
    gate.position = gate_at
    gate.collision_layer = 1
    gate.collision_mask = 1
    var shape := RectangleShape2D.new()
    shape.size = Vector2(24, 154)
    arena_gate_shape = CollisionShape2D.new()
    arena_gate_shape.shape = shape
    arena_gate_shape.disabled = true
    gate.add_child(arena_gate_shape)
    arena_gate_visual = Polygon2D.new()
    arena_gate_visual.polygon = PackedVector2Array([Vector2(-12, -77), Vector2(12, -77), Vector2(12, 77), Vector2(-12, 77)])
    arena_gate_visual.color = Color(0.70, 0.36, 0.22, 0.94)
    arena_gate_visual.visible = false
    gate.add_child(arena_gate_visual)
    level_root.add_child(gate)

    var threshold := _new_trigger("BossThreshold", threshold_at, Vector2(50, 120))
    threshold.body_entered.connect(_on_boss_threshold_entered)

func _make_hazard(at: Vector2, size: Vector2) -> void:
    var area := _new_trigger("PitHazard", at, size)
    area.body_entered.connect(_on_hazard_entered)
    for x in range(-int(size.x / 2) + 10, int(size.x / 2), 30):
        var spike := Polygon2D.new()
        spike.position = at + Vector2(x, -25)
        spike.polygon = PackedVector2Array([Vector2(-13, 25), Vector2(0, 0), Vector2(13, 25)])
        spike.color = Color(0.68, 0.34, 0.29) if current_level == 1 else Color(0.80, 0.42, 0.27)
        level_root.add_child(spike)

func _make_vent(at: Vector2) -> void:
    var vent := Polygon2D.new()
    vent.position = at + Vector2(0, 28)
    vent.polygon = PackedVector2Array([Vector2(-30, 15), Vector2(-20, -8), Vector2(-10, 15), Vector2(0, -18), Vector2(10, 15), Vector2(20, -8), Vector2(30, 15)])
    vent.color = Color(0.20, 0.82, 0.74, 0.8) if current_level == 1 else Color(0.98, 0.52, 0.30, 0.8)
    level_root.add_child(vent)
    vent_visuals.append(vent)
    var area := _new_trigger("BreathglassVent", at, Vector2(82, 72))
    area.body_entered.connect(_on_vent_entered)

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
    boss_label = Label.new()
    boss_label.text = "THE BELLOWS SAINT"
    boss_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    boss_label.position = Vector2(-190, 68)
    boss_label.size = Vector2(380, 30)
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_label.add_theme_font_size_override("font_size", 20)
    boss_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.38))
    boss_label.visible = false
    layer.add_child(boss_label)
    boss_bar = ProgressBar.new()
    boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    boss_bar.position = Vector2(-190, 100)
    boss_bar.size = Vector2(380, 22)
    boss_bar.max_value = 8
    boss_bar.value = 8
    boss_bar.show_percentage = false
    var bar_back := StyleBoxFlat.new()
    bar_back.bg_color = Color(0.09, 0.08, 0.10, 0.95)
    boss_bar.add_theme_stylebox_override("background", bar_back)
    var bar_fill := StyleBoxFlat.new()
    bar_fill.bg_color = Color(0.91, 0.38, 0.20, 0.98)
    boss_bar.add_theme_stylebox_override("fill", bar_fill)
    boss_bar.visible = false
    layer.add_child(boss_bar)
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
    if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("touch_pause"):
        _toggle_pause()
    if Input.is_action_just_pressed("restart"):
        _restart_level()

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
        var level_name := "FORGOTTEN HOLLOW"
        if current_level == 2:
            level_name = "THE PALE SPINE"
        elif current_level == 3:
            level_name = "THE HUSHVAULT"
        shard_label.text = "LEVEL %d: %s  •  SHARD %d/1" % [current_level, level_name, shards]

func _show_message(text: String, seconds: float) -> void:
    message_generation += 1
    var token := message_generation
    message_label.text = text
    message_label.visible = true
    await get_tree().create_timer(seconds).timeout
    if is_instance_valid(message_label) and token == message_generation and not completed:
        message_label.visible = false

func _on_checkpoint_entered(body: Node2D, at: Vector2) -> void:
    if body != player:
        return
    checkpoint_position = at
    player.respawn_position = checkpoint_position
    _show_message("CHECKPOINT KINDLED", 2.0)

func _on_collectible_entered(body: Node2D, area: Area2D, visual: Node2D) -> void:
    if body != player or not is_instance_valid(area):
        return
    shards = 1
    area.queue_free()
    visual.queue_free()
    _refresh_hud()
    _show_message("SHARD FOUND", 2.0)

func _on_stillheart_entered(body: Node2D, area: Area2D, visual: Node2D) -> void:
    if body != player or not is_instance_valid(area):
        return
    stillheart_collected = true
    area.queue_free()
    visual.queue_free()
    stillheart_area = null
    stillheart_visual = null
    _show_message("STILLHEART CLAIMED — THE KEY TO REGION FOUR", 3.0)

func _on_exit_entered(body: Node2D) -> void:
    if body != player or completed:
        return
    if current_level == 3 and not boss_defeated:
        _show_message("THE BELLOWS SAINT STILL GUARDS THE EXIT", 2.0)
        return
    if current_level == 3 and not stillheart_collected:
        _show_message("CLAIM THE STILLHEART FROM THE BELL-KEEPER", 2.0)
        return
    if shards < 1:
        _show_message("The sealed gate needs this level's shard", 2.0)
        return
    if current_level == 1:
        _start_level_two()
    elif current_level == 2:
        _start_level_three()
    else:
        _complete_game()

func _start_level_two() -> void:
    get_tree().paused = false
    paused = false
    completed = false
    checkpoint_position = Vector2(120, 418)
    player.respawn_position = checkpoint_position
    _build_level(2)
    player.respawn(checkpoint_position)
    _refresh_hud()
    _show_message("LEVEL 2: THE PALE SPINE  •  A harder crossing lies ahead", 3.0)

func _start_level_three() -> void:
    get_tree().paused = false
    paused = false
    completed = false
    checkpoint_position = Vector2(120, 418)
    player.respawn_position = checkpoint_position
    _build_level(3)
    player.respawn(checkpoint_position)
    _refresh_hud()
    _show_message("REGION 3: THE HUSHVAULT  •  Reach the bell-foundry and face its keeper", 3.0)

func _complete_game() -> void:
    completed = true
    player.set_physics_process(false)
    get_tree().paused = true
    pause_panel.visible = true
    pause_panel.get_child(0).text = "THE HUSHVAULT CLEARED\nTap ↻ or press R to replay"

func _on_hazard_entered(body: Node2D) -> void:
    if body == player:
        player._die()

func _on_vent_entered(body: Node2D) -> void:
    if body == player:
        player.breathglass_burst()

func _on_fall_damage_taken(amount: int) -> void:
    var heart_text := "HEART" if amount == 1 else "HEARTS"
    _show_message("HARD LANDING — %d %s LOST" % [amount, heart_text], 2.0)

func _on_enemy_stomped() -> void:
    _show_message("ASH MITE STOMP!", 1.0)

func _on_boss_threshold_entered(body: Node2D) -> void:
    if body != player or not is_instance_valid(boss) or bool(boss.get("active")):
        return
    boss.call("start_encounter")

func _on_boss_started() -> void:
    boss_label.visible = true
    boss_bar.visible = true
    if is_instance_valid(arena_gate_shape):
        arena_gate_shape.set_deferred("disabled", false)
    if is_instance_valid(arena_gate_visual):
        arena_gate_visual.visible = true

func _on_boss_health_changed(current: int, maximum: int) -> void:
    if not is_instance_valid(boss_bar):
        return
    boss_bar.max_value = maximum
    boss_bar.value = current

func _on_boss_message(text: String) -> void:
    _show_message(text, 1.8)

func _on_boss_vent_state_changed(vent_state: String) -> void:
    var tint := Color(0.98, 0.52, 0.30, 0.8)
    if vent_state == "siphon":
        tint = Color(0.72, 0.35, 0.83, 0.95)
    elif vent_state == "updraft":
        tint = Color(0.18, 0.88, 0.78, 0.95)
    for vent in vent_visuals:
        if is_instance_valid(vent):
            vent.color = tint

func _on_boss_defeated() -> void:
    boss_defeated = true
    boss_label.visible = false
    boss_bar.visible = false
    if is_instance_valid(arena_gate_shape):
        arena_gate_shape.set_deferred("disabled", true)
    if is_instance_valid(arena_gate_visual):
        arena_gate_visual.visible = false
    if is_instance_valid(boss):
        _make_stillheart(boss.global_position)
    _show_message("THE HUSHVAULT'S BELL GOES QUIET — THE EXIT IS OPEN", 3.0)

func _on_player_died() -> void:
    if is_instance_valid(boss) and not bool(boss.get("is_defeated")):
        boss.call("reset_encounter")
        boss_label.visible = false
        boss_bar.visible = false
        if is_instance_valid(arena_gate_shape):
            arena_gate_shape.set_deferred("disabled", true)
        if is_instance_valid(arena_gate_visual):
            arena_gate_visual.visible = false
    get_tree().create_timer(0.65).timeout.connect(func(): player.respawn(checkpoint_position))
