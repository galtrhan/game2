module GameInteraction
  def door_tile?(tx, ty)
    t = map_tile(tx, ty)
    t == :door || t == :locked_door
  end

  # Tile to toggle with E: underfoot, else tile in facing direction, else any adjacent (for locked doors you cannot stand on).
  def door_interact_target
    tx = @player[:tx]
    ty = @player[:ty]
    return [tx, ty] if door_tile?(tx, ty)

    d = player_facing_delta
    if d
      ax = tx + d[0]
      ay = ty + d[1]
      return [ax, ay] if door_tile?(ax, ay)
    end

    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      ax = tx + dx
      ay = ty + dy
      return [ax, ay] if door_tile?(ax, ay)
    end
    nil
  end

  def toggle_door_at(tx, ty)
    fl = @player[:floor]
    floor_map = @tilemap[fl]
    return unless floor_map && floor_map[ty]

    t = floor_map[ty][tx]
    return unless t == :door || t == :locked_door

    floor_map[ty][tx] = t == :door ? :locked_door : :door
  end

  private

  def player_facing_delta
    case @player[:facing]
    when :right then [1, 0]
    when :left then [-1, 0]
    when :up then [0, 1]
    when :down then [0, -1]
    end
  end
end
