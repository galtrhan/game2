require 'app/game/constants'
require 'app/scenes/menu'
require 'app/scenes/outro'
require 'app/game/map'
require 'app/game/save_load'
require 'app/game/collision'
require 'app/game/npcs'
require 'app/game/interaction'
require 'app/game/input'
require 'app/game/camera'
require 'app/game/renderer'
require 'app/scenes/game_scene'
require 'app/scene_manager'

$scene_manager = SceneManager.new

def tick args
  $scene_manager.args = args
  $scene_manager.tick
end

$gtk.reset
