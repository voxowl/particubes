---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Local

`Local` is a global variable containing everything that should only be visible to client devices (iOS, Android, Windows and Mac devices *Particubes* is installed on).

## Fields

### Player ([Player](/reference/Player)) (read-only)

`Local.Player` represents the local [Player](/reference/Player).

### Tick (Function)

`Local.Tick` can be defined and will then be triggers ~30 times per seconds. The time elapsed between 2 ticks is passed in parameter, in seconds, with millisecond precision. The value will not always be `0.033` as `Local.Tick ` calls are not perfectly regular.

```lua
-- User defined variable
Local.elapsed = 0.0

Local.Tick = function(delta)
	-- increase value of Local.elapsed
	Local.elapsed = Local.elapsed + delta
	-- check if it's been 60 seconds
	if Local.elapsed >= 60 then
		print("It's been 1 minute!")
		-- decrement 60 seconds instead of setting it to 0
		-- to keep remaining milliseconds.
		Local.elapsed = Server.elapsed - 60
	end
end
```

### PointerDown (Function)

`Local.PointerDown` is triggered when the user clicks or touches the screen while on pointer mode and not clicking on a button. The parameters represent the x and y screen coordinates where the click or touch has been made.

```lua
Local.PointerDown = function(x, y)
	print("Press in x = ", x, ", y = ", y)
end
```

### PointerUp (Function)

`Local.PointerUp` is triggered when the user stops pressing the left mouse button or the screen while on pointer mode and not clicking on a button. The parameters represent the x and y screen coordinates where the user has stopped pressing.

### PointerMove (Function)

`Local.PointerMove` is called every tick if a movement has been applied to the pointer between calls of `Local.PointerDown` and `Local.PointerUp`. The parameters give the final x and y coordinates and the x and y difference between the current call and the previous one.

```lua
Local.PointerMove = function(x, y, dx, dy)
	print("Pointer has moved from x = ", x - dx, ", y = ", y - dy, " to x = ", x, ", y = ", y)
end
```