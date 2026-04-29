module GameCollision
  include GameConstants

  CORNER_RADIUS = 8

  def rects_overlap?(ax, ay, aw, ah, bx, by, bw, bh)
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
  end

  def blocked_rect?(x, y, w, h, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    r = CORNER_RADIUS
    x0 = x + r
    y0 = y + r
    x1 = x + w - 1 - r
    y1 = y + h - 1 - r

    return true if movement_corner_blocked?((x0 / TILE_SIZE).to_i, (y0 / TILE_SIZE).to_i, floor)
    return true if movement_corner_blocked?((x1 / TILE_SIZE).to_i, (y0 / TILE_SIZE).to_i, floor)
    return true if movement_corner_blocked?((x0 / TILE_SIZE).to_i, (y1 / TILE_SIZE).to_i, floor)
    return true if movement_corner_blocked?((x1 / TILE_SIZE).to_i, (y1 / TILE_SIZE).to_i, floor)

    if @mode == :on_foot && @vehicle && @vehicle[:collidable]
      return rects_overlap?(x, y, w, h, @vehicle[:x], @vehicle[:y], VEHICLE_W, VEHICLE_H)
    end

    false
  end

  private

  def movement_corner_blocked?(ctx, cty, floor)
    t = map_tile(ctx, cty, floor)
    case t
    when :block
      true
    when :locked_door
      !(@mode == :on_foot && @player && ctx == @player[:tx] && cty == @player[:ty])
    else
      false
    end
  end
end
