module GameMap
  # ---------------------------------------------------------------------------
  # Chunk-flat-array storage helpers
  #
  # @tilemap[floor]        = Hash<int_chunk_key, Array<CHUNK_SIZE²>>
  # @structure_map[floor]  = Hash<int_chunk_key, Array<CHUNK_SIZE²>>
  #
  # chunk_key = cx * CHUNK_STRIDE + cy  (integer — no heap allocation)
  # tile_idx  = dy * CHUNK_SIZE + dx
  #
  # nil in the chunk array means "use floor default" (floor_defaults[floor]).
  # ---------------------------------------------------------------------------

  def set_tile(floor, tx, ty, val)
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = ((@tilemap[floor] ||= {})[cx * CHUNK_STRIDE + cy] ||= Array.new(CHUNK_SIZE * CHUNK_SIZE))
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)] = val
  end

  def set_smap(floor, tx, ty, val)
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = ((@structure_map[floor] ||= {})[cx * CHUNK_STRIDE + cy] ||= Array.new(CHUNK_SIZE * CHUNK_SIZE))
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)] = val
  end

  # Raw tile value from chunk array — nil if unset (caller applies default).
  def get_tile_raw(floor, tx, ty)
    fmap = @tilemap[floor]
    return nil unless fmap
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = fmap[cx * CHUNK_STRIDE + cy]
    return nil unless chunk
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)]
  end

  # Public API — returns the effective tile symbol, applying the floor default.
  def map_tile(tx, ty, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    default = @floor_defaults ? (@floor_defaults[floor] || :floor) : :floor
    fmap = @tilemap[floor]
    return default unless fmap
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = fmap[cx * CHUNK_STRIDE + cy]
    return default unless chunk
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)] || default
  end

  # True when the player (or vehicle center on floor 0) stands on a structure-owned tile.
  def player_in_interior?
    return false unless @structure_map && @player

    fl = (@mode == :in_vehicle && @vehicle) ? 0 : @player[:floor]
    tx, ty =
      if @mode == :in_vehicle && @vehicle
        cx = (@vehicle[:x] + (VEHICLE_W * 0.5).to_i) / TILE_SIZE
        cy = (@vehicle[:y] + (VEHICLE_H * 0.5).to_i) / TILE_SIZE
        [cx, cy]
      else
        [@player[:tx], @player[:ty]]
      end

    smap = @structure_map[fl]
    return false unless smap
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = smap[cx * CHUNK_STRIDE + cy]
    return false unless chunk
    !chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)].nil?
  end

  def find_spawn
    half = CHUNK_SIZE * INITIAL_CHUNK_RADIUS   # spawn inside positive initial area
    FIND_SPAWN_RANDOM_TRIES.times do
      tx = rand(half)
      ty = rand(half)
      return { tx: tx, ty: ty } if map_tile(tx, ty, 0) == :floor
    end
    { tx: 1, ty: 1 }
  end

  def spawn_vehicle(player_tx, player_ty)
    candidates = []
    (-6..6).each do |dy|
      (-6..6).each do |dx|
        dist_sq = dx * dx + dy * dy
        next unless dist_sq >= 4 && dist_sq <= 25
        tx = player_tx + dx
        ty = player_ty + dy
        next unless map_tile(tx, ty, 0) == :floor && map_tile(tx, ty + 1, 0) == :floor
        candidates << { tx: tx, ty: ty }
      end
    end
    return nil if candidates.empty?
    s = candidates[rand(candidates.length)]
    { x: s[:tx] * TILE_SIZE, y: s[:ty] * TILE_SIZE, collidable: true }
  end
end
