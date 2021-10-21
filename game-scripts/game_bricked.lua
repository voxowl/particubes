Config = {
    Map = "brymoi.blank",
    Items = {"brymoi.birdo",
             "brymoi.birdo_ground",
             "brymoi.birdo_pipe2",}
}

Client.OnStart = function()

    UI.Crosshair = false
    Fog.On = false

    Camera:SetModeSatellite()
    Camera.DistanceFromTarget = 500

    -- declare the global array containing the pipes
    pipes = {}
    
    const = {
        jumpStart = false, --variable to verify if the player jumped
        RotZ = 0, --Z rotation
        lastPipeX = 0,--last pipe X position
    }
    
    TimeCycle.On = false
    Time.Current = Time.Noon
    TimeCycle.Marks.Noon.SkyColor = Color(32, 99, 165)
    TimeCycle.Marks.Noon.HorizonColor = Color(44, 142, 209)

    birdo = Shape(Items.brymoi.birdo)
    Map:AddChild(birdo)
    birdo.Physics = true
    birdo.Position = Number3(0, 5, 0)
    birdo.Rotation.Z = 0
    birdo.OnCollision = function(self, other)
        if other == ground then
            deado()
        
        elseif other == pipeU or other == pipeD then
            deado()
        
        else
            deado()
        end
    end
    
    --creates ground
    ground = Shape(Items.brymoi.birdo_ground)
    Map:AddChild(ground)
    ground.LocalPosition = Number3(2, -59, 0)
    
    --creates first pipes
    local pipeU = Shape(Items.brymoi.birdo_pipe2)
    Map:AddChild(pipeU)
    pipeU.LocalPosition = Number3(50, 60, 0)
    const.lastPipeX = pipeU.Position.X

    local pipeD = Shape(Items.brymoi.birdo_pipe2)
    Map:AddChild(pipeD)
    pipeD.Rotation.Z = math.pi -- 3.14
    pipeD.LocalPosition = Number3(50, 0, 0)
    pipeD.LocalPosition.Y = pipeU.LocalPosition.Y - 110

    -- storing the pipes in the "pipes" array for easy future removal
    insertPipeInArray(pipeU)
    insertPipeInArray(pipeD)
end

Client.Tick = function(dt)
    -- Game loop, executed ~30 times per second on each client.
    
    if birdo.IsHidden == false then
        Camera.Target = birdo.Position
    end
    
    --animation for falling birdo
    if birdo.Rotation.Z <= 1.5 and const.jumpStart == true then
        birdo.Rotation.Z = birdo.Rotation.Z - 0.04
    elseif birdo.Rotation.Z <= 7 and birdo.Rotation.Z >= 5.5 and const.jumpStart == true then
        birdo.Rotation.Z = birdo.Rotation.Z - 0.04
    end
    
    ground.LocalPosition = Number3(birdo.LocalPosition.X, -59, 0)
    
    if const.jumpStart == true then
        birdo.Velocity.X = 100
    end
    
    --verifies if birdo passed a pipe
    if birdo.Position.X > const.lastPipeX then
        pipeAdd()
    end

end

i = 0

-- jump function, triggered with Action1
Client.Action1 = function()
    birdo.Rotation.Z = 1.5
    birdo.Velocity.Y = 120
    const.jumpStart = true
end

pipeAdd = function()
    print("ok")
    --creates new pipes (local variables)
    local pipeUp = Shape(Items.brymoi.birdo_pipe2)
    Map:AddChild(pipeUp)
    local pipeDown = Shape(Items.brymoi.birdo_pipe2)
    Map:AddChild(pipeDown)
    
    --defines the position of the pipes
    pipeUp.Position.X = const.lastPipeX + math.random(200, 400)
    pipeUp.LocalPosition.Y = math.random(30, 80)
    pipeUp.LocalPosition.Z = 0
    pipeDown.Rotation.Z = math.pi -- 3.14
    pipeDown.LocalPosition.X = pipeUp.LocalPosition.X
    pipeDown.LocalPosition.Y = pipeUp.LocalPosition.Y - 110
    
    const.lastPipeX = pipeUp.Position.X

    -- storing the pipes in the "pipes" array for easy future removal
    insertPipeInArray(pipeUp)
    insertPipeInArray(pipeDown)
end

deado = function()
    const.jumpStart = false
    birdo.Velocity.X = 0
    birdo.Velocity.Y = 0
    birdo.Position = Number3(0, 20, 0)
    birdo.Rotation.Z = 0
    birdo:TextBubble("?? Deado!")
    -- const.lastPipeX = pipeU.Position.X

    -- loop over pipes and remove them from their parent, and from the `pipes` array
    while i > 0 do
        print("test")
        local pipe = table.remove(pipes)
        pipe:RemoveFromParent()
    end
end

insertPipeInArray = function(pipe)
    table.insert(pipes, pipeUp)
    table.insert(pipes, pipeDown)
    i = i+2
end

--
-- Server code
--

Server.Tick = function(dt) 
    -- Server game loop, executed ~30 times per second on the server.
end