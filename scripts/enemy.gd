extends CharacterBody2D

const SPEED := 70.0
const GRAVITY := 1250.0
const MAX_HEALTH := 2

var health := MAX_HEALTH
var patrol_left := 0.0
var patrol_right := 0.0
var direction := -1
var dead := false
var hit_flash := 0

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    var shape := CapsuleShape2D.new()
    shape.radius = 17.0
    shape.height = 34.0
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)
    patrol_left = global_position.x - 90.0
    patrol_right = global_position.x + 90.0
    add_to_group("enemies")
    _make_visual()

func _make_visual() -> void:
    var sprite := Sprite2D.new()
    sprite.name = "Sprite"
    var path := "res://assets/sprites/ash-mite_sheet.png"
    if ResourceLoader.exists(path):
        var texture := load(path) as Texture2D
        if texture:
            sprite.texture = texture
            sprite.region_enabled = true
            sprite.region_rect = Rect2(0, 0, texture.get_width() / 4.0, texture.get_height() / 2.0)
            sprite.scale = Vector2(0.21, 0.21)
    if sprite.texture == null:
        var shell := Polygon2D.new()
        shell.name = "FallbackShell"
        shell.polygon = PackedVector2Array([Vector2(-18, 8), Vector2(-16, -4), Vector2(-8, -13), Vector2(7, -13), Vector2(17, -4), Vector2(18, 8), Vector2(10, 14), Vector2(-11, 14)])
        shell.color = Color(0.30, 0.40, 0.39)
        add_child(shell)
        var eyes := Polygon2D.new()
        eyes.polygon = PackedVector2Array([Vector2(6, -7), Vector2(11, -7), Vector2(11, -2), Vector2(6, -2)])
        eyes.color = Color(0.38, 0.91, 0.84)
        add_child(eyes)
    else:
        add_child(sprite)

func _physics_process(delta: float) -> void:
    if dead:
        return
    var player := get_tree().get_first_node_in_group("player")
    if player and not player.dead and global_position.distance_to(player.global_position) < 200.0:
        direction = 1 if player.global_position.x > global_position.x else -1
        if absf(player.global_position.x - global_position.x) > 35.0:
            velocity.x = direction * SPEED * 1.15
        else:
            velocity.x = 0.0
            if Time.get_ticks_msec() >= hit_flash:
                player.take_damage(1, global_position.x)
                hit_flash = Time.get_ticks_msec() + 1100
    else:
        if global_position.x < patrol_left:
            direction = 1
        elif global_position.x > patrol_right:
            direction = -1
        velocity.x = direction * SPEED

    if not is_on_floor():
        velocity.y += GRAVITY * delta
    move_and_slide()
    var sprite := get_node_or_null("Sprite") as Sprite2D
    if sprite:
        sprite.flip_h = direction < 0

func take_damage(amount: int, hit_direction: int) -> void:
    if dead:
        return
    health -= amount
    velocity = Vector2(hit_direction * 240.0, -150.0)
    modulate = Color(1.0, 0.62, 0.48)
    if health <= 0:
        dead = true
        var sprite := get_node_or_null("Sprite")
        if sprite:
            sprite.visible = false
        queue_free()
        return
    await get_tree().create_timer(0.18).timeout
    if is_instance_valid(self):
        modulate = Color.WHITE
