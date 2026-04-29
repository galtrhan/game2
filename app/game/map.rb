module GameMap
  include GameConstants

  def generate_map
    srand(@map_seed)
    map = []
    TILES_Y.times { map << Array.new(TILES_X, :floor) }
    @structure_map = []
    TILES_Y.times { @structure_map << Array.new(TILES_X, nil) }
    struct_id = 0
    y = 1
    while y < TILES_Y - 1
      x = 1
      while x < TILES_X - 1
        bw = [10 + rand(9), TILES_X - 1 - x].min
        bh = [10 + rand(9), TILES_Y - 1 - y].min
        place_structure(map, x, y, bw, bh, struct_id)
        struct_id += 1
        x += bw + 2 + rand(19)
      end
      y += (2 + rand(9)) + 2 + rand(19)
    end
    map
  end

  def find_spawn
    free = []
    TILES_Y.times { |ty| TILES_X.times { |tx| free << { tx: tx, ty: ty } if map_tile(tx, ty) == :floor } }
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
        next unless map_tile(tx, ty) == :floor && map_tile(tx, ty + 1) == :floor
        candidates << { tx: tx, ty: ty }
      end
    end
    return nil if candidates.empty?
    s = candidates[rand(candidates.length)]
    { x: s[:tx] * TILE_SIZE, y: s[:ty] * TILE_SIZE, collidable: true }
  end

  def map_tile(tx, ty)
    return :floor if tx < 0 || tx >= TILES_X || ty < 0 || ty >= TILES_Y
    @tilemap[ty][tx]
  end

  private

  def place_structure(map, x, y, bw, bh, struct_id)
    # Mark entire bounding box with this structure's ID (outer walls + interior)
    bw.times { |dx| bh.times { |dy| @structure_map[y + dy][x + dx] = struct_id } }

    # Outer walls, hollow interior
    bw.times do |dx|
      bh.times do |dy|
        map[y + dy][x + dx] = (dx == 0 || dx == bw - 1 || dy == 0 || dy == bh - 1) ? :block : :floor
      end
    end

    # Dividers: positions 3..size-4 guarantee ≥2 floor tiles between divider and outer wall
    col_dividers = []
    cx = 3
    while cx <= bw - 4
      col_dividers << cx
      cx += 3 + rand(3)
    end

    row_dividers = []
    ry = 3
    while ry <= bh - 4
      row_dividers << ry
      ry += 3 + rand(3)
    end

    # Draw ALL walls first so doors are never overwritten by a later wall pass
    col_dividers.each { |dx| (1..bh - 2).each { |dy| map[y + dy][x + dx] = :block } }
    row_dividers.each { |dy| (1..bw - 2).each { |dx| map[y + dy][x + dx] = :block } }

    # Bands: ranges of floor rows between row_dividers (and outer walls)
    row_bands = band_ranges(bh, row_dividers)
    col_bands = band_ranges(bw, col_dividers)

    # Each col_divider wall is cut into segments by row_dividers.
    # One door per segment ensures every adjacent room pair across the wall is reachable.
    col_dividers.each do |dx|
      row_bands.each do |band|
        door_dy = band.to_a[rand(band.size)]
        map[y + door_dy][x + dx] = rand(2) == 0 ? :locked_door : :door
      end
    end

    # Same for row_divider walls, segmented by col_dividers.
    row_dividers.each do |dy|
      col_bands.each do |band|
        door_dx = band.to_a[rand(band.size)]
        map[y + dy][x + door_dx] = rand(2) == 0 ? :locked_door : :door
      end
    end

    # Outer entrance door on the border (inner neighbour is always floor
    # because dividers are kept ≥2 tiles from outer walls)
    border = []
    bh.times do |dy|
      bw.times do |dx|
        next unless dx == 0 || dx == bw - 1 || dy == 0 || dy == bh - 1
        next if (dx == 0 || dx == bw - 1) && (dy == 0 || dy == bh - 1) # skip corners
        border << [x + dx, y + dy]
      end
    end
    dt = border[rand(border.length)]
    map[dt[1]][dt[0]] = :door if dt
  end

  # Returns ranges of interior positions between each pair of adjacent boundaries.
  # boundaries = [0] + dividers + [size-1]; ranges cover the gaps (excluding boundary tiles).
  def band_ranges(size, dividers)
    bounds = [0] + dividers + [size - 1]
    ranges = []
    bounds.each_cons(2) { |a, b| ranges << ((a + 1)..(b - 1)) if b - a > 1 }
    ranges
  end
end
