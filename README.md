# ASHENWILD — Phase 5: The Hushvault

A Godot 4 Android action-platformer prototype. This update adds a playable third region and the original Bellows Saint boss encounter after the two longer platforming routes. It keeps the existing health-scaled movement, double jump, collision-only enemy damage, large multitouch joystick, and Breathglass vents.

## Play flow and controls

Level 1, **The Forgotten Hollow**, crosses several screens of tiered platforms, dangerous gaps, and the low-roof Echo Crawl. Collect its teal shard and reach the gate to enter Level 2, **The Pale Spine**, a longer route with chained ascent/descent platforms, wider gaps, the Cinder Squeeze tunnel, Ash Mites, a checkpoint, an amber shard, and the next gate.

Level 2 now leads to Region 3, **The Hushvault**. A short approach ends at a checkpoint outside the arena. The bell-foundry has a low bell-throat hop, two vented floor gaps, raised side ledges, and the Bellows Saint chamber. Defeat the keeper, claim the dropped **Stillheart**, then reach the far exit.

The lower-left control is a large drag joystick. Hold it in either direction while using separate fingers for **JUMP** or **ATTACK**, including in the air. Pause and restart remain at the top right. Keyboard fallback: A/D or arrows to move, Space/W/Up to jump, J/X to attack, P/Escape to pause, and R to restart.

## Bellows Saint encounter

The Saint has eight core pips and three phases. Its shell is immune while closed. It announces a three-beat floor pulse, an ember drop with three visible landing marks, or a Breathglass siphon. Pulse waves and embers use real collision-tested hitboxes; the siphon pulls by force without causing damage. During recovery, the core opens briefly and the vents switch to an updraft cue. One successful melee hit closes the core again, so each exposure is a distinct risk/reward opportunity.

The encounter accelerates at low boss health, but the final pulse receives a longer tell and a single-wave pattern. A boss defeat drops the Stillheart, and the exit stays locked until the player collects it. If the player dies in the arena, the boss resets to full health and the player respawns at the Hushvault checkpoint with full hearts.

## Health and damage rules

Each missing heart makes a distinctly smaller character and faster movement profile. The body and collider are approximately **100% / 78% / 56%** at three, two, and one health. Lower health also increases acceleration, jump strength, gravity, and fall speed. The extra speed and reach are high-risk/high-reward; missed landings become harder to recover.

| Health | Run speed | Gravity | Max fall speed | First jump launch | Body scale |
|---|---:|---:|---:|---:|---:|
| 3 hearts | 260 px/s | 950 px/s² | 700 px/s | −525 px/s | 100% |
| 2 hearts | 350 px/s | 1,300 px/s² | 860 px/s | −570 px/s | 78% |
| 1 heart | 440 px/s | 1,650 px/s² | 1,020 px/s | −615 px/s | 56% |

Ash Mites and the Bellows Saint hurt the player only on actual body collision. Merely being nearby or jumping over an enemy is not enough. Landing on an Ash Mite is a safe stomp. Boss pulses and embers also require actual hitbox overlap. Hard landings at 650–829 px/s cost one heart; impacts at 830 px/s or higher cost two. Checkpoints restore full health.

## Testing

Tested with Godot **4.7.2 stable**. The checked-in headless regression covers simultaneous joystick/jump/attack multitouch, movement health tiers, collision-only enemy damage, stomps, Breathglass, fall damage, longer routes, Level 3 progression, boss attack patterns, core vulnerability and phase thresholds, projectile near-misses versus direct hits, Stillheart pickup, and final completion.

Run it from the project directory with:

```sh
godot --headless --path . --script res://tests/gameplay_smoke.gd
```

The automated checks are not a substitute for a real phone playtest. Touch sizing, arena readability, and jump timing still need confirmation on your device.

## Android test build

A signed **debug APK for ARM64 Android devices** is available with this iteration. It is a sideloadable test build, not a Play Store release, and it has not been installed on a physical phone in this session. The APK is provided as a separate download and is intentionally not committed to Git.

The project includes an `Android Debug (ARM64)` export preset. Open the folder containing `project.godot` in Godot 4.7.2 or later, install the matching Godot Android templates and Android SDK/JDK, then select that preset to export your own APK. See the [official Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) for setup details.

## Repository and project contents

The Region 3 design PR has been merged into public `main`. The playable boss implementation is on the separate `region3-boss-implementation` branch, with a draft review PR; it is not yet merged into `main`. The downloadable source package and debug APK accompany this iteration.

`scenes/` contains the main, player, enemy, Bellows Saint, and boss projectile scenes. `scripts/main.gd` builds all three routes and progression. `scripts/bellows_saint.gd` owns the three-phase encounter, and `scripts/boss_projectile.gd` implements the collision-tested attacks. `scripts/player.gd` owns movement, health, fall damage, vents, and melee; `scripts/touch_controls.gd` implements the drag joystick and concurrent touch buttons. `tests/gameplay_smoke.gd` checks key gameplay regressions. `assets/sprites/` contains the original wanderer, Ash Mite, Bellows Saint, and boss-effect art; `scripts/scenery.gd` fits the cavern backdrop to each route.
