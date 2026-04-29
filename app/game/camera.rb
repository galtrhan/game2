module GameCamera
  include GameConstants

  def effective_zoom
    z = @zoom
    z = ZOOM_DEFAULT if z.nil?
    hi = if player_in_interior?
            ZOOM_INTERIOR
          elsif z > ZOOM_DEFAULT
            ZOOM_INTERIOR
          else
            ZOOM_DEFAULT
          end
    z.clamp(ZOOM_MIN, hi)
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

    if player_in_interior?
      target = ZOOM_INTERIOR
      lerp = ZOOM_LERP
      @zoom += (target - @zoom) * lerp
      @zoom = target if (target - @zoom).abs < 0.002
      @zoom = @zoom.clamp(ZOOM_MIN, ZOOM_INTERIOR)
      return
    end

    moving_eligible_for_wide =
      (@mode == :in_vehicle && @vehicle) &&
      (@full_speed_run_ticks || 0) >= FULL_SPEED_ZOOM_DELAY_TICKS

    target = moving_eligible_for_wide ? ZOOM_MIN : ZOOM_DEFAULT

    lerp = if @zoom > ZOOM_DEFAULT
             ZOOM_LERP_EXIT_INTERIOR
           elsif target == ZOOM_DEFAULT && @zoom < ZOOM_DEFAULT
             ZOOM_LERP_RETURN
           else
             ZOOM_LERP
           end

    @zoom += (target - @zoom) * lerp
    @zoom = target if (target - @zoom).abs < 0.002
    @zoom = if @zoom > ZOOM_DEFAULT
              @zoom.clamp(ZOOM_MIN, ZOOM_INTERIOR)
            else
              @zoom.clamp(ZOOM_MIN, ZOOM_DEFAULT)
            end
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

    @cam_x = @cam_x.to_i
    @cam_y = @cam_y.to_i
    # Infinite world — no clamping to map edges.

    enqueue_chunks_around_camera
  end
end
