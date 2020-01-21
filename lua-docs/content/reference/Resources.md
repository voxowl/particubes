---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Resources

`Resources` and `R` are global aliases to `Shared.Resources`, a table containing loaded game resources (imported with [Import](/reference/Import)).

When you import a resource using `Import("<repo>.<name>")`, it is made available as `Resources.<repo>.<name>`.

## Usage

```
-- Import the map resource
Import("aduermael.dont_fall") 

-- Set the map using the imported resource
Map.Set(Shared.Resources.aduermael.dont_fall)
-- can also be written
Map.Set(Resources.aduermael.dont_fall)
-- or even shorter
Map.Set(R.aduermael.dont_fall)
```