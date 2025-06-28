# Dungeon game notes

## Free assets

https://craftpix.net/

## Zones example

1 {0, 360} 360

2 {90, 270, -90, 90} 180

3 {150, 270, 30, 150, -90, 30} 120

4 {180, 270, 90, 180, 0, 90, -90, 0} 90

5 {} 72

## Zones shader idea

- break background with circles
  - start shaders
  - draw backgrounds with stencils
  - end shaders
  - draw zone contents with stencils
