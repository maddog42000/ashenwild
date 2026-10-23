# ASHENWILD — Phase 7: Bow, Guard, and Vertical Routes

A Godot 4 Android action-platformer prototype. This iteration builds on the three-region Bellows Saint campaign, title menu, cheats, landscape rotation, and looping soundtracks with a bow, timed shot modifiers, a limited projectile guard, and new upward-left and controlled-drop routes.

## Play flow and controls

Level 1, **The Forgotten Hollow**, crosses several screens of tiered platforms, dangerous gaps, and the low-roof Echo Crawl. The new **Wisp Ladder** climbs to a high shelf, turns back left, and drops to a landing shelf. The Echo Crawl now includes a lower passage with staged catch ledges and a jump-out route. Collect its teal shard and reach the gate to enter Level 2, **The Pale Spine**.

Level 2 adds a longer route with chained ascent/descent platforms, the **Pale Spine return ridge**, a recoverable drop passage, wider gaps, the Cinder Squeeze tunnel, Ash Mites, checkpoints, an amber shard, and the next gate. Level 2 leads to Region 3, **The Hushvault**, whose **Bell Stair** climbs up and back left before the arena. Breathglass catch ledges sit below the arena gaps; the vents can kick the player upward. Defeat the Bellows Saint, claim the dropped **Stillheart**, then reach the far exit.

On mobile, use the large lower-left drag joystick. Independent fingers can steer, jump, melee, fire the bow, and hold the shield at the same time, including in the air. **JUMP** and **ATTACK** are along the lower-right edge; **BOW** and **SHIELD** are staggered above them. Pause and restart remain at the top right. Keyboard fallback: A/D or arrows to move, Space/W/Up to jump, J/X for melee, hold K/C to fire arrows, hold L/V to guard, P/Escape to pause, and R to restart.

The bow can hit Ash Mites and the Bellows Saint's **exposed core**; arrows do not damage the covered core and are stopped by solid terrain. Holding the fire input repeats shots at the current cooldown. **Quickstring** pickups shorten that cooldown for 12 seconds. **Fanstring** pickups fire a three-arrow spread for 12 seconds. Each buff refreshes its own timer when collected again.

The hold-to-guard shield blocks **frontal boss projectiles** only while held. It absorbs three hits, then breaks until a checkpoint or respawn restores it. It does not block melee contact or replace moving out of an attack lane.

The game opens at a title screen. **BEGIN JOURNEY** starts the run; the pause menu offers Resume and Return to Title. Optional, off-by-default cheats are **Invulnerable**, **Unlimited air jumps**, and **High-speed mode**. The Background music toggle controls both the menu theme and gameplay track. The menu theme plays only on the title screen; the supplied `assets/audio/ashenwild_gameplay_theme.mp3` loops during gameplay and pauses with the game. Replace that file with another MP3 at the same path to change the gameplay music.

Android orientation is set to **sensor landscape**, allowing either left- or right-landscape rotation while preventing portrait play.

## Bellows Saint encounter

The Saint has eight core pips and three phases. Its shell is immune while closed. It announces a three-beat floor pulse, an ember drop with three visible landing marks, or a Breathglass siphon. Pulse waves and embers use collision-tested hitboxes; a held, correctly oriented shield can consume up to three projectile hits. The siphon pulls by force without dealing damage. During recovery, the core opens briefly and the vents switch to an updraft cue. A melee strike or bow arrow can damage the core only during this exposure.

The encounter accelerates at low boss health, but the final pulse receives a longer tell and a single-wave pattern. A boss defeat drops the Stillheart, and the exit stays locked until the player collects it. If the player dies in the arena, the boss resets to full health and the player respawns at the Hushvault checkpoint with full hearts and guard charges.

## Health and damage rules

Each missing heart makes a distinctly smaller character and faster movement profile. The body and collider are approximately **100% / 78% / 56%** at three, two, and one health. Lower health also increases acceleration, jump strength, gravity, and fall speed. The extra speed and reach are high-risk/high-reward; missed landings become harder to recover.

| Health | Run speed | Gravity | Max fall speed | First jump launch | Body scale |
|---|---:|---:|---:|---:|---:|
| 3 hearts | 260 px/s | 950 px/s² | 700 px/s | −525 px/s | 100% |
| 2 hearts | 350 px/s | 1,300 px/s² | 860 px/s | −570 px/s | 78% |
| 1 heart | 440 px/s | 1,650 px/s² | 1,020 px/s | −615 px/s | 56% |

Ash Mites and the Bellows Saint hurt the player only on actual body collision. Merely being nearby or jumping over an enemy is not enough. Landing on an Ash Mite is a safe stomp. Boss pulses and embers also require actual hitbox overlap. Hard landings at 650–829 px/s cost one heart; impacts at 830 px/s or higher cost two. The new staged drops are designed to stay below the fall-damage threshold at one heart when landed on as intended. Checkpoints restore full health and shield durability.

## Testing

Tested with Godot **4.7.2 stable**. The checked-in headless regression covers title-menu startup, both looping audio streams, cheat toggles, sensor-landscape configuration, pause/resume and return-to-title, simultaneous joystick/jump/melee/bow/shield multitouch, movement health tiers, collision-only enemy damage, stomps, Breathglass, fall damage, a physics-driven one-heart catch-shelf descent, climb/drop platform presence in all regions, rapid-fire expiry, three-arrow spread volleys, real Ash Mite and exposed-core arrow hits, covered-core immunity, three shield blocks followed by an unblocked hit, Bellows Saint attack patterns and phases, projectile near-misses/direct hits, Stillheart pickup, and final completion.

Run it from the project directory with:

```sh
godot --headless --path . --script res://tests/gameplay_smoke.gd
```

The automated checks are not a substitute for a real phone playtest. Touch sizing, route readability, boss-shield timing, and jump timing still need confirmation on your device.

## Android test build

A signed **debug APK for ARM64 Android devices** is provided separately for sideload testing. It is a development build, not a Play Store release, and has not been installed on a physical phone in this session. The binary is intentionally not committed to Git.

The project includes an `Android Debug (ARM64)` export preset. Open the folder containing `project.godot` in Godot 4.7.2 or later, install the matching Godot Android templates and Android SDK/JDK, then select that preset to export your own APK. See the [official Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) for setup details.

## Repository and project contents

The original Region 3 encounter design and implementation are already on public `main`. This Phase 7 iteration is developed on `bow-shield-vertical-routes` for review. `scenes/` contains the main, player, enemy, Bellows Saint, boss projectile, and bow-arrow scenes. `scripts/main.gd` builds the routes, menus, music playback, pickups, and progression. `scripts/player.gd` owns movement, health, cheats, fall damage, bow, shield, vents, and melee; `scripts/player_arrow.gd` implements swept collision-tested arrows; `scripts/touch_controls.gd` implements the drag joystick and concurrent touch buttons. `scripts/bellows_saint.gd` owns the three-phase encounter, and `scripts/boss_projectile.gd` implements the collision-tested attacks. `assets/audio/ashenwild_menu_theme.ogg` is the original generated title-screen loop; `assets/audio/ashenwild_gameplay_theme.mp3` is the user-provided in-game loop. `tests/gameplay_smoke.gd` checks gameplay regressions. `assets/sprites/` contains the original wanderer, Ash Mite, Bellows Saint, and boss-effect art; `scripts/scenery.gd` fits the cavern backdrop to each route.
