---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Map

`Map` is a global variable that represents the world map.

## Fields

### Width (Integer, read-only)

Returns the map's width, measured in cubes.

### Height (Integer, read-only)

Returns the map's height, measured in cubes.

### Depth (Integer, read-only)

Returns the map's depth, measured in cubes.

### Scale (Float, read-only)

Returns the map's scale factor.

### Set (Function, read-only)

Function to define the world map.

Parameters:

- map name (string)
- scale factor (float)

```
Map.Set("myMap.particubes", 8)
```