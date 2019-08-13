---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# EventType

Describes the type of an [Event](/reference/Event). Some EventTypes are predefined, but you can also define your owns using `EventType.New()`.

A good practice is to store your types within `EventType`, where predefined ones are located:

```lua
EventType.myCustomEventType = Eventype.New()
```

It's totally fine though to store them elsewhere:

```lua
local myCustomEventType = Eventype.New()
```

### Predefined event types

- `EventType.PlayerJoined`

	Received when local player joins the game.

- `EventType.OtherPlayerJoined`

	Received when non local player joins the game.

- `EventType.PlayerRemoved` 

	Received when a player leaves the game.
