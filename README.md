# Dungeon

## TIPS

- **Resource _init args** must have a default value or it will cause silent error
- In `Visitor.run`, use `CONNECT_ONE_SHOT` when connecting a signal

## TODO

- on finish combat
    - if there is no next room, push a random zone room
    - next room

- bug: camera moving to new room is wonky
- feat: 'action' to pick up enemy weapon when walking past?
    - (later) slow-mo and show quick time event info
- feat: projectiles
- feat: AI randomly triggers sweet spot, frequency depends on difficulty setting
- feat: display weapon info in pause screen
    - attack strategy
    - damage / strength_ratio
