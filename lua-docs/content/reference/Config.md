---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Config

Contains predefined values used when running the script. Some values are read-only and can be used in your own functions. Others can be updated.

You can also use `Config` to store your own configuration values.

## Fields

### DefaultJumpStrength (Number, read-only)

The default jump strength, applied to `Player.Velocity.Y` when jumping in most games.

It's usually a good thing to apply multiples of `Config.DefaultJumpStrength` when defining jump functions. Like this:

```lua 
Player.Jump = function(player)
    if player.IsOnGround then
        player.Velocity.Y = Config.DefaultJumpStrength * 3
    end
end
```

## Define your own fields

Custom fields can be added, as long as names don't start with uppercase characters.

```lua
Config.myValue = "anything"
```


