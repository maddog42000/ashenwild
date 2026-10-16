extends Node2D

func _ready() -> void:
    var path := "res://assets/backgrounds/forgotten_hollow.png"
    if ResourceLoader.exists(path):
        var texture := load(path) as Texture2D
        if texture:
            var backdrop := Sprite2D.new()
            backdrop.texture = texture
            backdrop.position = Vector2(800, 270)
            backdrop.scale = Vector2(0.833333, 0.5)
            backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            add_child(backdrop)
            return
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-100, -100, 1900, 700), Color(0.035, 0.047, 0.075))
    for i in range(11):
        var x := float(i) * 170.0 - 30.0
        var height := 150.0 + float((i * 47) % 130)
        var points := PackedVector2Array([Vector2(x, 390), Vector2(x + 30, 390 - height), Vector2(x + 70, 390 - height * 0.62), Vector2(x + 110, 390 - height * 0.82), Vector2(x + 160, 390)])
        draw_colored_polygon(points, Color(0.065, 0.095, 0.12, 0.95))
    for i in range(22):
        var x := float((i * 83 + 25) % 1550)
        var y := float(210 + (i * 37) % 180)
        draw_circle(Vector2(x, y), 3.0 + float(i % 3), Color(0.18, 0.54, 0.48, 0.48))
        draw_circle(Vector2(x, y), 1.2, Color(0.48, 0.91, 0.73, 0.78))
