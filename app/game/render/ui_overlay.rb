module GameRenderer
  def render_hud
    args.outputs.labels << {
      x: 640, y: 710,
      text: "ESC pause  I debug#{@debug ? ' [ON]' : ''}  Floor:#{@player[:floor]}  #{@mode == :in_vehicle ? '[IN VEHICLE]' : ''}",
      font: UI_FONT,
      size_px: 16, anchor_x: 0.5,
      r: 60, g: 60, b: 60
    }

    args.outputs.labels << {
      x: 8, y: SCREEN_H - 8,
      text: "FPS: #{args.gtk.current_framerate.to_i}",
      font: UI_FONT,
      size_px: 14, anchor_x: 0, anchor_y: 1,
      r: 60, g: 60, b: 60
    }
  end

  def render_pause_overlay
    args.outputs.primitives << {
      x: 0, y: 0, w: SCREEN_W, h: SCREEN_H,
      r: 0, g: 0, b: 0, a: 150
    }.solid!

    panel_w = 300
    panel_h = 310
    panel_x = ((SCREEN_W - panel_w) * 0.5).to_i
    panel_y = ((SCREEN_H - panel_h) * 0.5).to_i

    args.outputs.solids << { x: panel_x, y: panel_y, w: panel_w, h: panel_h, r: 245, g: 245, b: 245 }

    args.outputs.labels << {
      x: SCREEN_W * 0.5, y: panel_y + panel_h - 28,
      text: 'PAUSED', font: UI_FONT, size_px: 22,
      anchor_x: 0.5, anchor_y: 0.5,
      r: 40, g: 40, b: 40
    }

    PAUSE_ITEMS.each_with_index do |label, i|
      active = i == @pause_selected
      by     = panel_y + panel_h - 75 - (i * 58)

      if active
        args.outputs.solids << { x: panel_x + 10, y: by - 16, w: panel_w - 20, h: 44, r: 30, g: 30, b: 30 }
      end

      args.outputs.labels << {
        x: SCREEN_W * 0.5, y: by + 8,
        text: label, font: UI_FONT, size_px: 22,
        anchor_x: 0.5, anchor_y: 0.5,
        r: active ? 255 : 60,
        g: active ? 255 : 60,
        b: active ? 255 : 60
      }
    end
  end

  def render_minimal_loading
    args.outputs.background_color = [32, 36, 44]

    title, detail = if @show_loading_save
                       ['Loading', '']
                     else
                       ['Generating world...', NEW_GAME_LOADING_DETAIL]
                     end

    args.outputs.labels << {
      x: SCREEN_W * 0.5, y: 400,
      text: title,
      font: UI_FONT,
      size_px: 32,
      anchor_x: 0.5, anchor_y: 0.5,
      r: 235, g: 240, b: 250
    }

    return if detail.empty?

    args.outputs.labels << {
      x: SCREEN_W * 0.5, y: 352,
      text: detail,
      font: UI_FONT,
      size_px: 18,
      anchor_x: 0.5, anchor_y: 0.5,
      r: 160, g: 170, b: 185
    }
  end
end
