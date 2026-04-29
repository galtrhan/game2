module GameConstants
  TILE_SIZE      = 32
  TILES_X        = 100
  TILES_Y        = 70
  MAP_PX         = TILES_X * TILE_SIZE
  MAP_PY         = TILES_Y * TILE_SIZE
  SCREEN_W       = 1280
  SCREEN_H       = 720
  PLAYER_W       = TILE_SIZE - 4
  PLAYER_H       = TILE_SIZE - 4
  PLAYER_SPEED   = 3
  VEHICLE_W      = TILE_SIZE
  VEHICLE_H      = TILE_SIZE * 2
  VEHICLE_SPEED  = 2
  INTERACT_DIST  = TILE_SIZE * 2
  SAVE_PATH      = 'saves/game2.sav'
  MAP_SAVE_PATH  = 'saves/game2_map.json'
  IDLE_FRAMES    = 180
  DOT_SIZE       = 5

  PAUSE_ITEMS = ['Continue', 'Save', 'Load', 'Quit'].freeze

  MAX_STRUCT_FLOOR =  3   # highest floor generated per structure
  MIN_STRUCT_FLOOR = -2   # lowest floor generated per structure

  DZ_W      = (SCREEN_W * 0.5).to_i
  DZ_H      = (SCREEN_H * 0.5).to_i
  DZ_LEFT   = ((SCREEN_W - DZ_W) * 0.5).to_i
  DZ_RIGHT  = DZ_LEFT + DZ_W
  DZ_BOTTOM = ((SCREEN_H - DZ_H) * 0.5).to_i
  DZ_TOP    = DZ_BOTTOM + DZ_H
end
