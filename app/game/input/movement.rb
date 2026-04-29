module GameInput
  private

  # Screen-space aim; uses camera + zoom (same math as render_player).
  def update_player_face_angle_from_mouse
    z = effective_zoom
    pcx = (@player[:x] + (PLAYER_W * 0.5) - @cam_x.to_i) * z
    pcy = (@player[:y] + (PLAYER_H * 0.5) - @cam_y.to_i) * z
    @player[:face_angle] = Math.atan2(args.inputs.mouse.y - pcy, args.inputs.mouse.x - pcx)
  end

  # Returns true and changes floor if player is on a stair exit tile moving in exit direction.
  def try_stair_transition(dx, dy)
    return false unless @stair_data
    data = @stair_data[[@player[:floor], @player[:tx], @player[:ty]]]
    return false unless data && data[:is_exit]
    return false unless dx == data[:exit_dx] && dy == data[:exit_dy]
    new_floor = @player[:floor] + data[:delta]
    # Generate the target floor now if it hasn't been yet.
    generate_struct_floor_if_needed(data[:struct_id], new_floor) if data[:struct_id]
    return false unless @tilemap[new_floor]
    @player[:floor] = new_floor
    true
  end

  # Returns true if target tile is a stair exit that can't be entered from current position.
  def stair_exit_blocked?(ntx, nty, dx, dy)
    return false unless @stair_data
    data = @stair_data[[@player[:floor], ntx, nty]]
    return false unless data && data[:is_exit]
    entry_tx = ntx - data[:exit_dx]
    entry_ty = nty - data[:exit_dy]
    @player[:tx] != entry_tx || @player[:ty] != entry_ty
  end
end
