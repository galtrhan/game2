module GameInteraction
  include GameConstants
  def near_vehicle?
    return false unless @vehicle
    return false if @mode == :in_vehicle
    dx = (@player[:x] + (PLAYER_W * 0.5).to_i) - (@vehicle[:x] + (VEHICLE_W * 0.5).to_i)
    dy = (@player[:y] + (PLAYER_H * 0.5).to_i) - (@vehicle[:y] + (VEHICLE_H * 0.5).to_i)
    dx * dx + dy * dy < INTERACT_DIST * INTERACT_DIST
  end

  def enter_vehicle
    @mode = :in_vehicle
  end

  def exit_vehicle
    candidates = [
      [@vehicle[:x] + VEHICLE_W + 2, @vehicle[:y] + 2],
      [@vehicle[:x] - PLAYER_W - 2,  @vehicle[:y] + 2],
      [@vehicle[:x] + 2,             @vehicle[:y] + VEHICLE_H + 2]
    ]
    candidates.each do |cx, cy|
      unless blocked_rect?(cx, cy, PLAYER_W, PLAYER_H)
        @player[:x] = cx
        @player[:y] = cy
        @mode = :on_foot
        return
      end
    end
    @player[:x] = @vehicle[:x] + VEHICLE_W + 2
    @player[:y] = @vehicle[:y] + 2
    @mode = :on_foot
  end
end
