class GameScene
  include GameMap
  include GameSaveLoad
  include GameCollision
  include GameInteraction
  include GameInput
  include GameCamera
  include GameRenderer

  include GameConstants

  attr_accessor :args, :scene_manager

  def tick
    defaults
    if !@initialized && show_minimal_loading_screen?
      render_minimal_loading
      return
    end
    return unless @initialized

    input
    update_camera unless @paused
    render
  end

  def show_minimal_loading_screen?
    @show_loading_save || @new_game_show_generating_screen
  end

  def defaults
    return if @initialized

    if scene_manager.pending_load_data
      if @deferred_save_raw.nil?
        @deferred_save_raw = scene_manager.pending_load_data
        scene_manager.pending_load_data = nil
        @show_loading_save = true
        return
      end

      raw = @deferred_save_raw
      @deferred_save_raw = nil
      @show_loading_save = false
      pairs = parse_save_pairs(raw)
      @map_seed = pairs['seed'].to_i
      generate_map
      apply_loaded_save_after_map!(pairs)
      @initialized = true
      return
    end

    # New game: first tick only shows UI; next tick runs synchronous generate_map (no Fiber).
    if @new_game_show_generating_screen
      @new_game_show_generating_screen = false
      @map_seed ||= rand(99999)
      generate_map

      spawn = find_spawn
      @player = {
        x:  spawn[:tx] * TILE_SIZE + 2,
        y:  spawn[:ty] * TILE_SIZE + 2,
        tx: spawn[:tx],
        ty: spawn[:ty],
        facing:     :idle,
        idle_timer: 0,
        floor:      0
      }
      @vehicle        = spawn_vehicle(@player[:tx], @player[:ty])
      @mode           = :on_foot
      @debug          = false
      @paused         = false
      @pause_selected = 0

      focus  = camera_focus
      half_w = (SCREEN_W * 0.5).to_i
      half_h = (SCREEN_H * 0.5).to_i
      @cam_x = (focus[:x] - half_w).clamp(0, MAP_PX - SCREEN_W)
      @cam_y = (focus[:y] - half_h).clamp(0, MAP_PY - SCREEN_H)

      @initialized = true
      return
    end

    @map_seed ||= rand(99999)
    @new_game_show_generating_screen = true
    return
  end
end
