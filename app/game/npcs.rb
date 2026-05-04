module GameNpcs
  include GameConstants

  WANDER_DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze
  LOS_RECHECK_INTERVAL = 4

  def spawn_npc_fleet
    @npcs = []
    @inhabited_structs = {}
    return unless @tilemap && @player && @struct_bounds

    @struct_bounds.each_key do |sid|
      inhabited = rand < NPC_INHABITED_PROBABILITY
      @inhabited_structs[sid] = inhabited
      next unless inhabited

      spawn_npcs_inside_building(sid, 0, npc_per_floor_count)
      spawn_npcs_outside_building(sid, npc_outside_count)
    end
  end

  # Called from generate_struct_floor_if_needed when a new upper/lower floor
  # of a building is generated on demand.
  def spawn_npcs_for_new_floor(struct_id, floor)
    return unless @inhabited_structs && @inhabited_structs[struct_id]
    return unless @npcs && @struct_bounds && @struct_bounds[struct_id]

    spawn_npcs_inside_building(struct_id, floor, npc_per_floor_count)
  end

  def update_npcs
    return if @paused || !@npcs

    player_floor = @player[:floor]
    container    = current_player_container_struct_id
    px = @player[:x]
    py = @player[:y]
    r2 = NPC_UPDATE_RADIUS_PX * NPC_UPDATE_RADIUS_PX

    @npcs.each_with_index do |n, i|
      next unless n[:floor] == player_floor
      next unless n[:home_struct_id] == container
      dx = n[:x] - px
      dy = n[:y] - py
      next if dx * dx + dy * dy > r2
      update_one_npc(n, i)
    end
  end

  # struct_id at the player's tile, or nil if outdoors. Used to gate which NPCs
  # get rendered/updated — players can only see/interact with NPCs in the same
  # container (same building floor, or both outdoors).
  def current_player_container_struct_id
    return nil unless @player && @structure_map
    fl = @player[:floor]
    smap = @structure_map[fl]
    return nil unless smap
    tx = @player[:tx]
    ty = @player[:ty]
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = smap[cx * CHUNK_STRIDE + cy]
    return nil unless chunk
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)]
  end

  private

  def npc_per_floor_count
    NPC_PER_FLOOR_MIN + rand(NPC_PER_FLOOR_MAX - NPC_PER_FLOOR_MIN + 1)
  end

  def npc_outside_count
    NPC_OUTSIDE_MIN + rand(NPC_OUTSIDE_MAX - NPC_OUTSIDE_MIN + 1)
  end

  def make_npc(x, y, floor, home_struct_id = nil)
    { x: x, y: y, floor: floor, mode: :wander, wander_timer: 40 + rand(61),
      home_struct_id: home_struct_id }
  end

  def npc_separation_ok?(x, y, floor)
    cx = x + PLAYER_W * 0.5
    cy = y + PLAYER_H * 0.5
    min_d2 = (TILE_SIZE * 2) * (TILE_SIZE * 2)
    @npcs.none? do |o|
      next false unless o[:floor] == floor
      ox = o[:x] + PLAYER_W * 0.5
      oy = o[:y] + PLAYER_H * 0.5
      dx = cx - ox
      dy = cy - oy
      dx * dx + dy * dy < min_d2
    end
  end

  def player_too_close?(tx, ty, floor)
    return false unless @player && @player[:floor] == floor
    dx = tx - @player[:tx]
    dy = ty - @player[:ty]
    dx * dx + dy * dy < NPC_MIN_SPAWN_TILES_FROM_PLAYER * NPC_MIN_SPAWN_TILES_FROM_PLAYER
  end

  def tile_in_struct?(floor, tx, ty, sid)
    smap = @structure_map[floor]
    return false unless smap
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = smap[cx * CHUNK_STRIDE + cy]
    return false unless chunk
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)] == sid
  end

  def tile_outside_all_structs?(floor, tx, ty)
    smap = @structure_map[floor]
    return true unless smap
    cx = tx.div(CHUNK_SIZE)
    cy = ty.div(CHUNK_SIZE)
    chunk = smap[cx * CHUNK_STRIDE + cy]
    return true unless chunk
    chunk[(ty - cy * CHUNK_SIZE) * CHUNK_SIZE + (tx - cx * CHUNK_SIZE)].nil?
  end

  def spawn_npcs_inside_building(sid, floor, count)
    bb = @struct_bounds[sid]
    return unless bb

    count.times do
      NPC_SPAWN_TRIES.times do
        tx = bb[:x] + 1 + rand(bb[:bw] - 2)
        ty = bb[:y] + 1 + rand(bb[:bh] - 2)
        next unless map_tile(tx, ty, floor) == :floor
        next unless tile_in_struct?(floor, tx, ty, sid)
        next if player_too_close?(tx, ty, floor)

        x = tx * TILE_SIZE + 2
        y = ty * TILE_SIZE + 2
        next if blocked_npc_circle?(x, y, floor)
        next unless npc_separation_ok?(x, y, floor)

        @npcs << make_npc(x, y, floor, sid)
        break
      end
    end
  end

  def spawn_npcs_outside_building(sid, count)
    bb = @struct_bounds[sid]
    return unless bb

    r     = NPC_OUTSIDE_RADIUS_TILES
    x_min = bb[:x] - r
    x_max = bb[:x] + bb[:bw] + r
    y_min = bb[:y] - r
    y_max = bb[:y] + bb[:bh] + r
    span_x = x_max - x_min
    span_y = y_max - y_min

    count.times do
      NPC_SPAWN_TRIES.times do
        tx = x_min + rand(span_x)
        ty = y_min + rand(span_y)
        next unless tile_outside_all_structs?(0, tx, ty)
        next unless map_tile(tx, ty, 0) == :floor
        next if player_too_close?(tx, ty, 0)

        x = tx * TILE_SIZE + 2
        y = ty * TILE_SIZE + 2
        next if blocked_npc_circle?(x, y, 0)
        next unless npc_separation_ok?(x, y, 0)

        @npcs << make_npc(x, y, 0)
        break
      end
    end
  end

  def update_one_npc(n, idx)
    if n[:floor] == @player[:floor]
      if npc_sees_player_cached?(n, idx)
        n[:mode] = :chase
      elsif n[:mode] == :chase
        n[:mode] = :wander
        n[:wander_timer] = 40 + rand(61)
      end
    elsif n[:mode] == :chase
      n[:mode] = :wander
      n[:wander_timer] = 40 + rand(61)
    end

    if n[:mode] == :chase && n[:floor] == @player[:floor]
      npc_step_chase(n, idx)
    else
      npc_step_wander(n, idx)
    end
  end

  def npc_step_chase(n, idx)
    x0 = n[:x] + PLAYER_W * 0.5
    y0 = n[:y] + PLAYER_H * 0.5
    x1 = @player[:x] + PLAYER_W * 0.5
    y1 = @player[:y] + PLAYER_H * 0.5
    dx = x1 - x0
    dy = y1 - y0

    if idx.even?
      npc_try_axis(n, idx, NPC_SPEED * (dx <=> 0), 0) if dx.abs >= 0.5
      npc_try_axis(n, idx, 0, NPC_SPEED * (dy <=> 0)) if dy.abs >= 0.5
    else
      npc_try_axis(n, idx, 0, NPC_SPEED * (dy <=> 0)) if dy.abs >= 0.5
      npc_try_axis(n, idx, NPC_SPEED * (dx <=> 0), 0) if dx.abs >= 0.5
    end
  end

  def npc_sees_player_cached?(n, idx)
    tick = args.state.tick_count
    if n[:los_tick] && (tick - n[:los_tick]) < LOS_RECHECK_INTERVAL
      return n[:los_seen]
    end

    seen = npc_sees_player?(n)
    n[:los_tick] = tick - (idx % LOS_RECHECK_INTERVAL)
    n[:los_seen] = seen
    seen
  end

  def npc_sees_player?(n)
    return false unless @player && n[:floor] == @player[:floor]

    x0 = n[:x] + PLAYER_W * 0.5
    y0 = n[:y] + PLAYER_H * 0.5
    x1 = @player[:x] + PLAYER_W * 0.5
    y1 = @player[:y] + PLAYER_H * 0.5
    dx = x1 - x0
    dy = y1 - y0
    d2 = dx * dx + dy * dy
    return false if d2 > NPC_DETECT_RADIUS_PX * NPC_DETECT_RADIUS_PX

    steps = NPC_LOS_STEPS
    (steps + 1).times do |i|
      t = i / steps.to_f
      wx = x0 + dx * t
      wy = y0 + dy * t
      tx = (wx / TILE_SIZE).floor
      ty = (wy / TILE_SIZE).floor
      return false if tile_npc_blocked?(tx, ty, n[:floor])
    end
    true
  end

  def npc_step_wander(n, idx)
    n[:wander_timer] -= 1
    if n[:wander_timer] <= 0
      d = WANDER_DIRS[rand(WANDER_DIRS.length)]
      n[:wander_dx] = d[0]
      n[:wander_dy] = d[1]
      n[:wander_timer] = 40 + rand(61)
    end

    dx = (n[:wander_dx] || 0) * NPC_SPEED
    dy = (n[:wander_dy] || 0) * NPC_SPEED
    npc_try_axis(n, idx, dx, 0) if dx != 0
    npc_try_axis(n, idx, 0, dy) if dy != 0
  end

  def npc_try_axis(n, idx, dx, dy)
    return if dx == 0 && dy == 0

    nx = n[:x] + dx
    ny = n[:y] + dy

    unless blocked_npc_circle?(nx, ny, n[:floor], exclude_npc_index: idx)
      n[:x] = nx
      n[:y] = ny
    end
  end
end
