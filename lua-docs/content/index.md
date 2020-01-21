---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Introduction

In Particubes, all rules and behaviors in the games you play are scripted with a language called [Lua](https://www.lua.org).

A default Lua script is generated when you create a world, you can open it from the pause menu.

The author of a world can allow other users to see the script.

Lua is easy to learn, don't worry if you never used it. You'll be able to define custom behaviors for your worlds in minutes. ☺️

### Quick example: How to jump higher?

- Find where `Local.Player.Jump` (or `Player.Jump`) is assigned in the generated script:

	```lua
	-- function triggered when pressing jump key
	Local.Player.Jump = function(player)
		-- Test if player is on ground before changing velocity,
		-- otherwise, player could jump while in the air. :D
		if player.IsOnGround then
			player.Velocity.Y = Config.DefaultJumpStrength
		end
	end
	```
- Edit this line: 

	```lua
	player.Velocity.Y = Config.DefaultJumpStrength * 3 -- added "* 3" to jump higher!
	```
- Use "Publish" button

	The game will restart for all connected players (including yourself), everyone will now jump higher. 🙂
	
💡 Script comments start with `--`. Comments are not considered when running the script, they're only notes for developers.


# Scripting environment

The script runs in an environment that contains predefined functions and variables. It allows developers to do powerful things and focus on gameplay without worrying about things like collisions, networking, storage, 3D rendering, etc.

💡 All variables and functions predefined in the environment have names that start with uppercase characters (like `Player`). You can't use names starting with uppercase characters for your own definitions. It makes things easier. All instances starting with an uppercase character are documented on this website. (see [Reference](/reference))

## Local / Server / Shared

`Local`, `Server` & `Shared` are top level variables exposed in the scripting environment.

Most predefined variables and your own definitions must belong to one of these 3 destinations.

What's in `Local` is only visible to client devices (iOS, Android, Windows and Mac devices *Particubes* is installed on).

What's in `Server` is only visible to the game server.

What's in `Shared` is automatically synchronized between all connected players and the server.

💡 Other variables look like top level variables, like `Player`. But they're in fact shortcuts to encapsulated ones: `Player == Local.Player`.


### Example: fall detection

These lines can be seen in the generated script. They're used to check if the player fell off the map. In that case, the player is dropped above center and an event is dispatched to inform others.

```lua
-- Local.Tick is called continuously, 30 times per second.
-- In this sample script, we're using it to detect if the 
-- player is falling from the map.
Local.Tick = function(dt)
    if Player.Position.Y < -200 then
        -- Local.Player.Say posts a message in the chat
        Player:Say('Nooooo! 😵')
        -- Bring the player back above center
        Local.dropAboveCenter()
    end
end

-- This function can be called to drop the local player above
-- the center of the map.
Local.dropAboveCenter = function()
    Player.Position = { Map.Width * 0.5, Map.Height  + 10, Map.Depth * 0.5 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end
```






