module GameMap
  # Perimeter doors (building shell) — visible from outside; interior doors stay hidden until you enter.
  # Used after loading tilemap from JSON (procedural gen marks doors during placement instead).
  def rebuild_outer_door_cells
    @outer_door_cells = {}
    return unless @structure_map && @tilemap

    @structure_map.each_key do |floor|
      smap = @structure_map[floor]
      tmap = @tilemap[floor]
      next unless smap && tmap

      minmax = {} # sid => [minx, maxx, miny, maxy]
      TILES_Y.times do |ty|
        row_s = smap[ty]
        TILES_X.times do |tx|
          sid = row_s[tx]
          next unless sid
          b = (minmax[sid] ||= [tx, tx, ty, ty])
          b[0] = tx if tx < b[0]
          b[1] = tx if tx > b[1]
          b[2] = ty if ty < b[2]
          b[3] = ty if ty > b[3]
        end
      end

      TILES_Y.times do |ty|
        row_t = tmap[ty]
        row_s = smap[ty]
        TILES_X.times do |tx|
          tile = row_t[tx]
          next unless tile == :door || tile == :locked_door

          sid = row_s[tx]
          next unless sid

          bounds = minmax[sid]
          next unless bounds

          minx, maxx, miny, maxy = bounds
          if tx == minx || tx == maxx || ty == miny || ty == maxy
            @outer_door_cells[[floor, tx, ty]] = true
          end
        end
      end
    end
  end

  def outer_door_cell?(floor, tx, ty)
    @outer_door_cells && @outer_door_cells[[floor, tx, ty]]
  end
end
