---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Config

Contains values used by Particubes Engine when running the script. Some values are read-only and can be used in your own functions. Others can be updated.

Custom fields can be added, as long as names don't start with uppercase characters.

## Fields

### DefaultJumpStrength (Number, read-only)

The default jump strength, applied to `Player.Velocity.Y` when jumping in most games.

It's usually a good thing to apply multiples of `Config. DefaultJumpStrength` when defining jump functions.