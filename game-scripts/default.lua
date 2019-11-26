-- Hi! Welcome to the current default script!
-- Lines that start with "--" are comments. 
-- Comments aren't considered when running the code,
-- it's a good thing to use them to leave notes for
-- yourself and other code contributors! :)

-- First thing to do in a game script: import some items!
-- (including the map)
function Preload()
	R.Load("land-map")
	R.Load("big-pen")
	R.Load("big-pickaxe")
end

-- Events are objects that can be sent to other players, 
-- and/or to the GameMaster.
-- There are pre-defined event types, documented here:
-- https://docs.particubes.com/reference/EventType
-- We can declare custom ones this way:
EventType.playerDied = EventType:New()

-- Set the map
Map.Set("land-map", 8)

-- Note: All variables starting with an uppercase character
-- are exposed by the engine and are documented here:
-- https://docs.particubes.com
-- You can define your own variables, as long as the
-- name doens't start with an uppercase character.

-- Player is a globally exposed variable, it represents
-- the local player.
-- Player.Jump is nil (non existent) by default but we
-- can assign a function, defining how the players jumps
-- in the game. 
-- NOTE: players can jump differently based on the item
-- they're holding for example.
Player.Jump = function (player)
    -- Test if player is on ground before changing velocity,
    -- otherwise, player could jump while in the air. :D
    if player.IsOnGround then
        player.Velocity.Y = Config.DefaultJumpStrength
    end
end

-- Player can be used to store custom fields.
-- Let's use this to set a few state properties:
Player.itemIndex = 1

-- Config is also exposed by the engine, it contains 
-- a few pre-configured values.
-- (like Config.DefaultJumpStrength, used in Player.Jump)
-- We can also use it to store our own things:
Config.items = {"", "big-pen", "big-pickaxe"}

-- This function can be called to drop Player above
-- the center of the map.
function dropAboveCenter()
    Player.Position = { Map.Width * 0.5, Map.Height  + 10, Map.Depth * 0.5 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end

-- We can call it right now!
-- Function calls at the root level in the script
-- are executed when the script is loaded.
dropAboveCenter()

-- Define primary action function
-- (left click on desktop, primary action button on mobile)
Player.PrimaryAction = function(player)
    local impact = player:CastRay()
    if impact.Block ~= nil then
    	local holdItem = Config.items[Player.itemIndex]
    	if holdItem == "big-pen" then
			local b = Block.New(15, 0, 0, 0)
			impact.Block:AddNeighbor(b, impact.FaceTouched)
    	elseif holdItem == "big-pickaxe" then
			impact.Block:Remove()
    	end
    end
end

-- PrimaryActionRelease can be defined and is triggered
-- when the primary action input gets released.
Player.PrimaryActionRelease = nil

-- Define secondary action function
-- (right click on desktop, secondary action button on mobile)
Player.SecondaryAction = function(player) 
    player.itemIndex = player.itemIndex + 1
    if player.itemIndex > #Config.items then 
       player.itemIndex = 1 
    end
    Player:Give(Config.items[player.itemIndex])
end

-- SecondaryActionRelease can be defined and is triggered
-- when the secondary action input gets released.
Player.SecondaryActionRelease = nil

-- Player.Tick is called continuously, 30 times per second.
-- In this sample script, we're using it to detect if the 
-- player is falling from the map.
Player.Tick = function(dt)
    if Player.Position.Y < -200 then
        local e = Event.New(EventType.playerDied)
        e:SendTo(GameMaster)
        Player.Velocity.Y = 0
        -- Player.Say posts a message in the chat
        Player:Say('Nooooo! 😵')
        -- Bring the player back above center
        dropAboveCenter()
    end
end

-- Player.DidReceiveEvent is triggered when an event 
-- is received. (sent by the GameMaster or another player)
-- Pre-defined event types (the ones starting with uppercase characters)
-- are documented here: https://docs.particubes.com/reference/EventType
Player.DidReceiveEvent = function(event)
    if event.Type == EventType.PlayerJoined then
        welcomeMessage(Player)
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

-- Prints welcome message
function welcomeMessage(player) 
    local welcomeMessages = { " is here.", " just landed.", " joined the party.", " appeared.", " has arrived."}
    local randomIndex = math.random(1, #welcomeMessages)
    print(player.Username .. welcomeMessages[randomIndex])
end

-- The GameMaster is responsible for coordination.
-- In this example, it simply counts when players 
-- fall off the map.

GameMaster.Counter = {}

-- Nothing to do in GameMaster.Tick
GameMaster.Tick = nil

GameMaster.DidReceiveEvent = function(event)
	if event.Type == EventType.playerDied then
        -- print("PLAYER DIED:", event.Sender)
        -- TODO: add count
	end
end
