# Dungeon game notes

## TODO

- Game State
  - [ ] X number of lives
  - Death
    - [ ] solo: option to start from beginning of zone or quit
    - [ ] online: start from beginning of zone
- Item
  - [ ] offer augment every X [rooms|combats]
- Events
  - Escort
    - [ ] npcs follow player
    - [x] npc can hold items
    - [ ] npc will flee when player dies
  - Quest
    - [ ] can be viewed from map screen
- Online
  - Pretty much same gameplay as solo except players can
    - Affect each other in certain rooms
    - Fight other players periodically
  - [ ] add checkbox at main menu to allow/disallow multiplayer features

### Polish

- Zones
  - [ ] add shaders (rotating circles in bg, bg distortion)
  - [ ] view map of discovered areas
    - reset at beginning of each new game?
  - [ ] calculate difficulty based on:
    - strength of enemies that can appear
    - room size?
- Events
  - [ ] add `rarity`: chance of event appearing
  - Quest
    - [ ] can view quest list on map screen

## Free assets

https://craftpix.net/

## Zones shader idea

- break background with circles
  - start shaders
  - draw backgrounds with stencils
  - end shaders
  - draw zone contents with stencils
