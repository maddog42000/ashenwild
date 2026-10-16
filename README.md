# ASHENWILD — The Forgotten Hollow (Playable Vertical Slice)

An original Godot 4 action-platformer prototype for Android. This first-level slice includes movement, a double jump, melee combat, one patrolling creature, three health points, a checkpoint, a collectible shard, a locked exit, touch pause/restart controls, and original visual assets. Everything needed to open the source project is in this folder; no plugins or external asset downloads are needed.

## Open on Android

1. Download and extract `ashenwild-starter.zip` in your phone's file manager.
2. In Godot Android Editor, import/scan for the extracted project folder (the one containing `project.godot`). Exact labels vary by editor version.
3. Let Godot import the project, open the main scene, and run it in landscape.
4. If prompted for storage access, allow the editor to access the extracted folder.

Keep the extracted folder in a writable location Godot can access. Do not try to run the ZIP without extracting it. The ZIP is a source project, not an Android APK.

## Controls

- Left and right: large lower-left buttons (keyboard A/D or arrows also work).
- Jump: lower-right **JUMP** button (Space/W/Up also work). Press again while airborne to double jump; releasing early shortens a jump.
- Attack: **HIT** button (J or X on a keyboard). Face the enemy and attack within range.
- Pause: upper-right **Ⅱ** button (P or Escape on a keyboard).
- Restart: upper-right **↻** button (R on a keyboard).

The controls accept simultaneous fingers, so you can move and jump/attack at the same time.

## First-level goals

1. Practice movement in the starting area and use the raised ledges; the opening ledge is reachable with one tuned jump, and the second jump gives extra recovery/range.
2. Defeat the Ash Mite with repeated attacks. It has two health points and approaches/patrols.
3. Find the teal shard above the second raised ledge.
4. Reach the checkpoint flag to set the respawn point.
5. Take the shard to the stone gate at the far right to finish the level.
6. Falling into the pit or losing all health respawns the player at the current checkpoint with full health.

The level is a compact prototype rather than a polished 2–5 minute final stage. Art, timing, enemy balance, and touch comfort are ready for your phone-side testing.

## What is implemented

- Responsive horizontal movement, acceleration, air control, variable-height first jump, and double jump.
- Solid platforms, a gap/hazard, camera follow, and automatic checkpoint-based respawn.
- Player health with three visible points, brief invulnerability after a hit, knockback, and death recovery.
- Short melee attack with cooldown; one original Ash Mite with patrol, approach, damage, and defeat behavior.
- Checkpoint, collectible, locked level exit, simple win state, pause, and restart.
- Original masked-wanderer and Ash-Mite sprite sheets plus a painted cavern background; geometric props and UI are drawn in Godot.
- Keyboard fallback and multitouch Android controls.

Not included in this vertical slice: save files, additional levels/worlds, multiple enemy classes, bosses, a full animation/audio suite, unlockable abilities beyond double jump, or production APK export/signing. Those are later roadmap work, not claimed as complete.

## Version, performance, and testing

Created and validated with Godot **4.7.2 stable**. The renderer is set to `gl_compatibility` for broad mobile support. The project was headless-imported and the main scene was run briefly in the sandbox without script/scene launch errors. The touchscreen build still needs your on-phone test; I cannot measure Galaxy S20 frame rate or certify touch comfort from this sandbox.

On phone, check: opening jump reaches the first ledge; double jump works once per airborne trip; attack defeats the creature; health decreases on contact; pit/death respawns at the latest checkpoint; shard is collected; gate remains sealed until shard is found; pause stops the game; restart returns to the start. Please send any exact Godot error or describe which check fails and I can fix the specific script.

## Project files

- `project.godot` — project, landscape, renderer settings
- `scenes/main.tscn` — entry scene
- `scenes/player.tscn`, `scenes/enemy.tscn` — reusable actor scenes
- `scripts/main.gd` — level layout, HUD, progression, pause/restart
- `scripts/player.gd`, `scripts/enemy.gd` — movement, combat, health, enemy behavior
- `scripts/touch_controls.gd` — on-screen multitouch controls
- `scripts/scenery.gd` — background and fallback decoration
- `assets/sprites/` and `assets/backgrounds/` — generated original art
