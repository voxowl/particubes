---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Block

A Block usually represents one block in the map. But could also represent a block for any shape in the game.

## Constructors

### Block Block(number colorIndex)

colorIndex: number

```
local block = Block(1)
```

### Block(colorIndex, x, y, z)

```
local block = Block(1, 10, 10, 10)
```

### Block(colorIndex, position)

```
local block = Block(1, Number3(10, 10, 10))
-- or
local block = Block(1, {10, 10, 10})
```

## Properties

### New (Function, read-only)

Creates and returns a new Block instance.

Arguments are:

- color id (int)
- x (int) (optional)
- y (int) (optional)
- z (int) (optional)

This function can be called with either 1 argument or 4.

```
local b1 = Block.New(id)
local b2 = Block.New(id, x, y, z)
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

### AddNeighbour (Function, read-only)

`anExistingBlock:AddNeighbour(newBlock, faceTouched)`

This function adds a new block in an existing block's parent shape.

**newBlock**

Describes what block needs to be added (only the color is used)

**faceTouched**

Indicates the face of the existing block against which the new cube should be positioned. (example: `Block.FACE_LEFT`)

This index is returned when using functions such as [Player.CastRay](/reference/Player#CastRay).

### Remove (Function, read-only)

`anExistingBlock:Remove()`

Removes the block from its parent shape.

### Replace (Function, read-only)

`anExistingBlock:Replace(newBlock)`

Replace the block with a new Block.

**newBlock**

The block that replaces the existing block. (only the color is used)