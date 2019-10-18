---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Block

Usually represents one block in the map. But could also represent a block for any shape in the game.

## Class Field

### New (Function, read-only)

Creates and returns a new Block instance.

Arguments are:

- block id (int)
- x (int) (optional)
- y (int) (optional)
- z (int) (optional)

This function can be called with either 1 argument or 4.

```
local b1 = Block.New(id);
local b2 = Block.New(id, x, y, z);
```

## Instance Fields

### Id (Integer, read-only)

Identifies the block type (used as color index). Two blocks with the exact same color have the same `Id`.

### X (Integer, read-only)

X position (in map or shape space).

### Y (Integer, read-only)

Y position (in map or shape space).

### Z (Integer, read-only)

Z position (in map or shape space).
