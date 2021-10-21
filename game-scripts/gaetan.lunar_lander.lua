
Config = {
    Map = "gaetan.lunar_lander_map",
	Items = {"gaetan.lunar_lander2",
             "gaetan.rocket_exhaust",
			 "gaetan.landing_pad_green",
			 "gaetan.landing_pad_blue",
			 "gaetan.single_cube_grey"},
}
Config.ConstantAcceleration = Config.ConstantAcceleration * 0.16

-- IDEAS
-- animate engine plume (scale/rotation)
-- put Player avatar in rocket
-- left/right modify the rotation speed (rotation acceleration), instead of setting its value

Client.OnStart = function()
    
    -- Constant values for the game
    const = {
		spawnPosition = Number3(20, 60, 20),
		spawnRotation = Number3(0, 0, 0),
		enginePower = 100,
		rotationSpeed = 100,
		landingSpeedLimit = 3.0,
		fuelTime = 100, -- in 10ths of second
		angleLimit = 0.20, -- in radians
		scoreBaseTime = 30, -- in seconds (0.03 * const.enginePower)
        scoreTimeComponent = 150, -- points
        scoreFuelComponent = 75, -- points
	}

	UI.Crosshair = false -- hide the crosshair
    Fog.On = false -- disable the distance fog

    -- disable the day/night cycle and set the ambiance
	TimeCycle.On = false
	Time.Current = Time.Noon
	TimeCycle.Marks.Noon.SkyColor = Color(0, 0, 0)
	TimeCycle.Marks.Noon.HorizonColor = Color(0, 0, 0)
	
    Camera:SetModeSatellite()
	Camera.DistanceFromTarget = 300

    -- Create shapes

	-- start landing pad
	startPad = Shape(Items.gaetan.landing_pad_blue)
	Map:AddChild(startPad)
    
	-- landing pad
	endPad = Shape(Items.gaetan.landing_pad_green)
	Map:AddChild(endPad)

	-- create ship
	ship = Shape(Items.gaetan.lunar_lander2)
	ship.Physics = true
	Map:AddChild(ship)
	ship.OnCollision = function(self, other)
		if ship.Velocity.Length > const.landingSpeedLimit or not isShipWithinAngleLimit(ship, const.angleLimit) then
            s:endGame(false) -- failure

		elseif other == startPad then

		elseif other == endPad then
            s:endGame(true) -- success
			
		else -- hit the map
			s:endGame(false) -- failure
		end
	end

	-- create exhaust
	exhaust = Shape(Items.gaetan.rocket_exhaust)
	exhaust.CollisionGroups = {}
	exhaust.CollidesWithGroups = {}
	ship:AddChild(exhaust)
	exhaust.LocalPosition = Number3(0, -7, 0)
	exhaust.IsHidden = true

    -- create & init game state
	s = {}
    s.init = function()
        s.bestScore = 0
    end
    s.reset = function()
        s.gameRunning = false
        s.engineOn = false
        s.rotation = 0
        s.time = 0
        s.fuel = const.fuelTime
        if s.timeLabel == nil then
            s.timeLabel = UI.Label("0 s", Anchor.Top, Anchor.HCenter)
        end
        if s.fuelLabel == nil then
            s.fuelLabel = UI.Label("", Anchor.Top, Anchor.HCenter)
        end
        if s.scoreLabel == nil then
            s.scoreLabel = UI.Label("", Anchor.Top, Anchor.HCenter)
        end
        s.fuelLabel.Text = "fuel: " .. math.floor(s.fuel)
        s.scoreLabel.Text = ""
        s.particules = {} -- array of particules used for explosions
        for i = 1, 50 do
            table.insert(s.particules, Shape(Items.gaetan.single_cube_grey))
        end
        startPad.LocalPosition = Number3(4, 5.5, 4)
        endPad.LocalPosition = Number3(81, 5.5, 4)
        ship.IsHidden = false
        ship.Physics = true
        ship.Position = const.spawnPosition
        ship.Rotation = const.spawnRotation
    end
    s.endGame = function(state, success)
        s.gameRunning = false
        s.fuel = 0
        if success then
            -- compute score
            -- time score
            local score = (const.scoreBaseTime - s.time) / const.scoreBaseTime * const.scoreTimeComponent
            -- fuel score
            score = score + (const.scoreFuelComponent * (s.fuel/const.fuelTime))
            score = math.floor(score) -- round it down
            s.scoreLabel.Text = "WIN! Score: " .. score .. " points"
            if score > s.bestScore then
                s.bestScore = score
                local e = Event()
                e.action = "didScore"
                e.score = score
                e:SendTo(Server)
            end
        else
            crash()
        end
        Pointer:Show()
    end
    s:init()
    s:reset()

    bestPlayerScore = UI.Label("My best: 0")
    bestWorldScore = UI.Label("World best: 0")

    retryButton = UI.Button("Retry!")
    retryButton.OnRelease = function()
        Pointer:Hide()
        s:reset()
    end

    -- Ping the server to notify it a player has arrived
    -- (This will be removed when "Server.OnPlayerJoin" callback will be working)
	local e = Event()
	e.action = "didStart"
	e:SendTo(Server)
end

Client.Tick = function(dt)
	-- Game loop, executed ~30 times per second on each client.

    if s.gameRunning then
        s.time = s.time + dt
    end
    s.timeLabel.Text = (math.floor(s.time * 1000)/1000) .. " s"

	if ship.IsHidden == false then
		Camera.Target = ship.Position
	end

	-- ship rotation
	if ship.IsOnGround == false then
		ship.Rotation.Z = ship.Rotation.Z -s.rotation * dt * const.rotationSpeed * 0.02
	end
	
	if s.engineOn and s.fuel > 0 then
        -- show engine exhaust plume
        exhaust.IsHidden = false
		ship.Velocity = ship.Velocity + (ship.Up * const.enginePower * dt)
		s.fuel = s.fuel - (dt * 10)
		if s.fuel < 0 then s.fuel = 0 end
		s.fuelLabel.Text = "fuel: " .. math.floor(s.fuel)
    else
		exhaust.IsHidden = true
	end
end

Client.DirectionalPad = function(x, y)
	-- x : left/right (-1 / 1)
	s.rotation = x
end

-- jump function, triggered with Action1
Client.Action1 = function()
    if s.gameRunning == false and ship.IsOnGround then
        s.gameRunning = true
    end

    if s.gameRunning == true then
        -- engine ON
	    s.engineOn = true
    end
end

Client.Action1Release = function()
	-- engine OFF
	s.engineOn = false
end

-- ship crash animation
crash = function()
	ship.IsHidden = true
	ship.Physics = false
	s.fuel = 0
	for i, c in ipairs(s.particules) do
		World:AddChild(c)
		c.Scale = 5
		c.CollisionGroupsMask = 0 -- TODO: replace this
		c.CollidesWithMask = 0    -- TODO: replace this
		c.Position = ship.Position
		c.Physics = true
		c.Velocity.Y = (math.random() - 0.5) * 150
		c.Velocity.X = (math.random() - 0.5) * 150
		c.Velocity.Z = (math.random() - 0.5) * 150
	end
end

-- 
isShipWithinAngleLimit = function(ship, angleLimit)
	local rot = ship.Rotation.Z
	local lim = angleLimit	
	return (rot >= 0 and rot <= lim) or (rot >= (math.pi * 2 - lim) and rot <= math.pi * 2) 
end

Client.DidReceiveEvent = function(e)
    if e.action == "player_best" then
        -- print("received player best: " .. e.score)
        s.bestScore = e.score
        bestPlayerScore.Text = "My best: " .. s.bestScore

    elseif e.action == "world_best" then
        -- print("received world best: " .. e.score)
        bestWorldScore.Text = "World best: " .. e.score

    end
end





-- --------------------------------------------------
--
-- Server code
--
-- --------------------------------------------------

-- called when the Server receives an event from a Client
Server.DidReceiveEvent = function(e)
    if e.action == "didStart" then
		-- print("DID START", e.Sender.Username, e.Sender.UserID)

		-- set player best score

	    local store = KeyValueStore(e.Sender.UserID)        
		local callback = function(success, results)
            -- print("DB GET success:", success)
            collectgarbage("collect")
            if success then
                local response = Event()
                response.action = "player_best"
                if results.bestScore == nil then
                    response.score = 0
                else
                    response.score = results.bestScore
                end
                response:SendTo(e.Sender) 
            end
		end
		store:Get("bestScore", callback)

        -- send world best score
        local store = KeyValueStore("global")        
		local callback = function(success, results)
            collectgarbage("collect")
            if success then    
                local response = Event()
                response.action = "world_best"
                if results.bestScore == nil then
                    response.score = 0
                else
                    response.score = results.bestScore
                end                
                response:SendTo(e.Sender)
            end
		end
		store:Get("bestScore", callback)

    elseif e.action == "didScore" then
        -- save score in DB
        local store = KeyValueStore(e.Sender.UserID)
        store:Set("bestScore", e.score, function(success)
            if success then
                local response = Event()
                response.action = "player_best"
                response.score = e.score
                response:SendTo(e.Sender)
            end
        end)

        -- get/set world best score
        local store = KeyValueStore("global")
		local callback = function(success, results)
            collectgarbage("collect")
            if success then
                if results.bestScore == nil or results.bestScore < e.score then
                    -- save world best score
                    local store2 = KeyValueStore("global")
                    store2:Set("bestScore", e.score, function(success2)
                        if success2 then
                            local response2 = Event()
                            response2.action = "world_best"
                            response2.score = e.score
                            response2:SendTo(e.Sender)
                        end
                    end)
                end
            end
		end
		store:Get("bestScore", callback)
	end
end

-- Server game loop, executed ~30 times per second on the Server
Server.Tick = function(dt) 

end