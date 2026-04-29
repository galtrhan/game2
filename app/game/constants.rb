module GameConstants
  UI_FONT = 'fonts/Kenney Mini Square.ttf'.freeze

  # Shown on the one-frame "Generating world..." screen (generation runs synchronously next tick).
  NEW_GAME_LOADING_DETAIL = 'Placing buildings, floors, doors, and stairs...'.freeze

  TILE_SIZE      = 32
  TILES_X        = 100
  TILES_Y        = 70
  MAP_PX         = TILES_X * TILE_SIZE
  MAP_PY         = TILES_Y * TILE_SIZE
  SCREEN_W       = 1280
  SCREEN_H       = 720
  # World→screen scale; default 2x (see @zoom in GameCamera). Min 1x when sprinting at max speed.
  ZOOM_DEFAULT   = 2.0
  ZOOM_MIN       = 1.0
  # After this many consecutive frames at full movement speed, zoom eases toward ZOOM_MIN (2s at 60fps).
  FULL_SPEED_ZOOM_DELAY_TICKS = 120
  # Per-frame lerp toward target zoom (higher = faster).
  ZOOM_LERP         = 0.04
  # Faster lerp when easing back to 2x after idling (no movement input).
  ZOOM_LERP_RETURN  = 0.1
  PLAYER_W       = TILE_SIZE - 4
  PLAYER_H       = TILE_SIZE - 4
  PLAYER_SPEED   = 3
  VEHICLE_W      = TILE_SIZE
  VEHICLE_H      = TILE_SIZE * 2
  VEHICLE_SPEED  = 10
  INTERACT_DIST  = TILE_SIZE * 2
  SAVE_PATH      = 'saves/game2.sav'
  MAP_SAVE_PATH  = 'saves/game2_map.json'
  IDLE_FRAMES    = 180
  DOT_SIZE       = 5

  PAUSE_ITEMS = ['Continue', 'Save', 'Load', 'Quit'].freeze

  MAX_STRUCT_FLOOR =  100  # highest floor generated per structure
  MIN_STRUCT_FLOOR = -40   # lowest floor generated per structure

end
