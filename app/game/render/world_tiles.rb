module GameRenderer
  def render_world_tiles
    cam_x_i = @cam_x.to_i
    cam_y_i = @cam_y.to_i
    vw = viewport_w
    vh = viewport_h
    tx_min = (cam_x_i / TILE_SIZE).floor
    tx_max = ((cam_x_i + vw) / TILE_SIZE).ceil
    ty_min = (cam_y_i / TILE_SIZE).floor
    ty_max = ((cam_y_i + vh) / TILE_SIZE).ceil

    cur_floor = @player[:floor]
    floor_map = @tilemap[cur_floor]
    floor_sm  = @structure_map && @structure_map[cur_floor]
    floor_def = @floor_defaults ? (@floor_defaults[cur_floor] || :floor) : :floor
    outer     = @outer_door_cells
    stairs    = @stair_data
    z         = effective_zoom
    tw        = TILE_SIZE * z
    half_tile = tw / 2
    label_px  = (11 * z).to_i

    player_s = if @mode == :on_foot && floor_sm
                 ptx = @player[:tx]
                 pty = @player[:ty]
                 pcx = ptx.div(CHUNK_SIZE)
                 pcy = pty.div(CHUNK_SIZE)
                 pc  = floor_sm[pcx * CHUNK_STRIDE + pcy]
                 pc && pc[(pty - pcy * CHUNK_SIZE) * CHUNK_SIZE + (ptx - pcx * CHUNK_SIZE)]
               end

    ty_min.upto(ty_max) do |ty|
      cy = ty.div(CHUNK_SIZE)
      dy = ty - cy * CHUNK_SIZE
      # Reset chunk cache each row (cy may have changed).
      last_cx      = nil
      tile_chunk   = nil
      sm_chunk     = nil

      tx_min.upto(tx_max) do |tx|
        cx = tx.div(CHUNK_SIZE)

        # Only look up chunk arrays when cx changes (≈ once per CHUNK_SIZE tiles).
        if cx != last_cx
          last_cx    = cx
          ck         = cx * CHUNK_STRIDE + cy
          tile_chunk = floor_map && floor_map[ck]
          sm_chunk   = floor_sm  && floor_sm[ck]
        end

        dx      = tx - cx * CHUNK_SIZE
        idx     = dy * CHUNK_SIZE + dx
        tile    = tile_chunk ? (tile_chunk[idx] || floor_def) : floor_def
        tile_s  = sm_chunk  &&  sm_chunk[idx]

        sd  = nil
        scr_x = (tx * TILE_SIZE - cam_x_i) * z
        scr_y = (ty * TILE_SIZE - cam_y_i) * z

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
          args.outputs.solids << { x: scr_x, y: scr_y, w: tw, h: tw, r: 90, g: 90, b: 90 }
        elsif show == :door
          args.outputs.solids << { x: scr_x, y: scr_y, w: tw, h: tw, r: 200, g: 100, b: 50 }
        elsif show == :locked_door
          args.outputs.solids << { x: scr_x, y: scr_y, w: tw, h: tw, r: 160, g: 30, b: 30 }
        elsif show == :stair_up || show == :stair_dn
          sd = stairs && stairs[[cur_floor, tx, ty]]
          r, g, b = show == :stair_up ? [50, 210, 180] : [210, 160, 50]
          if sd && !sd[:is_exit]
            t = 0.2
            r = (r + (255 - r) * t).to_i
            g = (g + (255 - g) * t).to_i
            b = (b + (255 - b) * t).to_i
          end
          args.outputs.solids << { x: scr_x, y: scr_y, w: tw, h: tw, r: r, g: g, b: b }
        end

        if !@paused && (show == :stair_up || show == :stair_dn) && sd
          target_floor = cur_floor + sd[:delta]
          args.outputs.labels << {
            x: scr_x + half_tile, y: scr_y + half_tile,
            text: target_floor.to_s,
            font: UI_FONT, size_px: label_px,
            anchor_x: 0.5, anchor_y: 0.5,
            r: 255, g: 255, b: 255
          }
        end

        if !player_s.nil? && tile_s.nil?
          args.outputs.solids << { x: scr_x, y: scr_y, w: tw, h: tw, r: 0, g: 0, b: 0, a: 128 }
        end

        args.outputs.borders << { x: scr_x, y: scr_y, w: tw, h: tw, r: 150, g: 150, b: 150, a: 90 } if @debug
      end
    end
  end
end
