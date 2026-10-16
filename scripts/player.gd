extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const SPEED := 260.0
const ACCELERATION := 1750.0
const FRICTION := 2100.0
const JUMP_VELOCITY := -525.0
const DOUBLE_JUMP_VELOCITY := -470.0
const GRAVITY := 1250.0
const MAX_HEALTH := 3

var health := MAX_HEALTH
var jumps_used := 0
var facing := 1
var invulnerable := false
var attacking := false
var dead := false
var attack_ready_at := 0
var respawn_position := Vector2(120, 418)

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    var shape := CapsuleShape2D.new()
    shape.radius = 12.0
    shape.height = 42.0
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)
    add_to_group("player")
    _make_visual()
    health_changed.emit(health, MAX_HEALTH)

func _make_visual() -> void:
    var sprite := AnimatedSprite2D.new()
    sprite.name = "Sprite"
    var sheet_path := "res://assets/sprites/wanderer_sheet.png"
    if ResourceLoader.exists(sheet_path):
        var texture := load(sheet_path) as Texture2D
        if texture:
            var frames := SpriteFrames.new()
            frames.remove_animation("default")
            var fw := texture.get_width() / 4
            var fh := texture.get_height() / 2
            var specs := {"idle": [Vector2i(0, 0)], "walk": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "jump": [Vector2i(0, 1)], "fall": [Vector2i(1, 1)], "attack": [Vector2i(2, 1)], "hurt": [Vector2i(3, 1)]}
            for anim in specs:
                frames.add_animation(anim)
                frames.set_animation_speed(anim, 8.0)
                frames.set_animation_loop(anim, anim == "walk" or anim == "idle")
                for cell in specs[anim]:
                    var atlas := AtlasTexture.new()
                    atlas.atlas = texture
                    atlas.region = Rect2(cell.x * fw, cell.y * fh, fw, fh)
                    frames.add_frame(anim, atlas)
            sprite.sprite_frames = frames
            sprite.scale = Vector2(0.21, 0.21)
    if sprite.sprite_frames == null:
        var fallback := Polygon2D.new()
        fallback.name = "FallbackBody"
        fallback.polygon = PackedVector2Array([Vector2(-13, -19), Vector2(9, -19), Vector2(15, -7), Vector2(12, 14), Vector2(0, 21), Vector2(-13, 13), Vector2(-15, -5)])
        fallback.color = Color(0.78, 0.81, 0.74)
        add_child(fallback)
        var eye := Polygon2D.new()
        eye.polygon = PackedVector2Array([Vector2(2, -10), Vector2(10, -9), Vector2(10, -5), Vector2(2, -5)])
        eye.color = Color(0.93, 0.68, 0.30)
        add_child(eye)
    else:
        add_child(sprite)
        sprite.play("idle")

func _physics_process(delta: float) -> void:
    if dead:
        return
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0.0:
        velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
        facing = 1 if direction > 0.0 else -1
    else:
        velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

    if is_on_floor():
        jumps_used = 0
    if Input.is_action_just_pressed("jump") and jumps_used < 2:
        velocity.y = JUMP_VELOCITY if jumps_used == 0 else DOUBLE_JUMP_VELOCITY
        jumps_used += 1
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    if Input.is_action_just_released("jump") and velocity.y < -120.0:
        velocity.y = -120.0

    if Input.is_action_just_pressed("attack") and Time.get_ticks_msec() >= attack_ready_at:
        _attack()
    move_and_slide()
    _update_animation(direction)
    if global_position.y > 680.0:
        _die()

func _update_animation(direction: float) -> void:
    var sprite := get_node_or_null("Sprite") as AnimatedSprite2D
    if sprite == null or attacking or dead:
        return
    sprite.flip_h = facing < 0
    var next := "idle"
    if not is_on_floor():
        next = "jump" if velocity.y < 0.0 else "fall"
    elif absf(direction) > 0.05:
        next = "walk"
    if sprite.animation != next:
        sprite.play(next)

func _attack() -> void:
    attacking = true
    attack_ready_at = Time.get_ticks_msec() + 420
    var sprite := get_node_or_null("Sprite") as AnimatedSprite2D
    if sprite:
        sprite.flip_h = facing < 0
        sprite.play("attack")
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var offset: Vector2 = enemy.global_position - global_position
        if absf(offset.y) <= 58.0 and absf(offset.x) <= 82.0 and offset.x * facing >= -8.0:
            if enemy.has_method("take_damage"):
                enemy.take_damage(1, facing)
    await get_tree().create_timer(0.18).timeout
    attacking = false
    if sprite and is_instance_valid(sprite):
        sprite.play("idle")

func take_damage(amount: int, source_x: float) -> void:
    if invulnerable or dead:
        return
    health = maxi(0, health - amount)
    health_changed.emit(health, MAX_HEALTH)
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
    modulate = Color.WHITE
    health_changed.emit(health, MAX_HEALTH)
