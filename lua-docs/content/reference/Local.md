---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Local

`Local` is a global variable containing everything that should only be visible to client devices (iOS, Android, Windows and Mac devices *Particubes* is installed on).

## Fields

### Action1 (Function)

Can be null.

### Action1Release (Function)

Can be null.

### Action2 (Function)

Can be null.

### Action2Release (Function)

Can be null.

### Action3 (Function)

Can be null.

### Action3Release (Function)

Can be null.

### DirectionDidChange (Function)

Can be null.

```lua
-- obtain the direction toward which the player wants to be moved
Local.DirectionDidChange = function(x, y)
	if x > 0 then
		print("player wants to go left")
	elseif x < 0 then
		print("player wants to go right")
	end
	
	if y > 0 then
		print("player wants to go forward")
	elseif y < 0 then
		print("player wants to go backward")
	end
end
```

### Player ([Player](/reference/Player)) (read-only)

`Local.Player` represents the local [Player](/reference/Player).

### PointerDown (Function)

Can be null.

### PointerMove (Function)

Can be null.

### PointerUp (Function)

Can be null.

### Tick (Function)

`Local.Tick` can be defined and will then be triggered ~30 times per seconds. The time elapsed between 2 ticks is passed in parameter, in seconds, with millisecond precision. The value will not always be `0.033` as `Local.Tick ` calls are not perfectly regular.

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