class GameScene
  include GameMap
  include GameSaveLoad
  include GameCollision
  include GameNpcs
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
    update_dynamic_zoom
    update_camera unless @paused   # also calls enqueue_chunks_around_camera
    map_generation_step!(MAP_GEN_CHUNKS_PER_TICK)
    update_npcs
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
      @deferred_save_raw  = nil
      @show_loading_save  = false
      load_from_data(raw)
      @initialized = true
      return
    end

    # First tick: show generating screen; second tick: run (sync) generation.
    if @new_game_show_generating_screen
      @new_game_show_generating_screen = false
      @map_seed ||= rand(99999)
      generate_map
      finalize_new_game_after_map!
      @initialized = true
      return
    end

    @map_seed ||= rand(99999)
    @new_game_show_generating_screen = true
  end

  def finalize_new_game_after_map!
    spawn = find_spawn
    @player = {
      x:  spawn[:tx] * TILE_SIZE + 2,
      y:  spawn[:ty] * TILE_SIZE + 2,
      tx: spawn[:tx],
      ty: spawn[:ty],
      face_angle: 0.0,
      floor:      0
    }
    @vehicle        = spawn_vehicle(@player[:tx], @player[:ty])
    @mode           = :on_foot
    @debug          = false
    @paused         = false
    @pause_selected = 0
    @zoom                  = ZOOM_DEFAULT
    @full_speed_run_ticks  = 0

    focus  = camera_focus
    half_w = (viewport_w * 0.5).to_i
    half_h = (viewport_h * 0.5).to_i
    @cam_x = (focus[:x] - half_w).to_i
    @cam_y = (focus[:y] - half_h).to_i

    spawn_npc_fleet
  end
end
