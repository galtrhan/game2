class SceneManager
  attr_gtk
  attr_accessor :pending_load_data

  FADE_DURATION = 30 # frames (0.5s at 60fps)

  def tick
    defaults
    update_fade
    current_scene_tick
    render_fade
  end

  def defaults
    state.scene ||= :menu
    state.fade_state ||= :none
    state.fade_alpha ||= 0
    state.fade_timer ||= 0
    state.fade_target_scene ||= nil
    state.fade_color_r ||= 0
    state.fade_color_g ||= 0
    state.fade_color_b ||= 0

    @menu_scene  ||= MenuScene.new
    @game_scene  ||= GameScene.new
    @outro_scene ||= OutroScene.new
  end

  def transition_to(scene, fade_r: 0, fade_g: 0, fade_b: 0)
    return if state.fade_state != :none

    @game_scene = GameScene.new if scene == :game

    state.fade_state = :fading_out
    state.fade_timer = 0
    state.fade_target_scene = scene
    state.fade_color_r = fade_r
    state.fade_color_g = fade_g
    state.fade_color_b = fade_b
  end

  def update_fade
    return if state.fade_state == :none

    state.fade_timer += 1

    if state.fade_state == :fading_out
      state.fade_alpha = (state.fade_timer.to_f / FADE_DURATION * 255).clamp(0, 255).to_i

      if state.fade_timer >= FADE_DURATION
        state.scene = state.fade_target_scene
        state.fade_state = :fading_in
        state.fade_timer = 0
        state.fade_alpha = 255
      end
    elsif state.fade_state == :fading_in
      state.fade_alpha = (255 - (state.fade_timer.to_f / FADE_DURATION * 255)).clamp(0, 255).to_i

      if state.fade_timer >= FADE_DURATION
        state.fade_state = :none
        state.fade_alpha = 0
        state.fade_timer = 0
      end
    end
  end

  def current_scene_tick
    scene = current_scene
    scene.args = args
    scene.scene_manager = self
    scene.tick
  end

  def current_scene
    case state.scene
    when :menu  then @menu_scene
    when :game  then @game_scene
    when :outro then @outro_scene
    end
  end

  def render_fade
    return if state.fade_alpha <= 0

    outputs.primitives << {
      x: 0, y: 0, w: 1280, h: 720,
      r: state.fade_color_r,
      g: state.fade_color_g,
      b: state.fade_color_b,
      a: state.fade_alpha
    }.solid!
  end

  def transitioning?
    state.fade_state != :none
  end

  def reset
    state.scene = :menu
    state.fade_state = :none
    state.fade_alpha = 0
    state.fade_timer = 0
    state.fade_target_scene = nil
    @menu_scene = MenuScene.new
    @game_scene = GameScene.new
    @outro_scene = OutroScene.new
  end
end
