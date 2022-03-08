-- Hi! This is the Item Editor.

-- %%%import_and_map_set%%%








Client.OnStart = function()
	
	----------------------------
	-- SETTINGS
	----------------------------

	Dev.DisplayBoxes = false

	cameraSpeed = 1.4 -- unit/sec per screen point
	cameraVelocityDrag = 0.6 -- ratio of carry-over camera velocity per frame
	cameraDPadSpeed = 6 -- unit/sec
	cameraDistFactor = 0.05 -- additive factor per distance unit above threshold
	cameraDistThreshold = 15 -- distance under which scaling is 1
	zoomSpeed = 7 -- unit/sec
	zoomSpeedMax = 200
	dPadZoomSpeed = 1.2 -- unit/sec
	zoomVelocityDrag = 0.92 -- ratio of carry-over zoom velocity per frame
	zoomMin = 5 -- unit, minimum zoom distance allowed
	angularSpeed = 0.4 -- rad/sec per screen point
	angularVelocityDrag = 0.91 -- ratio of carry-over angular velocity per frame
	dPadAngularFactor = 0.7 -- in free mode (triggered after using dPad), this multiplies angular velocity
	autosnapDuration = 0.3 -- seconds

	cameraStartRotation = Number3(0.32, -0.81, 0.0)
	cameraStartPreviewRotation = Number3(0, math.pi * -0.75, 0)
	cameraStartPreviewDistance = 15
	cameraThumbnailRotation = Number3(0.32, -0.81, 0.0)

	saveTrigger = 60 -- seconds

    mirrorMargin = 1.0 -- the mirror is x block larger than the item
    mirrorThickness = 1.0/4.0

    arrowScale = 0.4
    arrowMargin = 1 -- space between arrows and the item box
    arrowSpace = 2 -- space between arrows and item center on each side ie. 2*arrowSpace is the space between arrows
    hideArrowThreshold = 0.9
    showArrowThreshold = 0.3 -- for rot arrows

    darkTextColor = Color(100, 100, 100)
    darkTextColorDisabled = Color(100, 100, 100, 20)
    lightTextColor = Color(255, 255, 255)
    selectedButtonColor = Color(100, 100, 100)
    modeButtonColor = Color(50, 149, 201)
    modeButtonColorSelected = Color(94, 192, 242)

    ----------------------------
    -- AMBIENCE
    ----------------------------

    TimeCycle.On = false
    Time.Current = Time.Noon
    Clouds.On = false
    Fog.On = false

	----------------------------
	-- STATE VALUES
	----------------------------

	-- item editor modes

	mode = { edit = 1, points = 2, max = 2 }
    modeName = { "EDIT", "POINTS" }

    editSubmode = { add = 1, remove = 2, paint = 3, mirror = 4, max = 4 }
    editSubmodeName = { "add", "remove", "paint", "mirror" }

    pointsSubmode = { move = 1, rotate = 2, max = 2}
    pointsSubmodeName = { "Move", "Rotate"}

    currentMode = nil
    currentEditSubmode = nil
    currentPointsSubmode = pointsSubmode.move -- points sub mode
    previousEditSubmode = editSubmode.add

    -- camera

	cameraRotation = cameraStartRotation
	zoomVelocity = 0.0
	angularVelocity = Number3(0, 0, 0)
	cameraVelocity = Number3(0, 0, 0)
	blockHighlightDirty = false
	autosnapFromTarget = Number3(0, 0, 0)
	autosnapFromDistance = 0
	autosnapToTarget = Number3(0, 0, 0)
	autosnapToDistance = 0
	autosnapTimer = -1.0
	cameraFree = false -- used with dPad to rotate camera freely

	cameraStates = {
		item = {
		    -- initialized at the end of OnStart
		    target = nil,
		    distance = 0,
		    rotation = nil
		},
		preview = {
			distance = cameraStartPreviewDistance,
			rotation = cameraStartPreviewRotation
		}
	}
	cameraCurrentState = cameraStates.item
	
	-- input

	dragging = false -- drag motion active
    dragging2 = false -- drag2 motion active
    dPad = { x = 0.0, y = 0.0 }

    -- mirror mode

    mirrorShape = nil
    mirrorAxes = { x = 1, y = 2, z = 3}
    mirrorCoords = Number3(0,0,0) -- mirror block coords
    currentMirrorAxis = nil

    -- other variables
	
	gridEnabled = 0
	displayedModeUIElements = {} -- displayed UI elements specific to current mode
	editModeButtons = {}
	currentFacemode = false
    picking = false
	changesSinceLastSave = false
	autoSaveDT = 0.0
	halfVoxel = Number3(0.5, 0.5, 0.5)
	picker = nil
    pickerColorIndex = 157
    poiActiveName = "Hand"

	----------------------------
	-- OBJECTS & UI ELEMENTS
	----------------------------

	-- edited item
	-- getItemResource is defined in C++ for the item editor only
	item = MutableShape(getItemResource())
	item.History = true -- enable history for the edited item
	item:SetParent(World)

	-- long press + drag
	blocksAddedWithDrag = {}
	blocksRemovedWithDrag = {}
	blocksReplacedWithDrag = {}
	continuousEdition = false
	itemCopy = item:Copy()
	itemCopy:SetParent(World)
	itemCopy.Position = item.Position
	itemCopy.IsHidden = true

	-- a cube to show where the camera is looking at
	blockHighlight = MutableShape(Items.cube_selector)
	blockHighlight.PrivateDrawMode = 2 + (gridEnabled * 8) -- highlight
	blockHighlight.Scale = 1 / (blockHighlight.Width - 1)
	blockHighlight:SetParent(World)
	blockHighlight.IsHidden = true

    -- edit mode controls
    -- buttons are nil by default, set when the mode is selected
    colorPaletteBtn = nil
	pickBtn = nil
    selectModeSingleBtn = nil
    selectModeFaceBtn = nil
    mirrorRotateBtn = nil
    mirrorMove1Btn = nil
    mirrorMove2Btn = nil
    mirrorRemoveBtn = nil

    -- add
	editModeButtons[editSubmode.add] = Button("➕", Anchor.Left)
	editModeButtons[editSubmode.add].OnRelease = function()
		setMode(nil, editSubmode.add)
	end
	editModeButtons[editSubmode.add]:Remove()

	-- copy default button color
	-- a copy constructor would be a nice to have...
	local c = editModeButtons[editSubmode.add].Color
	defaultButtonColor = Color(c.R, c.G, c.B, c.A)
	defaultButtonColorDisabled = Color(c.R, c.G, c.B, 20)

	-- remove
	editModeButtons[editSubmode.remove] = Button("➖", Anchor.Left)
	editModeButtons[editSubmode.remove].OnRelease = function()
		setMode(nil, editSubmode.remove)
	end
	editModeButtons[editSubmode.remove]:Remove()

	-- paint
	editModeButtons[editSubmode.paint] = Button("🖌", Anchor.Left)
	editModeButtons[editSubmode.paint].OnRelease = function()
		setMode(nil, editSubmode.paint)
	end
	editModeButtons[editSubmode.paint]:Remove()

	-- mirror
	editModeButtons[editSubmode.mirror] = Button("🪞", Anchor.Left)
	editModeButtons[editSubmode.mirror].OnRelease = function()
		setMode(nil, editSubmode.mirror)
	end
	editModeButtons[editSubmode.mirror]:Remove()

	-- POI : Move POI button
	poiMoveBtn = Button("Move", Anchor.Top, Anchor.Left)
	poiMoveBtn.TextColor = darkTextColor
	poiMoveBtn.OnRelease = function()
		setMode(nil, pointsSubmode.move)
	end
	poiMoveBtn:Remove()

	-- POI : Rotate POI button
	poiRotateBtn = Button("Rotate", Anchor.Top, Anchor.Left)
	poiRotateBtn.TextColor = darkTextColor
	poiRotateBtn.OnRelease = function()
		setMode(nil, pointsSubmode.rotate) 
	end
	poiRotateBtn:Remove()

	-- TMP
	poiResetBtn = Button("Reset", Anchor.Top, Anchor.Left)
	poiResetBtn.TextColor = darkTextColor
	poiResetBtn.OnRelease = function()

		item:AddPoint(poiActiveName)
		
		if poiActiveName == "Hand" then
			Player:EquipRightHand(item)
		elseif poiActiveName == "Hat" then
			Player:EquipHat(item)
		elseif poiActiveName == "Backpack" then
			Player:EquipBackpack(item)
		end

		updateArrows()
	end
	poiResetBtn:Remove()

	-- item editor mode toggle
	editModeBtn, poiModeBtn = Private:ItemEditorCreateModeSwitch()
	editModeBtn.OnRelease = function()
		setMode(mode.edit, nil)
	end
	poiModeBtn.OnRelease = function()
		setMode(mode.points, nil)
	end

	----------------------------
	-- INIT
	----------------------------

	initClientFunctions()
	initRotationArrows()
    initMoveArrows()
	setFacemode(false)
    refreshUndoRedoGridButtons()
    refreshScreenshotAndSaveButtons()

    Pointer:Show()
    UI.Crosshair = false

    -- initial camera positioning using FitToScreen
    local targetPoint = item:BlockToWorld(item.Center)
    Camera.Position = targetPoint
	Camera.Rotation = cameraStartRotation
	Camera:FitToScreen(item, 0.8, true) -- sets camera back

    -- initialize camera satellite mode
    local distance = (Camera.Position - targetPoint).Length
    setCamera(cameraStartRotation, targetPoint, distance, false)

	refreshBlockHighlight()
	cameraStateSave()
	setMode(mode.edit, editSubmode.add)
end

Client.Action1 = nil
Client.Action2 = nil
Client.Action1Release = nil
Client.Action2Release = nil
Client.Action3Release = nil

Client.WillOpenGameMenu = function()
	if changesSinceLastSave then
		save()
	end
end

Client.Tick = function(dt)
	
	if currentMode == mode.edit then
		-- autosave only while in edit mode
		if changesSinceLastSave then
			autoSaveDT = autoSaveDT + dt
			if autoSaveDT > saveTrigger then
				save()
			end
		end
	end

	-- if camera target moved last frame, refresh block highlight
	if blockHighlightDirty then
        refreshBlockHighlight()
    end

	-- up/down directional pad can be used as an alternative to mousewheel on desktop
	if dPad.y ~= 0 then
	    zoomVelocity = zoomVelocity - dPad.y * dPadZoomSpeed * getCameraDistanceFactor()
	end
	-- right/left directional pad maps to lateral camera pan
	if dPad.x ~= 0 then
	    cameraVelocity = cameraVelocity + Camera.Right * dPad.x * cameraDPadSpeed
	end

    if cameraFree then
        -- consume camera angular velocity
        cameraRotation = cameraRotation + angularVelocity * dt * dPadAngularFactor
        angularVelocity = dragging and Number3(0, 0, 0) or (angularVelocity * angularVelocityDrag)
        Camera.Rotation = cameraRotation

        -- in free mode, set camera position directly
        Camera.Position = Camera.Position + (cameraVelocity + Camera.Backward * zoomVelocity) * dt
        cameraVelocity = dragging2 and Number3(0, 0, 0) or (cameraVelocity * cameraVelocityDrag)
        zoomVelocity = zoomVelocity * zoomVelocityDrag
	else
        -- consume camera angular velocity
        local rotation = cameraRotation + angularVelocity * dt
        angularVelocity = dragging and Number3(0, 0, 0) or (angularVelocity * angularVelocityDrag)

        local target = nil
        local distance = nil
        if autosnapTimer < 0 then
            -- consume camera target velocity and refresh block highlight
            target = Camera.target + cameraVelocity * dt
            cameraVelocity = dragging2 and Number3(0, 0, 0) or (cameraVelocity * cameraVelocityDrag)
            blockHighlightDirty = n3Equals(target, Camera.target, 0.001) == false

            -- consume camera zoom velocity
            distance = math.max(zoomMin, Camera.distance + zoomVelocity * dt)
            zoomVelocity = zoomVelocity * zoomVelocityDrag
        else -- execute autosnap
            autosnapTimer = autosnapTimer - dt
            if autosnapTimer <= 0.0 then
                target = autosnapToTarget
                distance = autosnapToDistance
                autosnapTimer = -1.0
            else
                local v = easingQuadOut(1.0 - autosnapTimer / autosnapDuration)
                target = lerp(autosnapFromTarget, autosnapToTarget, v)
                distance = lerp(autosnapFromDistance, autosnapToDistance, v)
            end
            cameraVelocity = Number3(0, 0, 0)
            zoomVelocity = 0
        end

        setCamera(rotation, target, distance, false)
    end
end

Pointer.Zoom = function(zoomValue)
    zoomVelocity = clamp(zoomVelocity + zoomValue * zoomSpeed * getCameraDistanceFactor(), -zoomSpeedMax, zoomSpeedMax)
end

Pointer.Down = function(e)
	if currentMode == mode.points then
		moveArrows.unselect()
		rotArrows.unselect()
		if currentPointsSubmode == pointsSubmode.move then
			moveArrows.select(e)
		elseif currentPointsSubmode == pointsSubmode.rotate then
			rotArrows.select(e)
		end
	end
end

Pointer.Up = function(e)
	if currentMode == mode.edit and dragging == false then
		local impact = e:CastRay(item)
		if picking then
			pickCubeColor(impact)
		elseif currentEditSubmode == editSubmode.add and not continuousEdition then
			addBlockWithImpact(impact, currentFacemode)
		elseif currentEditSubmode == editSubmode.remove and not continuousEdition then
			removeBlockWithImpact(impact, currentFacemode)
		elseif currentEditSubmode == editSubmode.paint and not continuousEdition then
			replaceBlockWithImpact(impact, currentFacemode)
		elseif currentEditSubmode == editSubmode.mirror and not mirrorPlaced then
			placeMirror(impact)
		end
		checkAutoSave()
		refreshUndoRedoGridButtons()
	end

	if currentMode == mode.points then
		moveArrows.unselect()
	
		rotArrows.rotate(e)
		rotArrows.unselect()
		
		updateArrows()

	elseif currentMode == mode.edit then
		if continuousEdition then
			-- show the original
			item.IsHidden = false
			itemCopy.IsHidden = true
			if mirrorShape ~= nil then
				mirrorShape:SetParent(item)
				mirrorShape.IsHidden = false
			end

			continuousEdition = false
			if currentEditSubmode == editSubmode.add then
				-- apply changes done in the copy
				for k, b in pairs(blocksAddedWithDrag) do
					item:AddBlock(b.PaletteIndex, b.Coords)
				end
				blocksAddedWithDrag = {}

			elseif currentEditSubmode == editSubmode.remove then
				for k, c in pairs(blocksRemovedWithDrag) do
					item:GetBlock(c):Remove()
						end
				blocksRemovedWithDrag = {}
			elseif currentEditSubmode == editSubmode.paint then
				for k, b in pairs(blocksReplacedWithDrag) do
					item:GetBlock(b.Coords):Replace(Block(b.PaletteIndex))
					end
				blocksReplacedWithDrag = {}
				end
			updateMirror()
			checkAutoSave()
			refreshUndoRedoGridButtons()
		end
	end

	dragging = false
end

Pointer.LongPress = function (e)
	if currentMode == mode.edit and not currentFacemode then

		local impact = nil
		if mirrorShape ~= nil then
			impact = e:CastRay(itemCopy, mirrorShape)
		else
			impact = e:CastRay(itemCopy)
		end
		if impact.Block ~= nil then
			-- show the copy
			itemCopy.IsHidden = false
			item.IsHidden = true
			if mirrorShape ~= nil then
				mirrorShape:SetParent(itemCopy)
				mirrorShape.IsHidden = false
			end

			continuousEdition = true

			-- add / remove / paint first block
			if currentEditSubmode == editSubmode.add then
				local addedBlock = addBlockWithImpact(impact, false)
				table.insert(blocksAddedWithDrag, addedBlock)
	
			elseif currentEditSubmode == editSubmode.remove then
				removeBlockWithImpact(impact, false)
	
			elseif currentEditSubmode == editSubmode.paint then
				replaceBlockWithImpact(impact, false)
			end
		end
	end
end

Pointer.Drag = function(e)
	if moveArrows.selected ~= nil then
		moveArrows.moveItem(e)
	elseif not continuousEdition then
		angularVelocity = angularVelocity + Number3(-e.DY * angularSpeed, e.DX * angularSpeed, 0)
	end

	dragging = true

	if continuousEdition and currentMode == mode.edit then
		local impact = nil
		if mirrorShape ~= nil then
			impact = e:CastRay(itemCopy, mirrorShape)
		else
			impact = e:CastRay(itemCopy)
		end

		if impact.Block ~= nil then
			if currentEditSubmode == editSubmode.add then
				local canBeAdded = true
				for k, b in pairs(blocksAddedWithDrag) do
						if impact.Block.Coords == b.Coords then
						-- do not add on top of added blocks
						canBeAdded = false
						break
					end
				end
				if canBeAdded then
				local addedBlock = addBlockWithImpact(impact, false)
				table.insert(blocksAddedWithDrag, addedBlock)
				end

			elseif currentEditSubmode == editSubmode.remove then
					-- check if the block can be removed
				local impactOnOriginal = e:CastRay(item, mirrorShape)
				if impact.Distance <= impactOnOriginal.Distance then
					removeBlockWithImpact(impact, false)
					end

			elseif currentEditSubmode == editSubmode.paint then
				replaceBlockWithImpact(impact, false)
			end
		end
	end
end

Pointer.Drag2 = function(e)
    -- in edit mode, Drag2 performs camera pan
	if currentMode == mode.edit then
        local dx = e.DX * cameraSpeed * getCameraDistanceFactor()
        local dy = e.DY * cameraSpeed * getCameraDistanceFactor()
        cameraVelocity = cameraVelocity - Camera.Right * dx - Camera.Up * dy

        -- restore satellite mode if dPad was in use
        if cameraFree then
            cameraFree = false
            blockHighlightDirty = true
            Camera.target = Camera.Position + Camera.Forward * Camera.distance
            Camera:SetModeSatellite(Camera.target, Camera.distance)
        end

		-- TODO: put this in Drag2Begin
		if dragging2 == false then
			dragging2 = true
			UI.Crosshair = true
			item.PrivateDrawMode = 1 + (gridEnabled * 8) -- enable transparent draw mode
		end
	end
end

Pointer.OnDrag2End = function(e)
	-- snaps to nearby block center after drag2 (camera pan)
	if dragging2 then
        local impact = Camera:CastRay(item)
        if impact.Block ~= nil then
            autosnapFromTarget = Camera.target
            autosnapFromDistance = Camera.distance

            -- both distance & target will need to be animated to emulate a camera translation
            autosnapToTarget = impact.Block.Position + halfVoxel
            autosnapToDistance = (autosnapToTarget - Camera.Position).Length

            autosnapTimer = autosnapDuration
        end

        dragging2 = false
        UI.Crosshair = false
        item.PrivateDrawMode = 0 + (gridEnabled * 8) -- disable transparent draw mode
    end
end

--------------------------------------------------
-- Utilities
--------------------------------------------------

initClientFunctions = function()
	function getCurrentColor()
		return ColorPicker:GetColorAt(pickerColorIndex)
	end

	function getCurrentColorIndex()
		return pickerColorIndex
	end

	function setMode(newMode, newSubmode)
		local updatingMode = newMode ~= nil and newMode ~= currentMode
		local updatingSubMode = false
		picking = false
		if pickBtn ~= nil then pickBtn.Color = defaultButtonColor end

		-- going from one mode to another
		if updatingMode then
			if newMode < 1 or newMode > mode.max then
				error("setMode - invalid change:" .. newMode .. " " .. newSubmode)
				return
			end

			cameraStateSave()

			currentMode = newMode

			if currentMode == mode.edit then
				-- unequip Player
				if poiActiveName == "Hand" then
					Player:EquipRightHand(nil)
				elseif poiActiveName == "Hat" then
					Player:EquipHat(nil)
				elseif poiActiveName == "Backpack" then
					Player:EquipBackpack(nil)
				end

				-- remove avatar and arrows
				Player:RemoveFromParent()

				item:SetParent(World)
                item.LocalPosition = { 0, 0, 0 }
                item.LocalRotation = { 0, 0, 0 }

				itemCopy = item:Copy()
				itemCopy:SetParent(World)
                itemCopy.LocalPosition = { 0, 0, 0 }
                itemCopy.LocalRotation = { 0, 0, 0 }
				itemCopy.IsHidden = true
				itemCopy.PrivateDrawMode = item.PrivateDrawMode

                -- in edit mode, using dPad will set camera free
                Client.DirectionalPad = function(x, y)
                    dPad.x = x
                    dPad.y = y
                    blockHighlight.IsHidden = true
                    Camera.distance = cameraDistThreshold -- reset distance, make dist scaling neutral
                    cameraFree = true
                    Camera:SetModeFree()
                end
			else -- place item points / preview
				-- make player appear in front of camera with item in hand
				Player:SetParent(World)
				Player.Physics = false
				
				if poiActiveName == "Hand" then
					Player:EquipRightHand(item)
				elseif poiActiveName == "Hat" then
					Player:EquipHat(item)
				elseif poiActiveName == "Backpack" then
					Player:EquipBackpack(item)
				end

				Client.DirectionalPad = nil
			end

			refreshUndoRedoGridButtons()
			cameraStateSetToExpected()
		end -- end updating node

		-- see if submode needs to be changed
		if newSubmode ~= nil then
			if newSubmode < 1 then
				error("setMode - invalid change:" .. newMode .. " " .. newSubmode)
				return
			end

			if currentMode == mode.edit then
				if newSubmode > editSubmode.max then
					error("setMode - invalid change:" .. newMode .. " " .. newSubmode)
					return
				end
				-- return if new submode is already active
				if newSubmode == currentEditSubmode then return end
				updatingSubMode = true
				previousEditSubmode = currentEditSubmode
				currentEditSubmode = newSubmode

			elseif currentMode == mode.points then
				if newSubmode > pointsSubmode.max then
					error("setMode - invalid change:" .. newMode .. " " .. newSubmode)
					return
				end
				-- return if new submode is already active
				if newSubmode == currentPointsSubmode then return end
				updatingSubMode = true
				currentPointsSubmode = newSubmode
			end
		end

		if updatingMode or updatingSubMode then
			if currentMode == mode.points then
				if currentPointsSubmode == pointsSubmode.move then
					initMoveArrows()
				elseif currentPointsSubmode == pointsSubmode.rotate then
					initRotationArrows()
				else
					moveArrows.destroy()
					rotArrows.destroy()
				end
			else
				if moveArrows.destroy ~= nil then moveArrows.destroy() end
				if rotArrows.destroy ~= nil then rotArrows.destroy() end
				blockHighlightDirty = true
			end

			updateUI()
			updateArrows()
		end
	end

	function setPointSwitchControls()
		poiHand, poiHat, poiBackpack = Private:ItemEditorCreatePointsSwitch()
		
		poiHand.Color = defaultButtonColor
		poiHat.Color = defaultButtonColor
		poiBackpack.Color = defaultButtonColor

		if poiActiveName == "Hand" then
			poiHand.Color = selectedButtonColor
		elseif poiActiveName == "Hat" then
			poiHat.Color = selectedButtonColor
		elseif poiActiveName == "Backpack" then
			poiBackpack.Color = selectedButtonColor
		end

		poiHand.OnRelease = function()
			poiActiveName = "Hand"
			Player:EquipHat(nil)
			Player:EquipBackpack(nil)
			Player:EquipRightHand(item)
			updateArrows()
			poiHand.Color = selectedButtonColor
			poiHat.Color = defaultButtonColor
			poiBackpack.Color = defaultButtonColor
		end

		poiHat.OnRelease = function()
			poiActiveName = "Hat"
			Player:EquipRightHand(nil)
			Player:EquipBackpack(nil)
			Player:EquipHat(item)
			updateArrows()
			poiHand.Color = defaultButtonColor
			poiHat.Color = selectedButtonColor
			poiBackpack.Color = defaultButtonColor
		end

		poiBackpack.OnRelease = function()
			poiActiveName = "Backpack"
			Player:EquipRightHand(nil)
			Player:EquipHat(nil)
			Player:EquipBackpack(item)
			updateArrows()
			poiHand.Color = defaultButtonColor
			poiHat.Color = defaultButtonColor
			poiBackpack.Color = selectedButtonColor
		end
	end

	function removePointsSwitchControls()
		poiHand = nil
		poiHat = nil
		poiBackpack = nil
		Private:ItemEditorRemovePointsSwitch()
	end

	function clearEditControls()
		colorPaletteBtn = nil
		pickBtn = nil
		selectModeSingleBtn = nil
		selectModeFaceBtn = nil
		mirrorRotateBtn = nil
		mirrorMove1Btn = nil
		mirrorMove2Btn = nil
		mirrorRemoveBtn = nil
		Private:ItemEditorClearControls()
	end

	function setEditControls()
		-- reset control buttons
		colorPaletteBtn = nil
		pickBtn = nil
		selectModeSingleBtn = nil
		selectModeFaceBtn = nil
		mirrorRotateBtn = nil
		mirrorMove1Btn = nil
		mirrorMove2Btn = nil
		mirrorRemoveBtn = nil

		-- fix stack order issue
		local pickerPresent = picker ~= nil
		if pickerPresent then hideColorPicker() end

		if picking then
			Private:ItemEditorCreatePickerText()
			pickerPresent = false -- force hide color picker
		elseif currentEditSubmode == editSubmode.add then
			selectModeSingleBtn, selectModeFaceBtn, pickBtn, colorPaletteBtn = Private:ItemEditorCreateAddControls()
		elseif currentEditSubmode == editSubmode.remove then
			selectModeSingleBtn, selectModeFaceBtn = Private:ItemEditorCreateRemoveControls()
		elseif currentEditSubmode == editSubmode.paint then
			selectModeSingleBtn, selectModeFaceBtn, pickBtn, colorPaletteBtn = Private:ItemEditorCreateReplaceControls()
		elseif currentEditSubmode == editSubmode.mirror then
			if (mirrorShape ~= nil) then
				mirrorRotateBtn, mirrorMove1Btn, mirrorMove2Btn, mirrorRemoveBtn = Private:ItemEditorCreateMirrorControls(true)
			else
				-- displays message to select cube if mirrorShape is nil
				Private:ItemEditorCreateMirrorControls(false)
			end
		else
			Private:ItemEditorClearControls()
		end

		if pickerPresent then showColorPicker() end

		-- set control callbacks
		if colorPaletteBtn ~= nil then
			colorPaletteBtn.OnRelease = function()
				if picker ~= nil then
					hideColorPicker()
				else
					showColorPicker()
				end
			end
			colorPaletteBtn.Color = getCurrentColor()
		else 
			hideColorPicker()
		end

		if pickBtn ~= nil then
			pickBtn.OnRelease = function()
				picking = true
				previousEditSubmode = currentEditSubmode
				updateUI()
			end
		end

		if selectModeSingleBtn ~= nil then
			selectModeSingleBtn.OnRelease = function()
				setFacemode(false)
			end

			if currentFacemode == false then
				selectModeSingleBtn.Color = selectedButtonColor
			else
				selectModeSingleBtn.Color = defaultButtonColor
			end

		end

		if selectModeFaceBtn ~= nil then
			selectModeFaceBtn.OnRelease = function()
				setFacemode(true)
			end
			
			if currentFacemode == true then
				selectModeFaceBtn.Color = selectedButtonColor
			else
				selectModeFaceBtn.Color = defaultButtonColor
			end
		end

		setMirrorControls()
	end

	function setMirrorControls()
		if mirrorRotateBtn ~= nil then
			mirrorRotateBtn.OnRelease = function()
				if currentMirrorAxis == mirrorAxes.x then
					currentMirrorAxis = mirrorAxes.y
				elseif currentMirrorAxis == mirrorAxes.y then
					currentMirrorAxis = mirrorAxes.z
				elseif currentMirrorAxis == mirrorAxes.z then
					currentMirrorAxis = mirrorAxes.x
				end
				updateMirror()
			end
		end

		if mirrorMove1Btn ~= nil then
			mirrorMove1Btn.OnRelease = function()
				offsetMirror(-0.5)
			end
		end

		if mirrorMove2Btn ~= nil then
			mirrorMove2Btn.OnRelease = function()
				offsetMirror(0.5)
			end
		end

		if mirrorRemoveBtn ~= nil then
			mirrorRemoveBtn.OnRelease = function()
				removeMirror()
				Private:ItemEditorCreateMirrorControls(false)
			end
		end
	end

	displayModeElement = function(e)
		e:Add()
		table.insert(displayedModeUIElements, e)
	end

	removeModeElement = function(element)
		element:Remove()
		for i,v in pairs(displayedModeUIElements) do
			if element == v then
				table.remove( displayedModeUIElements, i )
			end
		end
	end

	removeAllModeElements = function()
		for i,v in pairs(displayedModeUIElements) do
			v:Remove()
		end
		displayedModeUIElements = {}
	end

	updateUI = function()
		removeAllModeElements()
		removePointsSwitchControls()

		if currentMode == mode.edit then

			editModeBtn.Color = modeButtonColorSelected
			poiModeBtn.Color = modeButtonColor

			displayModeElement(editModeButtons[editSubmode.add])
			if currentEditSubmode == editSubmode.add then
				editModeButtons[editSubmode.add].Color = selectedButtonColor 
			else
				editModeButtons[editSubmode.add].Color = defaultButtonColor
			end
			displayModeElement(editModeButtons[editSubmode.remove])
			if currentEditSubmode == editSubmode.remove then
				editModeButtons[editSubmode.remove].Color = selectedButtonColor
			else
				editModeButtons[editSubmode.remove].Color = defaultButtonColor
			end
			displayModeElement(editModeButtons[editSubmode.paint])
			if currentEditSubmode == editSubmode.paint then
				editModeButtons[editSubmode.paint].Color = selectedButtonColor
			else
				editModeButtons[editSubmode.paint].Color = defaultButtonColor
			end
			displayModeElement(editModeButtons[editSubmode.mirror])
			if currentEditSubmode == editSubmode.mirror then
				editModeButtons[editSubmode.mirror].Color = selectedButtonColor
			else
				editModeButtons[editSubmode.mirror].Color = defaultButtonColor
			end

			if item.CanUndo == true then
				displayModeElement(undoBtnOld)
			end
			if item.CanRedo == true then
				displayModeElement(redoBtnOld)
			end

			setEditControls() -- refreshes edit controls
		elseif currentMode == mode.points then
			editModeBtn.Color = modeButtonColor
			poiModeBtn.Color = modeButtonColorSelected

			setPointSwitchControls()
			displayModeElement(poiMoveBtn)
			displayModeElement(poiRotateBtn)
			displayModeElement(poiResetBtn)

			if currentPointsSubmode == pointsSubmode.move then

				poiMoveBtn.Color = selectedButtonColor
				poiMoveBtn.TextColor = lightTextColor
				poiRotateBtn.Color = defaultButtonColor
				poiRotateBtn.TextColor = darkTextColor

			elseif currentPointsSubmode == pointsSubmode.rotate then

				poiMoveBtn.Color = defaultButtonColor
				poiMoveBtn.TextColor = darkTextColor
				poiRotateBtn.Color = selectedButtonColor
				poiRotateBtn.TextColor = lightTextColor
			end

			clearEditControls()
			removeMirror()
			hideColorPicker()
		end
	end

	function checkAutoSave()
		if changesSinceLastSave == false then
			changesSinceLastSave = true
			autoSaveDT = 0.0
		end
		refreshScreenshotAndSaveButtons()
	end

	function save()
		if mirrorShape ~= nil then mirrorShape.IsHidden = true end

		cameraStateSave()

		local wasInPointsMode = false
		if currentMode == mode.points then
            wasInPointsMode = true
            setMode(mode.edit, nil)
        end

		local highlightHidden = blockHighlight.IsHidden
		blockHighlight.IsHidden = true

		moveArrows.hide()
		rotArrows.hide()

		-- force drawmode 0 for save (needed for screenshot)
		local drawmode = item.PrivateDrawMode
		item.PrivateDrawMode = 0

        Camera.Position = Camera.target
		Camera.Rotation = cameraThumbnailRotation
		Camera:FitToScreen(item, 0.8, false) -- sets camera back
		item:Save(Config.editedItemName)

		cameraStateSetToExpected(true) -- force refresh camera

		changesSinceLastSave = false
		autoSaveDT = 0.0
		refreshScreenshotAndSaveButtons()

		item.PrivateDrawMode = drawmode -- restore drawmode

		if wasInPointsMode then
			setMode(mode.points, nil)
		end

		-- show mirror again
		if mirrorShape ~= nil then mirrorShape.IsHidden = false end
		blockHighlight.IsHidden = highlightHidden
	end

	addBlockWithImpact = function(impact, facemode)
		if impact == nil or facemode == nil or impact.Block == nil then return end
		if type(facemode) ~= Type.boolean then return end

		-- always add the first block
		local addedBlock = addSingleBlock(impact.Block, impact.FaceTouched)

		-- if facemode is enable, test the neighbor blocks of impact.Block
		if addedBlock ~= nil and facemode == true then
			local faceTouched = impact.FaceTouched
			local impactBlockColor = impact.Block.PaletteIndex
			local queue = { impact.Block }
			-- neighbor finder (depending on the mirror orientation)
			local neighborFinder = {}
			if faceTouched == BlockFace.Top or faceTouched == BlockFace.Bottom then
				neighborFinder = { Number3(1,0,0), Number3(-1,0,0), Number3(0,0,1), Number3(0,0,-1) }
			elseif faceTouched == BlockFace.Left or faceTouched == BlockFace.Right then
				neighborFinder = { Number3(0,1,0), Number3(0,-1,0), Number3(0,0,1), Number3(0,0,-1) }
			elseif faceTouched == BlockFace.Front or faceTouched == BlockFace.Back then
				neighborFinder = { Number3(1,0,0), Number3(-1,0,0), Number3(0,1,0), Number3(0,-1,0) }
			end

			-- explore
			while true do
				local b = table.remove(queue)
				if b == nil then break end
				for i, f in ipairs(neighborFinder) do
					local neighborCoords = b.Coords + f
					-- check there is a block
					local neighborBlock = item:GetBlock(neighborCoords)
					-- check it is the same color
					if neighborBlock ~= nil and neighborBlock.PaletteIndex == impactBlockColor then 
						-- try to add new block on top of neighbor
						addedBlock = addSingleBlock(neighborBlock, faceTouched)
						if addedBlock ~= nil then
							table.insert(queue, neighborBlock)
						end
					end
				end
			end
		end

		updateMirror()

		return addedBlock
	end

	addSingleBlock = function(block, faceTouched)
		-- block is either from item or itemCopy
		local addedBlock = block:AddNeighbor(Block(getCurrentColorIndex()), faceTouched)
		if not continuousEdition and addedBlock ~= nil then
			itemCopy:AddBlock(addedBlock.PaletteIndex, addedBlock.Coordinates)
		end

		if addedBlock ~= nil and mirrorShape ~= nil then
			local mirrorBlockCoords = mirrorCoords - {0.5, 0.5, 0.5}
			local mirrorBlock = nil
			local currentShape = nil
			if continuousEdition then
				currentShape = itemCopy
			else
				currentShape = item
			end

			if currentMirrorAxis == mirrorAxes.x then
				mirrorBlock = currentShape:AddBlock(getCurrentColorIndex(),
					mirrorBlockCoords.X - (addedBlock.Coordinates.X - mirrorBlockCoords.X),
					addedBlock.Coordinates.Y,
					addedBlock.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.y then
				mirrorBlock = currentShape:AddBlock(getCurrentColorIndex(),
					addedBlock.Coordinates.X,
					mirrorBlockCoords.Y - (addedBlock.Coordinates.Y - mirrorBlockCoords.Y),
					addedBlock.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.z then
				mirrorBlock = currentShape:AddBlock(getCurrentColorIndex(),
					addedBlock.Coordinates.X,
					addedBlock.Coordinates.Y,
					mirrorBlockCoords.Z - (addedBlock.Coordinates.Z - mirrorBlockCoords.Z))
			end

			if mirrorBlock ~= nil then
				if continuousEdition then
				table.insert(blocksAddedWithDrag, mirrorBlock)
				else
					itemCopy:AddBlock(mirrorBlock.PaletteIndex, mirrorBlock.Coordinates)
				end
			end
		end

		return addedBlock
	end

	removeBlockWithImpact = function(impact, facemode)
		if impact == nil or facemode == nil or impact.Block == nil then return end
		if type(facemode) ~= Type.boolean then return end

		-- always remove the first block
		-- it would be nice to have a return value here
		removeSingleBlock(impact.Block)
		
		-- if facemode is enable, test the neighbor blocks of impact.Block
		if facemode == true then
			local faceTouched = impact.FaceTouched
			local impactBlockColor = impact.Block.PaletteIndex
			local queue = { impact.Block }
			-- neighbor finder (depending on the mirror orientation)
			local neighborFinder = {}
			if faceTouched == BlockFace.Top or faceTouched == BlockFace.Bottom then
				neighborFinder = { Number3(1,0,0), Number3(-1,0,0), Number3(0,0,1), Number3(0,0,-1) }
			elseif faceTouched == BlockFace.Left or faceTouched == BlockFace.Right then
				neighborFinder = { Number3(0,1,0), Number3(0,-1,0), Number3(0,0,1), Number3(0,0,-1) }
			elseif faceTouched == BlockFace.Front or faceTouched == BlockFace.Back then
				neighborFinder = { Number3(1,0,0), Number3(-1,0,0), Number3(0,1,0), Number3(0,-1,0) }
			end

			-- relative coords from touched plan to block next to it
			-- (needed to check if there is a block next to the one we want to remove)
			local targetNeighbor = targetBlockDeltaFromTouchedFace(faceTouched)

			-- explore
			while true do
				local b = table.remove(queue)
				if b == nil then break end
				for i, f in ipairs(neighborFinder) do
					local neighborCoords = b.Coords + f
					-- check there is a block
					local neighborBlock = item:GetBlock(neighborCoords)
					-- check block on top
					local blockOnTopPosition = neighborCoords + targetNeighbor
					local blockOnTop = item:GetBlock(blockOnTopPosition)
					-- check it is the same color
					if neighborBlock ~= nil and neighborBlock.PaletteIndex == impactBlockColor and blockOnTop == nil then
						removeSingleBlock(neighborBlock)
						table.insert(queue, neighborBlock)
					end
				end
			end
		end

		updateMirror()
	end

	removeSingleBlock = function(block)
		if continuousEdition then
			table.insert(blocksRemovedWithDrag, block.Coordinates:Copy())
		else
		itemCopy:GetBlock(block.Coordinates):Remove()
		end
		block:Remove()

		if mirrorShape ~= nil then
			local mirrorBlockCoords = mirrorCoords - {0.5, 0.5, 0.5}
			local mirrorBlock = nil
			local currentShape = nil
			if continuousEdition then
				currentShape = itemCopy
			else
				currentShape = item
			end

			if currentMirrorAxis == mirrorAxes.x then
				mirrorBlock = currentShape:GetBlock(
					mirrorBlockCoords.X - (block.Coordinates.X - mirrorBlockCoords.X),
					block.Coordinates.Y,
					block.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.y then
				mirrorBlock = currentShape:GetBlock(
					block.Coordinates.X,
					mirrorBlockCoords.Y - (block.Coordinates.Y - mirrorBlockCoords.Y),
					block.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.z then
				mirrorBlock = currentShape:GetBlock(
					block.Coordinates.X,
					block.Coordinates.Y,
					mirrorBlockCoords.Z - (block.Coordinates.Z - mirrorBlockCoords.Z))
			end

			if mirrorBlock ~= nil then
				if continuousEdition then
					table.insert(blocksRemovedWithDrag, mirrorBlock.Coordinates:Copy())
				else
					itemCopy:GetBlock(mirrorBlock.Coordinates):Remove()
				end
				mirrorBlock:Remove()
			end
		end
	end

	replaceBlockWithImpact = function(impact, facemode)
		if impact == nil or facemode == nil or impact.Block == nil then return end
		if type(facemode) ~= Type.boolean then return end

		local impactBlockColor = impact.Block.PaletteIndex

		-- return if trying to replace with same color index
		if impactBlockColor == getCurrentColorIndex() then return end

		-- always remove the first block
		-- it would be nice to have a return value here
		replaceSingleBlock(impact.Block)

		if facemode == true then
			local faceTouched = impact.FaceTouched
			local queue = { impact.Block }
			-- neighbor finder (depending on the mirror orientation)
			local neighborFinder = {}
			if faceTouched == BlockFace.Top or faceTouched == BlockFace.Bottom then
				neighborFinder = { Number3(1,0,0), Number3(-1,0,0), Number3(0,0,1), Number3(0,0,-1) }
			elseif faceTouched == BlockFace.Left or faceTouched == BlockFace.Right then
				neighborFinder = { Number3(0,1,0), Number3(0,-1,0), Number3(0,0,1), Number3(0,0,-1) }
			elseif faceTouched == BlockFace.Front or faceTouched == BlockFace.Back then
				neighborFinder = { Number3(1,0,0), Number3(-1,0,0), Number3(0,1,0), Number3(0,-1,0) }
			end

			-- relative coords from touched plan to block next to it
			-- (needed to check if there is a block next to the one we want to remove)
			local targetNeighbor = targetBlockDeltaFromTouchedFace(faceTouched)

			-- explore
			while true do
				local b = table.remove(queue)
				if b == nil then break end
				for i, f in ipairs(neighborFinder) do
					local neighborCoords = b.Coords + f
					-- check there is a block
					local neighborBlock = item:GetBlock(neighborCoords)
					-- check block on top
					local blockOnTopPosition = neighborCoords + targetNeighbor
					local blockOnTop = item:GetBlock(blockOnTopPosition)
					-- check it is the same color
					if neighborBlock ~= nil and neighborBlock.PaletteIndex == impactBlockColor and blockOnTop == nil then
						replaceSingleBlock(neighborBlock)
						table.insert(queue, neighborBlock)
					end
				end
			end
		end
	end

	replaceSingleBlock = function(block)
		block:Replace(Block(getCurrentColorIndex()))
		if continuousEdition then
			table.insert(blocksReplacedWithDrag, block)
		else
		itemCopy:GetBlock(block.Coordinates):Replace(Block(getCurrentColorIndex()))
		end

		if mirrorShape ~= nil then
			local mirrorBlockCoords = mirrorCoords - {0.5, 0.5, 0.5}
			local mirrorBlock = nil
			local currentShape = nil
			if continuousEdition then
				currentShape = itemCopy
			else
				currentShape = item
			end

			if currentMirrorAxis == mirrorAxes.x then
				mirrorBlock = currentShape:GetBlock(
					mirrorBlockCoords.X - (block.Coordinates.X - mirrorBlockCoords.X),
					block.Coordinates.Y,
					block.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.y then
				mirrorBlock = currentShape:GetBlock(
					block.Coordinates.X,
					mirrorBlockCoords.Y - (block.Coordinates.Y - mirrorBlockCoords.Y),
					block.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.z then
				mirrorBlock = currentShape:GetBlock(
					block.Coordinates.X,
					block.Coordinates.Y,
					mirrorBlockCoords.Z - (block.Coordinates.Z - mirrorBlockCoords.Z))
			end

			if mirrorBlock ~= nil then
				if continuousEdition then
					table.insert(blocksReplacedWithDrag, mirrorBlock)
				else
					itemCopy:GetBlock(mirrorBlock.Coordinates):Replace(Block(getCurrentColorIndex()))
				end
				mirrorBlock:Replace(Block(getCurrentColorIndex()))
			end
		end
	end

	pickCubeColor = function(impact)
		if impact ~= nil and impact.Block ~= nil then
			setColorPickerIndex(impact.Block.PaletteIndex)
			if colorPaletteBtn ~= nil then
				colorPaletteBtn.Color = getCurrentColor()
			end
		end
		picking = false
		setMode(nil, previousEditSubmode)
		updateUI()
	end
	
	refreshUndoRedoGridButtons = function()
		-- destroy existing buttons if any
		Private:ItemEditorClearUndoRedoAndGrid()

		-- show these buttons only on edit mode
		if currentMode ~= mode.edit then
			return
		end

		-- construct new buttons
		local showUndoRedo = item.CanUndo or item.CanRedo
		undoBtn, redoBtn, gridModeBtn = Private:ItemEditorCreateUndoRedoAndGrid(showUndoRedo)

		gridModeBtn.TextColor = darkTextColor
		gridModeBtn.OnRelease = function()
			item.PrivateDrawMode = gridModeToggle(item.PrivateDrawMode)
			itemCopy.PrivateDrawMode = item.PrivateDrawMode
		end
		gridModeBtnRefresh()

		if item.CanUndo then
			undoBtn.Color = defaultButtonColor
			undoBtn.TextColor = darkTextColor
			undoBtn.OnRelease = function()
				if item ~= nil and item.CanUndo then
					item:Undo()
					itemCopy:RemoveFromParent()
					itemCopy = item:Copy()
					itemCopy:SetParent(World)
					itemCopy.Position = item.Position
					itemCopy.IsHidden = true
					itemCopy.PrivateDrawMode = item.PrivateDrawMode
					updateMirror()
					checkAutoSave()
					refreshUndoRedoGridButtons()
				end
			end
		else
			if undoBtn ~= nil then
				undoBtn.TextColor = darkTextColorDisabled
				undoBtn.Color = defaultButtonColorDisabled
			end
		end

		if item.CanRedo then
			redoBtn.Color = defaultButtonColor
			redoBtn.TextColor = darkTextColor
			redoBtn.OnRelease = function()
				if item ~= nil and item.CanRedo then
					item:Redo()
					itemCopy:RemoveFromParent()
					itemCopy = item:Copy()
					itemCopy:SetParent(World)
					itemCopy.Position = item.Position
					itemCopy.IsHidden = true
					itemCopy.PrivateDrawMode = item.PrivateDrawMode
					updateMirror()
					checkAutoSave()
					refreshUndoRedoGridButtons()
				end
			end
		else 
			if redoBtn ~= nil then
				redoBtn.TextColor = darkTextColorDisabled
				redoBtn.Color = defaultButtonColorDisabled
			end
		end
	end

	function refreshScreenshotAndSaveButtons()
		screenshotBtn, saveBtn = Private:ItemEditorCreateScreenshotAndSave(changesSinceLastSave)

		if saveBtn ~= nil then
			saveBtn.OnRelease = function()
				save()
			end
		end

		screenshotBtn.OnRelease = function()
			local drawmode = item.PrivateDrawMode
			
			-- temporary hide the mirror before taking the screenshot
			local mirrorEnabled = mirrorShape.IsHidden == false -- if nil -> false
			if currentMode == mode.edit then
				if mirrorShape ~= nil then mirrorShape.IsHidden = true end
			else
				moveArrows.hide()
				rotArrows.hide()
			end

            local highlightHidden = blockHighlight.IsHidden
			blockHighlight.IsHidden = true

			item.PrivateDrawMode = 0
			item:Capture()
			item.PrivateDrawMode = drawmode

			-- show mirror again after the screenshot
			if mirrorEnabled then
				mirrorShape.IsHidden = false
			end

			blockHighlight.IsHidden = highlightHidden
			
			moveArrows.show()
			rotArrows.show()
		end
	end

	placeMirror = function(impact)
		-- a block has been touched, place the mirror
		if impact ~= nil and impact.Block ~= nil then
			-- first time the mirror is placed since last removal
			if mirrorShape == nil then

				local face = impact.FaceTouched

				mirrorShape = Shape(Items.cube_white)
				mirrorShape.PrivateDrawMode = 1
			
				-- no rotation, only using scale
				if face == BlockFace.Right then
					currentMirrorAxis = mirrorAxes.x
				elseif face == BlockFace.Left then
					currentMirrorAxis = mirrorAxes.x
				elseif face == BlockFace.Top then
					currentMirrorAxis = mirrorAxes.y
				elseif face == BlockFace.Bottom then
					currentMirrorAxis = mirrorAxes.y
				elseif face == BlockFace.Back then
					currentMirrorAxis = mirrorAxes.z
				elseif face == BlockFace.Front then
					currentMirrorAxis = mirrorAxes.z
				else
					error("can't set mirror axis")
					currentMirrorAxis = nil
				end

				mirrorCoords = impact.Block.Coordinates + {0.5, 0.5, 0.5}
				updateMirror()

				item:AddChild(mirrorShape)

				mirrorRotateBtn, mirrorMove1Btn, mirrorMove2Btn, mirrorRemoveBtn = Private:ItemEditorCreateMirrorControls(true)

				setMirrorControls()
			else
				-- place the mirror in another block, keeping same orientation
				mirrorCoords = impact.Block.Coordinates + {0.5, 0.5, 0.5}
				updateMirror()
			end

		-- no block touched, remove mirror
		elseif mirrorShape ~= nil then
			removeMirror()
			Private:ItemEditorCreateMirrorControls(false)
		end
	end

	function offsetMirror(value)
		if currentMirrorAxis == mirrorAxes.x then
			if cameraRotation.Y < -math.pi * 0.5 or cameraRotation.Y > math.pi * 0.5 then
				value = -value
			end
			mirrorCoords.X = mirrorCoords.X + value
		elseif currentMirrorAxis == mirrorAxes.y then
			value = -value
			mirrorCoords.Y = mirrorCoords.Y + value
		elseif currentMirrorAxis == mirrorAxes.z then
			if cameraRotation.Y > 0 then
				value = -value
			end
			mirrorCoords.Z = mirrorCoords.Z + value
		end
		updateMirror()
	end

	removeMirror = function()
		if mirrorShape ~= nil then
			mirrorShape:RemoveFromParent()
		end
		mirrorShape = nil
		currentMirrorAxis = nil
	end

	-- updates the dimension of the mirror when adding/removing cubes
	updateMirror = function()
		if mirrorShape ~= nil then
			local parentShape = nil
			if continuousEdition then
				parentShape = itemCopy
			else
				parentShape = item
			end
			local width = parentShape.Width + mirrorMargin
			local height = parentShape.Height + mirrorMargin
			local depth = parentShape.Depth + mirrorMargin
			local center = parentShape:BlockToLocal(parentShape.Center)
			local mirrorLocalPosition = parentShape:BlockToLocal(mirrorCoords)
			
			if currentMirrorAxis == mirrorAxes.x then
				mirrorShape.LocalScale = { mirrorThickness, height, depth }
				mirrorShape.LocalPosition = { mirrorLocalPosition.X, center.Y, center.Z }

				if mirrorMove1Btn ~= nil then
					mirrorMove1Btn.Text = "⬅️"
				end
				if mirrorMove2Btn ~= nil then
					mirrorMove2Btn.Text = "➡️"
				end

			elseif currentMirrorAxis == mirrorAxes.y then
				mirrorShape.LocalScale = { width, mirrorThickness, depth }
				mirrorShape.LocalPosition = { center.X, mirrorLocalPosition.Y, center.Z }

				if mirrorMove1Btn ~= nil then
					mirrorMove1Btn.Text = "⬆️"
				end
				if mirrorMove2Btn ~= nil then
					mirrorMove2Btn.Text = "⬇️"
				end

			elseif currentMirrorAxis == mirrorAxes.z then
				mirrorShape.LocalScale = { width, height, mirrorThickness }
				mirrorShape.LocalPosition = { center.X, center.Y, mirrorLocalPosition.Z }

				if mirrorMove1Btn ~= nil then
					mirrorMove1Btn.Text = "⬅️"
				end
				if mirrorMove2Btn ~= nil then
					mirrorMove2Btn.Text = "➡️"
				end
			end
		end
	end

	getAlignment = function(normal)
		return math.abs(normal:Dot(Camera.Forward))
	end

	sqr_len = function(dx, dy)
		return dx * dx + dy * dy
	end

	cameraStateSave = function()
		cameraCurrentState.target = Camera.target:Copy()
        cameraCurrentState.distance = Camera.distance
		cameraCurrentState.rotation = cameraRotation:Copy()
	end

	cameraStateSet = function(state)
		if state == cameraStates.preview then
		    setCamera(state.rotation, Player.Head.Position, state.distance, false)

			blockHighlight.IsHidden = true
            Pointer:Show()
            UI.Crosshair = false
		else
            setCamera(state.rotation, state.target, state.distance, true) -- refresh camera immediately...
            blockHighlightDirty = true -- so that highlight block can be refreshed asap
		end
		cameraCurrentState = state
	end

	cameraStateSetToExpected = function(alwaysRefresh)
	    local state = cameraStates.item
		if currentMode == mode.points then
            state = cameraStates.preview
        end
		if alwaysRefresh == nil or alwaysRefresh or state ~= cameraCurrentState then
			cameraStateSet(state)
		end
	end

	setCamera = function(rotation, target, distance, immediate)
	    if rotation ~= nil then
	        cameraRotation = rotation:Copy()

	        -- clamp rotation between 90° and -90° on X
            cameraRotation.X = clamp(cameraRotation.X, -math.pi * 0.4999, math.pi * 0.4999)

	        Camera.Rotation = cameraRotation
        end

        -- store variables used for satellite mode, we need them to handle zoom&drag
        if target ~= nil then
            Camera.target = target:Copy()
        end
        if distance ~= nil then
            Camera.distance = distance
        end
        Camera:SetModeSatellite(Camera.target, Camera.distance)

        if immediate then
            Camera.Position = target + Camera.Backward * distance
        end
	end

	getCameraDistanceFactor = function()
	    return 1 + math.max(0, cameraDistFactor * (Camera.distance - cameraDistThreshold))
	end

	applyDrag = function(velocity, drag, isZero)
	    if isZero then
	        velocity = Number3(0, 0, 0)
        else
            velocity = velocity * drag
        end
	end

	refreshBlockHighlight = function()
	    local impact = Camera:CastRay(item)
        if impact.Block ~= nil then
            blockHighlight.Position = impact.Block.Position + halfVoxel
            blockHighlight.IsHidden = false
        else
            blockHighlight.IsHidden = true
        end
        blockHighlightDirty = false
	end
end

function gridModeBtnRefresh()
	if gridEnabled == 0 then
		gridModeBtn.Color = defaultButtonColor
		gridModeBtn.TextColor = darkTextColor
	else
		gridModeBtn.Color = selectedButtonColor
		gridModeBtn.TextColor = lightTextColor
	end
end

gridModeToggle = function(currentDrawMode)
	if gridEnabled == 1 then
		gridEnabled = 0
		gridModeBtnRefresh()
		return currentDrawMode - 8
	else
		gridEnabled = 1
		gridModeBtnRefresh()
		return currentDrawMode + 8
	end	
end

setFacemode = function(newFacemode)
	if newFacemode ~= currentFacemode then
		currentFacemode = newFacemode	
	end
	
	if currentFacemode == true then
		if selectModeSingleBtn ~= nil then selectModeSingleBtn.Color = defaultButtonColor end
		if selectModeFaceBtn ~= nil then selectModeFaceBtn.Color = selectedButtonColor end
	elseif currentFacemode == false then
		if selectModeSingleBtn ~= nil then selectModeSingleBtn.Color = selectedButtonColor end
		if selectModeFaceBtn ~= nil then selectModeFaceBtn.Color = defaultButtonColor end
	end
end

targetBlockDeltaFromTouchedFace = function(faceTouched)
	-- relative coords from touched plan to block next to it
	-- (needed to check if there is a block next to the one we want to remove)
	local targetNeighbor = Number3(0, 0, 0)
	if faceTouched == BlockFace.Top then
		targetNeighbor = Number3(0, 1, 0)
	elseif faceTouched == BlockFace.Bottom then
		targetNeighbor = Number3(0, -1, 0)
	elseif faceTouched == BlockFace.Left then
		targetNeighbor = Number3(-1, 0, 0)
	elseif faceTouched == BlockFace.Right then
		targetNeighbor = Number3(1, 0, 0)
	elseif faceTouched == BlockFace.Front then
		targetNeighbor = Number3(0, 0, -1)
	elseif faceTouched == BlockFace.Back then
		targetNeighbor = Number3(0, 0, 1)
	end
	return targetNeighbor
end

function initMoveArrows()
	if moveArrows ~= nil then return end
	if rotArrows.destroy ~= nil then rotArrows.destroy() end

    -- standard colors for transformations gizmo: X is red, Y is green, Z is blue
    -- Note: colors represents what transfo they apply, ie. for a local gizmo, colors will be wherever local axes are
    -- TODO: recolor "arrow_up" green and "arrow_forward" blue
	moveArrows = {
		object = Object(), -- object placed at center of item (not parented)
		arrowsUpDown = Object(),
		arrowsRightLeft = Object(),
		arrowsForwardBack = Object(),
		arrowUp = Shape(Items.arrow_up),
		arrowDown = Shape(Items.arrow_up),
		arrowRight = Shape(Items.arrow_right),
		arrowLeft = Shape(Items.arrow_right),
		arrowForward = Shape(Items.arrow_forward),
		arrowBack = Shape(Items.arrow_forward),
		poiActiveName = "",
		parent = nil,
		selected = nil,
		origin = Object(), -- item position/orientation when it starts moving
		impact = Object(), -- impact with arrow
		normal = nil, -- impact plane normal 

		destroy = function()
			if moveArrows ~= nil then
				moveArrows.object:RemoveFromParent()
				moveArrows.origin:RemoveFromParent()
				moveArrows.impact:RemoveFromParent()
				moveArrows = nil
			end
		end,

		hide = function()
			moveArrows.arrowsUpDown.IsHidden = true
			moveArrows.arrowsRightLeft.IsHidden = true
			moveArrows.arrowsForwardBack.IsHidden = true
		end,

		show = function()
			moveArrows.arrowsUpDown.IsHidden = false
			moveArrows.arrowsRightLeft.IsHidden = false
			moveArrows.arrowsForwardBack.IsHidden = false
		end,

		refresh = function()
			if moveArrows.poiActiveName ~= poiActiveName then
				moveArrows.poiActiveName = poiActiveName
				moveArrows.object:RemoveFromParent()

				if poiActiveName == "Hand" then
					moveArrows.parent = Player.RightArm
				elseif poiActiveName == "Hat" then
					moveArrows.parent = Player.Head
				elseif poiActiveName == "Backpack" then
					moveArrows.parent = Player.Body
				else
					moveArrows.parent = nil
				end

				if moveArrows.parent ~= nil then
					moveArrows.parent:AddChild(moveArrows.object)
				end
			end
			moveArrows.object.Scale = item.Scale
			moveArrows.object.LocalPosition = item.LocalPosition

			local worldAABB = item:ComputeWorldBoundingBox()
			local min = moveArrows.object:PositionWorldToLocal(worldAABB.Min)
			local max = moveArrows.object:PositionWorldToLocal(worldAABB.Max)
			-- Note: the resulting min/max isn't necessarily an axis-aligned box, just 2 local points (probably why the following code is here)
			-- TODO: this will need to be improved if we want to allow rotations that arnt always aligned with an axis,
			-- 2 solutions: use world pos w/ worldAABB or use item.Min/Max/Center if moveArrows is in same local space (see example for rotArrows)

			-- ensure min < max
			if min.X > max.X then
				local tmp = min.X
				min.X = max.X
				max.X = tmp
			end
			if min.Y > max.Y then
				local tmp = min.Y
				min.Y = max.Y
				max.Y = tmp
			end
			if min.Z > max.Z then
				local tmp = min.Z
				min.Z = max.Z
				max.Z = tmp
			end

			moveArrows.arrowUp.LocalPosition = { 0, max.Y + arrowMargin, 0 }
			moveArrows.arrowDown.LocalPosition = { 0, min.Y - arrowMargin, 0 }

			moveArrows.arrowRight.LocalPosition = { max.X + arrowMargin, 0, 0 }
			moveArrows.arrowLeft.LocalPosition = { min.X - arrowMargin, 0, 0 }

			moveArrows.arrowForward.LocalPosition = { 0, 0, max.Z + arrowMargin }
			moveArrows.arrowBack.LocalPosition = { 0, 0, min.Z - arrowMargin }

			-- rotate the arrows along their axes to make them visible
			local viewingItemFromTopOrBottom = false
			local viewingItemFromRightOrLeft = false

			if getAlignment(moveArrows.object.Up) > getAlignment(moveArrows.object.Forward) and
				getAlignment(moveArrows.object.Up) > getAlignment(moveArrows.object.Right) then
				viewingItemFromTopOrBottom = true
			end

			if getAlignment(moveArrows.object.Right) > getAlignment(moveArrows.object.Forward) then
				viewingItemFromRightOrLeft = true
			end

			if viewingItemFromTopOrBottom then
				moveArrows.arrowsRightLeft.LocalRotation = {math.pi * 0.5,0,0}
				moveArrows.arrowsForwardBack.LocalRotation = {0,0,math.pi * 0.5}
			else
				moveArrows.arrowsRightLeft.LocalRotation = {0,0,0}
				moveArrows.arrowsForwardBack.LocalRotation = {0,0,0}
			end

			if viewingItemFromRightOrLeft then
				moveArrows.arrowsUpDown.LocalRotation = {0,math.pi * 0.5,0}
			else
				moveArrows.arrowsUpDown.LocalRotation = {0,0,0}
			end

			-- hide arrows aligned with Camera
			moveArrows.arrowsUpDown.IsHidden = false
			moveArrows.arrowsRightLeft.IsHidden = false
			moveArrows.arrowsForwardBack.IsHidden = false

			if getAlignment(moveArrows.object.Right) > hideArrowThreshold then
				moveArrows.arrowsRightLeft.IsHidden = true

			elseif getAlignment(moveArrows.object.Up) > hideArrowThreshold then
				moveArrows.arrowsUpDown.IsHidden = true

			elseif getAlignment(moveArrows.object.Forward) > hideArrowThreshold then			
				moveArrows.arrowsForwardBack.IsHidden = true
			end
		end,

		hit = function(e)
			local impacts = {}

			local impactUp = e:CastRay(moveArrows.arrowUp)
			if impactUp ~= nil then table.insert(impacts, impactUp) end
			local impactDown = e:CastRay(moveArrows.arrowDown)
			if impactDown ~= nil then table.insert(impacts, impactDown) end
			local impactRight = e:CastRay(moveArrows.arrowRight)
			if impactRight ~= nil then table.insert(impacts, impactRight) end
			local impactLeft = e:CastRay(moveArrows.arrowLeft)
			if impactLeft ~= nil then table.insert(impacts, impactLeft) end
			local impactForward = e:CastRay(moveArrows.arrowForward)
			if impactForward ~= nil then table.insert(impacts, impactForward) end
			local impactBack = e:CastRay(moveArrows.arrowBack)
			if impactBack ~= nil then table.insert(impacts, impactBack) end
				
			if #impacts == 0 then 
				return nil, nil
			end

			local impact = nil

			for i,v in ipairs(impacts) do
				-- set impact to closest one
				if impact == nil or impact.Distance > v.Distance then
					impact = v
				end
			end

			if impact == nil then error("impact should not be nil here") end
				local arrow = nil

				if impact == impactUp then arrow = moveArrows.arrowUp
				elseif impact == impactDown then arrow = moveArrows.arrowDown
				elseif impact == impactRight then arrow = moveArrows.arrowRight
				elseif impact == impactLeft then arrow= moveArrows.arrowLeft
				elseif impact == impactForward then arrow = moveArrows.arrowForward
				elseif impact == impactBack then arrow = moveArrows.arrowBack end

				return arrow, impact
			end,

		hitPlane = function(e) -- returns a point in World coords
				if moveArrows.selected == nil then return nil end

				local p = e.Position + e.Direction * ((moveArrows.impact.Position - e.Position):Dot(moveArrows.normal) / e.Direction:Dot(moveArrows.normal))

				return p
			end,

		moveItem = function(e)
			local p = moveArrows.hitPlane(e)
			if p == nil then return end

			p = moveArrows.impact:PositionWorldToLocal(p)
		
			if moveArrows.selected == moveArrows.arrowRight or moveArrows.selected == moveArrows.arrowLeft then
				p.Y = 0
				p.Z = 0
			elseif moveArrows.selected == moveArrows.arrowUp or moveArrows.selected == moveArrows.arrowDown then
				p.X = 0
				p.Z = 0
			elseif moveArrows.selected == moveArrows.arrowForward or moveArrows.selected == moveArrows.arrowBack then
				p.X = 0
				p.Y = 0
			end

			p = moveArrows.impact:PositionLocalToWorld(p)

			item.Position = moveArrows.origin.Position + p - moveArrows.impact.Position
			moveArrows.object.LocalPosition = item.LocalPosition
		end,

		select = function(e) -- see if an arrow is selected with pointer event
			local impact = nil
			moveArrows.selected, impact = moveArrows.hit(e)

			if moveArrows.selected == nil then return end

			moveArrows.origin.Position = item.Position
			moveArrows.origin.Rotation = moveArrows.parent.Rotation -- item.Rotation

			moveArrows.impact.Position = e.Position + e.Direction * impact.Distance
			moveArrows.impact.Rotation = moveArrows.parent.Rotation -- item.Rotation

			if moveArrows.selected == moveArrows.arrowRight or moveArrows.selected == moveArrows.arrowLeft then
				-- choose best plan
				if getAlignment(moveArrows.object.Forward) > getAlignment(moveArrows.object.Up) then
					moveArrows.normal = moveArrows.object.Forward:Copy()
				else
					moveArrows.normal = moveArrows.object.Up:Copy()
				end

			elseif moveArrows.selected == moveArrows.arrowUp or moveArrows.selected == moveArrows.arrowDown then
				-- choose best plan
				if getAlignment(moveArrows.object.Right) > getAlignment(moveArrows.object.Forward) then
					moveArrows.normal = moveArrows.object.Right:Copy()
				else
					moveArrows.normal = moveArrows.object.Forward:Copy()
				end

			elseif moveArrows.selected == moveArrows.arrowForward or moveArrows.selected == moveArrows.arrowBack then
				-- choose best plan
				if getAlignment(moveArrows.object.Right) > getAlignment(moveArrows.object.Up) then
					moveArrows.normal = moveArrows.object.Right:Copy()
				else
					moveArrows.normal = moveArrows.object.Up:Copy()
				end
			end
		end,

		unselect = function()
			if moveArrows.selected ~= nil then
				-- snap
				item.LocalPosition.X = math.floor(item.LocalPosition.X * 2 + 0.5) * 0.5 - 0.001
				item.LocalPosition.Y = math.floor(item.LocalPosition.Y * 2 + 0.5) * 0.5 - 0.001
				item.LocalPosition.Z = math.floor(item.LocalPosition.Z * 2 + 0.5) * 0.5 - 0.001

				savePOI()
				moveArrows.selected = nil
			end
		end
	}

	moveArrows.impact:SetParent(World) -- for transformations

	moveArrows.object:AddChild(moveArrows.arrowsUpDown)
	moveArrows.object:AddChild(moveArrows.arrowsRightLeft)
	moveArrows.object:AddChild(moveArrows.arrowsForwardBack)

	moveArrows.arrowsUpDown:AddChild(moveArrows.arrowUp)
	moveArrows.arrowsUpDown:AddChild(moveArrows.arrowDown)

	moveArrows.arrowsRightLeft:AddChild(moveArrows.arrowRight)
	moveArrows.arrowsRightLeft:AddChild(moveArrows.arrowLeft)

	moveArrows.arrowsForwardBack:AddChild(moveArrows.arrowForward)
	moveArrows.arrowsForwardBack:AddChild(moveArrows.arrowBack)

	moveArrows.arrowUp.Scale = arrowScale
	moveArrows.arrowDown.Scale = arrowScale
	moveArrows.arrowRight.Scale = arrowScale
	moveArrows.arrowLeft.Scale = arrowScale
	moveArrows.arrowForward.Scale = arrowScale
	moveArrows.arrowBack.Scale = arrowScale

	moveArrows.arrowUp.Pivot.Y = 0
	moveArrows.arrowDown.Pivot.Y = 0
	moveArrows.arrowDown.LocalRotation = {0,0,math.pi}

	moveArrows.arrowRight.Pivot.X = 0
	moveArrows.arrowLeft.Pivot.X = 0
	moveArrows.arrowLeft.LocalRotation = {0,math.pi,0}

	moveArrows.arrowForward.Pivot.Z = 0
	moveArrows.arrowBack.Pivot.Z = 0
	moveArrows.arrowBack.LocalRotation = {math.pi,0,0}
end

function initRotationArrows()
	if rotArrows ~= nil then return end
	if moveArrows.destroy ~= nil then moveArrows.destroy() end

    -- standard colors for transformations gizmo: X is red, Y is green, Z is blue
    -- Note: colors represents what transfo they apply, ie. for a local gizmo, colors will be wherever local axes are
    -- TODO: recolor "arrow_rot_forward_norm_1/2" blue and "arrow_rot_up_norm_1/2" green
	rotArrows = {
		root = Object(), -- root of the arrows groups
		arrowsX = Object(), -- arrow group for X axis
		arrowsY = Object(), -- arrow group for Y axis
		arrowsZ = Object(), -- arrow group for Z axis
		arrowX1 = Shape(Items.arrow_rot_right_norm_1),
		arrowX2 = Shape(Items.arrow_rot_right_norm_2),
		arrowX3 = Shape(Items.arrow_rot_right_norm_1),
		arrowX4 = Shape(Items.arrow_rot_right_norm_2),
		arrowY1 = Shape(Items.arrow_rot_up_norm_1),
        arrowY2 = Shape(Items.arrow_rot_up_norm_2),
        arrowY3 = Shape(Items.arrow_rot_up_norm_1),
        arrowY4 = Shape(Items.arrow_rot_up_norm_2),
        arrowZ1 = Shape(Items.arrow_rot_forward_norm_1),
        arrowZ2 = Shape(Items.arrow_rot_forward_norm_2),
        arrowZ3 = Shape(Items.arrow_rot_forward_norm_1),
        arrowZ4 = Shape(Items.arrow_rot_forward_norm_2),
		poiActiveName = "",
		selected = nil, -- selected arrow, turns on PointerUp while still on selected arrow

		destroy = function()
			if rotArrows ~= nil then
				rotArrows.root:RemoveFromParent()
				rotArrows = nil
			end
		end,

		hide = function()
			rotArrows.root.IsHidden = true
		end,

		show = function()
			rotArrows.root.IsHidden = false
		end,

		refresh = function()
			rotArrows.arrowsX.IsHidden = false
			rotArrows.arrowsY.IsHidden = false
			rotArrows.arrowsZ.IsHidden = false

			-- hide arrows aligned with Camera
			if getAlignment(rotArrows.root.Right) < showArrowThreshold then
				rotArrows.arrowsX.IsHidden = true
			end

			if getAlignment(rotArrows.root.Up) < showArrowThreshold then
				rotArrows.arrowsY.IsHidden = true
			end

			if getAlignment(rotArrows.root.Forward) < showArrowThreshold then
				rotArrows.arrowsZ.IsHidden = true
			end

			---- The following uses LocalPosition to place rotArrows based on the local bounding box,
			---- since rotArrows and item are in the same local space (ie. same parent)
			local aabb = item:ComputeLocalBoundingBox()
            local center = aabb.Center
            
            -- make sure arrows are in the same local space whatever sub-mode we're in
            rotArrows.root:SetParent(item:GetParent())
            rotArrows.root.LocalPosition = { 0, 0, 0 }

            -- the item X axis is along the right of player's arm
            rotArrows.arrowX1.LocalPosition = { aabb.Max.X + arrowMargin, center.Y, center.Z + arrowSpace }
            rotArrows.arrowX2.LocalPosition = { aabb.Max.X + arrowMargin, center.Y, center.Z - arrowSpace }
            rotArrows.arrowX3.LocalPosition = { aabb.Min.X - arrowMargin, center.Y, center.Z + arrowSpace }
            rotArrows.arrowX4.LocalPosition = { aabb.Min.X - arrowMargin, center.Y, center.Z - arrowSpace }

            -- the item Y axis is along player's arm, hand to shoulder
            rotArrows.arrowY1.LocalPosition = { center.X + arrowSpace, aabb.Max.Y + arrowMargin, center.Z }
            rotArrows.arrowY2.LocalPosition = { center.X - arrowSpace, aabb.Max.Y + arrowMargin, center.Z }
            rotArrows.arrowY3.LocalPosition = { center.X + arrowSpace, aabb.Min.Y - arrowMargin, center.Z }
            rotArrows.arrowY4.LocalPosition = { center.X - arrowSpace, aabb.Min.Y - arrowMargin, center.Z }

            -- the item Z axis would be along player's thumb up
            rotArrows.arrowZ1.LocalPosition = { center.X, center.Y + arrowSpace, aabb.Max.Z + arrowMargin }
            rotArrows.arrowZ2.LocalPosition = { center.X, center.Y - arrowSpace, aabb.Max.Z + arrowMargin }
            rotArrows.arrowZ3.LocalPosition = { center.X, center.Y + arrowSpace, aabb.Min.Z - arrowMargin }
            rotArrows.arrowZ4.LocalPosition = { center.X, center.Y - arrowSpace, aabb.Min.Z - arrowMargin }

            ---- The following is the equivalent using world Position to place rotArrows based on world bounding box,
            ---- this is mainly for the example, but that means we could parent rotArrows anywhere
			--[[
			local aabb = item:ComputeWorldBoundingBox()
			local center = aabb.Center
			local scale = item.LossyScale

            -- the item X axis is along the right of player's arm
            local marginX = Player.RightArm.Right * arrowMargin * scale
            local spaceX = Player.RightArm.Forward * arrowSpace * scale
            rotArrows.arrowX1.Position = Number3(aabb.Max.X, center.Y, center.Z) + marginX + spaceX
            rotArrows.arrowX2.Position = Number3(aabb.Max.X, center.Y, center.Z) + marginX - spaceX
            rotArrows.arrowX3.Position = Number3(aabb.Min.X, center.Y, center.Z) - marginX + spaceX
            rotArrows.arrowX4.Position = Number3(aabb.Min.X, center.Y, center.Z) - marginX - spaceX

            -- the item Y axis is along player's arm, hand to shoulder
            local marginY = Player.RightArm.Up * arrowMargin * scale
            local spaceY = Player.RightArm.Right * arrowSpace * scale
            rotArrows.arrowY1.Position = Number3(center.X, center.Y, aabb.Max.Z) - marginY + spaceY
            rotArrows.arrowY2.Position = Number3(center.X, center.Y, aabb.Max.Z) - marginY - spaceY
            rotArrows.arrowY3.Position = Number3(center.X, center.Y, aabb.Min.Z) + marginY + spaceY
            rotArrows.arrowY4.Position = Number3(center.X, center.Y, aabb.Min.Z) + marginY - spaceY

            -- the item Z axis would be along player's thumb up
            local marginZ = Player.RightArm.Forward * arrowMargin * scale
            local spaceZ = Player.RightArm.Up * arrowSpace * scale
            rotArrows.arrowZ1.Position = Number3(center.X, aabb.Max.Y, center.Z) + marginZ + spaceZ
            rotArrows.arrowZ2.Position = Number3(center.X, aabb.Max.Y, center.Z) + marginZ - spaceZ
            rotArrows.arrowZ3.Position = Number3(center.X, aabb.Min.Y, center.Z) - marginZ + spaceZ
            rotArrows.arrowZ4.Position = Number3(center.X, aabb.Min.Y, center.Z) - marginZ - spaceZ
            ]]
		end,

		hit = function(e)
			local impacts = {}

			local impactY1 = e:CastRay(rotArrows.arrowY1)
			if impactY1 ~= nil then table.insert(impacts, impactY1) end
			local impactY2 = e:CastRay(rotArrows.arrowY2)
			if impactY2 ~= nil then table.insert(impacts, impactY2) end
			local impactY3 = e:CastRay(rotArrows.arrowY3)
			if impactY3 ~= nil then table.insert(impacts, impactY3) end
			local impactY4 = e:CastRay(rotArrows.arrowY4)
			if impactY4 ~= nil then table.insert(impacts, impactY4) end

			local impactX1 = e:CastRay(rotArrows.arrowX1)
			if impactX1 ~= nil then table.insert(impacts, impactX1) end
			local impactX2 = e:CastRay(rotArrows.arrowX2)
			if impactX2 ~= nil then table.insert(impacts, impactX2) end
			local impactX3 = e:CastRay(rotArrows.arrowX3)
			if impactX3 ~= nil then table.insert(impacts, impactX3) end
			local impactX4 = e:CastRay(rotArrows.arrowX4)
			if impactX4 ~= nil then table.insert(impacts, impactX4) end

			local impactZ1 = e:CastRay(rotArrows.arrowZ1)
			if impactZ1 ~= nil then table.insert(impacts, impactZ1) end
			local impactZ2 = e:CastRay(rotArrows.arrowZ2)
			if impactZ2 ~= nil then table.insert(impacts, impactZ2) end
			local impactZ3 = e:CastRay(rotArrows.arrowZ3)
			if impactZ3 ~= nil then table.insert(impacts, impactZ3) end
			local impactZ4 = e:CastRay(rotArrows.arrowZ4)
			if impactZ4 ~= nil then table.insert(impacts, impactZ4) end

			if #impacts == 0 then
				return nil
			end

			local impact = nil

			for i,v in ipairs(impacts) do
				-- set impact to closest one
				if impact == nil or impact.Distance > v.Distance then
					impact = v
				end
			end

			if impact == nil then error("impact should not be nil here") end

				local arrow = nil

				if impact == impactY1 then arrow = rotArrows.arrowY1
				elseif impact == impactY2 then arrow = rotArrows.arrowY2
				elseif impact == impactY3 then arrow = rotArrows.arrowY3
				elseif impact == impactY4 then arrow= rotArrows.arrowY4
				elseif impact == impactX1 then arrow = rotArrows.arrowX1
				elseif impact == impactX2 then arrow = rotArrows.arrowX2
				elseif impact == impactX3 then arrow = rotArrows.arrowX3
				elseif impact == impactX4 then arrow= rotArrows.arrowX4
				elseif impact == impactZ1 then arrow = rotArrows.arrowZ1
				elseif impact == impactZ2 then arrow = rotArrows.arrowZ2
				elseif impact == impactZ3 then arrow = rotArrows.arrowZ3
				elseif impact == impactZ4 then arrow= rotArrows.arrowZ4 end

				return arrow
			end,

		select = function(e) -- see if an arrow is selected with pointer event
			rotArrows.selected = rotArrows.hit(e)
		end,

		rotate = function(e)
			if rotArrows.selected == nil then return end

			if rotArrows.selected == rotArrows.hit(e) then

				local selected = rotArrows.selected

				if selected == rotArrows.arrowY1 or selected == rotArrows.arrowY2 then
					item:RotateLocal({0, 1, 0}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowY3 or selected == rotArrows.arrowY4 then
					item:RotateLocal({0, 1, 0}, math.pi * 0.5)
				elseif selected == rotArrows.arrowX1 or selected == rotArrows.arrowX2 then
					item:RotateLocal({1, 0, 0}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowX3 or selected == rotArrows.arrowX4 then
					item:RotateLocal({1, 0, 0}, math.pi * 0.5)
				elseif selected == rotArrows.arrowZ1 or selected == rotArrows.arrowZ2 then
					item:RotateLocal({0, 0, 1}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowZ3 or selected == rotArrows.arrowZ4 then
					item:RotateLocal({0, 0, 1}, math.pi * 0.5)
				end

				savePOI()
			end
		end,

		unselect = function()
			rotArrows.selected = nil
		end
	}

	-- we'll use local position to place arrows, so they must be in the same local space ie. same parent
	-- Note: we could have a world rotation gizmo mode using additional conversions, or use world Position (see commented code above)
	rotArrows.root:SetParent(item:GetParent())
	rotArrows.root.LocalPosition = { 0, 0, 0 }

	rotArrows.root:AddChild(rotArrows.arrowsX)
	rotArrows.root:AddChild(rotArrows.arrowsY)
	rotArrows.root:AddChild(rotArrows.arrowsZ)

	rotArrows.arrowsX:AddChild(rotArrows.arrowX1)
	rotArrows.arrowsX:AddChild(rotArrows.arrowX2)
	rotArrows.arrowsX:AddChild(rotArrows.arrowX3)
	rotArrows.arrowsX:AddChild(rotArrows.arrowX4)

	rotArrows.arrowsY:AddChild(rotArrows.arrowY1)
	rotArrows.arrowsY:AddChild(rotArrows.arrowY2)
	rotArrows.arrowsY:AddChild(rotArrows.arrowY3)
	rotArrows.arrowsY:AddChild(rotArrows.arrowY4)

	rotArrows.arrowsZ:AddChild(rotArrows.arrowZ1)
	rotArrows.arrowsZ:AddChild(rotArrows.arrowZ2)
	rotArrows.arrowsZ:AddChild(rotArrows.arrowZ3)
	rotArrows.arrowsZ:AddChild(rotArrows.arrowZ4)

	rotArrows.arrowX1.Scale = arrowScale
	rotArrows.arrowX2.Scale = arrowScale
	rotArrows.arrowX3.Scale = arrowScale
	rotArrows.arrowX4.Scale = arrowScale

	rotArrows.arrowY1.Scale = arrowScale
	rotArrows.arrowY2.Scale = arrowScale
	rotArrows.arrowY3.Scale = arrowScale
	rotArrows.arrowY4.Scale = arrowScale

	rotArrows.arrowZ1.Scale = arrowScale
	rotArrows.arrowZ2.Scale = arrowScale
	rotArrows.arrowZ3.Scale = arrowScale
	rotArrows.arrowZ4.Scale = arrowScale

	-- we want arrows to be flat against item's box, this depends on how the models were created
	rotArrows.arrowX3.LocalRotation = { 0.0, 0.0, math.pi }
	rotArrows.arrowX4.LocalRotation = { 0.0, 0.0, math.pi }

	rotArrows.arrowY3.LocalRotation = { math.pi, 0.0, 0.0 }
    rotArrows.arrowY4.LocalRotation = { math.pi, 0.0, 0.0 }

    rotArrows.arrowZ3.LocalRotation = { 0.0, math.pi, 0.0 }
    rotArrows.arrowZ4.LocalRotation = { 0.0, math.pi, 0.0 }
end

-- shows and places or hides arrows depending
-- on current mode and camera alignment
updateArrows = function()
	if moveArrows ~= nil then moveArrows.refresh() end
	if rotArrows ~= nil then rotArrows.refresh() end
end

function savePOI()
	local anchor = Number3(0, 0, 0)

	if poiActiveName == "Hand" then
		anchor = Player.RightArm:GetPoint("hand").LocalPosition -- "hand" is stored in block coordinates
		-- anchor = Player.RightArm:GetPoint("hand").Coords -- if "hand" becomes stored as a local position
		if anchor == nil then
			anchor = Player.RightArm:BlockToLocal(Number3(1, -7, 1)) -- use default value
		end
	elseif poiActiveName == "Hat" then
		anchor = nil -- Player.Head:GetPoint("Hat").LocalPosition
		if anchor == nil then
			anchor = Number3(-0.5, 8.5, -0.5) -- use default value in LocalPosition
		end
	elseif poiActiveName == "Backpack" then
		anchor = nil -- Player.Body:GetPoint("Backpack").LocalPosition
		if anchor == nil then
			anchor = Number3(0.5, 2.5, -1.5) -- use default value in LocalPosition
		end
	end

	local poiPos = item.LocalPosition - anchor

	-- Save new point coords/rotation
	-- `poiPos` is a local position => myPoint.Coords will return it without conversion.
	item:AddPoint(poiActiveName, poiPos, item.LocalRotation)

	updateArrows()
	checkAutoSave()
end

setColorPickerIndex = function(colorIndex)
	pickerColorIndex = colorIndex
	if picker ~= nil then
		picker.SelectedIndex = pickerColorIndex
	end
end

showColorPicker = function()
	picker = ColorPicker()
	picker.Visible = true
	picker.SelectedIndex = pickerColorIndex
	picker.OnColorSelect = function(index)
		pickerColorIndex = index
		if colorPaletteBtn ~= nil then
			colorPaletteBtn.Color = getCurrentColor()
		end
	end
end

hideColorPicker = function()
	picker:Remove()
	picker = nil
end

clamp = function(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

n3Equals = function(v1, v2, epsilon)
    return (v2 - v1).Length < epsilon
end

lerp = function(from, to, v)
    return from + (to - from) * clamp(v, 0.0, 1.0)
end

easingQuadOut = function(v)
    return 1.0 - (1.0 - v) * (1.0 - v);
end

bool2int = function(b)
    return b and 1 or 0
end
