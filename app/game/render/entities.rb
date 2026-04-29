module GameRenderer
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

    show_interact = !door_interact_target.nil?
    if near_vehicle? || show_interact
      args.outputs.labels << {
        x: @player[:x] - @cam_x + (PLAYER_W * 0.5).to_i,
        y: @player[:y] - @cam_y + PLAYER_H + 10,
        text: '!', font: UI_FONT, size_px: 22,
        anchor_x: 0.5, anchor_y: 0,
        r: 255, g: 220, b: 0
      }
    end
  end
end
