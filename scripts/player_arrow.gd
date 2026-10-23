extends Node2D

const SPEED := 900.0
const LIFETIME := 2.2

var travel_velocity := Vector2.ZERO
var facing := 1
var shooter_rid := RID()
var age := 0.0

func configure(origin: Vector2, direction: int, spread_angle: float, source_rid: RID) -> void:
    global_position = origin
    facing = 1 if direction >= 0 else -1
    var base_angle := 0.0 if facing > 0 else PI
    var angle := base_angle + spread_angle
    travel_velocity = Vector2(cos(angle), sin(angle)) * SPEED
    rotation = angle
    shooter_rid = source_rid

func _ready() -> void:
    add_to_group("player_arrows")
    queue_redraw()

func _physics_process(delta: float) -> void:
    age += delta
    if age >= LIFETIME:
        queue_free()
        return
    var destination := global_position + travel_velocity * delta
    var query := PhysicsRayQueryParameters2D.create(global_position, destination)
    query.collision_mask = 1
    query.collide_with_bodies = true
    query.collide_with_areas = false
    if shooter_rid.is_valid():
        query.exclude = [shooter_rid]
    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        _resolve_hit(hit)
        queue_free()
        return
    global_position = destination

func _resolve_hit(hit: Dictionary) -> void:
    var target: Object = hit.get("collider")
    if not (target is Node) or not target.is_in_group("enemies"):
        return
    if target.has_method("is_arrow_target_hit"):
        if bool(target.call("is_arrow_target_hit", hit.get("position"))):
            if target.has_method("take_arrow_damage"):
                target.call("take_arrow_damage", hit.get("position"), facing)
            else:
                target.call("take_damage", 1, facing)
        return
    if target.has_method("take_damage"):
        target.call("take_damage", 1, facing)

func _draw() -> void:
    draw_line(Vector2(-18, 0), Vector2(12, 0), Color(0.86, 0.77, 0.53), 3.0, true)
    draw_colored_polygon(PackedVector2Array([Vector2(18, 0), Vector2(8, -5), Vector2(8, 5)]), Color(0.98, 0.84, 0.55))
    draw_line(Vector2(-16, 0), Vector2(-22, -5), Color(0.32, 0.76, 0.68), 2.0, true)
    draw_line(Vector2(-16, 0), Vector2(-22, 5), Color(0.32, 0.76, 0.68), 2.0, true)
