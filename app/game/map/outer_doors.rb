module GameMap
  # Perimeter doors (building shell) — visible from outside; interior doors stay hidden until you enter.
  def rebuild_outer_door_cells
    @outer_door_cells = {}
    return unless @structure_map && @tilemap

    @structure_map.each_key do |floor|
      smap = @structure_map[floor]
      next unless smap

      by_sid = Hash.new { |h, k| h[k] = [] }
      TILES_Y.times do |ty|
        TILES_X.times do |tx|
          sid = smap[ty][tx]
          by_sid[sid] << [tx, ty] if sid
        end
      end

      by_sid.each_value do |positions|
        next if positions.empty?

        txs = positions.map(&:first)
        tys = positions.map(&:last)
        minx, maxx = txs.min, txs.max
        miny, maxy = tys.min, tys.max

        positions.each do |tx, ty|
          t = map_tile(tx, ty, floor)
          next unless t == :door || t == :locked_door

          on_perimeter = tx == minx || tx == maxx || ty == miny || ty == maxy
          @outer_door_cells[[floor, tx, ty]] = true if on_perimeter
        end
      end
    end
  end

  def outer_door_cell?(floor, tx, ty)
    @outer_door_cells && @outer_door_cells[[floor, tx, ty]]
  end
end
