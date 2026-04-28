class GameScene
  attr_accessor :args, :scene_manager

  TILE_SIZE      = 32
  TILES_X        = 100
  TILES_Y        = 70
  MAP_PX         = TILES_X * TILE_SIZE
  MAP_PY         = TILES_Y * TILE_SIZE
  SCREEN_W       = 1280
  SCREEN_H       = 720
  PLAYER_W       = TILE_SIZE - 4
  PLAYER_H       = TILE_SIZE - 4
  PLAYER_SPEED   = 3
  VEHICLE_W      = TILE_SIZE
  VEHICLE_H      = TILE_SIZE * 2
  VEHICLE_SPEED  = 2
  INTERACT_DIST  = TILE_SIZE * 2
  SAVE_PATH      = 'saves/game2.sav'
  IDLE_FRAMES    = 180  # 3s at 60fps
  DOT_SIZE       = 5

  PAUSE_ITEMS = ['Continue', 'Save', 'Load', 'Quit']

  DZ_W      = (SCREEN_W * 0.5).to_i
  DZ_H      = (SCREEN_H * 0.5).to_i
  DZ_LEFT   = ((SCREEN_W - DZ_W) * 0.5).to_i
  DZ_RIGHT  = DZ_LEFT + DZ_W
  DZ_BOTTOM = ((SCREEN_H - DZ_H) * 0.5).to_i
  DZ_TOP    = DZ_BOTTOM + DZ_H

  def tick
    defaults
    input
    update_camera unless @paused
    render
  end

  # --- Init ---

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
      facing_timer: 0
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

  # --- Map generation ---

  def generate_map
    srand(@map_seed)
    map = []
    TILES_Y.times { map << Array.new(TILES_X, :floor) }
    y = 1
    while y < TILES_Y - 1
      x = 1
      while x < TILES_X - 1
        bw = [2 + rand(9), TILES_X - 1 - x].min
        bh = [2 + rand(9), TILES_Y - 1 - y].min
        bh.times { |dy| bw.times { |dx| map[y + dy][x + dx] = :block } }
        x += bw + 2 + rand(19)
      end
      y += (2 + rand(9)) + 2 + rand(19)
    end
    map
  end

  def find_spawn
    free = []
    TILES_Y.times { |ty| TILES_X.times { |tx| free << { tx: tx, ty: ty } if map_tile(tx, ty) == :floor } }
    free.empty? ? { tx: 0, ty: 0 } : free[rand(free.length)]
  end

  def spawn_vehicle(player_tx, player_ty)
    candidates = []
    (-6..6).each do |dy|
      (-6..6).each do |dx|
        dist_sq = dx * dx + dy * dy
        next unless dist_sq >= 4 && dist_sq <= 25
        tx = player_tx + dx
        ty = player_ty + dy
        next unless map_tile(tx, ty) == :floor && map_tile(tx, ty + 1) == :floor
        candidates << { tx: tx, ty: ty }
      end
    end
    return nil if candidates.empty?
    s = candidates[rand(candidates.length)]
    { x: s[:tx] * TILE_SIZE, y: s[:ty] * TILE_SIZE, collidable: true }
  end

  def map_tile(tx, ty)
    return :floor if tx < 0 || tx >= TILES_X || ty < 0 || ty >= TILES_Y
    @tilemap[ty][tx]
  end

  # --- Save / Load ---

  def save_game
    v = @vehicle
    parts = [
      "seed=#{@map_seed}",
      "player_x=#{@player[:x]}",
      "player_y=#{@player[:y]}",
      "vehicle_x=#{v ? v[:x] : 'nil'}",
      "vehicle_y=#{v ? v[:y] : 'nil'}",
      "vehicle_col=#{v ? (v[:collidable] ? '1' : '0') : 'nil'}",
      "mode=#{@mode}",
      "cam_x=#{@cam_x.to_i}",
      "cam_y=#{@cam_y.to_i}"
    ]
    $gtk.write_file(SAVE_PATH, parts.join('|'))
  end

  def load_from_data(raw)
    pairs = {}
    raw.split('|').each { |p| k, v = p.split('='); pairs[k] = v }

    @map_seed = pairs['seed'].to_i
    @tilemap  = generate_map

    @player = { x: pairs['player_x'].to_i, y: pairs['player_y'].to_i, tx: 0, ty: 0, facing: :idle, facing_timer: 0 }
    @player[:tx] = ((@player[:x] + (PLAYER_W * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    @player[:ty] = ((@player[:y] + (PLAYER_H * 0.5).to_i) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    @vehicle = if pairs['vehicle_x'] != 'nil'
      { x: pairs['vehicle_x'].to_i, y: pairs['vehicle_y'].to_i, collidable: pairs['vehicle_col'] == '1' }
    end

    @mode           = pairs['mode'] == 'in_vehicle' ? :in_vehicle : :on_foot
    @cam_x          = pairs['cam_x'].to_i
    @cam_y          = pairs['cam_y'].to_i
    @debug          = false
    @paused         = false
    @pause_selected = 0
  end

  # --- Collision ---

  def rects_overlap?(ax, ay, aw, ah, bx, by, bw, bh)
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
  end

  def blocked_rect?(x, y, w, h)
    tile_hit = [
      [x,         y        ],
      [x + w - 1, y        ],
      [x,         y + h - 1],
      [x + w - 1, y + h - 1]
    ].any? { |cx, cy| map_tile((cx / TILE_SIZE).to_i, (cy / TILE_SIZE).to_i) == :block }
    return true if tile_hit

    if @mode == :on_foot && @vehicle && @vehicle[:collidable]
      return rects_overlap?(x, y, w, h, @vehicle[:x], @vehicle[:y], VEHICLE_W, VEHICLE_H)
    end

    false
  end

  # --- Interaction ---

  def near_vehicle?
    return false unless @vehicle
    return false if @mode == :in_vehicle
    dx = (@player[:x] + (PLAYER_W * 0.5).to_i) - (@vehicle[:x] + (VEHICLE_W * 0.5).to_i)
    dy = (@player[:y] + (PLAYER_H * 0.5).to_i) - (@vehicle[:y] + (VEHICLE_H * 0.5).to_i)
    dx * dx + dy * dy < INTERACT_DIST * INTERACT_DIST
  end

  def enter_vehicle
    @mode = :in_vehicle
  end

  def exit_vehicle
    candidates = [
      [@vehicle[:x] + VEHICLE_W + 2, @vehicle[:y] + 2],
      [@vehicle[:x] - PLAYER_W - 2,  @vehicle[:y] + 2],
      [@vehicle[:x] + 2,             @vehicle[:y] + VEHICLE_H + 2]
    ]
    candidates.each do |cx, cy|
      unless blocked_rect?(cx, cy, PLAYER_W, PLAYER_H)
        @player[:x] = cx
        @player[:y] = cy
        @mode = :on_foot
        return
      end
    end
    @player[:x] = @vehicle[:x] + VEHICLE_W + 2
    @player[:y] = @vehicle[:y] + 2
    @mode = :on_foot
  end

  # --- Input ---

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
        @player[:facing_timer] = 0
      else
        @player[:facing_timer] += 1
        @player[:facing] = :idle if @player[:facing_timer] >= IDLE_FRAMES
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

  # --- Camera ---

  def camera_focus
    if @mode == :in_vehicle && @vehicle
      { x: @vehicle[:x] + (VEHICLE_W * 0.5).to_i, y: @vehicle[:y] + (VEHICLE_H * 0.5).to_i }
    else
      { x: @player[:x] + (PLAYER_W * 0.5).to_i,   y: @player[:y] + (PLAYER_H * 0.5).to_i   }
    end
  end

  def update_camera
    focus = camera_focus
    px = focus[:x]
    py = focus[:y]

    sx = px - @cam_x.to_i
    sy = py - @cam_y.to_i

    @cam_x = px - DZ_LEFT   if sx < DZ_LEFT
    @cam_x = px - DZ_RIGHT  if sx > DZ_RIGHT
    @cam_y = py - DZ_BOTTOM if sy < DZ_BOTTOM
    @cam_y = py - DZ_TOP    if sy > DZ_TOP

    @cam_x = @cam_x.to_i.clamp(0, MAP_PX - SCREEN_W)
    @cam_y = @cam_y.to_i.clamp(0, MAP_PY - SCREEN_H)
  end

  # --- Render ---

  def render
    args.outputs.background_color = [200, 200, 200]

    tx_min = (@cam_x.to_i / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    tx_max = ((@cam_x.to_i + SCREEN_W) / TILE_SIZE).to_i.clamp(0, TILES_X - 1)
    ty_min = (@cam_y.to_i / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)
    ty_max = ((@cam_y.to_i + SCREEN_H) / TILE_SIZE).to_i.clamp(0, TILES_Y - 1)

    ty_min.upto(ty_max) do |ty|
      tx_min.upto(tx_max) do |tx|
        sx = tx * TILE_SIZE - @cam_x
        sy = ty * TILE_SIZE - @cam_y
        args.outputs.solids << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 90, g: 90, b: 90 } if @tilemap[ty][tx] == :block
        args.outputs.borders << { x: sx, y: sy, w: TILE_SIZE, h: TILE_SIZE, r: 150, g: 150, b: 150, a: 90 } if @debug
      end
    end

    render_vehicle
    render_player

    args.outputs.labels << {
      x: 640, y: 710,
      text: "ESC pause  I debug#{@debug ? ' [ON]' : ''}  #{@mode == :in_vehicle ? '[IN VEHICLE]' : ''}",
      size_px: 16, anchor_x: 0.5,
      r: 60, g: 60, b: 60
    }

    render_pause_overlay if @paused
  end

  def render_vehicle
    return unless @vehicle
    args.outputs.solids << {
      x: @vehicle[:x] - @cam_x, y: @vehicle[:y] - @cam_y,
      w: VEHICLE_W, h: VEHICLE_H,
      r: 255, g: 105, b: 180
    }
    if @debug
      args.outputs.borders << {
        x: @vehicle[:x] - @cam_x, y: @vehicle[:y] - @cam_y,
        w: VEHICLE_W, h: VEHICLE_H,
        r: 255, g: 0, b: 120
      }
    end
  end

  def render_player
    return if @mode == :in_vehicle

    px = @player[:x] - @cam_x
    py = @player[:y] - @cam_y

    args.outputs.solids << { x: px, y: py, w: PLAYER_W, h: PLAYER_H, r: 60, g: 120, b: 220 }

    half_dot = (DOT_SIZE * 0.5).to_i
    cx = px + (PLAYER_W * 0.5).to_i - half_dot
    cy = py + (PLAYER_H * 0.5).to_i - half_dot
    dot_x, dot_y = case @player[:facing]
                   when :right then [px + PLAYER_W - DOT_SIZE - 1, cy]
                   when :left  then [px + 1,                        cy]
                   when :up    then [cx, py + PLAYER_H - DOT_SIZE - 1]
                   when :down  then [cx, py + 1]
                   else             [cx, cy]
                   end
    args.outputs.solids << { x: dot_x, y: dot_y, w: DOT_SIZE, h: DOT_SIZE, r: 255, g: 255, b: 255 }

    if @debug
      args.outputs.borders << {
        x: @player[:tx] * TILE_SIZE - @cam_x, y: @player[:ty] * TILE_SIZE - @cam_y,
        w: TILE_SIZE, h: TILE_SIZE,
        r: 60, g: 180, b: 255
      }
    end

    if near_vehicle?
      args.outputs.labels << {
        x: @player[:x] - @cam_x + (PLAYER_W * 0.5).to_i,
        y: @player[:y] - @cam_y + PLAYER_H + 10,
        text: '!', size_px: 22,
        anchor_x: 0.5, anchor_y: 0,
        r: 255, g: 220, b: 0
      }
    end
  end

  def render_pause_overlay
    # Dark overlay
    args.outputs.primitives << {
      x: 0, y: 0, w: SCREEN_W, h: SCREEN_H,
      r: 0, g: 0, b: 0, a: 150
    }.solid!

    # Panel
    panel_w = 300
    panel_h = 310
    panel_x = ((SCREEN_W - panel_w) * 0.5).to_i
    panel_y = ((SCREEN_H - panel_h) * 0.5).to_i

    args.outputs.solids << { x: panel_x, y: panel_y, w: panel_w, h: panel_h, r: 245, g: 245, b: 245 }

    # Title
    args.outputs.labels << {
      x: SCREEN_W * 0.5, y: panel_y + panel_h - 28,
      text: 'PAUSED', size_px: 22,
      anchor_x: 0.5, anchor_y: 0.5,
      r: 40, g: 40, b: 40
    }

    # Buttons
    PAUSE_ITEMS.each_with_index do |label, i|
      active = i == @pause_selected
      by     = panel_y + panel_h - 75 - (i * 58)

      if active
        args.outputs.solids << { x: panel_x + 10, y: by - 16, w: panel_w - 20, h: 44, r: 30, g: 30, b: 30 }
      end

      args.outputs.labels << {
        x: SCREEN_W * 0.5, y: by + 8,
        text: label, size_px: 22,
        anchor_x: 0.5, anchor_y: 0.5,
        r: active ? 255 : 60,
        g: active ? 255 : 60,
        b: active ? 255 : 60
      }
    end
  end
end
