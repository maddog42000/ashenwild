extends Area2D

var attack_kind := "pulse"
var travel_velocity := Vector2.ZERO
var source_x := 0.0
var lifetime := 4.0
var effect_sprite: Sprite2D

func configure(kind: String, speed: Vector2, origin_x: float) -> void:
    attack_kind = kind
    travel_velocity = speed
    source_x = origin_x

func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    monitoring = true
    add_to_group("boss_projectiles")

    var collider := CollisionShape2D.new()
    if attack_kind == "pulse":
        var rectangle := RectangleShape2D.new()
        rectangle.size = Vector2(46.0, 18.0)
        collider.shape = rectangle
    else:
        var circle := CircleShape2D.new()
        circle.radius = 13.0
        collider.shape = circle
    add_child(collider)

    effect_sprite = Sprite2D.new()
    effect_sprite.name = "EffectSprite"
    var texture_path := "res://assets/sprites/bellows_effects_sheet_mobile.png"
    if ResourceLoader.exists(texture_path):
        effect_sprite.texture = load(texture_path) as Texture2D
        effect_sprite.hframes = 4
        effect_sprite.vframes = 2
        effect_sprite.frame = 0 if attack_kind == "pulse" else 4
        effect_sprite.scale = Vector2(0.52, 0.34) if attack_kind == "pulse" else Vector2(0.22, 0.22)
        add_child(effect_sprite)
    else:
        var fallback := Polygon2D.new()
        fallback.polygon = PackedVector2Array([Vector2(-15, 7), Vector2(-9, -7), Vector2(0, 0), Vector2(9, -7), Vector2(15, 7)]) if attack_kind == "pulse" else PackedVector2Array([Vector2(0, -12), Vector2(9, 0), Vector2(0, 12), Vector2(-9, 0)])
        fallback.color = Color(1.0, 0.66, 0.27) if attack_kind == "pulse" else Color(1.0, 0.49, 0.18)
        add_child(fallback)

    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position += travel_velocity * delta
    lifetime -= delta
    if attack_kind == "pulse" and is_instance_valid(effect_sprite):
        var frame_step := int(Time.get_ticks_msec() / 100) % 4
        effect_sprite.frame = frame_step
    if lifetime <= 0.0 or position.x < 0.0 or position.x > 3000.0 or position.y > 620.0:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        if body.has_method("try_block_projectile") and bool(body.call("try_block_projectile", source_x)):
            queue_free()
            return
        body.call("take_damage", 1, source_x)
        queue_free()
    elif attack_kind == "ember" and body is StaticBody2D:
        queue_free()
