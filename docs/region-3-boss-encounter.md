# Region 3 Boss Encounter — The Bellows Saint

**Status:** implemented in the playable feature branch; awaiting review before merging to `main`
**Placement:** the end of Region 3, after the two existing routes and a short approach section  
**Design aim:** a memorable, readable boss that tests ASHENWILD's jump timing, air steering, low-heart speed, Breathglass vents, and safe enemy stomps without copying another game's character, art, or attacks.

## Encounter pitch

Region 3 is **The Hushvault**, a buried bell-foundry where the cave's old Breathglass vents were tuned to keep the Ashenwild calm. Its keeper, **the Bellows Saint**, has fused with the great resonance bell. It is an original, non-humanoid cave guardian: a towering, six-limbed beetle-moth shape with a charcoal shell, a cracked amber bell cavity, and long trailing glass filaments that visibly vibrate before every attack. It should read clearly as a cave creature, not as a rabbit-like hero or a recognizable character from another game.

The battle's signature is **rhythm made physical**. The Saint announces attacks in a three-beat pattern; each beat changes the wind and lights a floor mark. The player learns the rhythm, moves through a shifting arena, then strikes the exposed bell-core during a short recovery. Breathglass vents help with recovery and traversal, but the Saint can temporarily reverse their airflow.

## Arena and arrival

The boss room is a broad, enclosed foundry hall sized for the existing 960×540 game view, with a little camera movement along its width. The entry gate closes when the fight begins and reopens after victory. Place the player entry and a checkpoint just outside the arena, so a loss restarts the fight with full health rather than replaying either long platforming region.

Use a first-pass arena of about **1,440×540 world units** with a continuous floor centered at y=462 (top at y=437). Keep the entry at x≈90 and the exit at x≈1,380. This fits the current 960×540 viewport with limited horizontal camera travel and does not require a vertical-camera rewrite.

The arena has three readable routes:

- A broad lower floor for running and jumping over the Saint's low shockwaves.
- Two raised side ledges, roughly centered at x=260 and x=1,180 with tops around y=340, for escaping floor attacks and repositioning during ember rain.
- A short, low-ceiling **bell throat** under a center roof spanning roughly x=530–870 at y=357. Leave about 72 units of floor clearance and put one 18-unit-high stone near x=700; a brief jump clears it without needing a crouch mechanic.

Two Breathglass vents sit off-center, one on each side. Their plumes have distinct shapes as well as colors. The boss's inhale can pull air toward the middle; its recovery reverses the vents into brief upward lifts. Keep the center floor open enough that faster one-heart movement remains useful rather than turning the fight into an unavoidable collision.

Place vent centers near x=430 and x=1,010, at about y=520. Keep the boss's initial position near x=720. The exposed core target should be offset toward the facing side of the body and receive its own attack-range check, so the existing short melee reach can hit it from outside the damaging body collider.

## Core loop

1. Read a visible tell and its beat count.
2. Use the joystick to choose a lane, then jump, double-jump, or run through the bell throat to avoid the attack.
3. Stay close enough to reach the Saint with the current melee attack during its recovery.
4. Strike the glowing core while it is open. A hit interrupts the recovery and advances the stagger count.
5. Repeat with one additional pattern at each phase; never stack two lethal patterns without a safe route.

The normal melee button is enough to finish the fight. A future optional **perfect resonance counter** can be added later, but the first boss version should not require a new control or a frame-perfect parry.

## Three phases

The Saint has **8 core pips**. Each successful hit during an open-core window removes one pip. The arena HUD shows the pips, and the shell visibly changes at each phase break.

### Phase I — The Counting Bell (8–6 pips)

The Saint stays grounded and teaches the beat language. Its bell cavity glows, it winds one filament backward, then strikes three floor pulses at an even rhythm. Each pulse has a thin, bright ground-hugging wave and a clear 0.85-second wind-up. Jump or double-jump over the wave; a direct hit costs one heart. After pulse three, the bell opens for 1.25 seconds.

A single ember-drop attack is the alternate pattern: three floor symbols appear, then one ember falls on each mark. The symbols use a shape and a brightness change, not color alone. Move laterally to a safe lane before the fall.

### Phase II — The Siphon (5–3 pips)

A crack runs through the Saint's shell. It alternates the three-pulse sweep with **Breathglass Inhale**: filaments spread, loose ash streams toward the boss, and horizontal pull begins after a 0.9-second tell. Counter-steer with the joystick, jump to a side ledge, or enter the bell throat to break line of pull. The pull is force, not damage; only a visible shockwave or projectile hitbox can hurt the player.

At the end of an inhale, the vents briefly blow upward and the core opens for 1.0 second. This is the phase's safest damage window and the clearest use of the updraft mechanic. The inhale adds a capped horizontal force to player velocity; it never applies damage or overrides the player's input entirely.

### Phase III — The Broken Chorus (2–1 pips)

The core is exposed and the rhythm accelerates slightly, but the visual tell remains unchanged. The Saint performs one double shockwave, then one ember-drop pattern; a brief rest follows each sequence. The core window is 0.9 seconds. The Saint can shuffle to the opposite side between patterns, but cannot body-check the player while its attack tell is active.

At one remaining pip, the bell gives a longer, unmistakable final wind-up, then releases a single broad pulse. Evade it, wait for the core's last open window, and land the final strike. Do not add an instant kill or an untelegraphed attack at low health.

## Attacks and damage rules

| Attack | Telegraph | Counterplay | Damage |
|---|---|---|---:|
| Three-beat floor pulse | Three evenly spaced flashes; filament draws back | Jump each low wave; a late double jump can recover a missed beat | 1 heart per hit, with existing invulnerability frames preventing rapid multi-hit loss |
| Ember drop | Floor marks brighten and rise before impact | Move to an unmarked lane or the side ledge | 1 heart on actual ember hitbox overlap |
| Breathglass inhale | Filaments fan outward; ash and hanging ribbons visibly stream inward | Steer against the pull, use a ledge, or shelter in the throat | Pull alone does not damage |
| Shell/body collision | Physical movement into the boss | Keep separation during its walking reposition; use the exposed-core window to attack | 1 heart only on actual body contact |

All damaging attacks must use collision-tested hitboxes. Being within a radius, standing near the boss, or jumping across its silhouette must never cause damage by itself. Mark each hitbox with its attack so it can be tested independently. A stomp on the Saint's upper shell should bounce the player but **not** count as damage to the core; the core is reachable only when open.

Implement the vulnerable core as a dedicated target/hit area. Because the current player attack query is short-range, the boss should expose an `is_player_in_attack_range(player)` method that checks distance to the visible core point and facing, rather than making the entire boss body hittable from far away. During the open window, disable shell contact damage so a successful approach is not punished by an invisible overlap.

## Balance targets

These are starting values for playtesting, not final promises:

- Boss core: 8 pips; one pip per valid melee hit while open.
- Typical full-health fight: about 60–100 seconds for a player who recognizes the rhythm.
- Normal attack warning: at least 0.8 seconds; the phase-three double wave can shorten the gap between waves, not the initial tell.
- Core opening: 1.25 / 1.0 / 0.9 seconds in phases I / II / III.
- Direct boss or projectile hit: one heart. The two-heart fall-damage rule remains only for genuinely hard landings; boss hazards should not chain the player into a second hit before invulnerability ends.
- At one heart, the existing faster movement and stronger launch remain intact. This is a high-risk, high-reward way to reach a core window sooner, but the stronger gravity and fall damage still punish a missed landing.
- Before release, test each phase at 3, 2, and 1 hearts. Tune arena width or attack spacing before weakening the established heart-by-heart identity.

## Victory and progression reward

On defeat, the Saint's bell goes quiet, the Hushvault's vents settle, and the exit opens to a short epilogue route. The boss drops a **Stillheart**: a small, warm shard that becomes the story key for Region 4. The first boss release should reward progression rather than immediately adding a complicated new attack button.

A later upgrade can let the Stillheart **store one Breathglass burst** for use in midair once per room. This builds on an existing mechanic and does not require copying a healing, dash, or parry system from another title.

## Implementation plan

1. Add a Region 3 entry after Level 2's current gate, plus a checkpoint outside the boss chamber.
2. Create a dedicated `BossBellows` scene and script with `core_health`, `phase`, `core_open`, and `defeated` state. Keep each attack as a small, named state with a tell, active hitbox, and recovery timer.
3. Put the boss in the enemy group so the existing attack can find it, but make `take_damage` ignore hits while the core is closed. Emit a boss-health signal for the HUD.
4. Implement floor pulses and embers as `Area2D`/projectile hitboxes that only call player damage on actual body overlap. Implement the inhale as non-damaging movement force.
5. Add a separate boss health display, phase transition cue, victory gate, and retry/reset behavior. Reset boss health on arena death for the first pass.
6. Add regression tests for closed/open core damage, each phase threshold, actual projectile contact versus near miss, pulse avoidance, inhale without damage, death/retry, and final completion.
7. Play-test on the Android editor with the larger virtual joystick. Confirm steering while jumping/attacking remains possible and every tell is readable on a phone screen.

## Implementation status

The first playable version is on the `region3-boss-implementation` branch. `scenes/bellows_saint.tscn` and `scripts/bellows_saint.gd` implement the eight-pip, three-phase encounter, core vulnerability, pulse and ember attacks, siphon pull, arena reset, and Stillheart drop. `scripts/boss_projectile.gd` handles collision-tested attacks. `scripts/main.gd` builds the Hushvault approach and arena, boss health HUD, entry gate, vents, reward pickup, and exit. The original Bellows Saint and effects atlases are in `assets/sprites/`.

`tests/gameplay_smoke.gd` verifies the level transition, each phase threshold, core immunity and damage, spawned attack patterns, non-damaging siphon, actual projectile hits versus near-misses, Stillheart pickup, and completion. The implementation has not yet been play-tested on a physical Android device; the timing and readability values above still need phone testing before they are considered final.
