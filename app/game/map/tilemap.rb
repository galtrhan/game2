module GameMap
  def map_tile(tx, ty, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    return :block if tx < 0 || tx >= TILES_X || ty < 0 || ty >= TILES_Y
    f = @tilemap[floor]
    return :block unless f
    f[ty][tx]
  end

  def find_spawn
    free = []
    TILES_Y.times { |ty| TILES_X.times { |tx| free << { tx: tx, ty: ty } if map_tile(tx, ty, 0) == :floor } }
    free.empty? ? { tx: 0, ty: 0 } : free[rand(free.length)]
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
