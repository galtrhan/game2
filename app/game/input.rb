module GameInput
  include GameConstants
end

require 'app/game/input/movement'
require 'app/game/input/pause'

module GameInput
  def input
    if scene_manager.transitioning?
      return
    end

    kb = args.inputs.keyboard

    @debug = !@debug if kb.key_down.i

    if kb.key_down.escape
      @paused = !@paused
      @pause_selected = 0
    end

    if @paused
      input_pause(kb)
      return
    end

    if kb.key_down.e
      if @mode == :in_vehicle
        exit_vehicle
      elsif near_vehicle?
        enter_vehicle
      elsif (tgt = door_interact_target)
        toggle_door_at(tgt[0], tgt[1])
      end
    end

    dx = 0
    dy = 0
    if @mode == :on_foot
      dx = -1 if kb.a
      dx =  1 if kb.d
      dy =  1 if kb.w
      dy = -1 if kb.s
    else
      dx = -1 if kb.a || kb.left
      dx =  1 if kb.d || kb.right
      dy =  1 if kb.w || kb.up
      dy = -1 if kb.s || kb.down
    end

    if @mode == :on_foot
      update_player_face_angle_from_mouse

      if dx != 0
        nx  = (@player[:x] + dx * PLAYER_SPEED).clamp(0, MAP_PX - PLAYER_W)
        ntx = ((nx + (PLAYER_W * 0.5).to_i) / TILE_SIZE).to_i
        nty = @player[:ty]
        if !try_stair_transition(dx, 0) &&
           !stair_exit_blocked?(ntx, nty, dx, 0) &&
           !blocked_rect?(nx, @player[:y], PLAYER_W, PLAYER_H)
          @player[:x] = nx
        end
      end
      if dy != 0
        ny  = (@player[:y] + dy * PLAYER_SPEED).clamp(0, MAP_PY - PLAYER_H)
        ntx = @player[:tx]
        nty = ((ny + (PLAYER_H * 0.5).to_i) / TILE_SIZE).to_i
        if !try_stair_transition(0, dy) &&
           !stair_exit_blocked?(ntx, nty, 0, dy) &&
           !blocked_rect?(@player[:x], ny, PLAYER_W, PLAYER_H)
          @player[:y] = ny
        end
      end
      @player[:tx] = ((@player[:x] + (PLAYER_W * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
      @player[:ty] = ((@player[:y] + (PLAYER_H * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    elsif @mode == :in_vehicle && @vehicle
      if dx != 0
        nx = (@vehicle[:x] + dx * VEHICLE_SPEED).clamp(0, MAP_PX - VEHICLE_W)
        @vehicle[:x] = nx unless blocked_rect?(nx, @vehicle[:y], VEHICLE_W, VEHICLE_H, 0)
      end
      if dy != 0
        ny = (@vehicle[:y] + dy * VEHICLE_SPEED).clamp(0, MAP_PY - VEHICLE_H)
        @vehicle[:y] = ny unless blocked_rect?(@vehicle[:x], ny, VEHICLE_W, VEHICLE_H, 0)
      end
    end

    # Sustained movement while driving — used only for optional wide (1x) zoom in vehicle.
    movement_intent = (@mode == :in_vehicle && @vehicle) && (dx != 0 || dy != 0)

    if movement_intent
      @full_speed_run_ticks = (@full_speed_run_ticks || 0) + 1
    else
      @full_speed_run_ticks = 0
    end
  end
end
