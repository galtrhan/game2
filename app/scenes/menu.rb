class MenuScene
  include GameConstants

  attr_accessor :args, :scene_manager

  SAVE_PATH = 'saves/game2.sav'

  def tick
    defaults
    input
    render
  end

  def defaults
    @buttons ||= [
      { label: 'Start', action: :game },
      { label: 'Load',  action: :load },
      { label: 'Quit',  action: :outro }
    ]
    @selected ||= 0
  end

  def input
    return if scene_manager.transitioning?

    kb = args.inputs.keyboard

    if kb.key_down.w || kb.key_down.up
      @selected = (@selected - 1) % @buttons.length
    end

    if kb.key_down.s || kb.key_down.down
      @selected = (@selected + 1) % @buttons.length
    end

    if kb.key_down.space || kb.key_down.enter || kb.key_down.e
      accept
    end
  end

  def accept
    case @buttons[@selected][:action]
    when :game
      scene_manager.transition_to(:game)
    when :load
      data = $gtk.read_file(SAVE_PATH)
      if data
        scene_manager.pending_load_data = data
        scene_manager.transition_to(:game)
      end
    when :outro
      scene_manager.transition_to(:outro)
    end
  end

  def render
    args.outputs.background_color = [255, 255, 255]

    @buttons.each_with_index do |btn, i|
      active = i == @selected
      y = 400 - (i * 60)

      if active
        args.outputs.solids << { x: 540, y: y - 15, w: 200, h: 44, r: 30, g: 30, b: 30 }
      end

      args.outputs.labels << {
        x: 640, y: y + 8,
        text: btn[:label],
        font: UI_FONT,
        size_px: 28, anchor_x: 0.5, anchor_y: 0.5,
        r: active ? 255 : 60,
        g: active ? 255 : 60,
        b: active ? 255 : 60
      }
    end
  end
end
