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
        nx  = @player[:x] + dx * PLAYER_SPEED
        ntx = (nx + (PLAYER_W * 0.5).to_i).div(TILE_SIZE)
        nty = @player[:ty]
        unless try_stair_transition(dx, 0) || stair_exit_blocked?(ntx, nty, dx, 0)
          if !blocked_player_circle?(nx, @player[:y])
            @player[:x] = nx
          else
            # Corner slide: nudge Y slightly to slip through door gaps and around corners.
            nudge = -PLAYER_SPEED
            while nudge <= PLAYER_SPEED
              if nudge != 0 && !blocked_player_circle?(nx, @player[:y] + nudge)
                @player[:x] = nx
                @player[:y] += nudge
                break
              end
              nudge += 1
            end
          end
        end
      end
      if dy != 0
        ny  = @player[:y] + dy * PLAYER_SPEED
        ntx = @player[:tx]
        nty = (ny + (PLAYER_H * 0.5).to_i).div(TILE_SIZE)
        unless try_stair_transition(0, dy) || stair_exit_blocked?(ntx, nty, 0, dy)
          if !blocked_player_circle?(@player[:x], ny)
            @player[:y] = ny
          else
            # Corner slide: nudge X slightly to slip through door gaps and around corners.
            nudge = -PLAYER_SPEED
            while nudge <= PLAYER_SPEED
              if nudge != 0 && !blocked_player_circle?(@player[:x] + nudge, ny)
                @player[:y] = ny
                @player[:x] += nudge
                break
              end
              nudge += 1
            end
          end
        end
      end
      @player[:tx] = (@player[:x] + (PLAYER_W * 0.5).to_i).div(TILE_SIZE)
      @player[:ty] = (@player[:y] + (PLAYER_H * 0.5).to_i).div(TILE_SIZE)

    elsif @mode == :in_vehicle && @vehicle
      if dx != 0
        nx = @vehicle[:x] + dx * VEHICLE_SPEED
        @vehicle[:x] = nx unless blocked_rect?(nx, @vehicle[:y], VEHICLE_W, VEHICLE_H, 0)
      end
      if dy != 0
        ny = @vehicle[:y] + dy * VEHICLE_SPEED
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
