module GameInput
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
