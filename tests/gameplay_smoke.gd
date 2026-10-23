extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error(message)
    quit(1)

func _has_platform_at(main: Node, expected: Vector2) -> bool:
    for child in main.level_root.get_children():
        if child is Node2D and child.is_in_group("platforms") and child.position.distance_to(expected) < 1.0:
            return true
    return false

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    var main := packed.instantiate()
    root.add_child(main)
    await physics_frame
    var player: CharacterBody2D = main.player
    var controls: Control = main.controls
    if main.game_started or not main.main_menu_panel.visible or player.visible or controls.visible or not paused:
        _fail("The new title menu did not open before gameplay")
        return
    if main.music_player.stream == null or not (main.music_player.stream is AudioStreamOggVorbis) or not (main.music_player.stream as AudioStreamOggVorbis).loop:
        _fail("Menu music did not load as a looping Ogg stream")
        return
    if main.game_music_player.stream == null or not (main.game_music_player.stream is AudioStreamMP3) or not (main.game_music_player.stream as AudioStreamMP3).loop:
        _fail("User-provided gameplay MP3 did not load as a looping game stream")
        return
    if int(ProjectSettings.get_setting("display/window/handheld/orientation")) != 4:
        _fail("Mobile orientation is not sensor landscape")
        return
    main._on_cheat_toggled(true, "speed_boost")
    if not player.cheat_speed_boost or player.get_current_speed() != 403.0:
        _fail("High-speed menu cheat did not enable its optional speed boost")
        return
    main._on_cheat_toggled(false, "speed_boost")
    main._on_cheat_toggled(true, "infinite_jumps")
    if player.get_current_jump_limit() < 3:
        _fail("Unlimited-jumps menu cheat did not change the jump limit")
        return
    main._on_cheat_toggled(false, "infinite_jumps")
    main._on_cheat_toggled(true, "invulnerable")
    player.take_damage(1, player.global_position.x)
    player._die()
    if player.health != 3 or player.dead:
        _fail("Invulnerability cheat did not block ordinary and pit death damage")
        return
    main._on_cheat_toggled(false, "invulnerable")
    main._on_music_toggled(false)
    if main.music_player.playing or main.game_music_player.playing:
        _fail("Background music toggle did not mute both tracks")
        return
    main._on_music_toggled(true)
    main._start_game()
    if not main.game_started or not controls.visible or not player.visible:
        _fail("Start button transition did not activate gameplay and touch controls")
        return
    if not main.game_music_player.playing or main.music_player.playing:
        _fail("Starting the game did not switch from menu music to the supplied gameplay track")
        return
    main._toggle_pause()
    if not main.paused or not main.pause_panel.visible or controls.visible or not main.game_music_player.stream_paused:
        _fail("Pause menu did not pause gameplay and hide movement controls")
        return
    main._resume_game()
    if main.paused or main.pause_panel.visible or not controls.visible or main.game_music_player.stream_paused:
        _fail("Resume button did not return to active gameplay")
        return
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
    stick_touch.pressed = true
    controls._input(stick_touch)
    stick_drag.position = control_positions["stick"] + Vector2(52, 0)
    controls._input(stick_drag)
    if not Input.is_action_pressed("move_right"):
        _fail("Virtual joystick did not remain held while adding combat touch inputs")
        return
    var bow_touch := InputEventScreenTouch.new()
    bow_touch.index = 5
    bow_touch.pressed = true
    bow_touch.position = control_positions["bow_fire"]
    controls._input(bow_touch)
    var shield_touch := InputEventScreenTouch.new()
    shield_touch.index = 6
    shield_touch.pressed = true
    shield_touch.position = control_positions["shield"]
    controls._input(shield_touch)
    if not Input.is_action_pressed("move_right") or not Input.is_action_pressed("bow_fire") or not Input.is_action_pressed("shield"):
        _fail("Movement, bow, and shield touch buttons did not register as independent held actions")
        return
    bow_touch.pressed = false
    controls._input(bow_touch)
    shield_touch.pressed = false
    controls._input(shield_touch)
    if not Input.is_action_pressed("move_right"):
        _fail("Releasing bow and shield also cleared the independent movement finger")
        return
    stick_touch.pressed = false
    controls._input(stick_touch)
    if Input.is_action_pressed("move_right") or Input.is_action_pressed("bow_fire") or Input.is_action_pressed("shield"):
        _fail("A touch release left movement, bow, or shield input stuck")
        return

    if main.current_level != 1 or main.level_world_width < 3000.0:
        _fail("Level 1 did not load at the expected expanded size")
        return
    if not _has_platform_at(main, Vector2(2010, 280)) or not _has_platform_at(main, Vector2(2330, 615)):
        _fail("Level 1 is missing its upward-left ridge or safe lower tunnel shelf")
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

    player.set_physics_process(false)
    var bow_target: Node = enemies[0]
    bow_target.health = 2
    player.global_position = bow_target.global_position + Vector2(-170, 0)
    player.velocity = Vector2.ZERO
    player.facing = 1
    player.bow_ready_at = 0
    player._shoot_bow()
    await create_timer(0.25).timeout
    if int(bow_target.health) != 1:
        _fail("A swept bow arrow did not damage an Ash Mite on contact")
        return
    player.activate_bow_pickup("rapid")
    if player.get_current_bow_cooldown_ms() != 260:
        _fail("Quickstring pickup did not shorten bow firing cooldown")
        return
    player.rapid_bow_timer.start(0.02)
    await create_timer(0.05).timeout
    if player.get_current_bow_cooldown_ms() != 600:
        _fail("Quickstring cooldown did not return to normal after the timer expired")
        return
    player.activate_bow_pickup("spread")
    if player.get_current_bow_arrow_count() != 3:
        _fail("Fanstring pickup did not enable a three-arrow spread volley")
        return
    player.bow_ready_at = 0
    var arrows_before: int = get_nodes_in_group("player_arrows").size()
    player._shoot_bow()
    if get_nodes_in_group("player_arrows").size() != arrows_before + 3:
        _fail("Fanstring did not fire three arrows while spending one volley")
        return
    for arrow in get_nodes_in_group("player_arrows"):
        arrow.queue_free()
    await physics_frame

    # One-heart gravity is the harshest profile: drop onto both tunnel shelves without splattering.
    player.health = 1
    player._update_health_scale()
    player.global_position = Vector2(2120, 418)
    player.velocity = Vector2.ZERO
    player.set_physics_process(true)
    Input.action_release("move_left")
    Input.action_release("move_right")
    var landed_on_catch_shelf := false
    for frame in range(60):
        await physics_frame
        if player.is_on_floor():
            landed_on_catch_shelf = true
            break
    if not landed_on_catch_shelf or player.health != 1 or player.global_position.y > 560.0:
        _fail("The first downward catch shelf was missed or caused excessive fall damage at one heart")
        return
    Input.action_press("move_right")
    var landed_on_lower_shelf := false
    for frame in range(60):
        await physics_frame
        if player.is_on_floor() and player.global_position.y > 550.0:
            landed_on_lower_shelf = true
            break
    Input.action_release("move_right")
    if not landed_on_lower_shelf or player.health != 1 or player.global_position.y > 620.0:
        _fail("The second down-tunnel ledge did not provide a safe one-heart landing")
        return
    player.set_physics_process(false)
    player.health = 3
    player._update_health_scale()

    # Collecting the first shard and entering its gate opens the longer sequel level.
    main.shards = 1
    main._on_exit_entered(player)
    await physics_frame
    await physics_frame
    if main.current_level != 2 or main.level_world_width < 4200.0 or get_nodes_in_group("enemies").size() < 4:
        _fail("Level 2 did not load with the longer route and enemy set")
        return
    if not _has_platform_at(main, Vector2(3290, 285)) or not _has_platform_at(main, Vector2(2480, 585)):
        _fail("Level 2 is missing its upward-left ridge or safe downward catch ledge")
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
    await physics_frame
    await physics_frame
    if main.current_level != 3 or main.level_world_width < 2500.0 or not is_instance_valid(main.boss):
        _fail("Level 2 did not open Region 3 and the Bellows Saint encounter")
        return
    if not _has_platform_at(main, Vector2(1430, 150)) or not _has_platform_at(main, Vector2(1340, 565)):
        _fail("The Hushvault is missing its high return path or Breathglass catch ledge")
        return

    var boss: Node = main.boss
    if int(boss.get("health")) != 8 or bool(boss.get("active")):
        _fail("Bellows Saint did not load dormant with eight core pips")
        return
    main._on_boss_threshold_entered(player)
    await physics_frame
    if not bool(boss.get("active")) or main.arena_gate_shape.disabled:
        _fail("Crossing the arena threshold did not start the boss and close the gate")
        return

    boss.set("attack_kind", "pulse")
    boss.call("_launch_attack")
    boss.call("_fire_next_pulse")
    if get_nodes_in_group("boss_projectiles").size() < 2:
        _fail("Bellows Saint did not spawn its two outward floor pulses")
        return
    for projectile in get_nodes_in_group("boss_projectiles"):
        projectile.queue_free()

    boss.set("attack_kind", "ember")
    boss.call("_launch_attack")
    if boss.get("ember_markers").size() != 3:
        _fail("Ember attack did not show three floor landing tells")
        return
    boss.call("_drop_embers")
    if get_nodes_in_group("boss_projectiles").size() < 3:
        _fail("Ember attack did not spawn the marked falling projectiles")
        return
    for projectile in get_nodes_in_group("boss_projectiles"):
        projectile.queue_free()
    boss.call("_clear_ember_markers")

    var health_before_siphon: int = player.health
    player.velocity.x = 0.0
    boss.set("attack_kind", "siphon")
    boss.call("_launch_attack")
    boss.call("_apply_siphon", 0.1)
    if player.health != health_before_siphon or absf(player.velocity.x) < 1.0:
        _fail("Siphon did not pull by force alone without dealing damage")
        return
    boss.call("_open_core")
    if main.vent_visuals[0].color.g < 0.7:
        _fail("Siphon recovery did not switch the vents to their updraft cue")
        return
    boss.call("_close_core")

    boss.call("take_damage", 1, 1)
    if int(boss.get("health")) != 8:
        _fail("Closed boss core accepted melee damage")
        return

    # A real arrow must pass through the boss's side only when it hits the exposed core.
    boss.set("facing", -1)
    player.set_physics_process(false)
    player.global_position = boss.global_position + Vector2(-150, -50)
    player.facing = 1
    player.bow_ready_at = 0
    player._shoot_bow()
    await create_timer(0.2).timeout
    if int(boss.get("health")) != 8:
        _fail("Bow arrow damaged the Bellows Saint while its core was closed")
        return
    boss.call("_open_core")
    player.bow_ready_at = 0
    player._shoot_bow()
    await create_timer(0.2).timeout
    if int(boss.get("health")) != 7:
        _fail("Bow arrow failed to damage the actually exposed Bellows Saint core")
        return
    boss.call("reset_encounter")
    boss.call("start_encounter")

    # Strike the actual exposed core point from the front-facing side.
    boss.set("facing", 1)
    var core_target: Vector2 = boss.global_position + Vector2(98, -50)
    player.global_position = core_target + Vector2(12, 0)
    player.facing = -1
    player.set_physics_process(false)
    boss.set("core_open", true)
    player._attack()
    await create_timer(0.22).timeout
    if int(boss.get("health")) != 7:
        _fail("Player melee did not hit the open core at its target point")
        return

    for hit in range(2):
        boss.set("core_open", true)
        boss.call("take_damage", 1, 1)
    if int(boss.get("health")) != 5 or int(boss.get("phase")) != 2:
        _fail("Boss did not enter Phase II at five core pips")
        return
    for hit in range(3):
        boss.set("core_open", true)
        boss.call("take_damage", 1, 1)
    if int(boss.get("health")) != 2 or int(boss.get("phase")) != 3:
        _fail("Boss did not enter Phase III at two core pips")
        return
    for hit in range(2):
        boss.set("core_open", true)
        boss.call("take_damage", 1, 1)
    if int(boss.get("health")) != 0 or not bool(boss.get("is_defeated")):
        _fail("Boss did not defeat cleanly after eight valid core hits")
        return
    await create_timer(1.05).timeout
    await physics_frame
    if not main.boss_defeated or not main.arena_gate_shape.disabled:
        _fail("Boss victory did not open the arena gate and advance the exit state")
        return
    if not is_instance_valid(main.stillheart_area) or not is_instance_valid(main.stillheart_visual):
        _fail("Boss victory did not drop the Stillheart reward")
        return
    player.global_position = main.boss.global_position
    main._on_stillheart_entered(player, main.stillheart_area, main.stillheart_visual)
    if not main.stillheart_collected:
        _fail("The Stillheart pickup did not unlock the final progression state")
        return

    # Boss projectiles hurt only when their Area2D hitboxes overlap the player.
    player.global_position = Vector2(1200, 418)
    player.health = 3
    player.invulnerable = false
    player._update_health_scale()
    var near_miss = load("res://scenes/boss_projectile.tscn").instantiate()
    near_miss.call("configure", "pulse", Vector2.ZERO, 1650.0)
    main.level_root.add_child(near_miss)
    near_miss.global_position = Vector2(1800, 418)
    await physics_frame
    await physics_frame
    if player.health != 3:
        _fail("Boss projectile damaged the player without collision")
        return
    near_miss.queue_free()

    var direct_hit = load("res://scenes/boss_projectile.tscn").instantiate()
    direct_hit.call("configure", "pulse", Vector2.ZERO, 1650.0)
    main.level_root.add_child(direct_hit)
    direct_hit.global_position = player.global_position
    player.facing = 1
    Input.action_press("shield")
    await physics_frame
    await physics_frame
    if player.health != 3 or player.shield_durability != 2:
        _fail("Held shield did not block a projectile hit and spend exactly one durability")
        return
    for block_index in range(2):
        var blocked_shot = load("res://scenes/boss_projectile.tscn").instantiate()
        blocked_shot.call("configure", "pulse", Vector2.ZERO, 1650.0)
        main.level_root.add_child(blocked_shot)
        blocked_shot.global_position = player.global_position
        await physics_frame
        await physics_frame
        if player.health != 3 or player.shield_durability != 1 - block_index:
            _fail("Shield durability did not decrement once for each separate projectile")
            return
    Input.action_release("shield")
    if player.shield_durability != 0:
        _fail("Shield was not depleted after exactly three blocked projectiles")
        return
    var fourth_hit = load("res://scenes/boss_projectile.tscn").instantiate()
    fourth_hit.call("configure", "pulse", Vector2.ZERO, 1650.0)
    main.level_root.add_child(fourth_hit)
    fourth_hit.global_position = player.global_position
    await physics_frame
    await physics_frame
    if player.health != 2:
        _fail("A projectile was not allowed through after shield durability ran out")
        return

    player.set_physics_process(true)
    main.shards = 1
    main._on_exit_entered(player)
    if not main.completed:
        _fail("Hushvault exit failed to complete the three-region prototype")
        return
    main._return_to_main_menu()
    if main.game_started or main.current_level != 1 or not main.main_menu_panel.visible or not paused:
        _fail("Return-to-title did not reset the run and reopen the menu")
        return
    if not main.music_player.playing or main.game_music_player.playing:
        _fail("Returning to the title did not restore menu music")
        return
    paused = false
    print("PASS: title/menu audio, cheats, sensor landscape, multitouch joystick+jump+melee+bow+shield, health tiers, collision-only damage, stomp, fall damage, one-heart safe tunnel drops, all-region climb/return routes, timed quickstring/fanstring, swept arrows vs Ash Mites and exposed boss core, three-charge frontal guard, boss phases/projectiles, Stillheart, and victory")
    quit(0)
