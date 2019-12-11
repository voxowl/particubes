---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Resources

`Resources` is a global table containing the names of the game resources (imported with the `Import` function).

When you import a resource using `Import("<repo>/<name>")`, it is made available as `Resources.<repo>.<name>`.

## Usage

```
-- Import the map resource
Import("aduermael.dont_fall") 

-- Set the map using the imported resource
Map.Set(Resources.aduermael.dont_fall)
```

`Resources` is also accessible using its shorter name `R`.


The two following lines are equivalent:

```
Map.Set(Resources.aduermael.dont_fall)

Map.Set(R.aduermael.dont_fall)
```