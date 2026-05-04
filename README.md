# game2

Top-down DragonRuby Game Toolkit prototype set in a procedurally generated, infinite tile world. Walk on foot or hop in a vehicle, enter buildings, climb stairs through their floors, and avoid the inhabitants.

## Running

From the repo root:

```bash
./dragonruby game2
```

Local dev server at `http://localhost:9001` while it's running.

## Controls

### On foot
- `WASD` — move
- Mouse — aim (player faces cursor; small white dot orbits the body)
- `E` — enter/exit vehicle, or toggle a door (when standing on or facing one). Locked doors require unlocking before use.
- `I` — toggle debug overlay
- `Esc` — pause menu

### In vehicle
- `WASD` — drive
- `E` — exit
- `Esc` — pause menu

### Pause menu
- `W` / `S` (or arrows / mouse) — navigate
- `Space` / `Enter` / `E` (or click) — select
- Items: Continue, Save, Load, Quit

## What's in the world

- **Buildings** are procedurally generated rectangles with interior walls, doors (regular + locked), and stairs. Floors above and below ground are generated on demand the first time the player ascends/descends.
- **Stairs**: each generated floor has at most one `stair_up` and one `stair_dn`, placed in a corner of a sub-room and never touching a door.
- **NPCs** (red triangles): about half of all buildings are inhabited. Each inhabited building gets 2-5 NPCs per floor and 1-10 NPCs roaming outside it. NPCs wander, then chase the player when they have line-of-sight on the same floor inside the same container (building or outdoors).
- **Vehicle** (pink rectangle): spawned near the player on open ground (never inside a building).

## Architecture

DragonRuby calls `tick(args)` 60 times per second. The entry point is `app/main.rb`, which dispatches to the active scene via `app/scene_manager.rb`. The main scene is `app/scenes/game_scene.rb`, which mixes in modules from `app/game/`:

```
app/
  main.rb              # tick entry point
  scene_manager.rb     # scene routing
  scenes/
    game_scene.rb      # composes all the game modules
    menu_scene.rb      # main menu
  game/
    constants.rb       # tunables (NPC counts, zoom, tile size, etc.)
    camera.rb          # zoom + scroll
    collision.rb       # circle/AABB checks shared by player and NPCs
    input.rb           # top-level input dispatch (foot / vehicle)
    input/
      movement.rb      # facing, stair transitions, corner-slide
      pause.rb         # pause menu input
    interaction.rb     # vehicle enter/exit, door toggling
    interaction/
      doors.rb         # door target lookup
    map.rb             # facade
    map/
      tilemap.rb       # chunk-flat-array storage; spawn helpers
      generation.rb    # chunk and structure generation, stair placement
    npcs.rb            # NPC spawn, AI, container-based culling
    render/
      world_tiles.rb   # tile / building rendering
      entities.rb      # player + vehicle
      npcs.rb          # NPC sprites
      ui_overlay.rb    # HUD / pause overlay
    renderer.rb        # render order
    save_load.rb       # serialize player + door mutations + seed
```

### Map storage

`@tilemap[floor]` is a hash of chunk-keyed flat arrays (one `Array(CHUNK_SIZE²)` per chunk), where `chunk_key = cx * CHUNK_STRIDE + cy`. Empty cells fall back to `@floor_defaults[floor]`. `@structure_map[floor]` mirrors this layout but stores `struct_id` per tile (nil = outdoors). `@stair_data[[floor, tx, ty]]` records each stair's destination delta, exit direction, and structure metadata.

### Deferred floor generation

Only floor 0 chunks generate eagerly (around the spawn point and as the camera moves). Higher and lower floors of a building are generated lazily by `generate_struct_floor_if_needed` the first time the player walks onto a stair exit. The originating floor records a `pending_struct_floors[[struct_id, target_floor]]` entry with the stair's coordinates so the new floor can stamp a matching return stair at the same position (vertical alignment between floors).

### Save / load

Only the world seed, player state, vehicle state, camera, and door toggles are persisted (`saves/game2.sav`). The map itself is regenerated from the seed on load — much smaller saves and faster I/O. NPCs are not persisted; they re-roll on load.

## Conventions

- All gameplay constants live in `app/game/constants.rb`.
- `attr_gtk` is used in `GameScene`, giving every mixed-in module access to `args`, `state`, `outputs`, `inputs`, etc.
- Hash-based primitives are preferred (`outputs.sprites << { x:, y:, w:, h:, path: }`) over positional arrays.
- Hot-path code avoids per-frame allocations: hoisted constants for direction arrays, `while` loops for short integer ranges, ivar memoization for per-tick lookups, throttled LOS checks staggered by NPC index.
