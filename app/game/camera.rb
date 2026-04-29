module GameCamera
  include GameConstants
  def camera_focus
    if @mode == :in_vehicle && @vehicle
      { x: @vehicle[:x] + (VEHICLE_W * 0.5).to_i, y: @vehicle[:y] + (VEHICLE_H * 0.5).to_i }
    else
      { x: @player[:x] + (PLAYER_W * 0.5).to_i,   y: @player[:y] + (PLAYER_H * 0.5).to_i   }
    end
  end

  def update_camera
    focus = camera_focus
    px = focus[:x]
    py = focus[:y]

    sx = px - @cam_x.to_i
    sy = py - @cam_y.to_i

    @cam_x = px - DZ_LEFT   if sx < DZ_LEFT
    @cam_x = px - DZ_RIGHT  if sx > DZ_RIGHT
    @cam_y = py - DZ_BOTTOM if sy < DZ_BOTTOM
    @cam_y = py - DZ_TOP    if sy > DZ_TOP

    @cam_x = @cam_x.to_i.clamp(0, MAP_PX - SCREEN_W)
    @cam_y = @cam_y.to_i.clamp(0, MAP_PY - SCREEN_H)
  end
end
