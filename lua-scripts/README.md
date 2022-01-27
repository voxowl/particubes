# Lua scripts

Here are a bunch of useful Lua scripts for Particubes. 🙂

### cameras.lua

This script shows how camera modes exposed in the [docs](https://docs.particubes.com/reference/camera) are implemented. It's easy to start from there to implement your own custom cameras: 

```lua
Camera.customMode = function(camera, param1, param2)
	-- use code from existing mode for inspiration :)
	-- you'll certainly need to set functions like 
	-- Camera.Tick or Camera.OnPointerDrag
end

-- call `Camera:customMode(param1, param2)` to activate
```

### default.lua

This is the script you're starting with currently when creating a new world.

### item_editor.lua

This is what the game engine uses for the Item Editor, with the help of some internal hooks to inject your item. Note that it uses a few private functions that may not be available in a player-based script.
