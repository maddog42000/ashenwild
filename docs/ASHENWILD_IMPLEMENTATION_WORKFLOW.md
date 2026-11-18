# ASHENWILD — Agent Workflow & Implementation Handoff

**Project:** ASHENWILD — The Hushvault  
**Engine:** Godot 4.7.2, GDScript, GL Compatibility  
**Target:** Android-first, landscape, touchscreen + keyboard fallback  
**Repository:** https://github.com/maddog42000/ashenwild  
**Baseline:** Existing main-branch playable slice. Preserve it.

## 1. Product direction (approved decisions)

ASHENWILD is a hybrid dark-fantasy action-adventure platformer combining exploration, combat, precision platforming, character progression, and player-created levels.

- Campaign difficulty: **Adaptive**.
- Death and saving: **Souls-inspired**. Carried Ashen Shards are dropped at death and can be recovered. A subsequent death before recovery replaces the previous dropped stash. Checkpoints bank carried currency.
- Characters: **Unlockable**, not all available at the start.
- Level editor: **Built into the game**.
- Level sharing: **Both local and online**. Local authoring/export/import comes first; online publishing and discovery follow.
- Platform priority: Android first. Preserve simultaneous multitouch and keyboard fallback.

## 2. Existing project baseline: do not regress

The current game already contains:
- Title menu and pause/return-to-title flow.
- Forgotten Hollow, Pale Spine, and Hushvault campaign regions.
- Bellows Saint boss encounter and Stillheart objective.
- Kettleback Bulwark and Gloam Cantor elite encounters.
- Bow, Quickstring/Fanstring pickups, and directional shield guarding.
- Checkpoints, collectible gate shards, fall hazards, Breathglass vents, and parkour routes.
- Touch joystick and independent jump, melee, bow, and shield controls.
- Script-drawn fallback visuals where optional art is absent.

Do not replace the existing level builder, input system, enemy/boss encounters, or fallback rendering just to introduce new architecture. Refactor incrementally.

## 3. Visual identity and asset guidance

Use a cohesive dark-fantasy palette:
- Deep navy, charcoal stone, muted moss, weathered bronze, ember amber, and luminous teal.
- Warm shrine/lantern light against cool forest and cave shadows.
- Clear silhouettes and high-contrast interactive objects for phone screens.
- Environment themes: ruined forest bridges, Hushvault stonework, crystal-lit caverns, ash-choked foundries.
- Character silhouettes: balanced sword-bearing Wanderer; shield-heavy Warden; agile shadow Shade; ranged Ashen Hunter.

The companion concept sheet is visual direction only. It is **not** a production sprite sheet, animation atlas, tileset, or licensed source asset. Never import it as a game texture without first slicing/redrawing and checking scale, transparency, frame consistency, and licensing. Keep procedural fallbacks.

## 4. Architecture target

Prefer small, testable systems with clear ownership:
- `AshenProfile`: persistent player profile, carried/banked currency, death-drop state, adaptive difficulty history.
- `CharacterData`: character identity, stats, unlock requirements, abilities.
- `AbilityManager`: unlocked/equipped abilities and cooldowns.
- `LevelData`: serializable level layout, entities, objectives, spawn, exits, metadata.
- `LevelManager`: loading, transitions, checkpoint state, completion.
- `WorkshopManager`: edit/test/save/import/export; later online publishing.

Use Resources or versioned JSON for data-driven content. Avoid one-off hard-coded level scripts as the long-term authoring format. Keep all runtime file access under Godot's `user://` path.

## 5. Implementation stages and acceptance criteria

### Stage 0 — Protect and validate the baseline
- Run Godot 4.7.2 headless editor import.
- Run the existing main scene and `tests/gameplay_smoke.gd`.
- Record baseline errors and retain the current controls and game flow.
- Test the Android export separately; a desktop/headless pass does not prove touch behavior.

**Done when:** existing smoke tests pass and no current region/control has regressed.

### Stage 1 — Souls-inspired currency and death recovery
- Add persistent carried and banked Ashen Shards.
- Award currency for existing collectible and enemy interactions.
- On death, drop carried currency at the death position.
- Add a clear visual/trigger for recovery.
- If the player dies again before recovery, the previous unclaimed drop is lost.
- Checkpoints bank carried currency and restore the existing shield behavior.
- Display carried/banked totals in the HUD.
- Keep the existing per-level gate shard separate from currency.

**Done when:** pickup → death → respawn → recovery works; second death overwrites the old drop; checkpoint banking survives app restart.

### Stage 2 — Adaptive difficulty
- Track deaths, successful region clears, damage, and challenge completion.
- Adjust bounded parameters such as regular enemy movement speed or recovery windows.
- Never silently remove boss mechanics, skip phases, or make unavoidable attacks.
- Expose an accessibility/manual override later.
- Make adaptive changes subtle, explainable, and testable.

**Done when:** repeated failure gives modest assistance; successful progression gradually restores challenge; values remain inside documented bounds.

### Stage 3 — Progression and unlockable characters
- Keep Wanderer as initial character.
- Add Warden, Shade, and Ashen Hunter as unlockable archetypes.
- Share campaign progress unless a character-specific challenge explicitly requires otherwise.
- Use data-driven stats/abilities and shared controller code.
- Add ability upgrades, relics, and cosmetic unlocks after core controls are stable.

**Done when:** unlock conditions persist, each archetype has a distinct gameplay identity, and all four work with mobile controls.

### Stage 4 — Campaign, UI, and content
- Add varied rooms, hidden routes, optional bosses, puzzle rooms, challenge arenas, and region identity.
- Add shrine UI, inventory/upgrades, character selection, world map, results screen, and touch-control layout settings.
- Keep readable HUD safe areas on common landscape phone aspect ratios.

**Done when:** the campaign has a coherent start-to-finish loop and every screen is usable on-device.

### Stage 5 — Local Workshop
- Grid placement for terrain/platforms, enemies, hazards, collectibles, checkpoints, exits, backgrounds, lighting, and objectives.
- Undo/redo, selection, delete, duplicate, snap-to-grid, zoom/pan, and immediate Test Play.
- Versioned local save format; robust validation and graceful handling of malformed files.
- Import/export a single level package with metadata and a thumbnail.
- Do not permit arbitrary scripts in user levels.

**Done when:** a player can build, save, close/reopen, test, export, and re-import a level entirely offline.

### Stage 6 — Online Workshop
- Add publishing, browsing, download, ratings/favourites, completion statistics, and featured challenges.
- Add moderation/reporting and safe limits for file size and object counts.
- Online must be optional; local levels remain playable offline.
- Do not hard-code credentials or introduce a server dependency before provider/security decisions are made.

**Done when:** publishing and downloading are authenticated, validated, moderated, and tested on Android.

### Stage 7 — Release readiness
- Godot 4.7.2 import + headless run + smoke tests.
- Android export/install/launch test on a real device.
- Save migration and interruption tests.
- Performance, thermal, memory, input, audio, and aspect-ratio checks.
- Provide a changelog and known-issues list.

## 6. Immediate implementation included with this handoff

The first implementation pass adds:
- An `AshenProfile` autoload for persistent carried/banked Ashen Shards, death-drop recovery state, death history, and a bounded adaptive enemy-speed factor.
- Enemy defeat rewards and a visible in-world death-drop recovery pickup.
- Checkpoint banking and HUD currency totals.
- A small adaptive speed adjustment for regular Ash Mites, based on deaths and successful region transitions.

This is a **vertical-slice foundation**, not the complete Souls economy or fully adaptive campaign. Elite/boss tuning, combat telemetry, inventory purchases, character unlocks, and Workshop systems remain staged work.

## 7. Test checklist for the first implementation

1. Launch the game and confirm the title menu still appears.
2. Start Forgotten Hollow and collect the teal gate shard. Confirm the gate objective still works.
3. Defeat an Ash Mite. Confirm Ashen Shards increase.
4. Reach a checkpoint. Confirm carried currency is banked.
5. Collect more currency, die, and respawn. Confirm the drop appears at the death location.
6. Touch the drop. Confirm the carried balance is restored.
7. Die a second time before recovering a drop. Confirm only the newest drop remains.
8. Restart the app. Confirm banked currency and profile history persist.
9. Transition through regions. Confirm adaptive pressure remains bounded and the game remains fair.
10. Repeat on Android with multitouch controls, landscape rotation, and interrupted-app save testing.

## 8. Agent operating rules

- Read this file and `AGENTS.md` before editing.
- Inspect the current implementation before changing it. Do not assume planned systems already exist.
- Keep changes focused and small. Avoid broad rewrites of `scripts/main.gd`.
- Preserve keyboard fallback, independent multitouch, landscape orientation, and script-drawn fallbacks.
- Use typed GDScript where practical; avoid Variant inference warnings treated as errors.
- Add/update smoke tests for every new gameplay rule.
- Never claim a feature is tested unless the relevant test was actually run.
- Report exact changed files, tests run, tests not run, and known limitations.
- Do not add online services, credentials, plugins, or analytics without explicit project-owner approval.

## 9. Current known limitations after the first pass

- Ashen Shards currently come from regular Ash Mite defeats and the existing level collectible; a complete loot/economy/inventory loop is not yet implemented.
- Adaptive tuning currently adjusts regular enemy movement speed only. It does not yet adapt boss/elite AI, damage, platform timing, or puzzle complexity.
- Character selection/unlock UI and character-specific animation sets are not implemented.
- The Workshop and online service are roadmap items, not part of this first playable slice.
- The concept sheet is a design reference, not in-game art assets.
- Android device testing and Godot headless validation must be run by an agent with the matching Godot 4.7.2 environment.
