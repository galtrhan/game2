module GameRenderer
  def render_vehicle
    return unless @vehicle
    z = effective_zoom
    vw = VEHICLE_W * z
    vh = VEHICLE_H * z
    vx = (@vehicle[:x] - @cam_x) * z
    vy = (@vehicle[:y] - @cam_y) * z
    args.outputs.solids << {
      x: vx, y: vy,
      w: vw, h: vh,
      r: 255, g: 105, b: 180
    }
    if @debug
      args.outputs.borders << {
        x: vx, y: vy,
        w: vw, h: vh,
        r: 255, g: 0, b: 120
      }
    end
  end

  def render_player
    return if @mode == :in_vehicle

    z = effective_zoom
    pw = PLAYER_W * z
    ph = PLAYER_H * z
    ds = DOT_SIZE * z
    px = (@player[:x] - @cam_x) * z
    py = (@player[:y] - @cam_y) * z

    args.outputs.solids << { x: px, y: py, w: pw, h: ph, r: 60, g: 120, b: 220 }

    half_dot = (ds * 0.5).to_i
    cx = px + (pw * 0.5).to_i - half_dot
    cy = py + (ph * 0.5).to_i - half_dot
    dot_x, dot_y = case @player[:facing]
                   when :right then [px + pw - ds - z, cy]
                   when :left  then [px + z,                       cy]
                   when :up    then [cx, py + ph - ds - z]
                   when :down  then [cx, py + z]
                   else             [cx, cy]
                   end
    args.outputs.solids << { x: dot_x, y: dot_y, w: ds, h: ds, r: 255, g: 255, b: 255 }

    if @debug
      tw = TILE_SIZE * z
      args.outputs.borders << {
        x: (@player[:tx] * TILE_SIZE - @cam_x) * z, y: (@player[:ty] * TILE_SIZE - @cam_y) * z,
        w: tw, h: tw,
        r: 60, g: 180, b: 255
      }
    end

    show_interact = !door_interact_target.nil?
    if near_vehicle? || show_interact
      args.outputs.labels << {
        x: (@player[:x] - @cam_x + (PLAYER_W * 0.5).to_i) * z,
        y: (@player[:y] - @cam_y + PLAYER_H + 10) * z,
        text: '!', font: UI_FONT, size_px: (22 * z).to_i,
        anchor_x: 0.5, anchor_y: 0,
        r: 255, g: 220, b: 0
      }
    end
  end
end
