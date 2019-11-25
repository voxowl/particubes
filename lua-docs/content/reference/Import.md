---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Import

`Import` is a top level function, allowing you to declare what are the resources needed for the Game.

## Usage

You simply need to call the `Import` function, passing the resources' names as parameters:

```
Import("sword", "pickaxe", "hat")
```

## Advanced Usage

Optionally, you can define the `Import` function yourself and customize it for your needs.

```
Import = function() 
	R.Load("sword")
	R.Load("pickaxe")
	R.Load("hat")
end
```
