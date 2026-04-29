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
    input
    update_camera unless @paused
    render
  end

  def defaults
    return if @initialized

    if scene_manager.pending_load_data
      load_from_data(scene_manager.pending_load_data)
      scene_manager.pending_load_data = nil
      @initialized = true
      return
    end

    @map_seed = rand(99999)
    @tilemap  = generate_map
    spawn     = find_spawn
    @player   = {
      x:  spawn[:tx] * TILE_SIZE + 2,
      y:  spawn[:ty] * TILE_SIZE + 2,
      tx: spawn[:tx],
      ty: spawn[:ty],
      facing:       :idle,
      idle_timer: 0
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
  end
end
