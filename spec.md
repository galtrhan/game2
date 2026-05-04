# specs

- tile size is 32x32
- screen size 1280x720 (dragonruby default)

- menu screen:
    - Start
        - generates new world map dynamically
            - tiles genration
            - must have loading screen
        - starts game in newly genarated world map, which expands as needed
            - when outside map has buffer zone preventing running out of map
            - structures have predefined bounds, first floor and outer doors and known floor count - generated is just the first
                - when entering floor, only then we generate floor one below and one floor above if any
            - need to figure out how we periodically save map and load it in parallel not to impact fps and avoid stutter
            - only current zone and buffer zones have active objects any other is being saved in map state when unloaded to be easily reactivated if player returns to them
        - pause screen has:
            - continue - back to game
            - save - saves map and all active object states
            - load - loads saved map and state
            - quit - returns to menu
    - Continue
        - continues saved map - no generation here
    - Quit
        - exits game
