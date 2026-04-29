module GameNpcs
  include GameConstants

  def spawn_npc_fleet
    @npcs = []
    return unless @tilemap && @player

    px = @player[:tx]
    py = @player[:ty]
    min_d2 = NPC_MIN_SPAWN_TILES_FROM_PLAYER * NPC_MIN_SPAWN_TILES_FROM_PLAYER
    area   = CHUNK_SIZE * (INITIAL_CHUNK_RADIUS * 2 + 1)

    NPC_COUNT.times do
      placed = false
      NPC_SPAWN_TRIES.times do
        tx = rand(area)
        ty = rand(area)
        next unless map_tile(tx, ty, 0) == :floor

        d2 = (tx - px) * (tx - px) + (ty - py) * (ty - py)
        next if d2 < min_d2

        x = tx * TILE_SIZE + 2
        y = ty * TILE_SIZE + 2
        next if blocked_npc_circle?(x, y, 0)

        ok = @npcs.none? do |o|
          ox = o[:x] + PLAYER_W * 0.5
          oy = o[:y] + PLAYER_H * 0.5
          dx = (x + PLAYER_W * 0.5) - ox
          dy = (y + PLAYER_H * 0.5) - oy
          dx * dx + dy * dy < (TILE_SIZE * 2) * (TILE_SIZE * 2)
        end
        next unless ok

        @npcs << {
          x: x, y: y, floor: 0,
          mode: :wander,
          wander_timer: 40 + rand(61)
        }
        placed = true
        break
      end
      break unless placed
    end
  end

  def update_npcs
    return if @paused || !@npcs

    @npcs.each_with_index { |n, i| update_one_npc(n, i) }
  end

  private

  def update_one_npc(n, idx)
    if n[:floor] == @player[:floor]
      if npc_sees_player?(n)
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
      dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]]
      d = dirs[rand(dirs.length)]
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
