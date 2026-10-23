extends Area2D

var attack_kind := "rivet"
var travel_velocity := Vector2.ZERO
var source_x := 0.0
var source_enemy: Node2D
var lifetime := 3.2

func configure(kind: String, origin: Vector2, velocity: Vector2, source: Node2D) -> void:
    attack_kind = kind
    global_position = origin
    travel_velocity = velocity
    source_enemy = source
    source_x = source.global_position.x if is_instance_valid(source) else origin.x

func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    monitoring = true
    add_to_group("elite_projectiles")

    var collider := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 11.0 if attack_kind == "rivet" else 14.0
    collider.shape = shape
    add_child(collider)

    var halo := Polygon2D.new()
    halo.name = "Halo"
    halo.polygon = PackedVector2Array([Vector2(0, -18), Vector2(18, 0), Vector2(0, 18), Vector2(-18, 0)])
    halo.color = Color(1.0, 0.48, 0.21, 0.32) if attack_kind == "rivet" else Color(1.0, 0.72, 0.30, 0.34)
    add_child(halo)
    var core := Polygon2D.new()
    core.name = "Core"
    core.polygon = PackedVector2Array([Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)])
    core.color = Color(1.0, 0.71, 0.32) if attack_kind == "rivet" else Color(1.0, 0.90, 0.58)
    add_child(core)
    rotation = travel_velocity.angle()
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    global_position += travel_velocity * delta
    lifetime -= delta
    if lifetime <= 0.0 or global_position.x < -100.0 or global_position.x > 4500.0 or global_position.y > 700.0:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        if body is StaticBody2D:
            queue_free()
        return
    var blocked := false
    if body.has_method("try_block_projectile"):
        blocked = bool(body.call("try_block_projectile", source_x, source_enemy))
    if blocked:
        queue_free()
        return
    body.call("take_damage", 1, source_x)
    queue_free()
