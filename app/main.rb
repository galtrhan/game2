require 'app/scenes/menu'
require 'app/scenes/game_scene'
require 'app/scenes/outro'
require 'app/scene_manager'

$scene_manager = SceneManager.new

def tick args
  $scene_manager.args = args
  $scene_manager.tick
end

$gtk.reset
