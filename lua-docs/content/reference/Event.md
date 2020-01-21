---
description: Particubes
keywords: particubes, game, mobile, scripting, cube, voxel, world
---

# Event

Events are objects that can be sent to other [Players](/reference/Players) and/or [Server](/reference/Server).

## Constructors

### New (Function)

This is how you create and send an event: 

```lua
local myEvent = Event.New(eventType)
myEvent.someKey = "someValue"
myEvent:SendTo(OtherPlayers)
```

`eventType` has to be an [EventType](/reference/EventType) for the event to be created successfully.

## Fields

### Type ([EventType](/reference/EventType))

Can only be set on creation, when calling `Event.New(eventType)`. 

Useful to test what kind of event just arrived in `Player.DidReceiveEvent` or `Server.DidReceiveEvent`:

```lua
Player.DidReceiveEvent = function(event)
	if event.Type == EventType.Joined then
		Player.Position = { 100, 100, 100 }
	end
end
```

Predefined and custom event types are documented [here](/reference/EventType).

### Sender ([Player](/reference/Player) or [Server](/reference/Server), read-only)

Who sent the event.

### Recipients (array of [Player](/reference/Player) and/or [Server](/reference/Server), read-only)

`event.Recipients` cannot be set directly. Recipients are being set when calling `event:SendTo(...)`.

It's possible to read the list of recipients when receiving an event though, and use it to answer: 

```lua
myEvent:SendDo(otherEvent.Recipients)
```

### Custom fields

Custom fields can be set. Field names have to start with lowercase characters:

```lua
local myEvent = Event.New(eventType)
myEvent.stringValue = "someValue"
myEvent.numberValue = 3.14
myEvent.booleanValue = true
myEvent:SendTo(Server)
```

### SendTo (Function, read-only)

Call this for the event to be sent!

```lua
-- send to other players
myEvent:SendTo(OtherPlayers)

-- send to all players (including self)
myEvent:SendTo(Players)

-- send to Server
myEvent:SendTo(Server)

-- send to specific players
-- ("player1" & "player2" here are stored references)
myEvent:SendTo(player1, player2)
```

💡 The `Server` can intercept all events. It's usually not necessary to do things like this: 

```lua
myEvent:SendTo(Players, Server)
```

### Cancel (Function, read-only)

`event:Cancel()` is only available to the `Server`. It can be used to catch events and stop them before they reach [Player](/reference/Player) recipients:

```lua
Server.DidReceiveEvent = function(event)
	if event.Type == myEventType then
		event:Cancel()
	end
end
```


