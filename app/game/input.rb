module GameInput
  include GameConstants

  def input
    return if scene_manager.transitioning?

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
      @mode == :in_vehicle ? exit_vehicle : (enter_vehicle if near_vehicle?)
    end

    dx = 0
    dy = 0
    dx = -1 if kb.a || kb.left
    dx =  1 if kb.d || kb.right
    dy =  1 if kb.w || kb.up
    dy = -1 if kb.s || kb.down

    if @mode == :on_foot
      if dx != 0
        nx = (@player[:x] + dx * PLAYER_SPEED).clamp(0, MAP_PX - PLAYER_W)
        @player[:x] = nx unless blocked_rect?(nx, @player[:y], PLAYER_W, PLAYER_H)
      end
      if dy != 0
        ny = (@player[:y] + dy * PLAYER_SPEED).clamp(0, MAP_PY - PLAYER_H)
        @player[:y] = ny unless blocked_rect?(@player[:x], ny, PLAYER_W, PLAYER_H)
      end
      @player[:tx] = ((@player[:x] + (PLAYER_W * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
      @player[:ty] = ((@player[:y] + (PLAYER_H * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

      if dx != 0 || dy != 0
        @player[:facing] = if dx > 0 then :right
                           elsif dx < 0 then :left
                           elsif dy > 0 then :up
                           else :down
                           end
        @player[:idle_timer] = 0
      else
        @player[:idle_timer] = (@player[:idle_timer] || 0) + 1
        @player[:facing] = :idle if @player[:idle_timer] >= IDLE_FRAMES
      end

    elsif @mode == :in_vehicle && @vehicle
      if dx != 0
        nx = (@vehicle[:x] + dx * VEHICLE_SPEED).clamp(0, MAP_PX - VEHICLE_W)
        @vehicle[:x] = nx unless blocked_rect?(nx, @vehicle[:y], VEHICLE_W, VEHICLE_H)
      end
      if dy != 0
        ny = (@vehicle[:y] + dy * VEHICLE_SPEED).clamp(0, MAP_PY - VEHICLE_H)
        @vehicle[:y] = ny unless blocked_rect?(@vehicle[:x], ny, VEHICLE_W, VEHICLE_H)
      end
    end
  end

  def input_pause(kb)
    if kb.key_down.w || kb.key_down.up
      @pause_selected = (@pause_selected - 1) % PAUSE_ITEMS.length
    end
    if kb.key_down.s || kb.key_down.down
      @pause_selected = (@pause_selected + 1) % PAUSE_ITEMS.length
    end
    if kb.key_down.space || kb.key_down.enter || kb.key_down.e
      pause_accept
    end
  end

  def pause_accept
    case @pause_selected
    when 0  # Continue
      @paused = false
    when 1  # Save
      save_game
      @paused = false
    when 2  # Load
      data = $gtk.read_file(SAVE_PATH)
      if data
        load_from_data(data)
      end
      @paused = false
    when 3  # Quit
      @paused = false
      scene_manager.transition_to(:menu, fade_r: 255, fade_g: 255, fade_b: 255)
    end
  end
end
