module GameSaveLoad
  include GameConstants
  TILE_CHAR = { floor: 'f', block: 'b', door: 'd', locked_door: 'l', stair_up: 'u', stair_dn: 'v' }.freeze
  CHAR_TILE = { 'f' => :floor, 'b' => :block, 'd' => :door, 'l' => :locked_door, 'u' => :stair_up, 'v' => :stair_dn }.freeze

  def save_game
    v = @vehicle
    parts = [
      "seed=#{@map_seed}",
      "player_x=#{@player[:x]}",
      "player_y=#{@player[:y]}",
      "player_floor=#{@player[:floor]}",
      "vehicle_x=#{v ? v[:x] : 'nil'}",
      "vehicle_y=#{v ? v[:y] : 'nil'}",
      "vehicle_col=#{v ? (v[:collidable] ? '1' : '0') : 'nil'}",
      "mode=#{@mode}",
      "cam_x=#{@cam_x.to_i}",
      "cam_y=#{@cam_y.to_i}"
    ]
    $gtk.write_file(SAVE_PATH, parts.join('|'))
    $gtk.write_file(MAP_SAVE_PATH, tilemap_to_json)
  end

  def load_from_data(raw)
    pairs = parse_save_pairs(raw)
    @map_seed = pairs['seed'].to_i
    # generate_map restores @structure_map and @stair_data from seed
    generate_map
    apply_loaded_save_after_map!(pairs)
  end

  def parse_save_pairs(raw)
    pairs = {}
    raw.split('|').each { |p| k, v = p.split('='); pairs[k] = v }
    pairs
  end

  # Call after generate_map has rebuilt @tilemap from the seed (sync path).
  def apply_loaded_save_after_map!(pairs)
    map_json = $gtk.read_file(MAP_SAVE_PATH)
    @tilemap = json_to_tilemap(map_json) if map_json
    rebuild_outer_door_cells

    @player = { x: pairs['player_x'].to_i, y: pairs['player_y'].to_i, tx: 0, ty: 0,
                facing: :idle, idle_timer: 0, floor: (pairs['player_floor'] || '0').to_i }
    @player[:tx] = ((@player[:x] + (PLAYER_W * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    @player[:ty] = ((@player[:y] + (PLAYER_H * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    @vehicle = if pairs['vehicle_x'] != 'nil'
      { x: pairs['vehicle_x'].to_i, y: pairs['vehicle_y'].to_i, collidable: pairs['vehicle_col'] == '1' }
    end

    @mode           = pairs['mode'] == 'in_vehicle' ? :in_vehicle : :on_foot
    @zoom                  = ZOOM_DEFAULT
    @full_speed_run_ticks  = 0
    # Clamp for tightest zoom-out (1x); update_camera may refine once @zoom is applied.
    @cam_x          = pairs['cam_x'].to_i.clamp(0, [MAP_PX - SCREEN_W, 0].max)
    @cam_y          = pairs['cam_y'].to_i.clamp(0, [MAP_PY - SCREEN_H, 0].max)
    @debug          = false
    @paused         = false
    @pause_selected = 0
  end

  private

  def tilemap_to_json
    floors_json = @tilemap.map do |floor_num, floor_map|
      data = floor_map.map { |row| row.map { |t| TILE_CHAR[t] || 'b' }.join }.join
      "\"#{floor_num}\":{\"w\":#{TILES_X},\"h\":#{TILES_Y},\"data\":\"#{data}\"}"
    end.join(',')
    "{\"floors\":{#{floors_json}}}"
  end

  def json_to_tilemap(json)
    parsed = $gtk.parse_json(json)
    result = {}
    (parsed['floors'] || {}).each do |floor_str, floor_data|
      floor_num = floor_str.to_i
      w    = floor_data['w'].to_i
      h    = floor_data['h'].to_i
      data = floor_data['data']
      floor_map = []
      h.times do |ty|
        row = []
        w.times { |tx| row << (CHAR_TILE[data[ty * w + tx]] || :floor) }
        floor_map << row
      end
      result[floor_num] = floor_map
    end
    result
  end
end
