# Map Forge rebuild

## Scope and campaign safety
The former image-backed Luminous Caves test-map gameplay hook and its collision builder have been removed from the main menu and campaign runtime. The original background image remains in `assets/backgrounds/luminous_caves_test.jpg` and is intentionally preserved as a reusable asset. The three campaign regions, player, enemies, elites, boss, touch controls, HUD, progression, profile autoload, and existing campaign construction remain in place.

Map Forge is kept separate from the campaign builder. Its data model lives in `scripts/map_forge_data.gd`, its editor UI in `scripts/map_forge.gd`, and custom-level construction in `scripts/custom_map_runtime.gd`.

## Editor controls
- Paint and Select tools.
- Stone, moss, and one-way terrain.
- Hazard, Ash Mite, Ashen Shard, checkpoint, exit, crystal, and player-spawn placement.
- Visible grid and distinct drawn tile/object silhouettes.
- Undo/redo, grid toggle, clear map, randomize, save, load, duplicate, rename, delete, create blank map, and Test Map.
- Touch and mouse painting; keyboard shortcuts: Ctrl+Z, Ctrl+Y, Ctrl+S, G, Delete, and Escape.
- Responsive layout for landscape screen sizes with a scrollable control rail and toolbar.

## Persistent map format
Maps are stored as JSON under `user://custom_maps/`. Format version 2 contains:
- Unique `id`, `name`, optional `description`, `created_at`, and `modified_at`.
- `width`, `height`, and `tile_size`.
- `tiles`: 2D terrain grid (0 empty, 1 stone, 2 moss, 3 one-way).
- `objects`: typed object placements with grid x/y coordinates.
- `spawn`: player spawn grid coordinates.
- Optional `seed` for reproducible generated layouts.

The loader validates format, dimensions, grid shape, terrain values, object types/counts, and spawn bounds. Version 1 cell maps are normalized into the new data contract. Invalid/corrupted maps are skipped by the library list and rejected on explicit load. Saving a draft does not require an exit; Test Map requires at least one exit.

## Runtime behavior
Terrain runs are merged horizontally into a single static collision body per contiguous run. One-way terrain uses one-way collision shapes. Hazards and object placements call the existing ASHENWILD gameplay handlers: enemies use the existing enemy scene, shards use the existing collectible/Ashen Shards path, checkpoints use the existing banking/respawn path, and exits use the existing completion path. Crystals are decorative and non-solid. The runtime builder is isolated from editor UI and campaign level construction.

Test Map saves the current editor state and hides, rather than frees, the editor instance. It then launches the custom level with the real player, camera, HUD, controls, and gameplay systems. The pause menu exposes **RETURN TO MAP FORGE** while testing. Returning hides the custom level and restores the same editor instance and map state without restarting the application.

## Generation
The seeded generator provides Basic Platforming, Ruined Castle, Underground Caves, Forest Ruins, and Challenge Course styles. Generated layouts include a continuous safe route, a raised platform sequence, a spawn, a checkpoint, an exit, and a limited number of enemies/hazards/collectibles/decorative crystals. The continuous floor keeps the exit reachable; raised platforms are optional traversal routes rather than mandatory precision jumps.

## Current limitations
- Tile visuals are procedural drawings in the editor and simple runtime geometry, not a finished imported production tileset. Existing character/enemy/background artwork is preserved and remains available for future use.
- The map library lists map names and dimensions but does not yet generate saved thumbnail images.
- Multi-layer background/foreground painting, moving platforms, breakables, doors/gates, zoom/pan, object-property inspector, and export/import packages are not implemented.
- The generator does not yet perform a full graph-based reachability or jump-physics simulation. It deliberately keeps a continuous base route to avoid generating impossible exits.
- Android device interaction and PC runtime behavior still require testing on real targets.

## Validation
The gameplay smoke script now covers title-menu cleanup, map library save/load/duplicate/delete, real custom-map runtime construction, and the Test Map → Return to Map Forge workflow in addition to the existing campaign regression checks. Run with Godot 4.7.2:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/gameplay_smoke.gd
```

A successful source edit or static inspection is not a substitute for these runtime commands or an Android device test.
