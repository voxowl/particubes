---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Map

`Map` is a global variable that represents the world map.

## Fields

### AddBlock (Function, read-only)

Adds a block to the Map.

It can by used in two ways:

```
Map.AddBlock(id, x, y, z)
```

```
local newBlock = Block.New(id, x, y, z)
Map.AddBlock(newBlock)
```

### Depth (Integer, read-only)

Returns the map's depth, measured in cubes.

```
local myMapDepth = Map.Depth
```

### Height (Integer, read-only)

Returns the map's height, measured in cubes.

```
local myMapHeight = Map.Height
```

### Scale (Float, read-only)

Returns the map's scale factor.

```
local myMapScale = Map.Scale
```

### Set (Function, read-only)

Function to define the world map.

Parameters:

- map name (string)
- scale factor (float)

The second argument is optional, you can omit it if you want to change the map
without changing the scale of it.

```
Map.Set("myMap.particubes")
Map.Set("myMap.particubes", 8)
```

### Width (Integer, read-only)

Returns the map's width, measured in cubes.

```
local myMapWidth = Map.Width
```