---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# GameMaster

The `GameMaster` acts as an organizer for the game. 

For example, if your game requires a minimum amount of players, it's a good idea to use the `GameMaster` to count and trigger game start.

You could use a [Player](/reference/Player) for that instead. But what if your designed game master [Player](/reference/Player) leaves the game? 😅

## Fields

### DidReceiveEvent (Function)

`GameMaster.DidReceiveEvent` is called when the [GameMaster](/reference/GameMaster) receives an [Event](/reference/Event).

```lua
-- Where your events are defined
EventType.playerDied = EventType.New()

-- [...]

GameMaster.DidReceiveEvent = function(event)
	if event.Type == EventType.playerDied then
		GameMaster.Say("Haha! 😄")
	end
end
```

### Say (Function, read-only)

`GameMaster.Say` can be used to say things, as the [GameMaster](/reference/GameMaster). Players will see something like this in the console: `GameMaster: <message>`. 

```lua
GameMaster.DidReceiveEvent = function(event)
	if event.Type == EventType.playerDied then
		GameMaster.Say("Haha! 😄")
	end
end
```

### Timer (Table)

`GameMaster.Timer` can be used to schedule function calls with a defined time interval.

```lua
-- Schedule function call every 10 seconds:
GameMaster.Timer["10s"] = function()
	print("It's been 10 seconds!")
end

-- Stop the timer:
GameMaster.Timer["10s"] = nil

-- ⚠️ Here, only `myFunction2` will be called every minute
-- Only one function assignation per time interval is allowed.
GameMaster.Timer["1m"] = myFunction1
GameMaster.Timer["1m"] = myFunction2

-- A workaround for both myFunction1 & myFunction2 to be called:
GameMaster.Timer["10s"] = function()
	myFunction1()
	myFunction2()
end
```

Supported time interval suffixes: `ms` (milliseconds), `s` (seconds), `m` (minutes), `h` (hours)

The smallest time interval possible is `"50ms"`

### Tick (Function)

💡 If you're **not** an experienced developer, `GameMaster.Timer` is easier to use if you want to schedule operations.

`GameMaster.Tick` can be defined and will then be triggers 20 times per seconds. The time elapsed between 2 ticks is passed in parameter, in seconds, with millisecond precision. The value will not always be `0.05` as `GameMaster.Tick` calls are not perfectly regular.

```lua
-- User defined variable
GameMaster.elapsed = 0.0

GameMaster.Tick = function(delta)
	-- increase value of GameMaster.elapsed
	GameMaster.elapsed += delta
	-- check if it's been 60 seconds
	if GameMaster.elapsed >= 60 then
		print("It's been 1 minute!")
		-- decrement 60 seconds instead of setting it to 0
		-- to keep remaining milliseconds.
		GameMaster.elapsed -= 60
	end
end
```


.