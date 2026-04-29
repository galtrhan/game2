module GameMap
  include GameConstants

  def generate_map
    srand(@map_seed)
    @tilemap      = {}
    @structure_map = {}
    @stair_data   = {}
    init_floor(0, :floor)

    struct_id = 0
    y = 1
    while y < TILES_Y - 1
      x = 1
      while x < TILES_X - 1
        bw = [10 + rand(9), TILES_X - 1 - x].min
        bh = [10 + rand(9), TILES_Y - 1 - y].min
        place_structure(x, y, bw, bh, struct_id, 0, 0)
        struct_id += 1
        x += bw + 2 + rand(19)
      end
      y += (2 + rand(9)) + 2 + rand(19)
    end
    @tilemap
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

  def map_tile(tx, ty, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    return :block if tx < 0 || tx >= TILES_X || ty < 0 || ty >= TILES_Y
    f = @tilemap[floor]
    return :block unless f
    f[ty][tx]
  end

  private

  def init_floor(floor, default_tile)
    @tilemap[floor]       = Array.new(TILES_Y) { Array.new(TILES_X, default_tile) }
    @structure_map[floor] = Array.new(TILES_Y) { Array.new(TILES_X, nil) }
  end

  # depth 0 = ground floor (gets entrance door + stairs)
  # depth 1 = adjacent floor (gets rooms, no new stairs, no entrance door)
  def place_structure(x, y, bw, bh, struct_id, floor, depth)
    init_floor(floor, :block) unless @tilemap[floor]

    map  = @tilemap[floor]
    smap = @structure_map[floor]

    bw.times { |dx| bh.times { |dy| smap[y + dy][x + dx] = struct_id } }

    bw.times do |dx|
      bh.times do |dy|
        map[y + dy][x + dx] = (dx == 0 || dx == bw - 1 || dy == 0 || dy == bh - 1) ? :block : :floor
      end
    end

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

    col_dividers.each { |dx| (1..bh - 2).each { |dy| map[y + dy][x + dx] = :block } }
    row_dividers.each { |dy| (1..bw - 2).each { |dx| map[y + dy][x + dx] = :block } }

    row_bands = band_ranges(bh, row_dividers)
    col_bands = band_ranges(bw, col_dividers)

    col_dividers.each do |dx|
      row_bands.each do |band|
        door_dy = band.to_a[rand(band.size)]
        map[y + door_dy][x + dx] = rand(2) == 0 ? :locked_door : :door
      end
    end

    row_dividers.each do |dy|
      col_bands.each do |band|
        door_dx = band.to_a[rand(band.size)]
        map[y + dy][x + door_dx] = rand(2) == 0 ? :locked_door : :door
      end
    end

    if depth == 0
      border = []
      bh.times do |dy|
        bw.times do |dx|
          next unless dx == 0 || dx == bw - 1 || dy == 0 || dy == bh - 1
          next if (dx == 0 || dx == bw - 1) && (dy == 0 || dy == bh - 1)
          border << [x + dx, y + dy]
        end
      end
      dt = border[rand(border.length)]
      map[dt[1]][dt[0]] = :door if dt

      place_stairs(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers) if bw >= 6 && bh >= 5
    end
  end

  def place_stairs(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers)
    return if rand(3) == 0  # 33% chance to skip

    20.times do
      tx = x + 2 + rand(bw - 5)
      ty = y + 2 + rand(bh - 4)
      lx = tx - x
      ly = ty - y
      next if col_dividers.include?(lx) || col_dividers.include?(lx + 1)
      next if row_dividers.include?(ly)
      next if tx + 1 >= x + bw - 1

      delta     = rand(2) == 0 ? 1 : -1
      tile      = delta == 1 ? :stair_up : :stair_dn
      map       = @tilemap[floor]
      map[ty][tx]     = tile
      map[ty][tx + 1] = tile

      @stair_data[[floor, tx,     ty]] = { delta: delta, exit_dx: 1, exit_dy: 0, is_exit: false }
      @stair_data[[floor, tx + 1, ty]] = { delta: delta, exit_dx: 1, exit_dy: 0, is_exit: true  }

      next_floor = floor + delta
      place_structure(x, y, bw, bh, struct_id, next_floor, 1)

      nmap      = @tilemap[next_floor]
      ret_tile  = delta == 1 ? :stair_dn : :stair_up
      nmap[ty][tx]     = ret_tile
      nmap[ty][tx + 1] = ret_tile
      @stair_data[[next_floor, tx + 1, ty]] = { delta: -delta, exit_dx: -1, exit_dy: 0, is_exit: false }
      @stair_data[[next_floor, tx,     ty]] = { delta: -delta, exit_dx: -1, exit_dy: 0, is_exit: true  }

      break
    end
  end

  def band_ranges(size, dividers)
    bounds = [0] + dividers + [size - 1]
    ranges = []
    bounds.each_cons(2) { |a, b| ranges << ((a + 1)..(b - 1)) if b - a > 1 }
    ranges
  end
end
