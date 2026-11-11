# game2

Top-down DragonRuby Game Toolkit prototype in a procedurally generated, infinite tile world. Walk on foot or drive a vehicle, enter buildings, climb stairs through their floors, and avoid the inhabitants.

## Running

From the repo root:

```bash
./dragonruby game2
```

A local dev server runs at `http://localhost:9001` while the game runs.

## Controls

### On foot

| Key | Action |
| --- | --- |
| `WASD` | Move |
| Mouse | Aim. The player faces the cursor, a small white dot orbits the body. |
| `E` | Enter or exit a vehicle, or toggle a door when standing on or facing one. Locked doors need unlocking first. |
| `I` | Toggle the debug overlay |
| `Esc` | Pause menu |

### In vehicle

| Key | Action |
| --- | --- |
| `WASD` | Drive |
| `E` | Exit |
| `Esc` | Pause menu |

### Pause menu

| Key | Action |
| --- | --- |
| `W` / `S`, arrows, mouse | Navigate |
| `Space`, `Enter`, `E`, click | Select |

Menu items: Continue, Save, Load, Quit.

## The world

- Buildings are procedurally generated rectangles with interior walls, regular and locked doors, and stairs.
- Each generated floor has at most one `stair_up` and one `stair_dn`. They sit in the corner of a sub-room and never touch a door.
- About half of all buildings are inhabited. Each inhabited building gets 2-5 NPCs per floor, and 1-10 NPCs roam outside it.
- NPCs are red triangles. They wander, then chase the player when they have line of sight on the same floor, inside the same container. A container is a building or the outdoors.
- The vehicle is a pink rectangle. It spawns near the player on open ground, never inside a building.

Floors above and below ground are generated on demand the first time the player uses a stair.

## Architecture

DragonRuby calls `tick(args)` 60 times per second. The entry point is `app/main.rb`. It dispatches to the active scene via `app/scene_manager.rb`. The main scene is `app/scenes/game_scene.rb`, which mixes in modules from `app/game/`:

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

`@tilemap[floor]` is a hash of chunk-keyed flat arrays, one `Array(CHUNK_SIZE²)` per chunk. The chunk key is `cx * CHUNK_STRIDE + cy`. Empty cells fall back to `@floor_defaults[floor]`.

`@structure_map[floor]` mirrors this layout. It stores the `struct_id` per tile. A `nil` value means outdoors.

`@stair_data[[floor, tx, ty]]` records each stair's destination delta, exit direction and structure metadata.

### Deferred floor generation

Only floor 0 chunks generate eagerly, around the spawn point and as the camera moves. Higher and lower floors of a building generate lazily, the first time the player walks onto a stair exit. `generate_struct_floor_if_needed` runs then.

The originating floor records a `pending_struct_floors[[struct_id, target_floor]]` entry with the stair's coordinates. The new floor uses it to stamp a matching return stair at the same position. The floors stay vertically aligned.

### Save and load

Only the world seed, player state, vehicle state, camera and door toggles are saved, in `saves/game2.sav`. The map regenerates from the seed on load. This keeps saves small and loading fast. NPCs are not saved, they re-roll on load.

## Conventions

- All gameplay constants live in `app/game/constants.rb`.
- `attr_gtk` is used in `GameScene`. Every mixed-in module gets access to `args`, `state`, `outputs` and `inputs`.
- Hash-based primitives are preferred over positional arrays, for example `outputs.sprites << { x:, y:, w:, h:, path: }`.
- Hot-path code avoids per-frame allocations. Direction arrays are hoisted constants, short integer ranges use `while` loops, per-tick lookups are memoized in ivars, and LOS checks are staggered by NPC index.
