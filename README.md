# ASHENWILD — Phase 9: Directional Parkour

A Godot 4 Android action-platformer prototype. This iteration adds three multi-directional parkour switchbacks: climb to a high crest, reverse direction across narrow ledges, then choose a controlled return drop. The new sections complement the bow-and-shield elite trials, Resonance Gallery, and Bell Stair.

## Play flow and controls

Level 1, **The Forgotten Hollow**, crosses several screens of tiered platforms, dangerous gaps, the low-roof Echo Crawl, and the **Wisp Ladder**. The Kettleback Bulwark guards the ladder approach: evade or block its slow rivet, then shoot its exposed jaw core. The optional **Ashglass Switchback** climbs above the eastern ridge, bends back left across its crest, and drops toward the exit shelf. The Echo Crawl includes a lower passage with staged catch ledges. Collect the teal shard and reach the gate to enter Level 2, **The Pale Spine**.

Level 2 has the **Resonance Gallery**, a multi-route gap crossing: climb up and back left, descend onto a safe mid-shelf, or take the lower catch-ledge path and jump back to the far-side floor. Near the exit, the new **Pale Spine Switchback** adds a three-step ascent, leftward crest traverse, and return drop. The Gloam Cantor telegraphs a falling chime bolt into the route. Correctly guard it to bring the Cantor down into arrow range; otherwise, dodge the marked lane. The level also retains its return ridge, Cinder Squeeze tunnel, Ash Mites, checkpoints, amber shard, and exit to Region 3, **The Hushvault**. Hushvault's Bell-Throat Steps and Bell Stair offer another climb-and-reverse route before the Breathglass catch ledges and Bellows Saint. Defeat it, claim the Stillheart, and reach the far exit.

On mobile, use the large lower-left drag joystick. Independent fingers can steer, jump, melee, fire the bow, and hold the shield at the same time, including in the air. **JUMP** and **ATTACK** are along the lower-right edge; **BOW** and **SHIELD** are staggered above them. Pause and restart remain at the top right. Keyboard fallback: A/D or arrows to move, Space/W/Up to jump, J/X for melee, hold K/C to fire arrows, hold L/V to guard, P/Escape to pause, and R to restart.

The bow can hit Ash Mites, elite weakpoints, and the Bellows Saint's **exposed core**; arrows do not damage closed elite armor or the covered boss core and are stopped by solid terrain. Holding the fire input repeats shots at the current cooldown. **Quickstring** pickups shorten that cooldown for 12 seconds. **Fanstring** pickups fire a three-arrow spread for 12 seconds. Each buff refreshes its own timer when collected again.

The hold-to-guard shield blocks **frontal enemy projectiles** only while held and while facing the projectile source. It absorbs three hits, then breaks until a checkpoint or respawn restores it. Guarding one of the new elites' signature shots consumes one charge and opens that elite's weakpoint briefly. Dodging avoids the shot but does not create the opening. The shield does not block melee contact or replace moving out of an attack lane.

The game opens at a title screen. **BEGIN JOURNEY** starts the run; the pause menu offers Resume and Return to Title. Optional, off-by-default cheats are **Invulnerable**, **Unlimited air jumps**, and **High-speed mode**. The Background music toggle controls both the menu theme and gameplay track. The menu theme plays only on the title screen; the supplied `assets/audio/ashenwild_gameplay_theme.mp3` loops during gameplay and pauses with the game. Replace that file with another MP3 at the same path to change the gameplay music.

Android orientation is set to **sensor landscape**, allowing either left- or right-landscape rotation while preventing portrait play.

## Elite enemies

**Kettleback Bulwark:** a ground sentinel with three health pips. It winds up for 0.9 seconds and fires a slow, straight rivet. A frontal shield block opens its jaw core for 2.35 seconds; a bow arrow must strike the core. Its shell cannot be damaged by melee or stomping.

**Gloam Cantor:** a hovering ranged elite with four health pips. It marks the player's lane for one second, then fires a falling chime bolt. A correctly faced shield guard suspends it low and exposes its hanging chime for 2.6 seconds. The marked lane can also be dodged; its weakpoint still requires the bow.

Both attacks are collision-tested, use an explicit projectile source for guard feedback, and clear pending shots/tells when the player dies. A successful block is the only action that opens their arrow weakpoints. The rest of the original [elite design set is documented in PR #5](https://github.com/maddog42000/ashenwild/pull/5); the remaining Glasswing Reaver is not implemented in this build.

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

Ash Mites, elites, and the Bellows Saint hurt the player only on actual body collision. Merely being nearby or jumping over an enemy is not enough. Landing on an Ash Mite is a safe stomp; elites cannot be stomped through their armor. Boss and elite projectiles must overlap the player, and only a held, correctly oriented shield blocks them. Hard landings at 650–829 px/s cost one heart; impacts at 830 px/s or higher cost two. Staged drops are designed to stay below the fall-damage threshold at one heart when landed on as intended. Checkpoints restore full health and shield durability.

## Testing

Tested with Godot **4.7.2 stable**. The checked-in headless regression covers title-menu startup, both looping audio streams, cheat toggles, sensor-landscape configuration, pause/resume and return-to-title, simultaneous joystick/jump/melee/bow/shield multitouch, movement health tiers, collision-only enemy damage, Ash Mite stomps, Breathglass, fall damage, one-heart catch-shelf descents, presence of the three new directional switchbacks and the existing all-region routes, timed bow buffs, real swept arrows, elite closed-weakpoint immunity, frontal versus rear guard behavior, successful Kettleback and Cantor counter windows, elite defeat, three-charge boss shielding, Bellows Saint attack patterns/phases, Stillheart pickup, and final completion.

Run it from the project directory with:

```sh
godot --headless --path . --script res://tests/gameplay_smoke.gd
```

The automated checks are not a substitute for a real phone playtest. Touch sizing, route readability, elite tells/guard timing, and jump timing still need confirmation on your device.

## Android test build

A signed **Phase 9 debug APK for ARM64 Android devices** is provided separately for sideload testing. It is a development build, not a Play Store release, and has not been installed on a physical phone in this session. The binary is intentionally not committed to Git.

The project includes an `Android Debug (ARM64)` export preset. Open the folder containing `project.godot` in Godot 4.7.2 or later, install the matching Godot Android templates and Android SDK/JDK, then select that preset to export your own APK. See the [official Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) for setup details.

## Repository and project contents

The original Region 3 encounter design and implementation are on public `main`. Phases 7–9 are developed on `bow-shield-vertical-routes` and reviewed in PR #4. `scenes/` contains the main, player, Ash Mite, Bellows Saint, elite, boss-projectile, elite-projectile, and bow-arrow scenes. `scripts/main.gd` builds the routes, encounters, menus, music, pickups, and progression. `scripts/player.gd` owns movement, health, cheats, fall damage, bow, shield, vents, and melee; `scripts/player_arrow.gd` implements swept arrows. `scripts/kettleback_bulwark.gd` and `scripts/gloam_cantor.gd` implement the two elites and their exposed-arrow checks. `scripts/elite_projectile.gd` uses hitbox collision and source-aware guard callbacks. `scripts/touch_controls.gd` implements the drag joystick and concurrent touch buttons. `scripts/bellows_saint.gd` owns the three-phase boss encounter. `assets/audio/ashenwild_menu_theme.ogg` is the original generated title-screen loop; `assets/audio/ashenwild_gameplay_theme.mp3` is the user-provided in-game loop. `tests/gameplay_smoke.gd` checks gameplay regressions. `assets/sprites/` contains the original wanderer, Ash Mite, Bellows Saint, and boss-effect art; the new elites have original procedural polygon visuals in Godot. `scripts/scenery.gd` fits the cavern backdrop to each route.
