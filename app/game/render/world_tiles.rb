module GameRenderer
  def render_world_tiles
    cam_x_i = @cam_x.to_i
    cam_y_i = @cam_y.to_i
    vw = viewport_w
    vh = viewport_h
    # Integer tile indices (same as original); avoid Float/Rational from division + clamp — Integer#upto needs Integer ends.
    tx_min = (cam_x_i / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    tx_max = ((cam_x_i + vw) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    ty_min = (cam_y_i / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)
    ty_max = ((cam_y_i + vh) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    cur_floor = @player[:floor]
    floor_map = @tilemap[cur_floor]
    floor_sm  = @structure_map && @structure_map[cur_floor]
    outer     = @outer_door_cells
    stairs    = @stair_data
    z = effective_zoom
    tw = TILE_SIZE * z
    half_tile = tw / 2
    label_px = (11 * z).to_i

    player_s = if @mode == :on_foot && floor_sm
                 row = floor_sm[@player[:ty]]
                 row && row[@player[:tx]]
               end

    ty_min.upto(ty_max) do |ty|
      map_row = floor_map && floor_map[ty]
      sm_row  = floor_sm && floor_sm[ty]

      tx_min.upto(tx_max) do |tx|
        sx = (tx * TILE_SIZE - cam_x_i) * z
        sy = (ty * TILE_SIZE - cam_y_i) * z

        tile = map_row ? map_row[tx] : :block
        tile_s = sm_row && sm_row[tx]

        # Outside: hide structure as wall, except perimeter doors (still see entrances).
        show = if player_s.nil?
          if !tile_s.nil? && (tile == :door || tile == :locked_door) && outer&.[]([cur_floor, tx, ty])
            tile
          elsif tile_s.nil?
            tile
          else
            :block
          end
        elsif tile_s == player_s
          tile
        elsif tile_s.nil?
          tile
        else
          :block
        end

        if show == :block
          args.outputs.solids << { x: sx, y: sy, w: tw, h: tw, r: 90, g: 90, b: 90 }
        elsif show == :door
          args.outputs.solids << { x: sx, y: sy, w: tw, h: tw, r: 200, g: 100, b: 50 }
        elsif show == :locked_door
          args.outputs.solids << { x: sx, y: sy, w: tw, h: tw, r: 160, g: 30, b: 30 }
        elsif show == :stair_up
          args.outputs.solids << { x: sx, y: sy, w: tw, h: tw, r: 50, g: 210, b: 180 }
        elsif show == :stair_dn
          args.outputs.solids << { x: sx, y: sy, w: tw, h: tw, r: 210, g: 160, b: 50 }
        end

        if show == :stair_up || show == :stair_dn
          sd = stairs && stairs[[cur_floor, tx, ty]]
          if sd
            target_floor = cur_floor + sd[:delta]
            args.outputs.labels << {
              x: sx + half_tile,
              y: sy + half_tile,
              text: target_floor.to_s,
              font: UI_FONT,
              size_px: label_px,
              anchor_x: 0.5, anchor_y: 0.5,
              r: 255, g: 255, b: 255
            }
          end
        end

        if !player_s.nil? && tile_s.nil?
          args.outputs.solids << { x: sx, y: sy, w: tw, h: tw, r: 0, g: 0, b: 0, a: 128 }
        end

        args.outputs.borders << { x: sx, y: sy, w: tw, h: tw, r: 150, g: 150, b: 150, a: 90 } if @debug
      end
    end
  end
end
