# Map Forge: first playable editor slice

## Purpose
Map Forge is an offline, touch-friendly tile editor opened from the ASHENWILD title menu. It uses a versioned JSON map format so player-authored maps and future procedural/AI map generation can share the same data contract.

## Included in this pass
- Title-menu entry: **MAP FORGE — CREATE YOUR OWN**.
- 30 × 18 grid with 24 px cells.
- Tap/click palette selection and paint placement, including drag painting.
- Procedural tile palette: erase, stone, moss platform, hazard, Ash Mite marker, Ashen Shard, checkpoint, exit, crystal.
- Undo/redo history.
- Random Map draft generation with a floor, elevated platforms, pickups, enemy markers, checkpoint, and exit.
- Local JSON save/load under `user://custom_maps/`.
- **Play in Game:** launches the custom map using the actual ASHENWILD player controller, camera, touch controls, enemy scenes, hazard triggers, shard pickups, checkpoint banking, and exit trigger.
- Custom map exits do not require the campaign gate shard.
- Android-friendly Godot Control/Button interface; mouse/keyboard support remains available.

## Data contract (version 1)
Each saved file contains:
- `version`: integer, currently 1.
- `name`: player-visible map name.
- `width`, `height`, `tile_size`.
- `cells`: 2D array of integer tile IDs.

Tile IDs:
0 erase/empty, 1 stone, 2 moss platform, 3 hazard, 4 Ash Mite marker, 5 Ashen Shard, 6 checkpoint, 7 exit, 8 crystal.

A future AI generator can return this same JSON structure. The game should validate dimensions, tile IDs, spawn/exit presence, object limits, and platform reachability before publishing or launching generated maps.

## How to use
1. Pull the `feature/map-forge` branch.
2. Launch ASHENWILD and choose **MAP FORGE — CREATE YOUR OWN** from the title menu.
3. Choose a piece on the left, then tap/drag over the grid.
4. Use Undo/Redo as needed.
5. Choose Random Map to create a starting layout.
6. Save stores the map locally. Load opens the first valid local JSON map found.
7. Play in Game launches the real gameplay runtime on the custom map. Use the in-game pause menu to return to title, then reopen Map Forge to continue editing.
8. Back returns to the title menu.

## Not yet implemented
- Custom maps now use the real player and existing enemy, hazard, pickup, checkpoint, and exit systems. Crystal tiles remain decorative.
- Custom maps are not yet wired into the campaign's full gameplay scene, progression, enemy scenes, or save slots.
- Load currently chooses the first valid saved map rather than presenting a map browser.
- No thumbnail generation, resize tool, rotate tool, object property inspector, multi-layer backgrounds, music selection, or full export/import share sheet yet.
- No online publishing, downloads, moderation, ratings, or cloud sync.
- Art is generated procedurally in-engine as crisp colored tile blocks with highlights. Dedicated production sprite/tile art and animations are a separate asset pass.
- No Godot 4.7.2 editor import, runtime, or Android device test could be run in the connected editing environment. Run these before treating the feature as verified.

## Next implementation priorities
1. Add map browser with rename, duplicate, delete, and explicit load selection.
2. Replace marker-only entities with reusable runtime scene instances and collision rules.
3. Add player spawn, map bounds, exit validation, and full gameplay Test Play using the existing player/enemy scenes.
4. Add terrain autotiling and original pixel-art tile atlas/decoration assets.
5. Add zoom/pan, brush size, selection/move, map resizing, and object inspector.
6. Add import/export package with validation and thumbnails.
7. Add online service only after authentication, moderation, storage, and privacy design are approved.
