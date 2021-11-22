Config = {
    Map = "aduermael.hills"
}

Client.OnStart = function()

    -- Defines a function to drop
    -- the player above the map.
    dropPlayer = function()
        Player.Position = Number3(Map.Width * 0.5, Map.Height + 10, Map.Depth * 0.5) * Map.Scale
        Player.Rotation = { 0, 0, 0 }
        Player.Velocity = { 0, 0, 0 }
    end

    World:AddChild(Player)

    -- Call dropPlayer function:
    dropPlayer()
end

Client.Tick = function(dt)
    -- Game loop, executed ~30 times per second on each client.

    -- Detect if player is falling,
    -- drop it above the map when it happens.
    if Player.Position.Y < -500 then
        dropPlayer()
        Player:TextBubble("💀 Oops!")
    end
end

-- jump function, triggered with Action1
Client.Action1 = function()
    if Player.IsOnGround then
        Player.Velocity.Y = 100
    end
end

--
-- Server code
--

Server.Tick = function(dt) 
    -- Server game loop, executed ~30 times per second on the server.
end