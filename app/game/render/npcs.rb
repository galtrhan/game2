module GameRenderer
  # Red isosceles triangle (apex up) in the same PLAYER_W × PLAYER_H screen box as the player.
  # Only NPCs sharing the player's container (same building floor, or both outdoors)
  # are visible — prevents seeing through walls into buildings.
  def render_npcs
    return unless @npcs && @player

    z  = effective_zoom
    fl = @player[:floor]
    container = current_player_container_struct_id
    pw = PLAYER_W * z
    ph = PLAYER_H * z

    @npcs.each do |n|
      next unless n[:floor] == fl
      next unless n[:home_struct_id] == container

      px = (n[:x] - @cam_x) * z
      py = (n[:y] - @cam_y) * z
      args.outputs.sprites << {
        x: px, y: py, w: pw, h: ph,
        path: 'sprites/triangle.png',
        r: 220, g: 40, b: 40
      }
    end
  end
end
