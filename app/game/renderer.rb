module GameRenderer
  include GameConstants
  def render
    args.outputs.background_color = [200, 200, 200]

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

        # Determine what to actually show
        show = if player_s.nil?
          # Outside: all structure tiles (walls, doors, interior) → hidden as wall
          tile_s.nil? ? tile : :block
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

    render_vehicle
    render_player

    args.outputs.labels << {
      x: 640, y: 710,
      text: "ESC pause  I debug#{@debug ? ' [ON]' : ''}  Floor:#{@player[:floor]}  #{@mode == :in_vehicle ? '[IN VEHICLE]' : ''}",
      size_px: 16, anchor_x: 0.5,
      r: 60, g: 60, b: 60
    }

    args.outputs.labels << {
      x: 8, y: SCREEN_H - 8,
      text: "FPS: #{args.gtk.current_framerate.to_i}",
      size_px: 14, anchor_x: 0, anchor_y: 1,
      r: 60, g: 60, b: 60
    }

    render_pause_overlay if @paused
  end

  def render_vehicle
    return unless @vehicle
    args.outputs.solids << {
      x: @vehicle[:x] - @cam_x, y: @vehicle[:y] - @cam_y,
      w: VEHICLE_W, h: VEHICLE_H,
      r: 255, g: 105, b: 180
    }
    if @debug
      args.outputs.borders << {
        x: @vehicle[:x] - @cam_x, y: @vehicle[:y] - @cam_y,
        w: VEHICLE_W, h: VEHICLE_H,
        r: 255, g: 0, b: 120
      }
    end
  end

  def render_player
    return if @mode == :in_vehicle

    px = @player[:x] - @cam_x
    py = @player[:y] - @cam_y

    args.outputs.solids << { x: px, y: py, w: PLAYER_W, h: PLAYER_H, r: 60, g: 120, b: 220 }

    half_dot = (DOT_SIZE * 0.5).to_i
    cx = px + (PLAYER_W * 0.5).to_i - half_dot
    cy = py + (PLAYER_H * 0.5).to_i - half_dot
    dot_x, dot_y = case @player[:facing]
                   when :right then [px + PLAYER_W - DOT_SIZE - 1, cy]
                   when :left  then [px + 1,                        cy]
                   when :up    then [cx, py + PLAYER_H - DOT_SIZE - 1]
                   when :down  then [cx, py + 1]
                   else             [cx, cy]
                   end
    args.outputs.solids << { x: dot_x, y: dot_y, w: DOT_SIZE, h: DOT_SIZE, r: 255, g: 255, b: 255 }

    if @debug
      args.outputs.borders << {
        x: @player[:tx] * TILE_SIZE - @cam_x, y: @player[:ty] * TILE_SIZE - @cam_y,
        w: TILE_SIZE, h: TILE_SIZE,
        r: 60, g: 180, b: 255
      }
    end

    on_door = map_tile(@player[:tx], @player[:ty]) == :door
    if near_vehicle? || on_door
      args.outputs.labels << {
        x: @player[:x] - @cam_x + (PLAYER_W * 0.5).to_i,
        y: @player[:y] - @cam_y + PLAYER_H + 10,
        text: '!', size_px: 22,
        anchor_x: 0.5, anchor_y: 0,
        r: 255, g: 220, b: 0
      }
    end
  end

  def render_pause_overlay
    args.outputs.primitives << {
      x: 0, y: 0, w: SCREEN_W, h: SCREEN_H,
      r: 0, g: 0, b: 0, a: 150
    }.solid!

    panel_w = 300
    panel_h = 310
    panel_x = ((SCREEN_W - panel_w) * 0.5).to_i
    panel_y = ((SCREEN_H - panel_h) * 0.5).to_i

    args.outputs.solids << { x: panel_x, y: panel_y, w: panel_w, h: panel_h, r: 245, g: 245, b: 245 }

    args.outputs.labels << {
      x: SCREEN_W * 0.5, y: panel_y + panel_h - 28,
      text: 'PAUSED', size_px: 22,
      anchor_x: 0.5, anchor_y: 0.5,
      r: 40, g: 40, b: 40
    }

    PAUSE_ITEMS.each_with_index do |label, i|
      active = i == @pause_selected
      by     = panel_y + panel_h - 75 - (i * 58)

      if active
        args.outputs.solids << { x: panel_x + 10, y: by - 16, w: panel_w - 20, h: 44, r: 30, g: 30, b: 30 }
      end

      args.outputs.labels << {
        x: SCREEN_W * 0.5, y: by + 8,
        text: label, size_px: 22,
        anchor_x: 0.5, anchor_y: 0.5,
        r: active ? 255 : 60,
        g: active ? 255 : 60,
        b: active ? 255 : 60
      }
    end
  end
end
