module GameCollision
  include GameConstants

  CORNER_RADIUS = 8

  def rects_overlap?(ax, ay, aw, ah, bx, by, bw, bh)
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
  end

  # On-foot player: circle centered in the PLAYER_W × PLAYER_H box, radius PLAYER_RADIUS.
  def blocked_player_circle?(x, y, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    cx = x + PLAYER_W * 0.5
    cy = y + PLAYER_H * 0.5
    r  = PLAYER_RADIUS

    tx_lo = ((cx - r) / TILE_SIZE).floor.clamp(0, TILES_X - 1)
    tx_hi = ((cx + r) / TILE_SIZE).ceil.clamp(0, TILES_X - 1)
    ty_lo = ((cy - r) / TILE_SIZE).floor.clamp(0, TILES_Y - 1)
    ty_hi = ((cy + r) / TILE_SIZE).ceil.clamp(0, TILES_Y - 1)

    ty_lo.upto(ty_hi) do |ty|
      tx_lo.upto(tx_hi) do |tx|
        next unless circle_aabb_overlap?(
          cx, cy, r,
          tx * TILE_SIZE, ty * TILE_SIZE, TILE_SIZE, TILE_SIZE
        )
        return true if tile_movement_blocked?(tx, ty, floor)
      end
    end

    if @mode == :on_foot && @vehicle && @vehicle[:collidable]
      return true if circle_aabb_overlap?(cx, cy, r, @vehicle[:x], @vehicle[:y], VEHICLE_W, VEHICLE_H)
    end

    false
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

  def circle_aabb_overlap?(cx, cy, r, ax, ay, aw, ah)
    px = cx.clamp(ax, ax + aw)
    py = cy.clamp(ay, ay + ah)
    dx = cx - px
    dy = cy - py
    dx * dx + dy * dy <= r * r
  end

  def tile_movement_blocked?(ctx, cty, floor)
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

  def movement_corner_blocked?(ctx, cty, floor)
    tile_movement_blocked?(ctx, cty, floor)
  end
end
