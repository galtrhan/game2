module GameCollision
  include GameConstants
  def rects_overlap?(ax, ay, aw, ah, bx, by, bw, bh)
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
  end

  def blocked_rect?(x, y, w, h)
    tile_hit = [
      [x,         y        ],
      [x + w - 1, y        ],
      [x,         y + h - 1],
      [x + w - 1, y + h - 1]
    ].any? { |cx, cy| t = map_tile((cx / TILE_SIZE).to_i, (cy / TILE_SIZE).to_i); t == :block || t == :locked_door }
    return true if tile_hit

    if @mode == :on_foot && @vehicle && @vehicle[:collidable]
      return rects_overlap?(x, y, w, h, @vehicle[:x], @vehicle[:y], VEHICLE_W, VEHICLE_H)
    end

    false
  end
end
