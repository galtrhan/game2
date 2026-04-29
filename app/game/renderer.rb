module GameRenderer
  include GameConstants
end

require 'app/game/render/world_tiles'
require 'app/game/render/entities'
require 'app/game/render/ui_overlay'

module GameRenderer
  def render
    args.outputs.background_color = [200, 200, 200]
    render_world_tiles
    render_vehicle
    render_player
    render_hud
    render_pause_overlay if @paused
  end
end
