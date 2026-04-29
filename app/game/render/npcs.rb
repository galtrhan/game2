module GameRenderer
  # Red isosceles triangle (apex up) in the same PLAYER_W × PLAYER_H screen box as the player.
  def render_npcs
    return unless @npcs && @player

    z = effective_zoom
    fl = @player[:floor]

    @npcs.each do |n|
      next unless n[:floor] == fl

      pw = PLAYER_W * z
      ph = PLAYER_H * z
      px = (n[:x] - @cam_x) * z
      py = (n[:y] - @cam_y) * z
      render_filled_triangle_up(px, py, pw, ph, 220, 40, 40)
    end
  end

  private

  # Apex at top center, base along bottom edge (matches “standing” triangle).
  def render_filled_triangle_up(px, py, pw, ph, r, g, b)
    ph_i = ph.to_i
    return if ph_i < 1

    cx = px + pw * 0.5
    ph_i.times do |i|
      y = (py + i).round
      t = i / [ph - 1, 1].max.to_f
      half_w = (pw * 0.5) * (1.0 - t)
      w = [half_w * 2, 1].max.round
      x = (cx - w * 0.5).round
      args.outputs.solids << { x: x, y: y, w: w, h: 1, r: r, g: g, b: b }
    end
  end
end
