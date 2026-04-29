module GameCamera
  include GameConstants

  def effective_zoom
    z = @zoom
    z = ZOOM_DEFAULT if z.nil?
    z.clamp(ZOOM_MIN, ZOOM_DEFAULT)
  end

  # Visible world size (float) for current zoom.
  def viewport_w
    SCREEN_W / effective_zoom
  end

  def viewport_h
    SCREEN_H / effective_zoom
  end

  def camera_focus
    if @mode == :in_vehicle && @vehicle
      { x: @vehicle[:x] + (VEHICLE_W * 0.5).to_i, y: @vehicle[:y] + (VEHICLE_H * 0.5).to_i }
    else
      { x: @player[:x] + (PLAYER_W * 0.5).to_i,   y: @player[:y] + (PLAYER_H * 0.5).to_i   }
    end
  end

  def update_dynamic_zoom
    @zoom ||= ZOOM_DEFAULT

    if @paused
      @full_speed_run_ticks = 0
    end

    # Streak is driven by movement intent in input (keys held); resets when idle.
    # When ticks reach the delay while still moving, ease toward 1x (zoom out / wider view).
    moving_eligible_for_wide = (@full_speed_run_ticks || 0) >= FULL_SPEED_ZOOM_DELAY_TICKS

    target = moving_eligible_for_wide ? ZOOM_MIN : ZOOM_DEFAULT

    lerp = if target == ZOOM_DEFAULT && @zoom < ZOOM_DEFAULT
             ZOOM_LERP_RETURN
           else
             ZOOM_LERP
           end

    @zoom += (target - @zoom) * lerp
    @zoom = target if (target - @zoom).abs < 0.002
    @zoom = @zoom.clamp(ZOOM_MIN, ZOOM_DEFAULT)
  end

  def update_camera
    focus = camera_focus
    px = focus[:x]
    py = focus[:y]

    vw = viewport_w
    vh = viewport_h
    dz_w      = (vw * 0.5).to_i
    dz_left   = ((vw - dz_w) * 0.5).to_i
    dz_right  = dz_left + dz_w
    dz_h      = (vh * 0.5).to_i
    dz_bottom = ((vh - dz_h) * 0.5).to_i
    dz_top    = dz_bottom + dz_h

    sx = px - @cam_x.to_i
    sy = py - @cam_y.to_i

    @cam_x = px - dz_left   if sx < dz_left
    @cam_x = px - dz_right  if sx > dz_right
    @cam_y = py - dz_bottom if sy < dz_bottom
    @cam_y = py - dz_top    if sy > dz_top

    max_x = [MAP_PX - vw, 0].max
    max_y = [MAP_PY - vh, 0].max
    @cam_x = @cam_x.to_i.clamp(0, max_x)
    @cam_y = @cam_y.to_i.clamp(0, max_y)
  end
end
