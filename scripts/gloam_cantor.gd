extends CharacterBody2D

signal status_changed(enemy_name: String, state: String, health: int, maximum: int)

const PROJECTILE_SCENE := preload("res://scenes/elite_projectile.tscn")
const MAX_HEALTH := 4
const CONTACT_COOLDOWN_MS := 900

var health := MAX_HEALTH
var state := "idle"
var facing := 1
var state_timer := 1.6
var hover_time := 0.0
var home_y := 0.0
var signature_in_flight := false
var signature_timer := 0.0
var contact_ready_at := 0
var dead := false
var exposure_target_y := 0.0
var telegraph_target := Vector2.ZERO
var visual_root: Node2D
var weak_chime: Polygon2D
var target_marker: Polygon2D
var telegraph_line: Line2D

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    add_to_group("enemies")
    home_y = global_position.y
    var shape := CapsuleShape2D.new()
    shape.radius = 25.0
    shape.height = 50.0
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)
    _make_visual()
    _emit_state()

func _make_visual() -> void:
    visual_root = Node2D.new()
    visual_root.name = "CantorSilhouette"
    add_child(visual_root)
    var mantle := Polygon2D.new()
    mantle.polygon = PackedVector2Array([Vector2(0, -30), Vector2(21, -17), Vector2(27, 12), Vector2(17, 27), Vector2(-17, 27), Vector2(-27, 12), Vector2(-21, -17)])
    mantle.color = Color(0.25, 0.27, 0.30)
    visual_root.add_child(mantle)
    var hood := Polygon2D.new()
    hood.polygon = PackedVector2Array([Vector2(-19, -13), Vector2(-13, -33), Vector2(0, -40), Vector2(14, -32), Vector2(21, -12), Vector2(9, -4), Vector2(-12, -5)])
    hood.color = Color(0.42, 0.35, 0.37)
    visual_root.add_child(hood)
    var face := Polygon2D.new()
    face.position = Vector2(0, -14)
    face.polygon = PackedVector2Array([Vector2(-10, -5), Vector2(10, -5), Vector2(7, 4), Vector2(-7, 4)])
    face.color = Color(0.83, 0.67, 0.46)
    visual_root.add_child(face)
    for x in [-18.0, 0.0, 18.0]:
        var chime := Polygon2D.new()
        chime.position = Vector2(x, 28)
        chime.polygon = PackedVector2Array([Vector2(-6, -4), Vector2(6, -4), Vector2(4, 9), Vector2(0, 13), Vector2(-4, 9)])
        chime.color = Color(0.55, 0.66, 0.68)
        visual_root.add_child(chime)
    weak_chime = Polygon2D.new()
    weak_chime.name = "OpenChimeWeakpoint"
    weak_chime.position = Vector2(0, 20)
    weak_chime.polygon = PackedVector2Array([Vector2(0, -12), Vector2(11, 0), Vector2(0, 12), Vector2(-11, 0)])
    weak_chime.color = Color(0.36, 0.88, 0.80)
    weak_chime.visible = false
    visual_root.add_child(weak_chime)

    target_marker = Polygon2D.new()
    target_marker.name = "DropLaneTell"
    target_marker.polygon = PackedVector2Array([Vector2(-24, 13), Vector2(-19, 2), Vector2(-10, -3), Vector2(10, -3), Vector2(19, 2), Vector2(24, 13), Vector2(17, 10), Vector2(10, 2), Vector2(-10, 2), Vector2(-17, 10)])
    target_marker.color = Color(1.0, 0.67, 0.28, 0.86)
    target_marker.visible = false
    add_child(target_marker)
    telegraph_line = Line2D.new()
    telegraph_line.name = "ChimeFallTell"
    telegraph_line.width = 3.0
    telegraph_line.default_color = Color(1.0, 0.72, 0.34, 0.72)
    telegraph_line.visible = false
    add_child(telegraph_line)

func _physics_process(delta: float) -> void:
    if dead:
        return
    hover_time += delta
    if signature_in_flight:
        signature_timer -= delta
        if signature_timer <= 0.0:
            signature_in_flight = false
    if state != "telegraph" and state != "exposed":
        global_position.y = home_y + sin(hover_time * 1.7) * 7.0

    if state == "telegraph":
        state_timer -= delta
        if state_timer <= 0.0:
            _launch_chime()
    elif state == "exposed":
        state_timer -= delta
        if state_timer <= 0.0:
            global_position.y = home_y
            _set_state("recovery", 1.05)
    elif state == "recovery":
        state_timer -= delta
        if state_timer <= 0.0:
            _set_state("idle", 1.25)
    else:
        state_timer -= delta
        var player := get_tree().get_first_node_in_group("player")
        if player and not player.dead:
            var offset: Vector2 = player.global_position - global_position
            if absf(offset.x) <= 440.0 and absf(offset.y) <= 390.0 and state_timer <= 0.0:
                facing = 1 if offset.x >= 0.0 else -1
                _begin_telegraph(player)
    visual_root.scale.x = float(facing)
    queue_redraw()

func _begin_telegraph(player: Node2D) -> void:
    telegraph_target = player.global_position
    exposure_target_y = player.global_position.y
    target_marker.global_position = telegraph_target + Vector2(0, 20)
    target_marker.visible = true
    telegraph_line.points = PackedVector2Array([Vector2.ZERO, target_marker.position])
    telegraph_line.visible = true
    signature_in_flight = false
    _set_state("telegraph", 1.0)

func _launch_chime() -> void:
    target_marker.visible = false
    telegraph_line.visible = false
    signature_in_flight = true
    signature_timer = 2.2
    var origin := global_position + Vector2(0, -34)
    var trajectory := telegraph_target - origin
    if trajectory.length() < 1.0:
        trajectory = Vector2(float(-facing), 1.0)
    var projectile := PROJECTILE_SCENE.instantiate()
    projectile.call("configure", "cantor_chime", origin, trajectory.normalized() * 560.0, self)
    get_parent().add_child(projectile)
    _set_state("recovery", 0.9)

func on_projectile_guarded() -> void:
    if dead or not signature_in_flight:
        return
    signature_in_flight = false
    global_position.y = exposure_target_y - 18.0
    weak_chime.visible = true
    _set_state("exposed", 2.6)

func cancel_pending_attack() -> void:
    if dead:
        return
    signature_in_flight = false
    global_position.y = home_y
    _set_state("recovery", 0.85)

func is_arrow_target_hit(hit_position: Vector2) -> bool:
    if dead or state != "exposed":
        return false
    var weakpoint := global_position + Vector2(0, 20)
    return hit_position.distance_to(weakpoint) <= 30.0

func take_arrow_damage(hit_position: Vector2, hit_direction: int) -> void:
    if is_arrow_target_hit(hit_position):
        _apply_damage(1, hit_direction)

func take_damage(amount: int, hit_direction: int) -> void:
    if state == "exposed":
        _apply_damage(amount, hit_direction)

func _apply_damage(amount: int, hit_direction: int) -> void:
    if dead or state != "exposed":
        return
    health = maxi(0, health - amount)
    velocity = Vector2(float(hit_direction) * 70.0, -35.0)
    if health <= 0:
        dead = true
        _set_state("defeated", 0.0)
        queue_free()
        return
    _emit_state()
    queue_redraw()

func is_player_in_attack_range(_player: Node2D) -> bool:
    return false

func can_be_stomped() -> bool:
    return false

func apply_contact_damage(player: Node) -> void:
    if dead or state == "exposed" or Time.get_ticks_msec() < contact_ready_at or player.dead:
        return
    contact_ready_at = Time.get_ticks_msec() + CONTACT_COOLDOWN_MS
    player.take_damage(1, global_position.x)

func _check_player_contacts() -> void:
    for index in range(get_slide_collision_count()):
        var collision := get_slide_collision(index)
        var collider := collision.get_collider()
        if collider is Node and collider.is_in_group("player") and collision.get_normal().y <= 0.65:
            apply_contact_damage(collider)

func _set_state(next_state: String, duration: float) -> void:
    state = next_state
    state_timer = duration
    if is_instance_valid(weak_chime):
        weak_chime.visible = state == "exposed"
    if state != "telegraph":
        target_marker.visible = false
        telegraph_line.visible = false
    _emit_state()
    queue_redraw()

func _emit_state() -> void:
    status_changed.emit("GLOAM CANTOR", state, health, MAX_HEALTH)

func _draw() -> void:
    draw_rect(Rect2(-22, -51, 44, 5), Color(0.07, 0.08, 0.09, 0.9))
    for index in range(MAX_HEALTH):
        var color := Color(0.47, 0.82, 0.79) if index < health else Color(0.24, 0.25, 0.25)
        draw_rect(Rect2(-20.0 + float(index) * 11.0, -50.0, 8.0, 3.0), color)
