---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Global Environment

The Global Environment of the Lua sandbox is the root of the sandbox. It describes what is available at a global level in the sandbox.

When global variables are declared, they are added to the Global Environment.
```
foo = 'bar'
```

## Fields

### EventType (Enum)

### Local (object)

### PlayerMode (Enum)

### Server (object)

## Disabled Lua functions

Some standard functions that come with your typical Lua sandbox, are unavailable in Particubes Worlds.

- rawset (table, index, value)
- os.*
- coroutine.*
