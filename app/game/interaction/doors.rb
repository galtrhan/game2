module GameInteraction
  ADJACENT_DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze

  def door_tile?(tx, ty)
    t = map_tile(tx, ty)
    t == :door || t == :locked_door
  end

  # Tile to toggle with E: underfoot, else tile in facing direction, else any adjacent (for locked doors you cannot stand on).
  def door_interact_target
    tx = @player[:tx]
    ty = @player[:ty]
    fa = @player[:face_angle]
    tick = args.state.tick_count
    if @dit_tick == tick && @dit_tx == tx && @dit_ty == ty && @dit_fa == fa
      return @dit_result
    end

    @dit_tick = tick
    @dit_tx = tx
    @dit_ty = ty
    @dit_fa = fa
    @dit_result = compute_door_interact_target(tx, ty)
  end

  private

  def compute_door_interact_target(tx, ty)
    return [tx, ty] if door_tile?(tx, ty)

    d = player_facing_delta
    if d
      ax = tx + d[0]
      ay = ty + d[1]
      return [ax, ay] if door_tile?(ax, ay)
    end

    ADJACENT_DIRS.each do |dx, dy|
      ax = tx + dx
      ay = ty + dy
      return [ax, ay] if door_tile?(ax, ay)
    end
    nil
  end

  public

  def toggle_door_at(tx, ty)
    fl = @player[:floor]
    t  = get_tile_raw(fl, tx, ty)
    return unless t == :door || t == :locked_door

    new_tile = t == :door ? :locked_door : :door
    set_tile(fl, tx, ty, new_tile)
    (@tile_mutations ||= {})[[fl, tx, ty]] = new_tile
  end

  private

  def player_facing_delta
    a = @player[:face_angle]
    return nil if a.nil?

    c = Math.cos(a)
    s = Math.sin(a)
    if c.abs >= s.abs
      c >= 0 ? [1, 0] : [-1, 0]
    else
      s >= 0 ? [0, 1] : [0, -1]
    end
  end
end
