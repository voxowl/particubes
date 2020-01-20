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
Config.breakableBlock = Block.New(68) -- to identify blocks that can be broken
Config.lavaBlock = Block.New(25) -- to identify lava blocks
Config.spawnAreas = {
    {{x = 18, z = 3}, {x = 36, z = 24}},
    {{x = 5, z = 26}, {x = 11, z = 32}},
    {{x = 4, z = 40}, {x = 23, z = 55}},
    {{x = 44, z = 44}, {x = 57, z = 57}},
    {{x = 47, z = 19}, {x = 60, z = 33}}
}

Config.fireRate = 0.1

Local.Player.triggerOn = false
Local.Player.firedOnce = false
Local.Player.fireDT = 0.0

-- Local.Player represents the local player.
-- Local.Player.Jump is nil (non existent) by default.
-- In this game, a player cannot decide to jump.
Local.Player.Jump = nil

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
    if Player.Position.Y < -200 then
        Local.die()
    end
    -- auto-fire
    if Player.triggerOn then
        Player.fireDT = Player.fireDT + dt

        if Player.fireDT > Config.fireRate then
            Player.fireDT = Player.fireDT - Config.fireRate
            Player.firedOnce = true
            local impact = Player:CastRay()
            if impact.Block ~= nil then
               Local.removeBreakableBlock(impact.Block.X, impact.Block.Y, impact.Block.Z)
            end
        end 
    end
    -- auto jump
    if Player.BlockUnderneath ~= nil then
        
        Local.privateJump(Player)
        
        local u = Player.BlockUnderneath
        
        if u.Id == Config.lavaBlock.Id then
            Local.die()
        else
            Local.removeBreakableBlock(u.X + 1, u.Y, u.Z)
            Local.removeBreakableBlock(u.X - 1, u.Y, u.Z)
            Local.removeBreakableBlock(u.X, u.Y, u.Z + 1)
            Local.removeBreakableBlock(u.X, u.Y, u.Z - 1)
            Local.removeBreakableBlock(u.X + 1, u.Y, u.Z + 1)
            Local.removeBreakableBlock(u.X - 1, u.Y, u.Z + 1)
            Local.removeBreakableBlock(u.X + 1, u.Y, u.Z - 1)
            Local.removeBreakableBlock(u.X - 1, u.Y, u.Z - 1)
            Local.removeBreakableBlock(u.X, u.Y, u.Z)
        end
    end
end

-- 
Player.DidReceiveEvent = function(event)
    if event.Type == EventType.PlayerJoined then
        Local.welcomeMessage(Player)
        
        -- spawn player
        Local.spawn()
        
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

-- Server.DidReceiveEvent is triggered when an event 
-- is received by the Server.
-- Pre-defined event types (the ones starting with uppercase characters)
-- are documented here: https://docs.particubes.com/reference/EventType
-- But custom events arrive here as well.
Server.DidReceiveEvent = function(event)
    if event.Type == EventType.playerDied then
        local player = event.Sender

        -- start counter at 1 if it's never been initialized
        if player.count == nil then
            player.count = 1
        else
            -- increment
            player.count = player.count + 1
        end

        -- print message in all player consoles
        if player.count == 1 then
            print("☠️ " .. player.Username .. " died once.")
        else 
            print("☠️ " .. player.Username .. " died " .. player.count .. " times.")
        end
    end
end

-- Removes block at given coords if the block is breakable
function Local.removeBreakableBlock(x, y, z)
    local b = Map.GetBlock(x, y, z)
    if b.Id == Config.breakableBlock.Id then
        b:Remove()
    end
end

-- Called when touching lava or falling off the map
Local.die = function()
    local e = Event.New(EventType.playerDied)
    e:SendTo(Server)
    Local.spawn()
end

-- Drops player above center of the map
-- (combine player's Username with random suffix)
Local.spawn = function()
    local area = math.random(1, #Config.spawnAreas)
    local x = math.random(Config.spawnAreas[area][1].x, Config.spawnAreas[area][2].x)
    local z = math.random(Config.spawnAreas[area][1].z, Config.spawnAreas[area][2].z)
    
    Player.Position = { x, Map.Height - 5, z }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end

-- Prints welcome message
Local.welcomeMessage = function(player) 
    local welcomeMessages = { " is here.", " just landed.", " joined the party.", " appeared.", " has arrived."}
    local randomIndex = math.random(1, #welcomeMessages)
    print(player.Username .. welcomeMessages[randomIndex])
end

-- Private jump function that cannot be triggered by the player,
-- but only by the game
Local.privateJump = function(player) 
    if player.IsOnGround then
      player.Velocity.Y = Config.DefaultJumpStrength
    end
end
