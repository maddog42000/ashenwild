extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal fall_damage_taken(amount: int)
signal enemy_stomped

const BASE_SPEED := 260.0
const SPEED_PER_MISSING_HEART := 90.0
const BASE_ACCELERATION := 1750.0
const ACCELERATION_PER_MISSING_HEART := 280.0
const BASE_FRICTION := 2100.0
const FRICTION_PER_MISSING_HEART := 480.0
const BASE_JUMP_VELOCITY := -525.0
const JUMP_BOOST_PER_MISSING_HEART := -45.0
const BASE_DOUBLE_JUMP_VELOCITY := -470.0
const DOUBLE_JUMP_BOOST_PER_MISSING_HEART := -50.0
const BASE_GRAVITY := 950.0
const GRAVITY_PER_MISSING_HEART := 350.0
const BASE_FALL_CAP := 700.0
const FALL_CAP_PER_MISSING_HEART := 160.0
const FALL_DAMAGE_THRESHOLD := 650.0
const MAX_HEALTH := 3
const FULL_HEALTH_BODY_SCALE := Vector2(0.27, 0.22)
const BASE_COLLIDER_RADIUS := 15.0
const BASE_COLLIDER_HEIGHT := 44.0

var health := MAX_HEALTH
var jumps_used := 0
var facing := 1
var invulnerable := false
var attacking := false
var dead := false
var attack_ready_at := 0
var vent_ready_at := 0
var respawn_position := Vector2(120, 418)
var body_shape: CapsuleShape2D
var player_sprite: AnimatedSprite2D
var fallback_visuals: Array[Node2D] = []

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    body_shape = CapsuleShape2D.new()
    body_shape.radius = BASE_COLLIDER_RADIUS
    body_shape.height = BASE_COLLIDER_HEIGHT
    var collider := CollisionShape2D.new()
    collider.shape = body_shape
    add_child(collider)
    add_to_group("player")
    _make_visual()
    _update_health_scale()
    health_changed.emit(health, MAX_HEALTH)

func _make_visual() -> void:
    player_sprite = AnimatedSprite2D.new()
    player_sprite.name = "Sprite"
    var sheet_path := "res://assets/sprites/wanderer_sheet.png"
    if ResourceLoader.exists(sheet_path):
        var texture := load(sheet_path) as Texture2D
        if texture:
            var frames := SpriteFrames.new()
            frames.remove_animation("default")
            var frame_width := texture.get_width() / 4
            var frame_height := texture.get_height() / 2
            var specs := {"idle": [Vector2i(0, 0)], "walk": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "jump": [Vector2i(0, 1)], "fall": [Vector2i(1, 1)], "attack": [Vector2i(2, 1)], "hurt": [Vector2i(3, 1)]}
            for animation in specs:
                frames.add_animation(animation)
                frames.set_animation_speed(animation, 8.0)
                frames.set_animation_loop(animation, animation == "walk" or animation == "idle")
                for cell in specs[animation]:
                    var atlas := AtlasTexture.new()
                    atlas.atlas = texture
                    atlas.region = Rect2(cell.x * frame_width, cell.y * frame_height, frame_width, frame_height)
                    frames.add_frame(animation, atlas)
            player_sprite.sprite_frames = frames
            player_sprite.scale = FULL_HEALTH_BODY_SCALE
    if player_sprite.sprite_frames == null:
        var fallback_body := Polygon2D.new()
        fallback_body.name = "FallbackBody"
        fallback_body.polygon = PackedVector2Array([Vector2(-13, -19), Vector2(9, -19), Vector2(15, -7), Vector2(12, 14), Vector2(0, 21), Vector2(-13, 13), Vector2(-15, -5)])
        fallback_body.color = Color(0.78, 0.81, 0.74)
        add_child(fallback_body)
        fallback_visuals.append(fallback_body)
        var eye := Polygon2D.new()
        eye.polygon = PackedVector2Array([Vector2(2, -10), Vector2(10, -9), Vector2(10, -5), Vector2(2, -5)])
        eye.color = Color(0.93, 0.68, 0.30)
        add_child(eye)
        fallback_visuals.append(eye)
    else:
        add_child(player_sprite)
        player_sprite.play("idle")

func _health_ratio() -> float:
    return float(health) / float(MAX_HEALTH)

func _missing_hearts() -> int:
    return MAX_HEALTH - health

func _update_health_scale() -> void:
    # Three visibly distinct silhouettes: full-size, reduced, then compact.
    var size_factor := 0.34 + 0.66 * _health_ratio()
    if is_instance_valid(player_sprite):
        player_sprite.scale = FULL_HEALTH_BODY_SCALE * size_factor
    for visual in fallback_visuals:
        if is_instance_valid(visual):
            visual.scale = Vector2.ONE * size_factor
    if is_instance_valid(body_shape):
        body_shape.radius = BASE_COLLIDER_RADIUS * size_factor
        body_shape.height = BASE_COLLIDER_HEIGHT * size_factor

func get_current_speed() -> float:
    return BASE_SPEED + SPEED_PER_MISSING_HEART * _missing_hearts()

func get_current_gravity() -> float:
    return BASE_GRAVITY + GRAVITY_PER_MISSING_HEART * _missing_hearts()

func get_current_fall_cap() -> float:
    return BASE_FALL_CAP + FALL_CAP_PER_MISSING_HEART * _missing_hearts()

func breathglass_burst() -> void:
    if dead or Time.get_ticks_msec() < vent_ready_at:
        return
    vent_ready_at = Time.get_ticks_msec() + 1400
    velocity.y = -760.0 - 55.0 * _missing_hearts()
    jumps_used = 1

func _physics_process(delta: float) -> void:
    if dead:
        return
    var was_on_floor := is_on_floor()
    var direction := Input.get_axis("move_left", "move_right")
    var missing_hearts := _missing_hearts()
    var run_speed := get_current_speed()
    var acceleration := BASE_ACCELERATION + ACCELERATION_PER_MISSING_HEART * missing_hearts
    var friction := BASE_FRICTION + FRICTION_PER_MISSING_HEART * missing_hearts
    if direction != 0.0:
        velocity.x = move_toward(velocity.x, direction * run_speed, acceleration * delta)
        facing = 1 if direction > 0.0 else -1
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)

    if was_on_floor:
        jumps_used = 0
    if Input.is_action_just_pressed("jump") and jumps_used < 2:
        velocity.y = BASE_JUMP_VELOCITY + JUMP_BOOST_PER_MISSING_HEART * missing_hearts if jumps_used == 0 else BASE_DOUBLE_JUMP_VELOCITY + DOUBLE_JUMP_BOOST_PER_MISSING_HEART * missing_hearts
        jumps_used += 1
    if not was_on_floor:
        velocity.y = minf(velocity.y + get_current_gravity() * delta, get_current_fall_cap())
    if Input.is_action_just_released("jump") and velocity.y < -120.0:
        velocity.y = -120.0

    if Input.is_action_just_pressed("attack") and Time.get_ticks_msec() >= attack_ready_at:
        _attack()

    var fall_speed_before_landing := velocity.y
    move_and_slide()
    var stomped_enemy := _check_enemy_contacts(fall_speed_before_landing)
    if not stomped_enemy and not was_on_floor and is_on_floor() and fall_speed_before_landing >= FALL_DAMAGE_THRESHOLD:
        _apply_fall_damage(fall_speed_before_landing)
    _update_animation(direction)
    if global_position.y > 700.0:
        _die()

func _check_enemy_contacts(fall_speed_before_landing: float) -> bool:
    var stomped_enemy := false
    for index in range(get_slide_collision_count()):
        var collision := get_slide_collision(index)
        var collider := collision.get_collider()
        if collider is Node and collider.is_in_group("enemies") and collider.has_method("apply_contact_damage"):
            if collision.get_normal().y < -0.65 and fall_speed_before_landing > 0.0:
                collider.take_damage(1, facing)
                velocity.y = -320.0
                jumps_used = 0
                enemy_stomped.emit()
                stomped_enemy = true
            else:
                collider.apply_contact_damage(self)
    return stomped_enemy

func _apply_fall_damage(impact_speed: float) -> void:
    if invulnerable or dead:
        return
    var damage := mini(2, 1 + int((impact_speed - FALL_DAMAGE_THRESHOLD) / 180.0))
    var previous_health := health
    take_damage(damage, global_position.x, false)
    if health < previous_health:
        fall_damage_taken.emit(previous_health - health)

func _update_animation(direction: float) -> void:
    if not is_instance_valid(player_sprite) or attacking or dead:
        return
    player_sprite.flip_h = facing < 0
    var next_animation := "idle"
    if not is_on_floor():
        next_animation = "jump" if velocity.y < 0.0 else "fall"
    elif absf(direction) > 0.05:
        next_animation = "walk"
    if player_sprite.animation != next_animation:
        player_sprite.play(next_animation)

func _attack() -> void:
    attacking = true
    attack_ready_at = Time.get_ticks_msec() + 420
    if is_instance_valid(player_sprite):
        player_sprite.flip_h = facing < 0
        player_sprite.play("attack")
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var offset: Vector2 = enemy.global_position - global_position
        if absf(offset.y) <= 58.0 and absf(offset.x) <= 82.0 and offset.x * facing >= -8.0:
            if enemy.has_method("take_damage"):
                enemy.take_damage(1, facing)
    await get_tree().create_timer(0.18).timeout
    attacking = false
    if is_instance_valid(player_sprite):
        player_sprite.play("idle")

func take_damage(amount: int, source_x: float, apply_knockback: bool = true) -> void:
    if invulnerable or dead:
        return
    health = maxi(0, health - amount)
    _update_health_scale()
    health_changed.emit(health, MAX_HEALTH)
    if apply_knockback:
        velocity = Vector2(signf(global_position.x - source_x) * 230.0, -210.0)
    invulnerable = true
    modulate = Color(1.0, 0.55, 0.52)
    if health <= 0:
        _die()
        return
    await get_tree().create_timer(0.75).timeout
    if is_instance_valid(self):
        invulnerable = false
        modulate = Color.WHITE

func _die() -> void:
    if dead:
        return
    dead = true
    velocity = Vector2.ZERO
    died.emit()

func respawn(at_position: Vector2) -> void:
    global_position = at_position
    velocity = Vector2.ZERO
    health = MAX_HEALTH
    jumps_used = 0
    dead = false
    invulnerable = false
    _update_health_scale()
    modulate = Color.WHITE
    health_changed.emit(health, MAX_HEALTH)
