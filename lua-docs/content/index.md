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

- Find where `Player.Jump` is assigned in the generated script:

	```lua
	-- function triggered when pressing jump key
	Player.Jump = function(player)
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

💡 All variables and functions predefined in the environment have names that start with uppercase characters (like `Config`). You can't use names starting with uppercase characters for your own definitions. It makes things easier. All instances starting with an uppercase character are documented on this website. (see [Reference](/reference))

### Example: fall detection

These lines can be seen in the generated script. They're used to check if the player fell off the world. In that case, the player is dropped above center and an event is dispatched to inform others.

```lua
-- Create custom event to inform others when dying.
EventType.playerDied = EventType.New()

-- Player represents the local player.
-- Player.Tick function is called ~30 times per second.
Player.Tick = function(dt)
	-- Check if player's vertical position is < -300
	if Player.Position.Y < -300 then
		-- Dispatch event to inform others
		local event = Event.New(EventType.playerDied)
		event:SendTo(OtherPlayers)
		-- Call Player's dropAboveCenter function (defined below)
		-- to move back to the center of the world.
		dropAboveCenter()
	end
end

-- Drops local player above center of the map
function dropAboveCenter()
	-- 512 because the map in that game has a width and depth of 1024
    Player.Position = { 512, 800, 512 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end
```






