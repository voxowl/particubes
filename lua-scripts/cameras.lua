-- (1) target: Object, defaults to Player
-- (2) offset: offset to target (number or Number3), default (0, 2.25, 0)
Camera.SetModeFirstPerson = function(camera, target, offset)
    
    if camera == nil or type(camera) ~= Type.Camera then
        error("Camera:SetModeFirstPerson should be called with `:`")
    end

    if target == nil then
        target = Player
    end

    if not isObject(target) then
        error("Camera:SetModeFirstPerson - target should be an Object")
    end

    if offset ~= nil and not isNumber(offset) and type(offset) ~= Type.Number3 then
        error("Camera:SetModeFirstPerson - offset should be a number or Number3")
    end

    -- if camera used to have another target,
    -- make sure not to leave it hidden.
    if isObject(camera.target) then
        camera:Show(camera.target)
    end

    camera.target = target
    camera:Hide(target)

    local _offset = Number3(0, 0, 0)

    if offset ~= nil then
        if type(offset) == Type.Number3 then
            _offset = offset
        else
            -- offset is a number
            _offset = Number3(0, offset, 0)
        end
    else
        if type(target) == Type.Player then
            _offset = Number3(0, 2.25, 0)
        end
    end

    if type(target) == Type.Player then
        camera:SetParent(target.Head)
    else
        camera:SetParent(target)
    end

    camera.OnPointerDrag = nil
    camera.Tick = nil

    camera.LocalRotation = { 0, 0, 0 }
    camera.LocalPosition = _offset
end

-- (1) target: camera target (Object), default to Player
-- (2) minDist: min camera distance (number), default 1
-- if the camera can't move to minDist, the view changes to "first person"
-- (3) maxDist: max camera distance (number), default 40
-- (4) offset: offset to target (number or Number3), default (0, 9.5, 0)
Camera.SetModeThirdPerson = function(camera, target, minDist, maxDist, offset)

    if camera == nil or type(camera) ~= Type.Camera then
        error("Camera:SetModeThirdPerson should be called with `:`")
    end

    if target == nil then
        target = Player
    end

    if not isObject(target) then
        error("Camera:SetModeThirdPerson - target should be an Object")
    end

    if minDist ~= nil and not isNumber(minDist) then
        error("Camera:SetModeThirdPerson - min distance should be a number")
    end
    if maxDist ~= nil and not isNumber(maxDist) then
        error("Camera:SetModeThirdPerson - max distance should be a number")
    end
    if offset ~= nil and not isNumber(offset) and type(offset) ~= Type.Number3 then
        error("Camera:SetModeThirdPerson - offset should be a number or Number3")
    end

    -- default values
    local _minDist = 1
    local _maxDist = 40
    local _defaultVerticalOffsetMargin = 4
    local _offset = Number3(0, 0, 0)

    -- if camera used to have another target,
    -- make sure not to leave it hidden.
    if isObject(camera.target) then
        camera:Show(camera.target)
    end

    camera.target = target

    if minDist ~= nil then
        _minDist = minDist
    end

    if maxDist ~= nil then
        _maxDist = maxDist
    end

    -- apply Camera offset
    if offset ~= nil then
        if type(offset) == Type.Number3 then
            _offset = offset
        else
            _offset = Number3(0, offset, 0)
        end
    else
        if camera.target.BoundingBox ~= nil then
            _offset = Number3(0, camera.target.BoundingBox.Max.Y + _defaultVerticalOffsetMargin, 0)
        else
            _offset = Number3(0, 0, 0)
        end
    end

    camera:SetParent(target)
    Camera.LocalRotation = {0,0,0}

    -- make sure Camera target is visible
    camera:Show(camera.target)

    local _pitch = 0.0

    -- OnPointerDrag can only be called if Pointer is shown
    -- used to rotate the target on drag events
    camera.OnPointerDrag = function(camera, event)

        _pitch = _pitch - event.DY * 0.01
        if _pitch > math.pi * 0.4999 then
            _pitch = math.pi * 0.4999
        elseif _pitch < -math.pi * 0.4999 then
            _pitch = -math.pi * 0.4999
        end

        camera.LocalRotation.X = _pitch
        target.Rotation.Y = target.Rotation.Y + event.DX * 0.01

        if target == Player then
            -- do what's done in default Client.AnalogPad implementation
            -- to update Player's motion
            if dpadX ~= nil and dpadY ~= nil then
                Player.Motion = (Player.Forward * dpadY + Player.Right * dpadX) * 50
            end
        end
    end

    -- we fit a box around the camera, sized slightly less than 1 map voxel
    -- we can tweak this size factor to reach a sweet spot between the 2 extreme cases:
    -- 1) smaller, approaching a point and clipping the camera view will be more frequent (like w/ a raycast)
    -- 2) larger, approaching the size of 1 voxel and near-character camera positionning will be more frequent
    local boxHalfExtents = Map.Scale * 0.8 * 0.5

    local targetThreshold = Number3(3, 3, 3) * target.LossyScale -- we use the threshold in local

    camera.Tick = function(camera, dt)
        if camera:GetParent() == nil or camera.target == nil then
            return
        end

        if Pointer.IsHidden then
            if type(target) == Type.Player then
                Camera.LocalRotation = { Player.Head.LocalRotation.X, 0, 0 }
            else
                camera.LocalRotation = { 0, 0, 0 }
            end
        else
            if type(target) == Type.Player then
                Player.Head.LocalRotation = { 0, 0, 0 }
            end
        end

        local distance = _maxDist

        local targetPos = target:PositionLocalToWorld(_offset)

        -- check how far back camera can be placed from that point
        local box = Box(targetPos - boxHalfExtents, targetPos + boxHalfExtents)
        local impact = box:Cast(camera.Backward, _maxDist, Map.CollisionGroups)
        if impact.Distance ~= nil and impact.Distance < distance then
            distance = math.max(0, impact.Distance)
        end

        camera.Position = targetPos + camera.Backward * distance

        -- hide target and switch to (basic) first person mode
        -- if distance < minDistance or if camera is too close from
        -- target's bounding box

        local tooClose = false

        if camera.target.BoundingBox ~= nil then
            local localPos = camera.target:PositionWorldToLocal(camera.Position)
            if boxContains(camera.target.BoundingBox, localPos, targetThreshold) then
                tooClose = true
            end
        end

        if distance <= _minDist then
            tooClose = true
        end

        if tooClose then
            camera:Hide(camera.target)
            if type(target) == Type.Player then
                camera.LocalPosition = Number3(0, camera.target.BoundingBox.Max.Y - 4, 0)
            else
                camera.LocalPosition = Number3(0, 0, 0)
            end

        else
            camera:Show(camera.target)
        end
    end
end

-- (1) target: Object or Number3, default to Camera current position
-- (2) distance: distance to target (number), defaults to current distance between Camera & target
Camera.SetModeSatellite = function(camera, target, distance)

    if camera == nil or type(camera) ~= Type.Camera then
        error("Camera:SetModeSatellite should be called with `:`")
    end

    if not isObject(target) and type(target) ~= Type.Number3 then
        error("Camera:SetModeSatellite - target should be an Object or Number3")
    end

    if distance ~= nil and not isNumber(distance) then
        error("Camera:SetModeSatellite - distance should be a number")
    end

    local targetPos = nil

    if isObject(target) then
        targetPos = target.Position
    elseif type(target) == Type.Number3 then
        targetPos = target;
    end

    -- if camera used to have another target,
    -- make sure not to leave it hidden.
    if isObject(camera.target) then
        camera:Show(camera.target)
    end

    camera.target = target

    local _dist = 0

    if distance ~= nil then
        _dist = distance
    else
        _dist = (targetPos - Camera.Position).Length
    end

    camera:SetParent(World, true) -- keep camera where it previously was

    if isObject(target) then
        camera:Show(target)
    end

    camera.OnPointerDrag = nil

    camera.Tick = function(camera, dt)
        if camera.target == nil then return end
    
        -- satellite mode only enforces position based on distance to target
        if type(camera.target) == Type.Number3 then
            camera.Position = camera.target - camera.Forward * _dist
        else
            camera.Position = camera.target.Position - camera.Forward * _dist
        end
    end
end

Camera.SetModeFree = function(camera)

    if camera == nil or type(camera) ~= Type.Camera then
        error("Camera:SetModeSatellite should be called with `:`")
    end

    camera.OnPointerDrag = nil
    camera.Tick = nil

    -- if camera used to have another target,
    -- make sure not to leave it hidden.
    if isObject(camera.target) then
        camera:Show(camera.target)
    end
    camera.target = nil

    -- `true` parameter allows to maintain the World position
    camera:SetParent(World, true)
end