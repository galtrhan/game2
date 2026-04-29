module GameMap
  def generate_map
    map_generation_begin!
    generate_initial_chunks
    @tilemap
  end

  def map_generation_begin!
    @outer_door_cells        = {}
    @tilemap                 = {}
    @structure_map           = {}
    @stair_data              = {}
    @generated_struct_floors = {}
    @floor_defaults          = {}
    @tile_mutations          = {}
    @gen_done                = {}   # [cx, cy] => true  (floor-0 chunks)
    @gen_queue               = []   # [cx, cy] pairs queued for background gen
    @gen_queued              = {}   # [cx, cy] => true  (fast membership check)
    # Deferred floor generation: [struct_id, floor] => {bx, by, bw, bh, return_stairs:[]}
    @pending_struct_floors   = {}
    init_floor(0, :floor)
  end

  # Generate a structure's non-zero floor on demand (called when player steps onto stair exit).
  # Idempotent — safe to call multiple times.
  def generate_struct_floor_if_needed(struct_id, target_floor)
    return if @generated_struct_floors[[struct_id, target_floor]]
    pending = @pending_struct_floors[[struct_id, target_floor]]
    return unless pending

    # Deterministic seed per struct+floor, independent of chunk RNG sequence.
    srand(@map_seed ^ (struct_id * 0x9e3779b9 & 0xffffffff) ^ (target_floor * 0x6c62272e & 0xffffffff))
    place_structure(pending[:bx], pending[:by], pending[:bw], pending[:bh], struct_id, target_floor, 1)

    # Place the explicit return stairs back to the originating floor.
    pending[:return_stairs].each do |rs|
      ret_tile = rs[:return_delta] == 1 ? :stair_up : :stair_dn
      set_tile(target_floor, rs[:tx],     rs[:ty], ret_tile)
      set_tile(target_floor, rs[:tx] + 1, rs[:ty], ret_tile)
      stair_base = { struct_id: struct_id,
                     bx: pending[:bx], by: pending[:by], bw: pending[:bw], bh: pending[:bh] }
      @stair_data[[target_floor, rs[:tx] + 1, rs[:ty]]] =
        stair_base.merge(delta: rs[:return_delta], exit_dx: -1, exit_dy: 0, is_exit: false)
      @stair_data[[target_floor, rs[:tx],      rs[:ty]]] =
        stair_base.merge(delta: rs[:return_delta], exit_dx: -1, exit_dy: 0, is_exit: true)
    end
  end

  # Enqueue any floor-0 chunks within the camera viewport + buffer that haven't
  # been generated yet.  Called every tick from update_camera.
  def enqueue_chunks_around_camera
    return unless @cam_x && @cam_y && @tilemap

    vw  = viewport_w
    vh  = viewport_h
    buf = BUFFER_CHUNKS * CHUNK_SIZE * TILE_SIZE

    cx_min = ((@cam_x - buf)      / (CHUNK_SIZE * TILE_SIZE)).floor
    cx_max = ((@cam_x + vw + buf) / (CHUNK_SIZE * TILE_SIZE)).floor
    cy_min = ((@cam_y - buf)      / (CHUNK_SIZE * TILE_SIZE)).floor
    cy_max = ((@cam_y + vh + buf) / (CHUNK_SIZE * TILE_SIZE)).floor

    cy_min.upto(cy_max) do |cy|
      cx_min.upto(cx_max) do |cx|
        key = [cx, cy]
        next if @gen_done[key] || @gen_queued[key]
        @gen_queue  << key
        @gen_queued[key] = true
      end
    end
  end

  # Process up to +budget+ queued chunks; returns true when the queue is empty.
  def map_generation_step!(budget)
    budget.times do
      return true if @gen_queue.empty?
      key    = @gen_queue.shift
      cx, cy = key
      @gen_queued.delete(key)
      generate_chunk(cx, cy) unless @gen_done[key]
    end
    @gen_queue.empty?
  end

  private

  def generate_initial_chunks
    generate_initial_chunks_around(0, 0)
  end

  def generate_initial_chunks_around(ocx, ocy)
    r = INITIAL_CHUNK_RADIUS
    ((ocy - r)..(ocy + r)).each do |cy|
      ((ocx - r)..(ocx + r)).each do |cx|
        generate_chunk(cx, cy)
      end
    end
  end

  # Generate one floor-0 chunk — floor 0 only, no recursive upper/lower floors.
  def generate_chunk(cx, cy)
    return if @gen_done[[cx, cy]]
    @gen_done[[cx, cy]] = true

    srand(@map_seed ^ chunk_hash(cx, cy))

    ox = cx * CHUNK_SIZE   # tile-space origin of this chunk
    oy = cy * CHUNK_SIZE

    base = chunk_struct_base(cx, cy)
    idx  = 0

    sx = 1
    while sx < CHUNK_SIZE - 10
      bw = [10 + rand(9), CHUNK_SIZE - 1 - sx].min
      break if bw < 10

      sy = 1
      while sy < CHUNK_SIZE - 10
        bh = [10 + rand(9), CHUNK_SIZE - 1 - sy].min
        break if bh < 10

        place_structure(ox + sx, oy + sy, bw, bh, base + idx, 0, 0)
        idx += 1
        sy += bh + 2 + rand(19)
      end

      sx += bw + 2 + rand(19)
    end
  end

  # Deterministic hash mixing chunk coords into a seed offset.
  def chunk_hash(cx, cy)
    ncx = cx < 0 ? (cx + (1 << 31)) : cx
    ncy = cy < 0 ? (cy + (1 << 31)) : cy
    ((ncx * 0x9e3779b9) ^ (ncy * 0x6c62272e)) & 0xffffffff
  end

  # Bijection (Z, Z) → N that assigns 100 unique struct-id slots per chunk.
  def chunk_struct_base(cx, cy)
    ecx = cx >= 0 ? cx * 2 : (-cx * 2 - 1)
    ecy = cy >= 0 ? cy * 2 : (-cy * 2 - 1)
    n   = ecx + ecy
    (n * (n + 1) / 2 + ecy) * 100
  end

  def mark_outer_door_if_needed(floor, tx, ty, sx, sy, bw, bh)
    return unless tx == sx || tx == sx + bw - 1 || ty == sy || ty == sy + bh - 1

    @outer_door_cells[[floor, tx, ty]] = true
  end

  def init_floor(floor, default_tile = :floor)
    @floor_defaults[floor] = default_tile
    @tilemap[floor]       ||= {}
    @structure_map[floor] ||= {}
  end

  def place_structure(x, y, bw, bh, struct_id, floor, depth)
    return if @generated_struct_floors[[struct_id, floor]]
    @generated_struct_floors[[struct_id, floor]] = true

    init_floor(floor, :block) unless @tilemap[floor]

    bw.times { |dx| bh.times { |dy| set_smap(floor, x + dx, y + dy, struct_id) } }

    bw.times do |dx|
      bh.times do |dy|
        set_tile(floor, x + dx, y + dy,
                 (dx == 0 || dx == bw - 1 || dy == 0 || dy == bh - 1) ? :block : :floor)
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

    col_dividers.each { |dx| (1..bh - 2).each { |dy| set_tile(floor, x + dx, y + dy, :block) } }
    row_dividers.each { |dy| (1..bw - 2).each { |dx| set_tile(floor, x + dx, y + dy, :block) } }

    row_bands = band_ranges(bh, row_dividers)
    col_bands = band_ranges(bw, col_dividers)

    col_dividers.each do |dx|
      row_bands.each do |band|
        door_dy = band.to_a[rand(band.size)]
        ty = y + door_dy
        tx = x + dx
        set_tile(floor, tx, ty, rand(2) == 0 ? :locked_door : :door)
        mark_outer_door_if_needed(floor, tx, ty, x, y, bw, bh)
      end
    end

    row_dividers.each do |dy|
      col_bands.each do |band|
        door_dx = band.to_a[rand(band.size)]
        ty = y + dy
        tx = x + door_dx
        set_tile(floor, tx, ty, rand(2) == 0 ? :locked_door : :door)
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
        set_tile(floor, dt[0], dt[1], :door)
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
    20.times do
      tx = x + 2 + rand(bw - 5)
      ty = y + 2 + rand(bh - 4)
      lx = tx - x
      ly = ty - y
      next if col_dividers.include?(lx) || col_dividers.include?(lx + 1)
      next if row_dividers.include?(ly)
      next if tx + 1 >= x + bw - 1
      next if get_tile_raw(floor, tx, ty) != :floor || get_tile_raw(floor, tx + 1, ty) != :floor

      tile = delta == 1 ? :stair_up : :stair_dn
      set_tile(floor, tx,     ty, tile)
      set_tile(floor, tx + 1, ty, tile)

      stair_base = { struct_id: struct_id, bx: x, by: y, bw: bw, bh: bh }
      @stair_data[[floor, tx,     ty]] = stair_base.merge(delta: delta, exit_dx: 1, exit_dy: 0, is_exit: false)
      @stair_data[[floor, tx + 1, ty]] = stair_base.merge(delta: delta, exit_dx: 1, exit_dy: 0, is_exit: true)

      # Record the adjacent floor as pending — generated on demand when player enters.
      next_floor = floor + delta
      rec = (@pending_struct_floors[[struct_id, next_floor]] ||=
               { bx: x, by: y, bw: bw, bh: bh, return_stairs: [] })
      rec[:return_stairs] << { tx: tx, ty: ty, return_delta: -delta }

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
