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
    await physics_frame
    await physics_frame
    if main.current_level != 3 or main.level_world_width < 2500.0 or not is_instance_valid(main.boss):
        _fail("Level 2 did not open Region 3 and the Bellows Saint encounter")
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
    await physics_frame
    await physics_frame
    if player.health != 2:
        _fail("Boss projectile failed to damage the player on actual hitbox overlap")
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
    print("PASS: title menu, looping menu/gameplay music, three cheats, sensor landscape, pause/resume, return-to-title, multitouch, health tiers, collision-only damage, stomp, vents, fall damage, all three regions, Bellows Saint phases/core, projectile hitboxes, and victory")
    quit(0)
