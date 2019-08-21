---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Number3

Number3 is a structure containing 3 floating number fields.
Number3 fields can be set individually or as a set of 3 values:

```
myNumber3.X = 42.0
myNumber3.Y = 12.3

myNumber3 = { X = 1, Y = 2, Z = 3 }
myNumber3 = { 1, 2, 3 }
```

## Constructors

### New (Function)

This is how you create a `Number3`: 

```lua
local n3 = Number3.New()
n3 = { 1, 2, 3 }

-- Initial values can directly be passed to New():
local n3 = Number3.New(1, 2, 3)
```

## Fields

### X (Number)

### Y (Number)

### Z (Number)

