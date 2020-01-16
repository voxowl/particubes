--
--
-- Don't Fall
--
--

-- First thing to do in a game script: import some items!
-- (including the map)
-- Complete item names should be used: <repository>.<item>
-- Official items can be imported with just <item> (shortcut for official.<item>)
-- Imported items become available under Resources (or R shortcut):
-- Resources.<repository>.<item> (or R.<repository>.<item>)
Import (
    "aduermael.dont_fall_2" -- item used as map
)

-- Events are objects that can be sent to other players, 
-- and/or to the Server.
-- There are pre-defined event types, documented here:
-- https://docs.particubes.com/reference/EventType
-- We can declare custom ones this way:
EventType.playerDied = EventType:New() 

-- Set the map
-- (R is a shortcut for Shared.Resources)
Map.Set(R.aduermael.dont_fall_2)

-- Config is also exposed by the engine, it contains 
-- a few pre-configured values. (like Config.DefaultJumpStrength)
-- We can also use it to store our own things:
Config.fireRate = 0.1

Local.Player.triggerOn = false
Local.Player.firedOnce = false
Local.Player.fireDT = 0.0

-- Local.Player represents the local player.
-- Local.Player.Jump is nil (non existent) by default but we
-- can assign a function, defining how the players jumps
-- in the game. 
-- NOTE: players can jump differently based on the item
-- they're holding for example.
Local.Player.Jump = function (player)
    -- Test if player is on ground before changing velocity,
    -- otherwise, player could jump while in the air. :D
    if player.IsOnGround then
      player.Velocity.Y = Config.DefaultJumpStrength
    end
end

-- Left click / primary action
Player.PrimaryAction = function(player)
    Player.triggerOn = true
    Player.firedOnce = false
end

Player.PrimaryActionRelease = function(player)
    if Player.firedOnce == false then
        local impact = player:CastRay()
        if impact.Block ~= nil then
           impact.Block:Remove() 
        end
    end
    Player.triggerOn = false
end

-- Local.Tick is called continuously, 30 times per second.
-- In this sample script, we're using it to detect if the 
-- player is falling from the map, to automatically make the
-- player jump when touching the ground, and to auto-fire.
Local.Tick = function(dt)
    -- test for local player death
    if Player.Position.Y < -300 then
        local e = Event.New(EventType.playerDied)
        e:SendTo(Server)
        Player.Velocity.Y = 0
        Local.dropAboveCenter()
    end
    -- auto-fire
    if Player.triggerOn then
        Player.fireDT = Player.fireDT + dt

        if Player.fireDT > Config.fireRate then
            Player.fireDT = Player.fireDT - Config.fireRate
            Player.firedOnce = true
            local impact = Player:CastRay()
            if impact.Block ~= nil then
               impact.Block:Remove() 
            end
        end 
    end
    -- auto jump
    if Player.BlockUnderneath ~= nil then
       Player:Jump()
        local u = Player.BlockUnderneath
        Block.New(1, u.X + 1, u.Y, u.Z):Remove()
        Block.New(1, u.X - 1, u.Y, u.Z):Remove()
        Block.New(1, u.X, u.Y, u.Z + 1):Remove()
        Block.New(1, u.X, u.Y, u.Z - 1):Remove()
        Block.New(1, u.X + 1, u.Y, u.Z + 1):Remove()
        Block.New(1, u.X - 1, u.Y, u.Z + 1):Remove()
        Block.New(1, u.X + 1, u.Y, u.Z - 1):Remove()
        Block.New(1, u.X - 1, u.Y, u.Z - 1):Remove()
        u:Remove()
    end
end

-- 
Player.DidReceiveEvent = function(event)
    if event.Type == EventType.PlayerJoined then
        
        Local.welcomeMessage(Player)
        
        -- spawn player
        Local.dropAboveCenter()
        
        -- this will be done automatically soon
        -- no need to worry about this line
        Player.Mode = PlayerMode.Playing
        
    elseif event.Type == EventType.OtherPlayerJoined then
        welcomeMessage(event.Player)
        
    elseif event.Type == EventType.PlayerRemoved then
        print(event.Player.Username .. ' is gone.')

    else
        print('unsupported event type:', event.type)
    end
end

--
Server.Tick = nil

--
Server.DidReceiveEvent = nil

--
-- custom functions
--

-- Drops player above center of the map
-- (combine player's Username with random suffix)
Local.dropAboveCenter = function()
    Player.Position = { Map.Width * 0.5, Map.Height + 5, Map.Depth * 0.5 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end

-- Prints welcome message
Local.welcomeMessage = function(player) 
    local welcomeMessages = { " is here.", " just landed.", " joined the party.", " appeared.", " has arrived."}
    local randomIndex = math.random(1, #welcomeMessages)
    print(player.Username .. welcomeMessages[randomIndex])
end
