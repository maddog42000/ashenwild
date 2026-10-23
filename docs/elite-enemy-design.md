# Elite Enemy Set — Resonance Gallery

**Status:** Design only; none of these enemies is implemented yet.

**Target build:** ASHENWILD Phase 7 bow/guard kit (currently under review in [PR #4](https://github.com/maddog42000/ashenwild/pull/4)). These are original enemies for a future Hushvault extension, not copies of another game's characters or moves.

## Core design goal

Each elite teaches one readable loop: **read the tell → face the incoming shot → hold SHIELD to absorb one projectile → use the resulting exposure to land BOW hits**. The shield blocks rather than reflects; the player must still aim by facing the enemy and place arrows through the exposed weakpoint. A successful guard costs one of the shield's three durability charges. Missing the guard must hurt or reposition the player, not produce an unavoidable hit or a softlock.

The roster varies how that loop is performed: a grounded timing check, a vertical-lane puzzle, and a mobile aerial interception. Every enemy has at least one non-guard dodge option, but only a correctly guarded signature projectile creates its bow vulnerability window.

## Shared implementation contract

Each elite should be a `CharacterBody2D` in the existing `enemies` group, retain physical body contact as its only contact-damage source, and expose `take_damage(amount, hit_direction)`. To restrict arrows to a weakpoint, implement `is_arrow_target_hit(hit_position: Vector2) -> bool` like the Bellows Saint; return false while the armor is closed or when the ray misses the weakpoint. Keep a single health authority on the elite root.

The current guard callback knows only a projectile's `source_x`, not which enemy fired it. Before implementation, give enemy projectiles a source reference or emit a `projectile_blocked(source_enemy)` signal. The projectile should call the elite's `on_projectile_guarded()` only after `try_block_projectile()` returns true. This keeps “blocked” distinct from “dodged,” avoids proximity-based exposure, and lets the shield preserve its current frontal, three-charge behavior. Clear exposure and projectiles when an elite dies or the level resets.

## 1. Kettleback Bulwark — the timing test

**Role:** Heavy ground sentinel; teaches the basic guard-then-shoot rhythm.

**Silhouette and read:** A squat ash-plated crawler with a riveted back shell, two low lantern eyes, and one bright hanging core beneath the jaw. Its stance points toward the player. The signature projectile is a single, slow orange rivet with a bright center and a short, distinct wind-up sound.

**Attack loop:** The Bulwark plants its front feet, flashes its eye slits, then launches one straight rivet at chest height. The wind-up is about **0.9 seconds**. The player can jump over the shot, but that only avoids damage and does not expose the core. If the player faces the Bulwark and guards the rivet, the shot is absorbed, the shell rings, and the jaw core opens for **2.2 seconds**. If the player is facing away, the projectile hits normally. After a failed shot or a completed exposure, the Bulwark pauses briefly and repeats.

**Bow opportunity:** The core is visible just below the head, within ordinary horizontal arrow height. It takes **three accepted arrows** to defeat. A closed-shell arrow still consumes itself but causes no damage. Melee contact and jumping over it do not bypass the guard requirement.

**Fairness and placement:** Use wide, flat ground with no moving hazard underneath. Keep it on camera before the wind-up begins. Introduce one Bulwark alone near a checkpoint; only later pair it with ordinary Ash Mites. Its slow approach makes it possible to recover from a mistimed jump.

## 2. Gloam Cantor — the vertical-lane puzzle

**Role:** Ranged elite that asks the player to manage height and firing lanes.

**Silhouette and read:** A tall, hovering bell-frame wrapped in dark cloth strips, with three suspended glass chimes. The lowest chime glows orange before its attack; the upper body remains dim until a guard breaks the rhythm.

**Attack loop:** The Cantor rises above the player's current lane, then marks a narrow vertical impact lane on the floor with a clearly visible amber ring for **1.0 second**. It drops one heavy chime-bolt into that lane. The player may move out of the ring or use a lower/upper ledge; only guarding the bolt from its incoming side makes the Cantor stagger. The bolt's spawn point must remain on screen and its approach must be visible.

**Bow opportunity:** A successful guard knocks the lowest glass chime loose and suspends the Cantor for **2.6 seconds**. The weakpoint hangs low enough to hit from the floor and from the nearby catch ledge. It takes **four arrows** to defeat. Fanstring's spread may make the timing easier, but must not be required.

**Fairness and placement:** Stage this elite near one safe drop shelf and one climb-back platform, not over a lethal pit. The marked lane should be no wider than roughly one character-width plus a modest dodge margin. The Cantor never aims a new lane at a player who is still in hit-stun, and it does not fire off-screen.

## 3. Glasswing Reaver — the moving interception

**Role:** Agile aerial elite; combines lateral movement, guard orientation, and a short bow window.

**Silhouette and read:** A manta-like silhouette made from ash-dark membrane and three pale glass vanes. It hovers with the vanes folded, then turns its whole body toward the player before its signature attack. A teal-white vein traces the attack lane, contrasting with the orange danger projectile.

**Attack loop:** The Reaver sweeps to one side of the arena, faces the player, and launches one fast but broad, horizontally travelling glass lance after a **0.75-second** tell. The lance can be avoided with a jump or by changing platforms. A correctly oriented held guard consumes one durability and arrests the Reaver's momentum, causing a brief low hover. It does not damage on body overlap during this recovery; ordinary body contact outside the recovery remains dangerous.

**Bow opportunity:** The near wing vane unfolds as a bright weakpoint for **1.8 seconds** while the Reaver hovers within normal bow range. It takes **three arrows** to defeat. Its height changes between cycles so the player must reposition or use a jump; the weakpoint never sits behind solid terrain during the exposure.

**Fairness and placement:** Put it in a two-level arena with a clear left/right route and generous landing shelves. Limit its sweep to visible bounds, pause its movement during the guard counter, and avoid chaining the lance directly into another attack before the player can fire or dodge.

## Encounter rhythm and tuning

Introduce the enemies one at a time in this order: Bulwark, Cantor, Reaver. Then use a short **Resonance Gallery** gauntlet with one of each, separated by safe ground and readable checkpoint/recovery opportunities. At three shield charges, one successful guard per elite is the intended minimum-cost clear; if the player spends an extra charge, the next retry should still be possible through a nearby checkpoint or an optional one-charge shield repair pickup. Do not place the entire gauntlet between one checkpoint and a no-return boss gate until real-device tests show the shield economy is fair.

Initial tuning targets: exposed windows must permit at least three normal bow shots; tell colors/shapes must remain distinct in the generated cavern palette; weakpoints should be large enough for the swept arrow ray; and no attack should require holding guard for more than one projectile in a volley. Rapid-fire should shorten the number of taps, while Fanstring should improve coverage, but neither buff should trivialize the required guard.

## Acceptance checks for a future implementation

1. Each elite's signature projectile visibly telegraphs before launch and can be dodged without damage.
2. A frontal held guard blocks the projectile, spends exactly one durability, preserves player health, and triggers that elite's counter window. Facing away, releasing the guard, or having zero charges does not trigger it.
3. Arrows and melee do no elite health damage while its weakpoint is closed; arrows only damage the open weakpoint when their swept hit position intersects it.
4. Exposure expires on schedule, and only a new successful guard opens it again.
5. Each enemy can be defeated with the intended three-to-four arrows within its window; no spread or rapid buff is mandatory.
6. Physical contact damage is based on actual collision, not proximity. The Reaver's counter hover is safe from accidental body-contact damage.
7. Simulated touch input can move, jump, guard, and fire concurrently. An elite cannot consume more than one guard charge from a single projectile.
8. Run one elite encounter at one heart and one at full health; test a missed guard, depleted shield, retry, and player death/respawn.
