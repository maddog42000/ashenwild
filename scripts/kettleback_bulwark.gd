extends CharacterBody2D

signal status_changed(enemy_name: String, state: String, health: int, maximum: int)

const PROJECTILE_SCENE := preload("res://scenes/elite_projectile.tscn")
const MAX_HEALTH := 3
const GRAVITY := 1250.0
const CONTACT_COOLDOWN_MS := 900

var health := MAX_HEALTH
var state := "idle"
var facing := 1
var state_timer := 1.7
var signature_in_flight := false
var signature_timer := 0.0
var contact_ready_at := 0
var dead := false
var visual_root: Node2D
var jaw_core: Polygon2D
var tell_glow: Polygon2D

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    add_to_group("enemies")
    var shape := CapsuleShape2D.new()
    shape.radius = 27.0
    shape.height = 52.0
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)
    _make_visual()
    _emit_state()

func _make_visual() -> void:
    visual_root = Node2D.new()
    visual_root.name = "KettlebackSilhouette"
    add_child(visual_root)

    var shell := Polygon2D.new()
    shell.polygon = PackedVector2Array([Vector2(-30, 13), Vector2(-27, -11), Vector2(-17, -23), Vector2(8, -26), Vector2(27, -17), Vector2(32, 2), Vector2(24, 18), Vector2(-19, 20)])
    shell.color = Color(0.30, 0.34, 0.33)
    visual_root.add_child(shell)
    var ridge := Polygon2D.new()
    ridge.polygon = PackedVector2Array([Vector2(-20, -13), Vector2(-11, -31), Vector2(-4, -14), Vector2(5, -34), Vector2(12, -13), Vector2(21, -25), Vector2(23, -5)])
    ridge.color = Color(0.53, 0.39, 0.31)
    visual_root.add_child(ridge)
    for x in [-17.0, 1.0, 20.0]:
        var rivet := Polygon2D.new()
        rivet.position = Vector2(x, -7)
        rivet.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
        rivet.color = Color(0.81, 0.62, 0.40)
        visual_root.add_child(rivet)
    var jaw := Polygon2D.new()
    jaw.polygon = PackedVector2Array([Vector2(14, 6), Vector2(35, 1), Vector2(29, 16), Vector2(16, 16)])
    jaw.color = Color(0.43, 0.40, 0.34)
    visual_root.add_child(jaw)
    jaw_core = Polygon2D.new()
    jaw_core.name = "JawCore"
    jaw_core.position = Vector2(24, -6)
    jaw_core.polygon = PackedVector2Array([Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)])
    jaw_core.color = Color(0.33, 0.82, 0.73)
    jaw_core.visible = false
    visual_root.add_child(jaw_core)
    var eye := Polygon2D.new()
    eye.name = "TellEye"
    eye.position = Vector2(27, -13)
    eye.polygon = PackedVector2Array([Vector2(-6, -3), Vector2(6, -3), Vector2(8, 0), Vector2(-6, 3)])
    eye.color = Color(0.96, 0.57, 0.29)
    visual_root.add_child(eye)
    tell_glow = eye
    for side in [-1.0, 1.0]:
        var leg := Polygon2D.new()
        leg.position = Vector2(side * 17.0, 15)
        leg.polygon = PackedVector2Array([Vector2(-7, -1), Vector2(6, -1), Vector2(10, 12), Vector2(-11, 12)])
        leg.color = Color(0.22, 0.25, 0.26)
        visual_root.add_child(leg)

func _physics_process(delta: float) -> void:
    if dead:
        return
    if not is_on_floor():
        velocity.y = minf(velocity.y + GRAVITY * delta, 760.0)
    velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
    move_and_slide()
    _check_player_contacts()

    if signature_in_flight:
        signature_timer -= delta
        if signature_timer <= 0.0:
            signature_in_flight = false
    if state == "exposed":
        state_timer -= delta
        if state_timer <= 0.0:
            _set_state("recovery", 0.85)
    elif state == "windup":
        state_timer -= delta
        if state_timer <= 0.0:
            _fire_rivet()
    elif state == "recovery":
        state_timer -= delta
        if state_timer <= 0.0:
            _set_state("idle", 1.15)
    else:
        state_timer -= delta
        var target := get_tree().get_first_node_in_group("player")
        if target and not target.dead:
            var offset: Vector2 = target.global_position - global_position
            if absf(offset.x) > 90.0 and absf(offset.x) <= 430.0 and absf(offset.y) <= 145.0 and state_timer <= 0.0:
                facing = 1 if offset.x > 0.0 else -1
                _set_state("windup", 0.9)
    visual_root.scale.x = float(facing)
    tell_glow.color = Color(1.0, 0.84, 0.42) if state == "windup" else Color(0.96, 0.57, 0.29)
    queue_redraw()

func _fire_rivet() -> void:
    _set_state("recovery", 1.1)
    signature_in_flight = true
    signature_timer = 2.25
    var projectile := PROJECTILE_SCENE.instantiate()
    projectile.call("configure", "kettle_rivet", global_position + Vector2(float(facing) * 39.0, -7.0), Vector2(float(facing) * 315.0, 0.0), self)
    get_parent().add_child(projectile)

func on_projectile_guarded() -> void:
    if dead or state != "recovery" or not signature_in_flight:
        return
    signature_in_flight = false
    _set_state("exposed", 2.35)

func cancel_pending_attack() -> void:
    if dead:
        return
    signature_in_flight = false
    _set_state("recovery", 0.85)

func is_arrow_target_hit(hit_position: Vector2) -> bool:
    if dead or state != "exposed":
        return false
    var weakpoint := global_position + Vector2(float(facing) * 24.0, -6.0)
    return hit_position.distance_to(weakpoint) <= 25.0

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
    velocity = Vector2(float(hit_direction) * 95.0, -55.0)
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
    if dead or Time.get_ticks_msec() < contact_ready_at or player.dead:
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
    jaw_core.visible = state == "exposed"
    if state == "windup":
        tell_glow.visible = true
    elif state == "exposed":
        tell_glow.visible = false
    else:
        tell_glow.visible = true
    _emit_state()
    queue_redraw()

func _emit_state() -> void:
    status_changed.emit("KETTLEBACK BULWARK", state, health, MAX_HEALTH)

func _draw() -> void:
    draw_rect(Rect2(-21, -43, 42, 5), Color(0.07, 0.08, 0.09, 0.9))
    for index in range(MAX_HEALTH):
        var color := Color(0.91, 0.53, 0.30) if index < health else Color(0.24, 0.25, 0.25)
        draw_rect(Rect2(-19.0 + float(index) * 13.0, -42.0, 10.0, 3.0), color)
