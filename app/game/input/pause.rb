module GameInput
  def input_pause(kb)
    if args.inputs.mouse.moved
      pt = args.inputs.mouse.point
      PAUSE_ITEMS.length.times do |i|
        if pt.inside_rect?(pause_menu_item_rect(i))
          @pause_selected = i
          break
        end
      end
    end

    if kb.key_down.w || kb.key_down.up
      @pause_selected = (@pause_selected - 1) % PAUSE_ITEMS.length
    end
    if kb.key_down.s || kb.key_down.down
      @pause_selected = (@pause_selected + 1) % PAUSE_ITEMS.length
    end
    if kb.key_down.space || kb.key_down.enter || kb.key_down.e
      pause_accept
    end

    if args.inputs.mouse.click
      click = args.inputs.mouse.click
      PAUSE_ITEMS.length.times do |i|
        next unless click.point.inside_rect?(pause_menu_item_rect(i))

        @pause_selected = i
        pause_accept
        break
      end
    end
  end

  def pause_accept
    case @pause_selected
    when 0
      @paused = false
    when 1
      save_game
      @paused = false
    when 2
      data = $gtk.read_file(SAVE_PATH)
      load_from_data(data) if data
      @paused = false
    when 3
      @paused = false
      scene_manager.transition_to(:menu, fade_r: 255, fade_g: 255, fade_b: 255)
    end
  end
end
