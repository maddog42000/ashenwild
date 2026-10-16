# ASHENWILD — The Forgotten Hollow + The Pale Spine

An original Godot 4 action-platformer prototype for Android. This update adds a second connected level and a simple risk/reward effect: the wanderer is broadest and most buoyant at full health, then visibly shrinks and falls faster as health is lost.

## Open on Android

1. Download and extract the repository ZIP or clone the public GitHub repository.
2. In Godot Android Editor, import/scan for the extracted project folder (the one containing `project.godot`). Exact labels vary by editor version.
3. Let Godot import the project, open the main scene, and run it in landscape.
4. If prompted for storage access, allow the editor to access the project folder.

The GitHub repository is public at https://github.com/maddog42000/ashenwild. The `main` branch is the stable baseline; `development` contains the latest unmerged update. The ZIP/source folder is not an Android APK.

## Controls

- Left/right: large lower-left buttons (keyboard A/D or arrows also work).
- Jump: lower-right **JUMP** button (Space/W/Up also work). Press again in the air for a double jump; releasing early shortens the jump.
- Attack: **HIT** button (J or X on a keyboard). Face an enemy and attack within range.
- Pause: upper-right **Ⅱ** button (P or Escape on a keyboard).
- Restart: upper-right **↻** button (R on a keyboard).

Touch controls accept simultaneous fingers, so you can move and jump/attack together.

## Playthrough

**Level 1 — The Forgotten Hollow:** traverse the starter platforms, defeat an Ash Mite, collect the teal shard, kindle the checkpoint, and use the shard to open the exit.

**Level 2 — The Pale Spine:** continue into a longer, warmer-toned cavern crossing with two gaps, raised stepping stones, two Ash Mites, its own checkpoint and shard, and a final gate. The level transition restores health and starts Level 2 at its own checkpoint. Collect its shard to finish the current two-level prototype.

Each death restores three health points at the latest checkpoint. Restart begins again from Level 1.

## New movement and damage behavior

At full health the wanderer has a wider body, reduced gravity, and a controlled maximum falling speed for more deliberate landings. The base gravity was lowered from 1,250 to 980 px/s², and the maximum fall speed is capped at 620 px/s. Each missing health point makes the sprite and collision capsule smaller, increases gravity by 170 px/s², and raises the fall-speed cap by 75 px/s. At one remaining health point this is 1,320 px/s² gravity and a 770 px/s fall cap. The double jump remains available. Checkpoints restore full size and full health.

These values are a first tuning pass, not measured on your phone. Please adjust them after playing if the character feels too floaty, the body-size effect feels too strong, or landings are still difficult.

## Included systems and limitations

The project includes movement and double jump, collision, camera follow, melee attacks, one basic enemy type, three-point health, hit invulnerability/knockback, hazards, checkpoints, collectibles, a shard-locked gate, a win state, restart/pause controls, generated original character/enemy sprites, and a painted cavern backdrop.

Still not included: save files, a boss, extra abilities beyond double jump, varied enemy classes, audio, menus, and Android APK export/signing. These remain future work. The two-level prototype reuses an enemy and background rather than claiming a complete production game.

## Version and test status

Created for Godot **4.7.2 stable** with the `gl_compatibility` renderer. The updated project was editor-imported and its entry scene was run briefly headlessly in this sandbox. The Level 2 transition and health-scaling behavior should still be confirmed on-device; this environment cannot measure Galaxy S20 performance or touchscreen comfort.

On phone, test that the first ledge and double jump work; attack enemies; compare the character’s size and falling feel at three, two, and one health; reach the first exit with its shard; complete Level 2; verify checkpoint respawn restores full health/size; and check pause/restart. Please share an exact Godot error or the step that behaves unexpectedly.

## Project files

- `project.godot` — landscape/mobile renderer setup
- `scenes/main.tscn` — main scene
- `scenes/player.tscn`, `scenes/enemy.tscn` — reusable actors
- `scripts/main.gd` — both level layouts, progression, HUD, and pause/restart
- `scripts/player.gd` — movement, health-scaled body/gravity, and attack
- `scripts/enemy.gd` — Ash Mite behavior
- `scripts/touch_controls.gd` — multitouch controls
- `scripts/scenery.gd` — shared backdrop treatment and fallback scenery
- `assets/` — generated character/enemy sheets and cavern backdrop
