---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Introduction

In Particubes, all rules and behaviors in the games you play are scripted with a language called [Lua](https://www.lua.org).

A default Lua script is generated when you create a new game. You can launch the game in debug mode and select `Edit code` in the pause menu to see it.

By default, only the author of a game can access its code. But it's possible to allow other users to contribute. (more to come about this)

Lua is easy to learn, don't worry if you've never used it. You'll be able to define custom things for your games in minutes. ☺️

### Quick example: How to jump higher?

- Find where `Client.Action1` is defined in the default script:

	```lua
	-- function triggered when pressing the Action1 button
	Client.Action1 = function()
		-- Player represents the local player ingame avatar.
		-- Test if Player is on ground before changing velocity,
		-- otherwise, player could jump while in the air. :D
		if Player.IsOnGround then
			Player.Velocity.Y = 50
		end
	end
	```
- Edit this line: 

	```lua
	Player.Velocity.Y = 200 -- changed the value to jump higher
	```
- Use "Publish" button

	The game will restart for all connected players (including yourself), everyone will now jump higher. 🙂
	
💡 Script comments start with `--`. Comments are not considered when running the script, they're only notes for developers.


# Scripting environment

Game scripts run in an environment that contains predefined functions and variables. It allows developers to do powerful things and focus on gameplay without worrying about things like collisions, networking, storage, 3D rendering, etc.

💡 All predefined variables and functions have names that start with uppercase characters (like `Player`). You can't use names starting with uppercase characters for your own definitions. It makes things easier because you can be sure that all instances starting with uppercase characters are documented on this website. (see [Reference](/reference))

## Client / Server / Shared

`Client`, `Server` & `Shared` are top level variables exposed in the scripting environment.

Most predefined variables and your own definitions must belong to one of these 3 destinations.

What's in `Client` is accessed and processed on each connected player device.

What's in `Server` is accessed and processed on the game server.

What's in `Shared` is meant to be synchronized between all connected players and the server.

💡 Other variables may look like top level variables, like `Player` or `Time`. But they're in fact shortcuts to encapsulated ones: `Player == Client.Player`, `Time == Shared.Time`.

### Example: fall detection

These lines can be seen in the default game script. They're used to do something when the player falls off the map:

```lua
-- Client.Tick is called repeatedly and indefinitely,
-- ~30 times per second.
-- In this script, we're using it to detect if the 
-- player is falling off the map.
Client.Tick = function(dt)
    -- dt represents the elapsed time (in seconds)
    -- since previous Tick. But we don't need it here.
    if Player.Position.Y < -200 then
        -- Player:Say posts a message in the chat
        -- on behalf of the local player.
        Player:Say('Nooooo! 😵')
        -- Bring the player back above center
        Client.dropAboveCenter()
    end
end

-- This function drops the local player above
-- the center of the map.
Client.dropAboveCenter = function()
    -- all coordinates are in Blocks
    Player.Position = { Map.Width * 0.5, Map.Height + 10, Map.Depth * 0.5 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end
```






