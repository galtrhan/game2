module GameSaveLoad
  include GameConstants
  TILE_CHAR = { floor: 'f', block: 'b', door: 'd', locked_door: 'l' }.freeze
  CHAR_TILE = { 'f' => :floor, 'b' => :block, 'd' => :door, 'l' => :locked_door }.freeze

  def save_game
    v = @vehicle
    parts = [
      "seed=#{@map_seed}",
      "player_x=#{@player[:x]}",
      "player_y=#{@player[:y]}",
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
    pairs = {}
    raw.split('|').each { |p| k, v = p.split('='); pairs[k] = v }

    @map_seed = pairs['seed'].to_i
    generate_map  # restores @structure_map deterministically from seed
    map_json = $gtk.read_file(MAP_SAVE_PATH)
    @tilemap = json_to_tilemap(map_json) if map_json

    @player = { x: pairs['player_x'].to_i, y: pairs['player_y'].to_i, tx: 0, ty: 0, facing: :idle, idle_timer: 0 }
    @player[:tx] = ((@player[:x] + (PLAYER_W * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    @player[:ty] = ((@player[:y] + (PLAYER_H * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    @vehicle = if pairs['vehicle_x'] != 'nil'
      { x: pairs['vehicle_x'].to_i, y: pairs['vehicle_y'].to_i, collidable: pairs['vehicle_col'] == '1' }
    end

    @mode           = pairs['mode'] == 'in_vehicle' ? :in_vehicle : :on_foot
    @cam_x          = pairs['cam_x'].to_i
    @cam_y          = pairs['cam_y'].to_i
    @debug          = false
    @paused         = false
    @pause_selected = 0
  end

  private

  def tilemap_to_json
    data = @tilemap.map { |row| row.map { |t| TILE_CHAR[t] }.join }.join
    "{\"w\":#{TILES_X},\"h\":#{TILES_Y},\"data\":\"#{data}\"}"
  end

  def json_to_tilemap(json)
    parsed = $gtk.parse_json(json)
    w      = parsed['w'].to_i
    h      = parsed['h'].to_i
    data   = parsed['data']
    map    = []
    h.times do |ty|
      row = []
      w.times { |tx| row << (CHAR_TILE[data[ty * w + tx]] || :floor) }
      map << row
    end
    map
  end
end
