class OutroScene
  attr_accessor :args, :scene_manager

  DISPLAY_FRAMES = 180 # 3 seconds at 60fps

  def tick
    defaults
    update
    render
  end

  def defaults
    @timer ||= 0
  end

  def update
    return if scene_manager.transitioning?

    @timer += 1

    if @timer >= DISPLAY_FRAMES
      $gtk.request_quit
    end
  end

  def render
    args.outputs.background_color = [0, 0, 0]

    args.outputs.labels << {
      x: 640,
      y: 360,
      text: 'Bye Bye',
      size_px: 48,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255, g: 255, b: 255
    }
  end
end
