module GameCollision
  include GameConstants

  CORNER_RADIUS = 8

  def rects_overlap?(ax, ay, aw, ah, bx, by, bw, bh)
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
  end

  def blocked_rect?(x, y, w, h, floor = nil)
    floor ||= @player ? @player[:floor] : 0
    r = CORNER_RADIUS
    tile_hit = [
      [x + r,         y + r        ],
      [x + w - 1 - r, y + r        ],
      [x + r,         y + h - 1 - r],
      [x + w - 1 - r, y + h - 1 - r]
    ].any? do |cx, cy|
      ctx = (cx / TILE_SIZE).to_i
      cty = (cy / TILE_SIZE).to_i
      t = map_tile(ctx, cty, floor)
      case t
      when :block
        true
      when :locked_door
        # Standing on a door then locking it traps the hitbox on locked_door; allow leaving that tile only.
        next false if @mode == :on_foot && @player && ctx == @player[:tx] && cty == @player[:ty]

        true
      else
        false
      end
    end
    return true if tile_hit

    if @mode == :on_foot && @vehicle && @vehicle[:collidable]
      return rects_overlap?(x, y, w, h, @vehicle[:x], @vehicle[:y], VEHICLE_W, VEHICLE_H)
    end

    false
  end
end
