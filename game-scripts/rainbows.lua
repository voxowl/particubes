-- Hi! Welcome to the current default script!
-- Lines that start with "--" are comments. 
-- Comments aren't considered when running the code,
-- it's a good thing to use them to leave notes for
-- yourself and other code contributors! :)

-- First thing to do in a game script: import some items!
-- (including the map)
-- Complete item names should be used: .
-- Official items can be imported with just  (shortcut for official.)
-- Imported items become available under Resources (or R shortcut):
-- Resources.. (or R..)
Import (
    "gdevillele.tower2_map" -- item used as map
)

-- draws rainbows on the ground when true
Player.rainbowMode = false

Local.blueBlock = Block.New(28)
Local.greenBlock = Block.New(11)
Local.yellowBlock = Block.New(10)
Local.orangeBlock = Block.New(25)
Local.redBlock = Block.New(24)

-- Events are objects that can be sent to other players, 
-- and/or to the Server.
-- There are pre-defined event types, documented here:
-- https://docs.particubes.com/reference/EventType
-- We can declare custom ones this way:
EventType.playerDied = EventType:New()

-- Set the map
-- (R is a shortcut for Shared.Resources)
Map.Set(R.gdevillele.tower2_map)

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
	-- Do not check if on round to be able to "fly"
    -- if player.IsOnGround then
        player.Velocity.Y = Config.DefaultJumpStrength
    -- end
end

-- This function can be called to drop the local player above
-- the center of the map.
Local.dropAboveCenter = function()
    Player.Position = { Map.Width * 0.5, Map.Height  + 10, Map.Depth * 0.5 }
    Player.Rotation = { 0, 0, 0 }
    Player.Velocity = { 0, 0, 0 }
end

-- Define primary action function for the local Player
-- (left click on desktop, primary action button on mobile)
-- Note that "Player" is a shortcut for "Local.Player"
Player.PrimaryAction = function(player)
    if Player.rainbowMode == false then
        Player.rainbowMode = true
        Player:Say("🌈 mode! 🤩")
    else 
        Player.rainbowMode = false
    end
end

Player.PrimaryActionRelease = nil
Player.SecondaryAction = nil
Player.SecondaryActionRelease = nil

function Player.getLineBlocks(player, block)
    
    local pi = math.pi
    
    local orientation = player.Rotation.Y
    
    if orientation > (7.0 * pi / 8.0) or orientation < -(7.0 * pi / 8.0) then
       return {
            Map.GetBlock(block.X - 2, block.Y, block.Z),
            Map.GetBlock(block.X - 1, block.Y, block.Z),
            block,
            Map.GetBlock(block.X + 1, block.Y, block.Z),
            Map.GetBlock(block.X + 2, block.Y, block.Z)
        }
    elseif orientation > (5.0 * pi / 8.0) then
    	return {
            Map.GetBlock(block.X - 2, block.Y, block.Z - 2),
            Map.GetBlock(block.X - 1, block.Y, block.Z - 1),
            block,
            Map.GetBlock(block.X + 1, block.Y, block.Z + 1),
            Map.GetBlock(block.X + 2, block.Y, block.Z + 2)
        }
	elseif orientation > (3.0 * pi / 8.0) then
		return {
            Map.GetBlock(block.X, block.Y, block.Z - 2),
            Map.GetBlock(block.X, block.Y, block.Z - 1),
            block,
            Map.GetBlock(block.X, block.Y, block.Z + 1),
            Map.GetBlock(block.X, block.Y, block.Z + 2)
        }
	elseif orientation > (1.0 * pi / 8.0) then
		return {
            Map.GetBlock(block.X + 2, block.Y, block.Z - 2),
            Map.GetBlock(block.X + 1, block.Y, block.Z - 1),
            block,
            Map.GetBlock(block.X - 1, block.Y, block.Z + 1),
            Map.GetBlock(block.X - 2, block.Y, block.Z + 2)
        }
    elseif orientation > (-1.0 * pi / 8.0) then
		return {
            Map.GetBlock(block.X + 2, block.Y, block.Z),
            Map.GetBlock(block.X + 1, block.Y, block.Z),
            block,
            Map.GetBlock(block.X - 1, block.Y, block.Z),
            Map.GetBlock(block.X - 2, block.Y, block.Z)
        }
    elseif orientation > (-3.0 * pi / 8.0) then
		return {
			Map.GetBlock(block.X + 2, block.Y, block.Z + 2),
			Map.GetBlock(block.X + 1, block.Y, block.Z + 1),
			block,
			Map.GetBlock(block.X - 1, block.Y, block.Z - 1),
			Map.GetBlock(block.X - 2, block.Y, block.Z - 2)
        }
    elseif orientation > (-5.0 * pi / 8.0) then
		return {
			Map.GetBlock(block.X, block.Y, block.Z + 2),
			Map.GetBlock(block.X, block.Y, block.Z + 1),
			block,
			Map.GetBlock(block.X, block.Y, block.Z - 1),
			Map.GetBlock(block.X, block.Y, block.Z - 2)
        }
    elseif orientation > (-7.0 * pi / 8.0) then
		return {
			Map.GetBlock(block.X - 2, block.Y, block.Z + 2),
			Map.GetBlock(block.X - 1, block.Y, block.Z + 1),
			block,
			Map.GetBlock(block.X + 1, block.Y, block.Z - 1),
			Map.GetBlock(block.X + 2, block.Y, block.Z - 2)
        }
    end
        
    return { nil, nil, nil, nil, nil }
end

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
    end
    
    -- Rainbow mode
    if Player.rainbowMode then
	    local blockUnderneath = Player.BlockUnderneath
	    
	    if blockUnderneath ~= nil then
	        
	        if blockUnderneath.Id ~= Local.yellowBlock.Id then
	            
	            local lineBlocks = Player:getLineBlocks(blockUnderneath)

	            lineBlocks[1]:Replace(Local.blueBlock)
	            lineBlocks[2]:Replace(Local.greenBlock)
	            lineBlocks[3]:Replace(Local.yellowBlock)
	            lineBlocks[4]:Replace(Local.orangeBlock)
	            lineBlocks[5]:Replace(Local.redBlock)
	        end
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

        print("👋 " .. Player.Username .. "!")
        print("Use left click or primary action button on mobile to activate 🌈 mode.")

    elseif event.Type == EventType.OtherPlayerJoined then
        Local.welcomeMessage(event.Player)
    elseif event.Type == EventType.PlayerRemoved then
        print(event.Player.Username .. ' is gone.')
    else
        print('unsupported event type:', event.type)
    end
end

-- This function builds and displays random welcome messages
Local.welcomeMessage = function(player) 
    local welcomeMessages = { " is here.", " just landed.", " joined the party.", " appeared.", " has arrived."}
    local randomIndex = math.random(1, #welcomeMessages)
    print(player.Username .. welcomeMessages[randomIndex])
end
	