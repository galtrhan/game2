module GameMap
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

    return false if tx < 0 || tx >= TILES_X || ty < 0 || ty >= TILES_Y

    smap = @structure_map[fl]
    return false unless smap

    row = smap[ty]
    row && !row[tx].nil?
  end

  def map_tile(tx, ty, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    return :block if tx < 0 || tx >= TILES_X || ty < 0 || ty >= TILES_Y
    f = @tilemap[floor]
    return :block unless f
    f[ty][tx]
  end

  def find_spawn
    FIND_SPAWN_RANDOM_TRIES.times do
      tx = rand(TILES_X)
      ty = rand(TILES_Y)
      return { tx: tx, ty: ty } if map_tile(tx, ty, 0) == :floor
    end

    # Rare fallback: sparse floor — scan without allocating a huge array.
    TILES_Y.times do |ty|
      TILES_X.times do |tx|
        return { tx: tx, ty: ty } if map_tile(tx, ty, 0) == :floor
      end
    end
    { tx: 0, ty: 0 }
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
