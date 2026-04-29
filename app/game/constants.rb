module GameConstants
  UI_FONT = 'fonts/Kenney Mini Square.ttf'.freeze

  # Shown while the map streams in across ticks (see MAP_GEN_STRUCTURES_PER_TICK).
  NEW_GAME_LOADING_DETAIL = 'Placing buildings, floors, doors, and stairs...'.freeze

  TILE_SIZE      = 32
  TILES_X        = 100
  TILES_Y        = 100
  MAP_PX         = TILES_X * TILE_SIZE
  MAP_PY         = TILES_Y * TILE_SIZE
  SCREEN_W       = 1280
  SCREEN_H       = 720
  # World→screen scale; default 2x (see @zoom in GameCamera). Min 1x only while driving (after delay).
  ZOOM_DEFAULT   = 2.0
  # Inside a building (structure cell); camera eases to and stays at this zoom.
  ZOOM_INTERIOR  = 3.0
  ZOOM_MIN       = 1.0
  # After this many consecutive frames of vehicle movement, zoom eases toward ZOOM_MIN (2s at 60fps).
  FULL_SPEED_ZOOM_DELAY_TICKS = 120
  # Per-frame lerp toward target zoom (higher = faster).
  ZOOM_LERP         = 0.04
  # Faster lerp when easing back to 2x after idling (no movement input).
  ZOOM_LERP_RETURN  = 0.04
  # Slower lerp when leaving interior (3x) so outdoor zoom does not snap to 2x.
  ZOOM_LERP_EXIT_INTERIOR = 0.022
  PLAYER_W       = TILE_SIZE - 4
  PLAYER_H       = TILE_SIZE - 4
  PLAYER_SPEED   = 3
  VEHICLE_W      = TILE_SIZE
  VEHICLE_H      = TILE_SIZE * 2
  VEHICLE_SPEED  = 10
  INTERACT_DIST  = TILE_SIZE * 2
  SAVE_PATH      = 'saves/game2.sav'
  MAP_SAVE_PATH  = 'saves/game2_map.json'
  DOT_SIZE       = 5

  PAUSE_ITEMS = ['Continue', 'Save', 'Load', 'Quit'].freeze

  PAUSE_PANEL_W           = 300
  PAUSE_PANEL_H           = 310
  PAUSE_ITEM_Y_FROM_TOP   = 75   # first row anchor measured up from panel bottom
  PAUSE_ITEM_Y_STEP       = 58

  # Centered pause panel origin (bottom-left of panel rect).
  def pause_menu_panel
    px = ((SCREEN_W - PAUSE_PANEL_W) * 0.5).to_i
    py = ((SCREEN_H - PAUSE_PANEL_H) * 0.5).to_i
    { x: px, y: py, w: PAUSE_PANEL_W, h: PAUSE_PANEL_H }
  end

  # Hit box / highlight rect for pause row i (must match render_pause_overlay).
  def pause_menu_item_rect(i)
    p = pause_menu_panel
    by = p[:y] + p[:h] - PAUSE_ITEM_Y_FROM_TOP - (i * PAUSE_ITEM_Y_STEP)
    { x: p[:x] + 10, y: by - 16, w: p[:w] - 20, h: 44 }
  end

  MAX_STRUCT_FLOOR =  100  # highest floor generated per structure
  MIN_STRUCT_FLOOR = -40   # lowest floor generated per structure

  # Top-level structures placed per tick while generating (larger maps need >1 to stay responsive).
  MAP_GEN_STRUCTURES_PER_TICK = 12

  # Random tries before scanning for a floor tile (avoid building a million-entry spawn list).
  FIND_SPAWN_RANDOM_TRIES = 800
end
