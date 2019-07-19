---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Player

Object representing a player, someone who's connected to the game.

- Caps fields are read-only (expect for exceptions)
- Lowercase fields are free to use (read/write)

## Fields

### Id (Integer, read-only)

Unique player id for played game. A different id can be attributed after reconnection.

### Username (String, read-only)

`Player`'s account username.

### IsLocal (Boolean, read-only)

When the script runs locally (on player's device), `Player.IsLocal` is true for local player only.

### IsOnGround (Boolean, read-only)

`Player.IsOnground` is true if there's a block underneath `Player`'s feet.

### Jump (Function)

`Player.Jump` is triggered when jumping. `nil` by default, it has to be defined for players to jump! 

Different `Jump` functions assigned randomly when players join the game:

```lua
Player.DidReceiveEvent = function(event)

if event.Type == EventType.Joined then
	-- Assign random jump function, unfair but fun! ^^
	local r = math.random()
	if r < 0.33 then
		Player.Jump = doubleJump    
	elseif r < 0.66 then 
		Player.Jump = bigJump
	else 
		Player.Jump = defaultJump
	end
end

function defaultJump(player)
	if player.IsOnGround then
		player.Velocity.Y = Local.Config.DefaultJumpStrength
	end
end

function bigJump(player)
	if player.IsOnGround then
		player.Velocity.Y = Local.Config.DefaultJumpStrength * 3
	end
end

function doubleJump(player)
	if player.IsOnGround then
		player.Velocity.Y = Local.Config.DefaultJumpStrength
		jumpCounter = 1
	elseif jumpCounter == 1 then
		player.Velocity.Y = Local.Config.DefaultJumpStrength * 1.5
		jumpCounter = 2
	end
end
```

### Position (Number3)

`Player`'s absolute world position.

Different ways to set it:

```lua
player.Position = { 300, 300, 300 }
player.Position = { X = 300, Y = 300, Z = 300 }
player.X = 300
player.Y = 300
player.Z = 300
```

### Rotation (Number3)

*// TODO*

### Say (Function)

Sends a message that will be displayed in the game console. All connected players will see it.

How to use it: 

```lua
player:Say("Hello everyone!")
```

### Velocity (Number3)

`Player`'s velocity (speed + direction).

Different ways to set it:

```lua
Player.Velocity = { 300, 300, 300 }
Player.Velocity = { X = 300, Y = 300, Z = 300 }
Player.Velocity.X = 300
Player.Velocity.Y = 300
Player.Velocity.Z = 300
```

### BlockUnderneath ([Block](/reference/block)) (read-only)

Returns the [Block](/reference/block) the player is standing on. Returns `nil` if `Player.IsOnGround == false`.
