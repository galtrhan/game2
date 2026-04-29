module GameSaveLoad
  include GameConstants

  TILE_CHAR = {
    floor: 'f',
    block: 'b',
    door: 'd',
    locked_door: 'l',
    stair_up: 'u',
    stair_dn: 'v'
  }.freeze

  CHAR_TILE = TILE_CHAR.invert.freeze

  def save_game
    v = @vehicle
    # Only persist tile mutations (door toggles) — the rest is regenerated from seed.
    mut_str = (@tile_mutations || {}).map do |(fl, tx, ty), tile|
      "#{fl},#{tx},#{ty},#{TILE_CHAR[tile]}"
    end.join(';')

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
      "cam_y=#{@cam_y.to_i}",
      "mutations=#{mut_str}"
    ]
    $gtk.write_file(SAVE_PATH, parts.join('|'))
  end

  def load_from_data(raw)
    pairs     = parse_save_pairs(raw)
    @map_seed = pairs['seed'].to_i

    # Derive the chunk the player was in so we seed the right area.
    px        = (pairs['player_x'] || '0').to_i
    py        = (pairs['player_y'] || '0').to_i
    player_cx = (px / TILE_SIZE).div(CHUNK_SIZE)
    player_cy = (py / TILE_SIZE).div(CHUNK_SIZE)

    map_generation_begin!
    generate_initial_chunks_around(player_cx, player_cy)
    apply_loaded_save_after_map!(pairs)
  end

  def parse_save_pairs(raw)
    pairs = {}
    raw.split('|').each { |p| k, v = p.split('=', 2); pairs[k] = v }
    pairs
  end

  def apply_loaded_save_after_map!(pairs)
    # Apply tile mutations on top of the freshly generated map.
    @tile_mutations = {}
    mut_str = pairs['mutations'] || ''
    mut_str.split(';').each do |m|
      parts = m.split(',')
      next unless parts.length == 4
      fl   = parts[0].to_i
      tx   = parts[1].to_i
      ty   = parts[2].to_i
      tile = CHAR_TILE[parts[3]]
      next unless tile
      set_tile(fl, tx, ty, tile)
      @tile_mutations[[fl, tx, ty]] = tile
    end

    @player = { x: pairs['player_x'].to_i, y: pairs['player_y'].to_i, tx: 0, ty: 0,
                face_angle: 0.0, floor: (pairs['player_floor'] || '0').to_i }
    @player[:tx] = (@player[:x] + (PLAYER_W * 0.5).to_i).div(TILE_SIZE)
    @player[:ty] = (@player[:y] + (PLAYER_H * 0.5).to_i).div(TILE_SIZE)

    @vehicle = if pairs['vehicle_x'] && pairs['vehicle_x'] != 'nil'
      { x: pairs['vehicle_x'].to_i, y: pairs['vehicle_y'].to_i,
        collidable: pairs['vehicle_col'] == '1' }
    end

    @mode                  = pairs['mode'] == 'in_vehicle' ? :in_vehicle : :on_foot
    @zoom                  = ZOOM_DEFAULT
    @full_speed_run_ticks  = 0
    @cam_x                 = pairs['cam_x'].to_i
    @cam_y                 = pairs['cam_y'].to_i
    @debug                 = false
    @paused                = false
    @pause_selected        = 0

    spawn_npc_fleet
  end
end
