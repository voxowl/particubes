---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Player

Object to represent any connected player.

`Player` is also a global variable that is an alias to `Local.Player`, representing the local player.

Some fields are specific to the local player only.

## Fields

### BlockUnderneath ([Block](/reference/Block)) (read-only)

Returns the [Block](/reference/block) the player is standing on. Returns `nil` if `Player.IsOnGround == false`.

### CastRay (Function)

Casts a ray from player's position, returns an [Impact](/reference/Impact) object if it hits something, `nil` otherwise.

```lua
local impact = Player: CastRay()

if impact ~= nil then
	print(impact)
end
```

### Give (Function, read-only)

Gives an item to the `Player`. The parameter has to be an holdable item. (items can be browsed in the gallery)

```lua
Import("aduermael.rainbow_sword")

Player:Give(R.aduermael.rainbow_sword)
```

### Id (Integer, read-only)

Unique player id for played game. A different id can be attributed after reconnection.

### IsOnGround (Boolean, read-only)

`Player.IsOnground` is true if there's a block right underneath `Player`'s feet.

### Jump (Function)

`Player.Jump` is triggered when jumping. `nil` by default, it has to be defined for players to jump!

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
		player.jumpCounter = 1
	elseif player.jumpCounter == 1 then
		player.Velocity.Y = Local.Config.DefaultJumpStrength * 1.5
		player.jumpCounter = 2
	end
end
```

### Position ([Number3](/reference/Number3))

`Player`'s absolute world position.

Different ways to set it:

```lua
player.Position = { 300, 300, 300 }
player.Position = { X = 300, Y = 300, Z = 300 }
player.X = 300
player.Y = 300
player.Z = 300
```

### Rotation ([Number3](/reference/Number3))

`Player`'s rotation. (`Y` value is not considered)

Different ways to set it:

```lua
-- x = 0 and z = 1 means facing north
player.Position = { 0, 0, 1 }
player.Position = { X = 0, Z = 1 }
player.X = 0
player.Z = 1
```

### Say (Function)

Sends a message that will be displayed in the game console. All connected players will see it.

How to use it: 

```lua
player:Say("Hello everyone!")
```

### Swap (Function)

Takes no argument, swaps held items.

How to use it:

```lua
player:Swap()
```

### Username (String, read-only)

`Player`'s account username. Usernames are unique.

### Velocity ([Number3](/reference/Number3))

`Player`'s velocity (speed + direction).

Different ways to set it:

```lua
Player.Velocity = { 300, 300, 300 }
Player.Velocity = { X = 300, Y = 300, Z = 300 }
Player.Velocity.X = 300
Player.Velocity.Y = 300
Player.Velocity.Z = 300
```
