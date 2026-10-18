extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal encounter_started
signal boss_message(text: String)
signal vent_state_changed(state: String)
signal defeated

const MAX_HEALTH := 8
const GRAVITY := 1300.0
const PULSE_SPEED := 410.0
const EMBER_SPEED := 560.0
const CONTACT_DAMAGE_COOLDOWN_MS := 900
const ARENA_LEFT := 930.0
const ARENA_RIGHT := 2360.0
const PROJECTILE_SCENE := preload("res://scenes/boss_projectile.tscn")

enum BossState { DORMANT, REST, WINDUP, PULSES, EMBER_WARNING, EMBER_FALL, SIPHON, CORE_OPEN, STAGGER, PHASE_CHANGE, DEFEATED }

var health := MAX_HEALTH
var phase := 1
var active := false
var core_open := false
var is_defeated := false
var state: BossState = BossState.DORMANT
var state_timer := 0.0
var attack_count := 0
var pulse_count := 0
var pulse_total := 3
var attack_kind := "pulse"
var facing := -1
var contact_ready_at := 0
var defeat_signal_sent := false
var boss_sprite: Sprite2D
var core_glow: Polygon2D
var ember_markers: Array[Node2D] = []

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    var body_shape := RectangleShape2D.new()
    body_shape.size = Vector2(170.0, 110.0)
    var collider := CollisionShape2D.new()
    collider.shape = body_shape
    collider.position = Vector2(0, -45)
    add_child(collider)
    add_to_group("enemies")
    _make_visuals()
    health_changed.emit(health, MAX_HEALTH)

func _make_visuals() -> void:
    boss_sprite = Sprite2D.new()
    boss_sprite.name = "BossSprite"
    var texture_path := "res://assets/sprites/bellows_saint_sheet_mobile.png"
    if ResourceLoader.exists(texture_path):
        boss_sprite.texture = load(texture_path) as Texture2D
        boss_sprite.hframes = 4
        boss_sprite.vframes = 2
        boss_sprite.frame = 0
        boss_sprite.scale = Vector2(0.75, 0.75)
        boss_sprite.position = Vector2(0, -100)
        add_child(boss_sprite)
    else:
        var shell := Polygon2D.new()
        shell.name = "FallbackShell"
        shell.position = Vector2(0, -72)
        shell.polygon = PackedVector2Array([Vector2(-95, 8), Vector2(-80, -47), Vector2(-42, -90), Vector2(15, -100), Vector2(78, -65), Vector2(100, -18), Vector2(84, 30), Vector2(40, 47), Vector2(-48, 45)])
        shell.color = Color(0.18, 0.22, 0.21)
        add_child(shell)
        var core := Polygon2D.new()
        core.position = Vector2(0, -75)
        core.polygon = PackedVector2Array([Vector2(0, -23), Vector2(18, 0), Vector2(0, 23), Vector2(-18, 0)])
        core.color = Color(0.93, 0.55, 0.22)
        add_child(core)

    core_glow = Polygon2D.new()
    core_glow.name = "ExposedCoreGlow"
    core_glow.polygon = PackedVector2Array([Vector2(0, -29), Vector2(22, 0), Vector2(0, 29), Vector2(-22, 0)])
    core_glow.color = Color(1.0, 0.70, 0.28, 0.72)
    core_glow.visible = false
    add_child(core_glow)
    _update_facing_visuals()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    else:
        velocity.y = 0.0
    velocity.x = 0.0
    move_and_slide()

    var player := get_tree().get_first_node_in_group("player")
    if active and is_instance_valid(player) and not bool(player.get("dead")):
        facing = 1 if player.global_position.x >= global_position.x else -1
        _update_facing_visuals()

    if state == BossState.DORMANT or state == BossState.DEFEATED:
        if state == BossState.DEFEATED and not defeat_signal_sent and state_timer <= 0.0:
            defeat_signal_sent = true
            defeated.emit()
        else:
            state_timer = maxf(0.0, state_timer - delta)
        return

    state_timer -= delta
    match state:
        BossState.REST:
            if state_timer <= 0.0:
                _begin_attack_cycle()
        BossState.WINDUP:
            if state_timer <= 0.0:
                _launch_attack()
        BossState.PULSES:
            if state_timer <= 0.0:
                _fire_next_pulse()
        BossState.EMBER_WARNING:
            if state_timer <= 0.0:
                _drop_embers()
        BossState.EMBER_FALL:
            if state_timer <= 0.0:
                _open_core()
        BossState.SIPHON:
            _apply_siphon(delta)
            if state_timer <= 0.0:
                _open_core()
        BossState.CORE_OPEN:
            if state_timer <= 0.0:
                _close_core()
        BossState.STAGGER, BossState.PHASE_CHANGE:
            if state_timer <= 0.0:
                state = BossState.REST
                state_timer = 0.65
                _set_frame(0)

func start_encounter() -> void:
    if active or is_defeated:
        return
    active = true
    state = BossState.REST
    state_timer = 0.85
    encounter_started.emit()
    boss_message.emit("THE BELLOWS SAINT AWAKENS")

func reset_encounter() -> void:
    for projectile in get_tree().get_nodes_in_group("boss_projectiles"):
        projectile.queue_free()
    _clear_ember_markers()
    health = MAX_HEALTH
    phase = 1
    active = false
    core_open = false
    is_defeated = false
    defeat_signal_sent = false
    attack_count = 0
    pulse_count = 0
    contact_ready_at = 0
    state = BossState.DORMANT
    state_timer = 0.0
    core_glow.visible = false
    _set_frame(0)
    vent_state_changed.emit("normal")
    health_changed.emit(health, MAX_HEALTH)

func _begin_attack_cycle() -> void:
    attack_count += 1
    if phase == 1:
        attack_kind = "pulse" if attack_count % 2 == 1 else "ember"
    elif phase == 2:
        match (attack_count - 1) % 3:
            0: attack_kind = "pulse"
            1: attack_kind = "siphon"
            _: attack_kind = "ember"
    else:
        attack_kind = "pulse" if attack_count % 2 == 1 else "ember"

    state = BossState.WINDUP
    state_timer = 1.35 if health == 1 and attack_kind == "pulse" else (0.9 if attack_kind == "siphon" else 0.85)
    _set_frame(4 if attack_kind == "siphon" else 1)
    if attack_kind == "pulse":
        boss_message.emit("THREE BEATS — PREPARE TO JUMP")
    elif attack_kind == "ember":
        boss_message.emit("EMBER MARKS — MOVE TO A SAFE LANE")
    else:
        boss_message.emit("THE HUSHVAULT DRAWS IN — COUNTER-STEER")

func _launch_attack() -> void:
    if attack_kind == "pulse":
        pulse_count = 0
        pulse_total = 1 if health == 1 else (2 if phase == 3 else 3)
        state = BossState.PULSES
        state_timer = 0.12
    elif attack_kind == "siphon":
        state = BossState.SIPHON
        state_timer = 2.15
        vent_state_changed.emit("siphon")
    else:
        _make_ember_markers()
        state = BossState.EMBER_WARNING
        state_timer = 0.6

func _fire_next_pulse() -> void:
    for direction in [-1, 1]:
        var projectile := PROJECTILE_SCENE.instantiate()
        projectile.call("configure", "pulse", Vector2(float(direction) * PULSE_SPEED, 0.0), global_position.x)
        get_parent().add_child(projectile)
        projectile.global_position = global_position + Vector2(float(direction) * 98.0, -5.0)
    pulse_count += 1
    if pulse_count < pulse_total:
        state_timer = 0.48 if phase < 3 else 0.36
    else:
        _open_core()

func _make_ember_markers() -> void:
    _clear_ember_markers()
    var player := get_tree().get_first_node_in_group("player")
    var target_x := global_position.x
    if is_instance_valid(player):
        target_x = player.global_position.x
    var level_root := get_parent()
    for offset in [-150.0, 0.0, 150.0]:
        var warning := Polygon2D.new()
        warning.name = "EmberLandingTell"
        warning.polygon = PackedVector2Array([Vector2(0, -12), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0)])
        warning.color = Color(1.0, 0.66, 0.26, 0.9)
        var x := clampf(target_x + offset, ARENA_LEFT + 40.0, ARENA_RIGHT - 40.0)
        warning.global_position = Vector2(x, 426.0)
        level_root.add_child(warning)
        ember_markers.append(warning)

func _drop_embers() -> void:
    var level_root := get_parent()
    for marker in ember_markers:
        if not is_instance_valid(marker):
            continue
        var projectile := PROJECTILE_SCENE.instantiate()
        projectile.call("configure", "ember", Vector2(0.0, EMBER_SPEED), global_position.x)
        level_root.add_child(projectile)
        projectile.global_position = Vector2(marker.global_position.x, 26.0)
    state = BossState.EMBER_FALL
    state_timer = 1.05

func _apply_siphon(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if not is_instance_valid(player) or bool(player.get("dead")):
        return
    var pull_direction := signf(global_position.x - player.global_position.x)
    var strength := 245.0
    var speed_limit := float(player.call("get_current_speed")) * 1.1
    player.velocity.x = clampf(player.velocity.x + pull_direction * strength * delta, -speed_limit, speed_limit)

func _open_core() -> void:
    _clear_ember_markers()
    core_open = true
    state = BossState.CORE_OPEN
    state_timer = 1.25 if phase == 1 else (1.0 if phase == 2 else 0.9)
    vent_state_changed.emit("updraft" if attack_kind == "siphon" else "normal")
    core_glow.position = Vector2(float(facing) * 98.0, -50.0)
    core_glow.visible = true
    _set_frame(3)
    boss_message.emit("CORE EXPOSED — STRIKE NOW")

func _close_core() -> void:
    core_open = false
    core_glow.visible = false
    state = BossState.REST
    state_timer = 0.55
    vent_state_changed.emit("normal")
    _set_frame(0)

func is_player_in_attack_range(player: Node2D) -> bool:
    if not core_open or is_defeated:
        return false
    var target := global_position + Vector2(float(facing) * 98.0, -50.0)
    var offset := target - player.global_position
    var player_facing := float(player.get("facing"))
    return absf(offset.x) <= 82.0 and absf(offset.y) <= 58.0 and offset.x * player_facing >= -8.0

func take_damage(amount: int, hit_direction: int) -> void:
    if not active or is_defeated or not core_open:
        return
    health = maxi(0, health - amount)
    core_open = false
    core_glow.visible = false
    health_changed.emit(health, MAX_HEALTH)
    if health <= 0:
        is_defeated = true
        active = false
        state = BossState.DEFEATED
        state_timer = 0.9
        collision_layer = 0
        collision_mask = 0
        _set_frame(7)
        for projectile in get_tree().get_nodes_in_group("boss_projectiles"):
            projectile.queue_free()
        vent_state_changed.emit("normal")
        boss_message.emit("THE HUSHVAULT FALLS QUIET")
        return

    var next_phase := 1
    if health <= 5:
        next_phase = 2
    if health <= 2:
        next_phase = 3
    if next_phase != phase:
        phase = next_phase
        state = BossState.PHASE_CHANGE
        state_timer = 1.1
        _set_frame(5)
        boss_message.emit("THE BELL CRACKS — PHASE %d" % phase)
    else:
        state = BossState.STAGGER
        state_timer = 0.65
        _set_frame(6)

func apply_contact_damage(player: Node) -> void:
    if not active or is_defeated or core_open or state != BossState.REST or bool(player.get("dead")):
        return
    if Time.get_ticks_msec() < contact_ready_at:
        return
    contact_ready_at = Time.get_ticks_msec() + CONTACT_DAMAGE_COOLDOWN_MS
    player.call("take_damage", 1, global_position.x)

func _update_facing_visuals() -> void:
    if is_instance_valid(boss_sprite):
        boss_sprite.flip_h = facing < 0
    if is_instance_valid(core_glow) and core_open:
        core_glow.position = Vector2(float(facing) * 98.0, -50.0)

func _set_frame(frame_index: int) -> void:
    if is_instance_valid(boss_sprite):
        boss_sprite.frame = clampi(frame_index, 0, 7)

func _clear_ember_markers() -> void:
    for marker in ember_markers:
        if is_instance_valid(marker):
            marker.queue_free()
    ember_markers.clear()
