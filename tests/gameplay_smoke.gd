extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error(message)
    quit(1)

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    var main := packed.instantiate()
    root.add_child(main)
    await physics_frame
    var player: CharacterBody2D = main.player
    var controls: Control = main.controls
    var control_positions: Dictionary = controls._positions(controls.get_viewport_rect().size)
    var stick_touch := InputEventScreenTouch.new()
    stick_touch.index = 2
    stick_touch.pressed = true
    stick_touch.position = control_positions["stick"]
    controls._input(stick_touch)
    var stick_drag := InputEventScreenDrag.new()
    stick_drag.index = 2
    stick_drag.position = control_positions["stick"] + Vector2(-52, 0)
    controls._input(stick_drag)
    var jump_touch := InputEventScreenTouch.new()
    jump_touch.index = 3
    jump_touch.pressed = true
    jump_touch.position = control_positions["jump"]
    controls._input(jump_touch)
    var attack_touch := InputEventScreenTouch.new()
    attack_touch.index = 4
    attack_touch.pressed = true
    attack_touch.position = control_positions["attack"]
    controls._input(attack_touch)
    if not Input.is_action_pressed("move_left") or not Input.is_action_pressed("jump") or not Input.is_action_pressed("attack"):
        _fail("Virtual joystick could not steer simultaneously with jump and attack")
        return
    jump_touch.pressed = false
    controls._input(jump_touch)
    attack_touch.pressed = false
    controls._input(attack_touch)
    stick_touch.pressed = false
    controls._input(stick_touch)
    if Input.is_action_pressed("move_left") or Input.is_action_pressed("jump") or Input.is_action_pressed("attack"):
        _fail("A touch release left a movement or action input stuck")
        return
    stick_touch.pressed = true
    controls._input(stick_touch)
    stick_drag.position = control_positions["stick"] + Vector2(52, 0)
    controls._input(stick_drag)
    if not Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
        _fail("Virtual joystick did not switch cleanly to right steering")
        return
    stick_touch.pressed = false
    controls._input(stick_touch)

    if main.current_level != 1 or main.level_world_width < 3000.0:
        _fail("Level 1 did not load at the expected expanded size")
        return
    if player.get_current_speed() != 260.0 or player.get_current_gravity() != 950.0:
        _fail("Full-health movement profile is incorrect")
        return

    var full_scale: float = player.get_node("Sprite").scale.x
    player.health = 2
    player._update_health_scale()
    if player.get_current_speed() != 350.0 or player.get_current_gravity() != 1300.0 or player.get_current_fall_cap() != 860.0:
        _fail("Two-heart movement profile is incorrect")
        return
    var medium_scale: float = player.get_node("Sprite").scale.x
    player.health = 1
    player._update_health_scale()
    if player.get_current_speed() != 440.0 or player.get_current_gravity() != 1650.0 or player.get_current_fall_cap() != 1020.0:
        _fail("One-heart movement profile is incorrect")
        return
    var low_scale: float = player.get_node("Sprite").scale.x
    if not (full_scale > medium_scale and medium_scale > low_scale):
        _fail("Body size did not shrink distinctly at each missing-heart tier")
        return
    player.health = 3
    player._update_health_scale()

    var enemies: Array = get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.set_physics_process(false)
    var stomp_target: CharacterBody2D = enemies[1]
    player.set_physics_process(false)
    player.position = stomp_target.position + Vector2(0, -100)
    for frame in range(12):
        await physics_frame
    if player.health != 3:
        _fail("Enemy proximity without physical contact damaged the player")
        return

    # Falling onto an Ash Mite should stomp it and bounce the player safely.
    var old_enemy_health: int = stomp_target.health
    player.position = stomp_target.position + Vector2(0, -75)
    player.velocity = Vector2(0, 520)
    player.set_physics_process(true)
    for frame in range(24):
        await physics_frame
    if player.health != 3 or stomp_target.health >= old_enemy_health:
        _fail("A safe stomp did not hurt the enemy and protect the player")
        return

    # A real side/body collision should still hurt.
    player.position = stomp_target.position + Vector2(-60, 0)
    player.velocity = Vector2(500, 0)
    player.invulnerable = false
    for frame in range(12):
        await physics_frame
    if player.health >= 3:
        _fail("Physical side contact did not damage the player")
        return

    player.breathglass_burst()
    if player.velocity.y >= -700.0:
        _fail("Breathglass did not launch the player upward")
        return

    # Collecting the first shard and entering its gate opens the longer sequel level.
    player.set_physics_process(false)
    main.shards = 1
    main._on_exit_entered(player)
    await physics_frame
    await physics_frame
    if main.current_level != 2 or main.level_world_width < 4200.0 or get_nodes_in_group("enemies").size() < 4:
        _fail("Level 2 did not load with the longer route and enemy set")
        return
    if player.health != 3:
        _fail("Level transition should restore all health")
        return

    # A high-speed landing on solid ground must cause fall damage.
    for creature in get_nodes_in_group("enemies"):
        creature.set_physics_process(false)
    player.health = 3
    player.invulnerable = false
    player._update_health_scale()
    player.position = Vector2(350, 120)
    player.velocity = Vector2.ZERO
    player.set_physics_process(true)
    await create_timer(1.3).timeout
    if player.health >= 3:
        _fail("A high-speed landing did not trigger fall damage")
        return

    main.shards = 1
    main._on_exit_entered(player)
    if not main.completed:
        _fail("Final gate failed to complete the prototype")
        return
    paused = false
    print("PASS: multitouch joystick, health tiers, collision-only enemy hits, safe stomp, Breathglass, fall damage, longer Level 2, and completion")
    quit(0)
