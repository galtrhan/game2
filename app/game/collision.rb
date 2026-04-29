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
    ].any? { |cx, cy| t = map_tile((cx / TILE_SIZE).to_i, (cy / TILE_SIZE).to_i, floor); t == :block || t == :locked_door }
    return true if tile_hit

    if @mode == :on_foot && @vehicle && @vehicle[:collidable]
      return rects_overlap?(x, y, w, h, @vehicle[:x], @vehicle[:y], VEHICLE_W, VEHICLE_H)
    end

    false
  end
end
