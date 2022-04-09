Config = {
    Map = "aduermael.hills",
    Items = {} -- no items used in that script (yet)
}

-- This script is the most basic implementation
-- for a realtime multiplayer chat room.

Client.OnStart = function()
    -- when sync() is called, an event carrying
    -- local player's information is sent and
    -- distributed to all other connected players.
    function sync()
        local e = Event()
        e.action = "sync"
        e.p = Player.Position
        e.m = Player.Motion
        e.v = Player.Velocity
        e.r = Player.Rotation
        e:SendTo(OtherPlayers)
    end

    function dropPlayerAboveTheMap(player)
        player.Position = Map.Scale * {Map.Width * 0.5, Map.Height + 25, Map.Depth * 0.5}
        player.Velocity = {0, 0, 0}
        player.Motion = {0, 0, 0}
        sync()
    end
end

Client.OnPlayerJoin = function(player)
    World:AddChild(player)
    dropPlayerAboveTheMap(player)
end

Client.Tick = function(dt)
    if Player.Position.Y < -500 then
        dropPlayerAboveTheMap(Player)
    end
end

-- jump function
Client.Action1 = function()
    if Player.IsOnGround then
        Player.Velocity.Y = 100
        sync()
    end
end

Client.OnChat = function(message)
    -- display bubble over local Player
    -- when a message is posted
    print(Player.Username .. ": " .. message)
    Player:TextBubble(message, 5, true)

    -- send message to other players
    local e = Event()
    e.action = "chat"
    e.msg = message
    e:SendTo(OtherPlayers)
end

Client.DidReceiveEvent = function(e)
    if e.action == "sync" then
        local sender = e.Sender
        sender.Position = e.p
        sender.Motion = e.m
        sender.Velocity = e.v
        sender.Rotation = e.r
    elseif e.action == "chat" then
            -- display messages from other players
            print(e.Sender.Username .. ": " .. e.msg)
            e.Sender:TextBubble(e.msg, 5, true)
    end
end

-- default AnalogPad implementation
-- with sync() call added at the end
-- https://docs.particubes.com/reference/client#property-analogpad
Client.AnalogPad = function(dx, dy)
    Player.LocalRotation.Y = Player.LocalRotation.Y + dx * 0.01
    Player.LocalRotation.X = Player.LocalRotation.X + -dy * 0.01

    if dpadX ~= nil and dpadY ~= nil then
        Player.Motion = (Player.Forward * dpadY + Player.Right * dpadX) * 50
    end

    sync()
end

-- default DirectionalPad implementation
-- with sync() call added at the end
-- https://docs.particubes.com/reference/client#property-directionalpad
Client.DirectionalPad = function(x, y)
    -- storing globals here for AnalogPad to update Player.Motion
    dpadX = x dpadY = y
    Player.Motion = (Player.Forward * y + Player.Right * x) * 50

    sync()
end