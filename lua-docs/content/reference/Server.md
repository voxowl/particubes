---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Server

The `Server` acts as a host and director for the game.

For example, if your game requires a minimum amount of players, it's a good idea to use the `Server` to count and trigger game start.

Unlike [Players](/reference/Players), the `Server` never leaves the game. 🙂

## Fields

### DidReceiveEvent (Function)

`Server.DidReceiveEvent` is called when the [Server](/reference/Server) receives an [Event](/reference/Event).

```lua
-- Where your events are defined
EventType.playerDied = EventType.New()

-- [...]

Server.DidReceiveEvent = function(event)
	if event.Type == EventType.playerDied then
		print("Haha! 😄")
	end
end
```

### Tick (Function)

💡 If you're **not** an experienced developer, `Server.Timer` is probably easier to use if you want to schedule operations.

`Server.Tick` can be defined and will then be triggers 20 times per seconds. The time elapsed between 2 ticks is passed in parameter, in seconds, with millisecond precision. The value will not always be `0.05` as `Server.Tick` calls are not perfectly regular.

```lua
-- User defined variable
Server.elapsed = 0.0

Server.Tick = function(delta)
	-- increase value of Server.elapsed
	Server.elapsed = Server.elapsed + delta
	-- check if it's been 60 seconds
	if Server.elapsed >= 60 then
		print("It's been 1 minute!")
		-- decrement 60 seconds instead of setting it to 0
		-- to keep remaining milliseconds.
		Server.elapsed = Server.elapsed - 60
	end
end
```

## Coming soon

### Say (Function, read-only) 👷‍♀️COMING SOON👷‍♂️

`Server.Say` can be used to say things, as the [Server](/reference/Server). Players will see something like this in the console: `Server: <message>`. 

```lua
Server.DidReceiveEvent = function(event)
	if event.Type == EventType.playerDied then
		Server:Say("Haha! 😄")
	end
end
```

### Timer (Table) 👷‍♀️COMING SOON👷‍♂️

`Server.Timer` can be used to schedule function calls with a defined time interval.

```lua
-- Schedule function call every 10 seconds:
Server.Timer["10s"] = function()
	print("It's been 10 seconds!")
end

-- Stop the timer:
Server.Timer["10s"] = nil

-- ⚠️ Here, only `myFunction2` will be called every minute
-- Only one function assignation per time interval is allowed.
Server.Timer["1m"] = myFunction1
Server.Timer["1m"] = myFunction2

-- A workaround for both myFunction1 & myFunction2 to be called:
Server.Timer["10s"] = function()
	myFunction1()
	myFunction2()
end
```

Supported time interval suffixes: `ms` (milliseconds), `s` (seconds), `m` (minutes), `h` (hours)

The smallest time interval possible is `"50ms"`