module GameMap
  # Synchronous full generation (e.g. console load). Prefer map_generation_begin! +
  # map_generation_step! for large maps to spread work across ticks.
  def generate_map
    map_generation_begin!
    until map_generation_step!(1 << 28); end
    @tilemap
  end

  def map_generation_begin!
    @outer_door_cells = {}
    @map_gen_y = 1
    @map_gen_x = 1
    @map_gen_struct_id = 0
    @map_gen_done = false

    srand(@map_seed)
    @tilemap                 = {}
    @structure_map           = {}
    @stair_data              = {}
    @generated_struct_floors = {}
    init_floor(0, :floor)
  end

  # Places up to `structures_budget` top-level buildings; returns true when finished.
  def map_generation_step!(structures_budget)
    return true if @map_gen_done

    placed = 0
    while @map_gen_y < TILES_Y - 1 && placed < structures_budget
      while @map_gen_x < TILES_X - 1 && placed < structures_budget
        bw = [10 + rand(9), TILES_X - 1 - @map_gen_x].min
        bh = [10 + rand(9), TILES_Y - 1 - @map_gen_y].min
        place_structure(@map_gen_x, @map_gen_y, bw, bh, @map_gen_struct_id, 0, 0)
        @map_gen_struct_id += 1
        @map_gen_x += bw + 2 + rand(19)
        placed += 1
      end
      if @map_gen_x >= TILES_X - 1
        @map_gen_x = 1
        @map_gen_y += (2 + rand(9)) + 2 + rand(19)
      end
    end

    if @map_gen_y >= TILES_Y - 1
      @map_gen_done = true
      return true
    end
    false
  end

  private

  def mark_outer_door_if_needed(floor, tx, ty, sx, sy, bw, bh)
    return unless tx == sx || tx == sx + bw - 1 || ty == sy || ty == sy + bh - 1

    @outer_door_cells[[floor, tx, ty]] = true
  end

  def init_floor(floor, default_tile)
    @tilemap[floor]       = Array.new(TILES_Y) { Array.new(TILES_X, default_tile) }
    @structure_map[floor] = Array.new(TILES_Y) { Array.new(TILES_X, nil) }
  end

  def place_structure(x, y, bw, bh, struct_id, floor, depth)
    return if @generated_struct_floors[[struct_id, floor]]
    @generated_struct_floors[[struct_id, floor]] = true

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
        ty = y + door_dy
        tx = x + dx
        map[ty][tx] = rand(2) == 0 ? :locked_door : :door
        mark_outer_door_if_needed(floor, tx, ty, x, y, bw, bh)
      end
    end

    row_dividers.each do |dy|
      col_bands.each do |band|
        door_dx = band.to_a[rand(band.size)]
        ty = y + dy
        tx = x + door_dx
        map[ty][tx] = rand(2) == 0 ? :locked_door : :door
        mark_outer_door_if_needed(floor, tx, ty, x, y, bw, bh)
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
      if dt
        map[dt[1]][dt[0]] = :door
        mark_outer_door_if_needed(floor, dt[0], dt[1], x, y, bw, bh)
      end
    end

    place_stairs(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers)
  end

  def place_stairs(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers)
    return unless bw >= 6 && bh >= 5

    if floor < MAX_STRUCT_FLOOR
      2.times { place_single_stair(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers, 1) }
    end

    if floor > MIN_STRUCT_FLOOR
      place_single_stair(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers, -1)
    end
  end

  def place_single_stair(x, y, bw, bh, struct_id, floor, col_dividers, row_dividers, delta)
    map = @tilemap[floor]
    20.times do
      tx = x + 2 + rand(bw - 5)
      ty = y + 2 + rand(bh - 4)
      lx = tx - x
      ly = ty - y
      next if col_dividers.include?(lx) || col_dividers.include?(lx + 1)
      next if row_dividers.include?(ly)
      next if tx + 1 >= x + bw - 1
      next if map[ty][tx] != :floor || map[ty][tx + 1] != :floor

      tile = delta == 1 ? :stair_up : :stair_dn
      map[ty][tx]     = tile
      map[ty][tx + 1] = tile

      @stair_data[[floor, tx,     ty]] = { delta: delta, exit_dx: 1, exit_dy: 0, is_exit: false }
      @stair_data[[floor, tx + 1, ty]] = { delta: delta, exit_dx: 1, exit_dy: 0, is_exit: true  }

      next_floor = floor + delta
      place_structure(x, y, bw, bh, struct_id, next_floor, 1)

      nmap     = @tilemap[next_floor]
      ret_tile = delta == 1 ? :stair_dn : :stair_up
      nmap[ty][tx]     = ret_tile
      nmap[ty][tx + 1] = ret_tile
      @stair_data[[next_floor, tx + 1, ty]] = { delta: -delta, exit_dx: -1, exit_dy: 0, is_exit: false }
      @stair_data[[next_floor, tx,     ty]] = { delta: -delta, exit_dx: -1, exit_dy: 0, is_exit: true  }

      return
    end
  end

  def band_ranges(size, dividers)
    bounds = [0] + dividers + [size - 1]
    ranges = []
    bounds.each_cons(2) { |a, b| ranges << ((a + 1)..(b - 1)) if b - a > 1 }
    ranges
  end
end
