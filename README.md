# ASHENWILD — Phase 3: Longer Hollow Routes

A Godot 4 Android action-platformer prototype. This iteration makes both levels longer and more route-driven, adds a marked high-risk/high-reward health profile, fixes enemy contact damage, and adds fall damage and Breathglass rescue vents.

## Play flow and controls

Level 1, **The Forgotten Hollow**, now spans several screens and moves through tiered stepping stones, two dangerous gaps, and the low-roof Echo Crawl. Collect the teal shard, touch the checkpoint, and reach the gate. The gate leads to Level 2, **The Pale Spine**, a longer route with four wider gaps, chained ascent/descent platforms, a second narrow-roof tunnel, four Ash Mites, a checkpoint, an amber shard, and the final gate.

Touch controls remain: left/right on the lower left, jump and hit on the lower right, pause and restart at the top right. Keyboard fallback: A/D or arrows to move, Space/W/Up to jump, J/X to attack, P/Escape to pause, and R to restart. Holding separate fingers still supports movement plus jump or attack.

**New environmental mechanic — Breathglass vents:** a glowing updraft in the large pits can catch a falling wanderer and launch them back toward the platforms with a strong upward burst. They are a rescue option, not a substitute for landing safely; the vent has a short cooldown.

**Tunnel technique:** the Echo Crawl and Cinder Squeeze place a low stone inside a low-ceiling passage. A short, carefully timed jump can clear the stone without hitting the roof. The gaps and tunnel geometry are deliberately more demanding than the first prototype; adjust the layout if the on-phone feel proves too punishing.

## High-risk, high-reward health tuning

Each missing heart makes a clearly distinct character-size and movement change. The visual and collision size factors are approximately **100% / 78% / 56%** at three, two, and one health. The wanderer also runs faster and gets a stronger launch at lower health, but gravity and falling speed increase sharply. Current tuning:

| Health | Run speed | Gravity | Max fall speed | First jump launch | Body scale |
|---|---:|---:|---:|---:|---:|
| 3 hearts | 260 px/s | 950 px/s² | 700 px/s | −525 px/s | 100% |
| 2 hearts | 350 px/s | 1,300 px/s² | 860 px/s | −570 px/s | 78% |
| 1 heart | 440 px/s | 1,650 px/s² | 1,020 px/s | −615 px/s | 56% |

Double-jump launch strength also increases with each missing heart. That extra speed and launch can carry the player farther, but the heavier gravity means a smaller landing window. The values are exposed as constants near the top of `scripts/player.gd` for further tuning.

### Damage rules

Ash Mites now damage the player **only on actual body collision**. Merely being close or jumping over one is not enough. Landing on an enemy from above is a safe stomp that hurts the Ash Mite and bounces the player. Side/body contact still damages the player. There are no enemy projectiles in this build; any future projectile should damage only when its hitbox actually touches the player.

Hard landings also hurt: a downward impact of 650–829 px/s costs one heart; at 830 px/s or higher it costs two. Ordinary controlled jumps are below the threshold. Checkpoints and level transitions restore full health, size, and the safer full-health movement profile.

## Testing status

Tested against Godot **4.7.2 stable**: editor import, entry-scene launch, and automated smoke checks for both level transitions and completion, all three health profiles, no proximity damage, side-contact damage, safe stomping, fall damage, and Breathglass launch. Run the regression on desktop Godot with `godot --headless --path . --script res://tests/gameplay_smoke.gd`. The game has **not** been run on your phone in this session. The spacing, tunnel clearance, fall-damage feel, and touch-button comfort need a playtest in the Android Editor.

## Import on Android

Extract the project archive into a new folder, then import/scan that folder (the one containing `project.godot`) in Godot Android Editor. Let the editor finish importing. The project is source, not an APK. The latest code is on the public GitHub `development` branch; `main` remains the stable baseline pending review.

## Project contents

`scenes/` contains the main, player, and enemy scenes. `scripts/main.gd` builds both routes and progression; `scripts/player.gd` owns movement, health, fall damage, Breathglass bursts, and attacks; `scripts/enemy.gd` owns patrol, pursuit, contact damage, stomps, and defeat. `tests/gameplay_smoke.gd` checks the key gameplay regressions headlessly. `assets/` contains the original wanderer and Ash Mite sprite sheets plus the cavern background. `scripts/scenery.gd` fits the backdrop to each longer route and provides a no-art fallback.
