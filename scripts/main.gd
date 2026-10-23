extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/bellows_saint.tscn")
const PLAYER_ARROW_SCENE := preload("res://scenes/player_arrow.tscn")
const KETTLEBACK_SCENE := preload("res://scenes/kettleback_bulwark.tscn")
const GLOAM_CANTOR_SCENE := preload("res://scenes/gloam_cantor.tscn")
const MENU_MUSIC_PATH := "res://assets/audio/ashenwild_menu_theme.ogg"
const GAME_MUSIC_PATH := "res://assets/audio/ashenwild_gameplay_theme.mp3"

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
var combat_label: Label
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
var game_started := false
var main_menu_panel: ColorRect
var pause_title: Label
var resume_button: Button
var music_player: AudioStreamPlayer
var game_music_player: AudioStreamPlayer
var music_toggle_buttons: Array[CheckButton] = []
var cheat_toggle_buttons: Array[CheckButton] = []
var cheat_options := {"invulnerable": false, "infinite_jumps": false, "speed_boost": false}
var menu_music_enabled := true

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
    player.arrow_shot_requested.connect(_on_arrow_shot_requested)
    player.bow_state_changed.connect(_refresh_combat_hud)
    player.shield_state_changed.connect(_on_shield_state_changed)
    _on_health_changed(player.health, player.MAX_HEALTH)
    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    player.add_child(camera)
    camera.make_current()
    _update_camera_limits()
    _setup_touch_controls()
    _refresh_hud()
    _setup_menu_music()
    _show_main_menu()

func _setup_actions() -> void:
    var definitions := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_J, KEY_X], "bow_fire": [KEY_K, KEY_C], "shield": [KEY_L, KEY_V], "pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R]}
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
        _platform(Vector2(2010, 462), Vector2(180, 50), Color(0.19, 0.24, 0.24))
        _platform(Vector2(3000, 462), Vector2(600, 50), Color(0.19, 0.24, 0.24))
        _platform(Vector2(590, 354), Vector2(150, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(815, 278), Vector2(150, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1050, 345), Vector2(145, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1280, 278), Vector2(170, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1510, 323), Vector2(170, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(1760, 246), Vector2(180, 24), Color(0.31, 0.37, 0.34))
        # Wisp Ladder: climb up, traverse back left, then drop shelf-by-shelf.
        _platform(Vector2(1840, 355), Vector2(150, 22), Color(0.33, 0.46, 0.39))
        _platform(Vector2(2010, 280), Vector2(150, 22), Color(0.33, 0.46, 0.39))
        _platform(Vector2(2130, 190), Vector2(150, 22), Color(0.33, 0.46, 0.39))
        _platform(Vector2(1940, 210), Vector2(150, 22), Color(0.33, 0.46, 0.39))
        _platform(Vector2(1580, 355), Vector2(150, 22), Color(0.33, 0.46, 0.39))
        # The Echo Crawl drops into a short catch-shelf tunnel and climbs back out.
        _platform(Vector2(2160, 540), Vector2(156, 18), Color(0.39, 0.47, 0.41))
        _platform(Vector2(2330, 615), Vector2(156, 18), Color(0.39, 0.47, 0.41))
        _platform(Vector2(2500, 540), Vector2(156, 18), Color(0.39, 0.47, 0.41))
        _platform(Vector2(2615, 475), Vector2(140, 18), Color(0.39, 0.47, 0.41))
        # Echo Crawl: tap-jump over the low stone while staying under the roof.
        _platform(Vector2(2300, 357), Vector2(520, 16), Color(0.25, 0.29, 0.29))
        _platform(Vector2(2285, 428), Vector2(34, 18), Color(0.48, 0.40, 0.34))
        _platform(Vector2(2650, 345), Vector2(160, 24), Color(0.31, 0.37, 0.34))
        _platform(Vector2(2760, 275), Vector2(180, 24), Color(0.31, 0.37, 0.34))
        _make_checkpoint(Vector2(760, 418))
        _make_collectible(Vector2(1760, 198))
        _make_bow_pickup(Vector2(2130, 152), "rapid")
        _make_bow_pickup(Vector2(1760, 206), "spread")
        _make_exit(Vector2(3180, 420))
        _make_enemy(Vector2(1050, 417))
        _make_enemy(Vector2(1970, 417))
        _make_elite(KETTLEBACK_SCENE, Vector2(1700, 418))
        _make_hazard(Vector2(595, 635), Vector2(220, 70))
        _make_hazard(Vector2(1280, 635), Vector2(220, 70))
        _make_hazard(Vector2(2340, 730), Vector2(480, 70))
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
        # Pale Spine return ridge: rise, double back left, then descend to the tunnel lip.
        _platform(Vector2(3090, 360), Vector2(150, 22), Color(0.48, 0.37, 0.31))
        _platform(Vector2(3290, 285), Vector2(150, 22), Color(0.48, 0.37, 0.31))
        _platform(Vector2(3120, 185), Vector2(150, 22), Color(0.48, 0.37, 0.31))
        _platform(Vector2(2910, 275), Vector2(150, 22), Color(0.48, 0.37, 0.31))
        # Drop passage in the central gap: every fall is caught before the hazard shelf.
        _platform(Vector2(2360, 525), Vector2(150, 18), Color(0.48, 0.37, 0.31))
        _platform(Vector2(2480, 585), Vector2(150, 18), Color(0.48, 0.37, 0.31))
        # Resonance Gallery: climb high, double back, then descend shelf-by-shelf
        # through the 3300–3550 pit and jump back to the far-side floor.
        _platform(Vector2(3360, 355), Vector2(120, 20), Color(0.46, 0.62, 0.57))
        _platform(Vector2(3510, 195), Vector2(120, 20), Color(0.46, 0.62, 0.57))
        _platform(Vector2(3350, 305), Vector2(120, 20), Color(0.46, 0.62, 0.57))
        _platform(Vector2(3320, 390), Vector2(110, 18), Color(0.35, 0.59, 0.53))
        _platform(Vector2(3350, 490), Vector2(120, 18), Color(0.35, 0.59, 0.53))
        _platform(Vector2(3445, 560), Vector2(120, 18), Color(0.35, 0.59, 0.53))
        _platform(Vector2(3490, 490), Vector2(100, 18), Color(0.35, 0.59, 0.53))
        # The Cinder Squeeze is a second low-roof tap-jump tunnel.
        _platform(Vector2(3750, 357), Vector2(400, 16), Color(0.33, 0.27, 0.25))
        _platform(Vector2(3760, 428), Vector2(34, 18), Color(0.53, 0.37, 0.30))
        _platform(Vector2(3650, 337), Vector2(150, 24), Color(0.38, 0.30, 0.27))
        _platform(Vector2(4000, 300), Vector2(170, 24), Color(0.38, 0.30, 0.27))
        _make_checkpoint(Vector2(1850, 418))
        _make_collectible(Vector2(2960, 176))
        _make_bow_pickup(Vector2(3120, 145), "rapid")
        _make_bow_pickup(Vector2(2910, 235), "spread")
        _make_exit(Vector2(4160, 420))
        _make_enemy(Vector2(1050, 417))
        _make_enemy(Vector2(2220, 417))
        _make_enemy(Vector2(3000, 417))
        _make_enemy(Vector2(3930, 417))
        _make_elite(GLOAM_CANTOR_SCENE, Vector2(3430, 150))
        _make_hazard(Vector2(625, 635), Vector2(250, 70))
        _make_hazard(Vector2(1625, 635), Vector2(250, 70))
        _make_hazard(Vector2(2425, 730), Vector2(250, 70))
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
    # Hushvault Bell Stair: gain height, double back left, then drop onto the vent shelf.
    _platform(Vector2(1430, 270), Vector2(145, 22), ledge)
    _platform(Vector2(1600, 190), Vector2(145, 22), ledge)
    _platform(Vector2(1430, 150), Vector2(145, 22), ledge)
    _platform(Vector2(1240, 220), Vector2(145, 22), ledge)

    # The arena is about 1,420 units wide, with two vented gaps and raised escape ledges.
    _platform(Vector2(1110, 462), Vector2(340, 50), stone)
    _platform(Vector2(1650, 462), Vector2(500, 50), stone)
    _platform(Vector2(2190, 462), Vector2(340, 50), stone)
    # Breathglass catch ledges below the arena gaps make controlled drops recoverable.
    _platform(Vector2(1340, 565), Vector2(128, 18), Color(0.29, 0.52, 0.48))
    _platform(Vector2(1960, 565), Vector2(128, 18), Color(0.29, 0.52, 0.48))
    _platform(Vector2(1310, 300), Vector2(140, 22), ledge)
    _platform(Vector2(1840, 275), Vector2(145, 22), ledge)
    _platform(Vector2(1880, 300), Vector2(145, 22), ledge)
    _platform(Vector2(2020, 205), Vector2(145, 22), ledge)
    _platform(Vector2(2200, 270), Vector2(145, 22), ledge)
    _platform(Vector2(1210, 340), Vector2(170, 24), ledge)
    _platform(Vector2(2090, 340), Vector2(170, 24), ledge)
    _platform(Vector2(1650, 357), Vector2(340, 16), Color(0.34, 0.27, 0.25))
    _platform(Vector2(1650, 428), Vector2(34, 18), Color(0.55, 0.39, 0.30))

    _make_checkpoint(Vector2(850, 418))
    _make_collectible(Vector2(620, 300))
    _make_bow_pickup(Vector2(1430, 125), "spread")
    _make_bow_pickup(Vector2(2020, 165), "rapid")
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
        camera.limit_bottom = 800

func _platform(center: Vector2, size: Vector2, tint: Color) -> void:
    var body := StaticBody2D.new()
    body.position = center
    body.collision_layer = 1
    body.collision_mask = 1
    body.add_to_group("platforms")
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

func _make_bow_pickup(at: Vector2, effect: String) -> void:
    var visual := Node2D.new()
    visual.name = "RapidStringPickup" if effect == "rapid" else "FanstringPickup"
    visual.position = at
    var halo := Polygon2D.new()
    halo.polygon = PackedVector2Array([Vector2(0, -18), Vector2(13, 0), Vector2(0, 18), Vector2(-13, 0)])
    halo.color = Color(0.95, 0.64, 0.28, 0.36) if effect == "rapid" else Color(0.50, 0.74, 1.0, 0.38)
    visual.add_child(halo)
    var core := Polygon2D.new()
    core.polygon = PackedVector2Array([Vector2(0, -11), Vector2(8, 0), Vector2(0, 11), Vector2(-8, 0)])
    core.color = Color(1.0, 0.83, 0.42) if effect == "rapid" else Color(0.76, 0.88, 1.0)
    visual.add_child(core)
    level_root.add_child(visual)
    var area := _new_trigger("BowPickup", at, Vector2(48, 52))
    area.body_entered.connect(_on_bow_pickup_entered.bind(effect, area, visual))

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

func _make_elite(scene: PackedScene, at: Vector2) -> void:
    var elite := scene.instantiate() as Node2D
    elite.position = at
    elite.connect("status_changed", Callable(self, "_on_elite_status_changed"))
    level_root.add_child(elite)

func _on_elite_status_changed(enemy_name: String, state: String, _health: int, _maximum: int) -> void:
    if not game_started:
        return
    if state == "windup":
        _show_message("%s — BLOCK OR MOVE" % enemy_name, 1.25)
    elif state == "telegraph":
        _show_message("%s — MARKED DROP LANE" % enemy_name, 1.25)
    elif state == "exposed":
        _show_message("%s WEAKPOINT OPEN — BOW!" % enemy_name, 1.8)
    elif state == "defeated":
        _show_message("%s DEFEATED" % enemy_name, 2.0)

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
    combat_label = Label.new()
    combat_label.position = Vector2(22, 78)
    combat_label.add_theme_font_size_override("font_size", 16)
    combat_label.add_theme_color_override("font_color", Color(0.80, 0.90, 0.84))
    combat_label.visible = false
    layer.add_child(combat_label)
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
    pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
    layer.add_child(pause_panel)
    var pause_center := CenterContainer.new()
    pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pause_panel.add_child(pause_center)
    var pause_card := PanelContainer.new()
    pause_card.custom_minimum_size = Vector2(410, 410)
    _style_card(pause_card)
    pause_center.add_child(pause_card)
    var pause_stack := VBoxContainer.new()
    pause_stack.add_theme_constant_override("separation", 10)
    pause_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    pause_card.add_child(pause_stack)
    pause_title = _make_heading("PAUSED", 30)
    pause_stack.add_child(pause_title)
    resume_button = _make_menu_button("RESUME", _resume_game)
    pause_stack.add_child(resume_button)
    var pause_cheats := _make_cheat_toggles()
    pause_stack.add_child(pause_cheats)
    var pause_music := _make_music_toggle()
    pause_stack.add_child(pause_music)
    var return_button := _make_menu_button("RETURN TO TITLE", _return_to_main_menu)
    pause_stack.add_child(return_button)

    main_menu_panel = ColorRect.new()
    main_menu_panel.name = "MainMenu"
    main_menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main_menu_panel.color = Color(0.015, 0.025, 0.045, 0.90)
    main_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    main_menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
    layer.add_child(main_menu_panel)
    var menu_center := CenterContainer.new()
    menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main_menu_panel.add_child(menu_center)
    var menu_card := PanelContainer.new()
    menu_card.custom_minimum_size = Vector2(480, 480)
    _style_card(menu_card)
    menu_center.add_child(menu_card)
    var menu_stack := VBoxContainer.new()
    menu_stack.add_theme_constant_override("separation", 12)
    menu_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    menu_card.add_child(menu_stack)
    menu_stack.add_child(_make_heading("ASHENWILD", 42))
    var subtitle := _make_heading("THE HUSHVAULT", 17)
    subtitle.add_theme_color_override("font_color", Color(0.65, 0.82, 0.75))
    menu_stack.add_child(subtitle)
    menu_stack.add_child(_make_menu_button("BEGIN JOURNEY", _start_game))
    var cheat_heading := _make_heading("OPTIONAL CHEATS", 16)
    cheat_heading.add_theme_color_override("font_color", Color(0.94, 0.70, 0.42))
    menu_stack.add_child(cheat_heading)
    menu_stack.add_child(_make_cheat_toggles())
    menu_stack.add_child(_make_music_toggle())
    var hint := _make_heading("Stick · JUMP · ATTACK · BOW · SHIELD", 13)
    hint.add_theme_color_override("font_color", Color(0.69, 0.73, 0.72))
    menu_stack.add_child(hint)

func _style_card(card: PanelContainer) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.045, 0.065, 0.075, 0.97)
    style.border_color = Color(0.37, 0.57, 0.48, 0.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(14)
    style.content_margin_left = 24
    style.content_margin_right = 24
    style.content_margin_top = 22
    style.content_margin_bottom = 22
    card.add_theme_stylebox_override("panel", style)

func _make_heading(text: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.94, 0.89, 0.75))
    label.custom_minimum_size.y = float(font_size + 8)
    return label

func _make_menu_button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(300, 50)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    button.add_theme_font_size_override("font_size", 20)
    button.pressed.connect(callback)
    return button

func _make_cheat_toggles() -> VBoxContainer:
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 1)
    _add_cheat_toggle(stack, "Invulnerable", "invulnerable")
    _add_cheat_toggle(stack, "Unlimited air jumps", "infinite_jumps")
    _add_cheat_toggle(stack, "High-speed mode", "speed_boost")
    return stack

func _add_cheat_toggle(parent: VBoxContainer, label: String, cheat_key: String) -> void:
    var toggle := CheckButton.new()
    toggle.text = label
    toggle.button_pressed = bool(cheat_options[cheat_key])
    toggle.add_theme_font_size_override("font_size", 16)
    toggle.toggled.connect(_on_cheat_toggled.bind(cheat_key))
    parent.add_child(toggle)
    cheat_toggle_buttons.append(toggle)

func _make_music_toggle() -> CheckButton:
    var toggle := CheckButton.new()
    toggle.text = "Background music"
    toggle.button_pressed = menu_music_enabled
    toggle.add_theme_font_size_override("font_size", 16)
    toggle.toggled.connect(_on_music_toggled)
    music_toggle_buttons.append(toggle)
    return toggle

func _setup_menu_music() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "MenuMusic"
    music_player.volume_db = -14.0
    music_player.process_mode = Node.PROCESS_MODE_ALWAYS
    if ResourceLoader.exists(MENU_MUSIC_PATH):
        music_player.stream = load(MENU_MUSIC_PATH) as AudioStream
        if music_player.stream is AudioStreamOggVorbis:
            (music_player.stream as AudioStreamOggVorbis).loop = true
    add_child(music_player)

    game_music_player = AudioStreamPlayer.new()
    game_music_player.name = "GameplayMusic"
    game_music_player.volume_db = -12.0
    game_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
    if ResourceLoader.exists(GAME_MUSIC_PATH):
        game_music_player.stream = load(GAME_MUSIC_PATH) as AudioStream
        if game_music_player.stream is AudioStreamMP3:
            (game_music_player.stream as AudioStreamMP3).loop = true
    add_child(game_music_player)

func _show_main_menu() -> void:
    game_started = false
    paused = false
    completed = false
    get_tree().paused = true
    level_root.visible = false
    player.visible = false
    player.set_physics_process(false)
    health_label.visible = false
    shard_label.visible = false
    combat_label.visible = false
    controls.visible = false
    controls.set_process_input(false)
    pause_panel.visible = false
    main_menu_panel.visible = true
    _update_music_playback()

func _start_game() -> void:
    game_started = true
    paused = false
    completed = false
    get_tree().paused = false
    main_menu_panel.visible = false
    pause_panel.visible = false
    level_root.visible = true
    player.visible = true
    player.set_physics_process(true)
    health_label.visible = true
    shard_label.visible = true
    combat_label.visible = true
    controls.visible = true
    controls.set_process_input(true)
    resume_button.visible = true
    _update_music_playback()
    _show_message("THE FORGOTTEN HOLLOW  •  Find the teal shard, then reach the gate", 3.0)

func _resume_game() -> void:
    if completed:
        return
    paused = false
    get_tree().paused = false
    pause_panel.visible = false
    controls.visible = true
    controls.set_process_input(true)
    resume_button.visible = true
    _update_music_playback()

func _return_to_main_menu() -> void:
    get_tree().paused = false
    paused = false
    completed = false
    boss_defeated = false
    checkpoint_position = Vector2(120, 418)
    player.respawn_position = checkpoint_position
    player.respawn(checkpoint_position)
    _build_level(1)
    _refresh_hud()
    _show_main_menu()

func _on_cheat_toggled(enabled: bool, cheat_key: String) -> void:
    cheat_options[cheat_key] = enabled
    player.set("cheat_" + cheat_key, enabled)
    for toggle in cheat_toggle_buttons:
        if is_instance_valid(toggle):
            var matches := (cheat_key == "invulnerable" and toggle.text == "Invulnerable") or (cheat_key == "infinite_jumps" and toggle.text == "Unlimited air jumps") or (cheat_key == "speed_boost" and toggle.text == "High-speed mode")
            if matches:
                toggle.set_pressed_no_signal(enabled)

func _on_music_toggled(enabled: bool) -> void:
    menu_music_enabled = enabled
    for toggle in music_toggle_buttons:
        if is_instance_valid(toggle):
            toggle.set_pressed_no_signal(enabled)
    _update_music_playback()

func _update_music_playback() -> void:
    if not is_instance_valid(music_player) or not is_instance_valid(game_music_player):
        return
    if game_started:
        music_player.stop()
        if not menu_music_enabled or game_music_player.stream == null:
            game_music_player.stop()
        else:
            if not game_music_player.playing:
                game_music_player.play()
            game_music_player.stream_paused = paused
    else:
        game_music_player.stop()
        if menu_music_enabled and music_player.stream != null:
            if not music_player.playing:
                music_player.play()
        elif music_player.playing:
            music_player.stop()

func _process(_delta: float) -> void:
    _refresh_combat_hud()
    if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("touch_pause"):
        _toggle_pause()
    if Input.is_action_just_pressed("restart"):
        _restart_level()

func _toggle_pause() -> void:
    if not game_started or completed:
        return
    paused = not paused
    get_tree().paused = paused
    pause_panel.visible = paused
    controls.visible = not paused
    controls.set_process_input(not paused)
    if paused:
        pause_title.text = "PAUSED"
        resume_button.visible = true
    _update_music_playback()

func _restart_level() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_health_changed(current: int, maximum: int) -> void:
    health_label.text = "HEALTH  " + "◆".repeat(current) + "◇".repeat(maximum - current)

func _on_arrow_shot_requested(origin: Vector2, direction: int, spread_angle: float, shooter_rid: RID) -> void:
    if not is_instance_valid(level_root):
        return
    var arrow := PLAYER_ARROW_SCENE.instantiate() as Node2D
    level_root.add_child(arrow)
    arrow.call("configure", origin, direction, spread_angle, shooter_rid)

func _on_shield_state_changed(_durability: int, _maximum: int) -> void:
    _refresh_combat_hud()
    if _durability == 0 and game_started:
        _show_message("GUARD BROKEN — RESTORE AT A CHECKPOINT", 2.0)

func _refresh_combat_hud() -> void:
    if is_instance_valid(combat_label) and is_instance_valid(player):
        combat_label.text = player.get_combat_status_text()

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
    player.restore_shield()
    _show_message("CHECKPOINT KINDLED", 2.0)

func _on_collectible_entered(body: Node2D, area: Area2D, visual: Node2D) -> void:
    if body != player or not is_instance_valid(area):
        return
    shards = 1
    area.queue_free()
    visual.queue_free()
    _refresh_hud()
    _show_message("SHARD FOUND", 2.0)

func _on_bow_pickup_entered(body: Node2D, effect: String, area: Area2D, visual: Node2D) -> void:
    if body != player or not is_instance_valid(area):
        return
    player.activate_bow_pickup(effect)
    area.queue_free()
    if is_instance_valid(visual):
        visual.queue_free()
    var label := "QUICKSTRING — FASTER ARROWS FOR 12 SECONDS" if effect == "rapid" else "FANSTRING — THREE-WAY VOLLEY FOR 12 SECONDS"
    _show_message(label, 2.4)

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
    paused = true
    player.set_physics_process(false)
    get_tree().paused = true
    pause_panel.visible = true
    controls.visible = false
    controls.set_process_input(false)
    pause_title.text = "THE HUSHVAULT CLEARED"
    resume_button.visible = false
    _update_music_playback()

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
    for projectile in get_tree().get_nodes_in_group("elite_projectiles"):
        projectile.queue_free()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy.has_method("cancel_pending_attack"):
            enemy.call("cancel_pending_attack")
    if is_instance_valid(boss) and not bool(boss.get("is_defeated")):
        boss.call("reset_encounter")
        boss_label.visible = false
        boss_bar.visible = false
        if is_instance_valid(arena_gate_shape):
            arena_gate_shape.set_deferred("disabled", true)
        if is_instance_valid(arena_gate_visual):
            arena_gate_visual.visible = false
    get_tree().create_timer(0.65).timeout.connect(func(): player.respawn(checkpoint_position))
