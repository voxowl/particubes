-- Hi!
-- 
-- This is a variant of the default script. It has been modified in order 
-- to allow "autofire" when maintaining the primary action button down.
-- This allow adding and removing cubes rapidly.
--
-- Lines that start with "--" are comments. 
-- Comments aren't considered when running the code,
-- it's a good thing to use them to leave notes for
-- yourself and other code contributors! :)

-- First thing to do in a game script: import some items!
-- (including the map)
-- Complete item names should be used: <repository>.<item>
-- Official items can be imported with just <item> (shortcut for official.<item>)
-- Imported items become available under Resources (or R shortcut):
-- Resources.<repository>.<item> (or R.<repository>.<item>)
Import (
    "aduermael.hills", -- item used as map
    "pen", 
    "pickaxe",
    "gdevillele.pan"
)

-- Events are objects that can be sent to other players, 
-- and/or to the Server.
-- There are pre-defined event types, documented here:
-- https://docs.particubes.com/reference/EventType
-- We can declare custom ones this way:
EventType.playerDied = EventType:New()

-- Set the map
-- (R is a shortcut for Shared.Resources)
Map.Set(R.aduermael.hills)

-- Note: All variables starting with an uppercase character
-- are exposed by the engine and are documented here:
-- https://docs.particubes.com
-- You can define your own variables, as long as the
-- name doens't start with an uppercase character.

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

-- Local.Player can be used to store custom fields.
-- Let's use this to store the index of the item currently held by the player.
Local.Player.itemIndex = 1

-- List of items the player can hold
Local.items = {nil, R.pen, R.pickaxe, R.gdevillele.pan}

-- For now, colors can only be refered by their index in the default palette.
-- You can try different ones from 0 to 95.
-- A better system will be introduced soon.
Local.pinkColorIndex = 31

-- Fire rate for adding or removing cubes
-- ("Player" is a shortcut for "Local.Player")
Player.fireRate = 0.1 -- in seconds
Player.triggerOn = false
Player.firedOnce = false -- set to true when the auto-fire did fire at least once
Player.fireDT = 0.0

-- Define primary action function for the local Player
-- (left click on desktop, primary action button on mobile)
-- Note that "Player" is a shortcut for "Local.Player"
Player.PrimaryAction = function(player)
    Player.triggerOn = true
    Player.firedOnce = false
end

-- Player.PrimaryActionRelease can be defined and is triggered
-- when the primary action input gets released.
Player.PrimaryActionRelease = function(player)
    if Player.firedOnce == false then
        Local.fire()
    end
    Player.triggerOn = false
end

-- Define secondary action function
-- (right click on desktop, secondary action button on mobile)
Player.SecondaryAction = function(player) 
    player.itemIndex = player.itemIndex + 1
    if player.itemIndex > #Local.items then 
        player.itemIndex = 1 
    end
    player:Give(Local.items[player.itemIndex])
end

-- SecondaryActionRelease can be defined and is triggered
-- when the secondary action input gets released.
Player.SecondaryActionRelease = nil

-- Local.Tick is called continuously, 30 times per second.
-- In this sample script, we're using it to detect if the 
-- player is falling from the map.
Local.Tick = function(dt)
    if Player.Position.Y < -200 then
        local e = Event.New(EventType.playerDied)
        e:SendTo(Server)
        Player.Velocity.Y = 0
        -- Local.Player.Say posts a message in the chat
        Player:Say('Nooooo! 😵')
        -- Bring the player back above center
        Local.dropAboveCenter()
    elseif Player.IsOnGround then
        local heldItem = Local.items[Local.Player.itemIndex]
        if heldItem == R.gdevillele.pan then -- change color on ground if player is holding the pan
            local u = Player.BlockUnderneath
            if u.Id ~= pinkColorIndex then
                local newBlock = Block.New(Local.pinkColorIndex)
                u:Replace(newBlock)
            end
        end
    end

    -- auto-fire
    if Player.triggerOn then
        Player.fireDT = Player.fireDT + dt
        if Player.fireDT > Player.fireRate then
            Player.fireDT = Player.fireDT - Player.fireRate
            Player.firedOnce = true
            Local.fire()
        end 
    end
end

-- Local.Player.DidReceiveEvent is triggered when an event 
-- is received. (sent by the Server or another player)
-- Pre-defined event types (the ones starting with uppercase characters)
-- are documented here: https://docs.particubes.com/reference/EventType
Player.DidReceiveEvent = function(event)
    if event.Type == EventType.PlayerJoined then
        Local.welcomeMessage(Player)
        -- set player position above the center of the map
        Local.dropAboveCenter()
        -- this will be done automatically soon
        -- no need to worry about this line
        Player.Mode = PlayerMode.Playing
    elseif event.Type == EventType.OtherPlayerJoined then
        Local.welcomeMessage(event.Player)
    elseif event.Type == EventType.PlayerRemoved then
        print(event.Player.Username .. ' is gone.')
    else
        print('unsupported event type:', event.type)
    end
end

-- This function displays random welcome messages
Local.welcomeMessage = function(player) 
    local welcomeMessages = { " is here.", " just landed.", " joined the party.", " appeared.", " has arrived."}
    local randomIndex = math.random(1, #welcomeMessages)
    print(player.Username .. welcomeMessages[randomIndex])
end

-- This function drops the local player above the center of the map
Local.dropAboveCenter = function()
    Player.Position = { Map.Width * 0.5, Map.Height  + 10, Map.Depth * 0.5 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end

-- Used for primay action
Local.fire = function()
    local impact = Player:CastRay()
    if impact.Block ~= nil then
        local heldItem = Local.items[Player.itemIndex]
        if heldItem == R.pen then -- add blocks when holding the pen
            local b = Block.New(Local.pinkColorIndex, 0, 0, 0)
            impact.Block:AddNeighbor(b, impact.FaceTouched)
        elseif heldItem == R.pickaxe then -- remove blocks when holding the pickaxe
            impact.Block:Remove()
        end
    end
end

-- The Server is responsible for coordination.
-- In this example, it simply counts when players 
-- fall off the map.

-- Nothing to do in Server.Tick
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
        print(player.Username .. " died " .. player.count .. " times.")
    end
end
