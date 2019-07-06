---
description: Particubes
keywords:
- particubes, game, mobile, scripting, cube, voxel, world
---

# Introduction

In Particubes, all experiences are scripted with a language called [Lua](https://www.lua.org). You can always see the script that's been generated for your own worlds, from the pause menu. You can also edit scripts of worlds created by others as long as you've been given the right to do so.

Lua defines a syntax. For example, functions are written this way: 

```lua
-- doSomething does something <- comment
function doSomething(argument1)
	-- implementation
end
```

Lua is easy to learn, don't worry if you never used it. You'll be able to define custom behaviors for your world in minutes. ☺️

# The Lua Sandbox

As mentioned above, Lua by itself defines a syntax. But it allows Particubes Engine developers to create a **sandbox**. The sandbox is the environment in which your script is going to be executed. 

In other words, it means that some functions and variables are already defined. You don't see them all in the initial script, but you can and will have to use them in order to obtain what you want.

💡 All variables and functions defined in the **sandbox** have names that start with uppercase characters. You can't use names starting with uppercase characters for your own definitions. It makes things easier. All instances starting with an uppercase character are documented on this website. (see index)

Here's a script that assigns random jump functions to incoming players:

```lua

-- jump functions

function normalJump(player)
    if player.IsOnGround then
        player.Velocity.Y = 120
    end
end

function bigJump(player)
    if player.IsOnGround then
        player.Velocity.Y = 600
    end
end

-- Everything that's in "Local" runs player devices (locally).
-- Each player will execute the same script.
-- Local.DidReceiveEvent is called when an event arrives on the device.
-- It can comes from the server or from other players.
Local.DidReceiveEvent = function(event)

	if event.Type == EventType.PlayerAdded then
		local player = event.Player
		-- Only set Jump function if added player is the local one.
		-- Each player will execute this part for himself.
		if player.IsLocal then
			local r = math.random()
			-- It's unfair, but each player gets a random
			-- jump function in my game! :p
			if r < 0.5 then 
                player.Jump = normalJump
			else 
                player.Jump = bigJump
			end
		end
	end
end
```






