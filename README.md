# Dungeon

## TIPS

- Resource _init args must have a default value or it will cause silent error

## TODO

- feat: looting
- feat: projectile weapon
- clean: find other stuff to decouple

## Glossary

- **attack** deal damage, `+1 charge` to all items
- **quick_attack** deal damage, `+0 charge` to all items
- **item** activates when attacking at `n charges`
- **held_item** used to **attack**

## Zones

Each zone has a unique mini game theme. Typically you can get to a new zone after
**defeating the boss** in the previous zone or **completing an important quest**.

- **Forest** get basic weapons, basic items, basic quests
- **Town** lots of quests
- **Medieval Times** quick time events

## Items (name `charges` effect)

- **Hand (default)** `0` (no effect)
- **Sword** `0` `+2 charge`
- **Spear** `3` attack twice
- **Wand**
- **Dagger** `5` quick_attack `x++` times
