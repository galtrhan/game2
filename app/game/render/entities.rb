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

    cx = px + pw * 0.5
    cy = py + ph * 0.5
    r_screen = PLAYER_RADIUS * z
    render_filled_circle_scanlines(cx, cy, r_screen, 60, 120, 220)

    half_dot = (ds * 0.5).to_i
    a = @player[:face_angle]
    orbit = (r_screen * 0.7).to_i
    dot_x = if a.nil?
              (cx - half_dot).to_i
            else
              (cx + Math.cos(a) * orbit - half_dot).to_i
            end
    dot_y = if a.nil?
              (cy - half_dot).to_i
            else
              (cy + Math.sin(a) * orbit - half_dot).to_i
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

  # Custom pointer while on foot (system cursor hidden in GameRenderer#render).
  def render_aim_crosshair
    return if @mode != :on_foot || @paused

    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y
    arm = 6
    c = 55
    args.outputs.lines << [mx - arm, my, mx + arm, my, c, c, c, 255]
    args.outputs.lines << [mx, my - arm, mx, my + arm, c, c, c, 255]
  end

  private

  # Filled disc from 1px-tall horizontal solids (no texture).
  def render_filled_circle_scanlines(cx, cy, radius, cr, cg, cb)
    ri = radius.round.clamp(1, 256)
    r2 = ri * ri
    ry = -ri
    while ry <= ri
      hw = Math.sqrt([0, r2 - ry * ry].max).floor
      y = (cy + ry).round
      x = (cx - hw).round
      w = hw * 2 + 1
      args.outputs.solids << { x: x, y: y, w: w, h: 1, r: cr, g: cg, b: cb }
      ry += 1
    end
  end
end
