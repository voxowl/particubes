---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Impact

An `Impact` object can be returned when casting a ray. (see [Player.CastRay](/reference/Player#CastRay))

### Block ([Block](/reference/Block)) (read-only)

Not `nil` if the [Impact](/reference/Impact) represents a [Block](/reference/Block).

```
local impact = Local.Player:CastRay()

if impact.Block ~= nil then
	print(impact.Block.Id)	-- prints hit block's id
end
```

### Distance (Number) (read-only)

Distance to impact when casting a ray. (see [Player.CastRay](/reference/Player#CastRay))

```
local impact = Local.Player:CastRay()

if impact ~= nil then
	print(impact.Distance)
end
```

### FaceTouched (Number) (read-only)

Not `nil` if the [Impact](/reference/Impact) represents a [Block](/reference/Block).

Index of hit block's face.

### Player ([Player](/reference/Player)) (read-only)

Not `nil` if the [Impact](/reference/Impact) represents a [Player](/reference/Player).

```
local impact = Local.Player:CastRay()

if impact.Player ~= nil then
	print(Local.Player.Username .. " ☠️ " .. impact.Player.Username)
end
```


