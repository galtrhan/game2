module GameRenderer
  def render_world_tiles
    tx_min = (@cam_x.to_i / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    tx_max = ((@cam_x.to_i + SCREEN_W) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    ty_min = (@cam_y.to_i / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)
    ty_max = ((@cam_y.to_i + SCREEN_H) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    cur_floor = @player[:floor]
    player_s = if @mode == :on_foot && @structure_map
                 sm = @structure_map[cur_floor]
                 sm && sm[@player[:ty]] && sm[@player[:ty]][@player[:tx]]
               end

    ty_min.upto(ty_max) do |ty|
      tx_min.upto(tx_max) do |tx|
        sx     = tx * TILE_SIZE - @cam_x
        sy     = ty * TILE_SIZE - @cam_y
        tile   = map_tile(tx, ty, cur_floor)
        sm     = @structure_map && @structure_map[cur_floor]
        tile_s = sm && sm[ty] && sm[ty][tx]

        # Outside: hide structure as wall, except perimeter doors (still see entrances).
        show = if player_s.nil?
          if !tile_s.nil? && (tile == :door || tile == :locked_door) && outer_door_cell?(cur_floor, tx, ty)
            tile
          elsif tile_s.nil?
            tile
          else
            :block
          end
        elsif tile_s == player_s
          tile          # current structure → show normally
        elsif tile_s.nil?
          tile          # exterior → show (dimmed below)
        else
          :block        # different structure → hidden
        end

        if show == :block
          args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 90, g: 90, b: 90 }
        elsif show == :door
          args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 200, g: 100, b: 50 }
        elsif show == :locked_door
          args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 160, g: 30, b: 30 }
        elsif show == :stair_up
          args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 50, g: 210, b: 180 }
        elsif show == :stair_dn
          args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 210, g: 160, b: 50 }
        end

        if show == :stair_up || show == :stair_dn
          sd = @stair_data && @stair_data[[cur_floor, tx, ty]]
          if sd
            target_floor = cur_floor + sd[:delta]
            args.outputs.labels << {
              x: sx + (TILE_SIZE * 0.5).to_i,
              y: sy + (TILE_SIZE * 0.5).to_i,
              text: target_floor.to_s,
              font: UI_FONT,
              size_px: 11,
              anchor_x: 0.5, anchor_y: 0.5,
              r: 255, g: 255, b: 255
            }
          end
        end

        # Inside: dim exterior world with 50% black overlay
        if !player_s.nil? && tile_s.nil?
          args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 0, g: 0, b: 0, a: 128 }
        end

        args.outputs.borders << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 150, g: 150, b: 150, a: 90 } if @debug
      end
    end
  end
end
