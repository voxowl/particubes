-- Hi! This is the Item Editor.

-- %%%import_and_map_set%%%








Client.OnStart = function()
	
	----------------------------
	-- CONSTANTS
	----------------------------

	kCameraSpeed = 60
	kZoomSpeed = 5

	----------------------------
	-- STATE VALUES
	----------------------------

	cameraRotation = Number3(0, 0, 0)

	mode = { edit = 1, points = 2, max = 2 }
	modeName = { "EDIT", "POINTS" }

	editedItemState = { 
		position = Number3(0,0,0), 
		rotation = Number3(0,0,0),
		-- pivot used by the item shape in "edit/<any>" and "points/place" modes
		itemPivot = Number3(0,0,0)
	}

	-- saved camera states
	cameraStates = { 
		item = { --[[ set at the end of OnStart ]] },
		preview = {
			target = Number3(0, 1.1 * Map.Scale.Y, 0),
			distance = 3 * Map.Scale.Length,
			rotation = Number3(0, math.pi * -0.75, 0)
		}
	}

	cameraCurrentState = cameraStates.item
	
	editSubmode = { add = 1, remove = 2, paint = 3, mirror = 4, max = 4 }
	editSubmodeName = { "add", "remove", "paint", "mirror" }
	
	pointsSubmode = { move = 1, rotate = 2, max = 2}
	pointsSubmodeName = { "Move", "Rotate"}

	currentMode = nil
	currentEditSubmode = nil
	currentPointsSubmode = pointsSubmode.move -- points sub mode
	previousEditSubmode = editSubmode.add
	
	gridEnabled = 0

	changesSinceLastSave = false
	autoSaveDT = 0.0
	saveTrigger = 60 -- 60 seconds

	-- Drag info (rotate)
	drag = nil
	dragFriction = 2.0

	-- Drag2 info (pan)
	drag2 = { dragging = false, dx = 0, dy = 0 }

	dPad = { x = 0.0, y = 0.0 }

	cameraModes = { aroundBlock = 1, aroundCamera = 2 }
	cameraMode = nil

	-- displayed UI elements specific to current mode
	displayedModeUIElements = {}

	editModeButtons = {}

	darkTextColor = Color(100, 100, 100)
	darkTextColorDisabled = Color(100, 100, 100, 20)
	lightTextColor = Color(255, 255, 255)
	selectedButtonColor = Color(100, 100, 100)

	currentFacemode = false
	picking = false

	-- mirror mode
	mirrorShape = nil
	mirrorAxes = { x = 1, y = 2, z = 3}
	mirrorCoords = Number3(0,0,0) -- mirror block coords
	currentMirrorAxis = nil
	mirrorMargin = 1.0 -- the mirror is x block larger than the item
	mirrorThickness = 1.0/4.0

	arrowScale = 0.4
	arrowMargin = 1 -- the arrow is n block away from the item
	arrowSpace = 2 -- the arrow is n block away from the item

	hideArrowThreshold = 0.9
	showArrowThreshold = 0.3 -- for rot arrows

	----------------------------
	-- FUNCTIONS
	----------------------------

	initClientFunctions()

	----------------------------
	-- AMBIENCE
	----------------------------

	TimeCycle.On = false
	Time.Current = Time.Noon
	Clouds.On = false
    Fog.On = false

	----------------------------
	-- COMPONENTS
	----------------------------

	-- half of map voxel size in world
    halfMapVoxel = Map.Scale * 0.5
	
	-- color picker
	picker = nil
	pickerColorIndex = 157

	-- edited item
	-- getItemResource is defined in C++ for the item editor only
	item = MutableShape(getItemResource())
	item.History = true -- enable history for the edited item
	Map:AddChild(item)
	item.Position = Number3(0, 0, 0)

	poiActiveName = "Hand"

	-- a cube to show where the camera is looking at
	cameraTargetShape = MutableShape(Items.cube_selector)
	cameraTargetShape.PrivateDrawMode = 2 + (gridEnabled * 8) -- highlight
	cameraTargetShape.Scale = Map.Scale / (cameraTargetShape.Width - 1)

	----
    -- edit mode buttons
    ----

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

	modeButtonColor = Color(50, 149, 201)
	modeButtonColorSelected = Color(94, 192, 242)

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

	----
	-- mode independent buttons
	----

	-- mode toggle
	editModeBtn, poiModeBtn = Private:ItemEditorCreateModeSwitch()
	editModeBtn.OnRelease = function()
		setMode(mode.edit, nil)
	end
	poiModeBtn.OnRelease = function()
		setMode(mode.points, nil)
	end

	setFacemode(false)

	refreshUndoRedoGridButtons()

	refreshScreenshotAndSaveButtons()

	----------------------------
	-- INIT
	----------------------------

    Pointer:Show()

	initRotationArrows()
	initMoveArrows()

	Camera:SetModeSatellite(Number3(0,0,0))
	setMode(mode.edit, editSubmode.add)

	Camera:SetModeFree()
	cameraRotation = Number3(0.32, -0.81, 0.0)
	Camera.Rotation = cameraRotation

	Camera:FitToScreen(item, 0.8, true)

	cameraMode = cameraModes.aroundBlock
	Camera.target = item:PositionLocalToWorld(item.Center)
	Camera.dist = (Camera.Position - Camera.target).Length
	Camera:SetModeSatellite(Camera.target, Camera.dist)

	cameraStateSave()
end

Pointer.Zoom = function(zoomValue)
	if cameraMode == cameraModes.aroundBlock or currentMode == mode.points then
		if Camera.target == nil then return end
		Camera.dist = Camera.dist + zoomValue * kZoomSpeed
		if Camera.dist < 1 then
			Camera.dist = 1
		end
    	
    	Camera:SetModeSatellite(Camera.target, Camera.dist)
	else
		Camera.Position = Camera.Position + Camera.Forward * -zoomValue * kZoomSpeed
	end
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
	
	-- autosave only while in edit mode
	if currentMode == mode.edit then
		if changesSinceLastSave then
			autoSaveDT = autoSaveDT + dt
			if autoSaveDT > saveTrigger then
				save()
			end
		end
	end

	-- only consider drag2 when manipuling the item
	if currentMode ~= mode.points then

		if drag2 ~= nil then
			if drag2.dragging and UI.Crosshair == false then
				UI.Crosshair = true
			elseif not drag2.dragging and UI.Crosshair == true then
				UI.Crosshair = false
			end
			
			-- pan
			if drag2.dragging and (drag2.dx ~= 0.0 or drag2.dy ~= 0.0) then

				-- take care of the highlighted cube
				local impact = Camera:CastRay(item)
				if impact.Block ~= nil then
					cameraTargetShape.Position = impact.Block.Position + halfMapVoxel - Number3(0.05, 0.05, 0.05)
					World:AddChild(cameraTargetShape)
				else
					cameraTargetShape:RemoveFromParent()
				end
				
				-- move camera
				if cameraMode == cameraModes.aroundBlock then

					local dist = Camera.dist
					local dx = drag2.dx * dist * 0.0017
					local dy = drag2.dy * dist * 0.0017
					Camera.target = Camera.target - Camera.Right * dx - Camera.Up * dy

				elseif cameraMode == cameraModes.aroundCamera then

					local dx = drag2.dx * 0.2
					local dy = drag2.dy * 0.2
					Camera.Position = Camera.Position - Camera.Right * dx - Camera.Up * dy
				end
				
				drag2.dx = 0.0
				drag2.dy = 0.0
			end
		end

	end

	if cameraMode == cameraModes.aroundCamera then
		Camera.Position = Camera.Position +
						Camera.Forward * dPad.y * kCameraSpeed * dt +
						Camera.Right * dPad.x * kCameraSpeed * dt
	end

	if drag ~= nil then
		
		if drag.dragging == true then

			local dx = drag.dx * 0.01
			local dy = drag.dy * 0.01
			local rotX = cameraRotation.X - dy
			local rotY = cameraRotation.Y + dx

			-- keep rotX/Y between PI and -PI
			while rotX > math.pi do
				rotX = rotX - (math.pi * 2.0)
			end
			while rotX < -math.pi do
				rotX = rotX + (math.pi * 2.0)
			end
			while rotY > math.pi do
				rotY = rotY - (math.pi * 2.0)
			end
			while rotY < -math.pi do
				rotY = rotY + (math.pi * 2.0)
			end

			-- clamp rotation between 90° and -90° on X
			if rotX < -math.pi * 0.4999 then
				rotX = -math.pi * 0.4999
			elseif rotX > math.pi * 0.4999 then
				rotX = math.pi * 0.4999
			end

			-- compute speed
			drag.speedX = (rotX - cameraRotation.X) / dt * 0.5
			drag.speedY = (rotY - cameraRotation.Y) / dt * 0.5
			
			-- apply rotation
			cameraRotation = Number3(rotX, rotY, 0)
			Camera.Rotation = cameraRotation
			
			-- consume drag delta
			drag.dx = 0
			drag.dy = 0
		else
			-- not dragging, apply speed
			if drag.speedX > 0 then
				drag.speedX = drag.speedX - (dragFriction * dt * drag.speedX)
				if drag.speedX < 0.2 then
					drag.speedX = 0	
				end
			elseif drag.speedX < 0 then
				drag.speedX = drag.speedX - (dragFriction * dt * drag.speedX)
				if drag.speedX > -0.2 then
					drag.speedX = 0
				end
			end

			if drag.speedY > 0 then
				drag.speedY = drag.speedY - (dragFriction * dt * drag.speedY)
				if drag.speedY < 0.2 then
					drag.speedY = 0
				end
			else
				drag.speedY = drag.speedY - (dragFriction * dt * drag.speedY)
				if drag.speedY > -0.2 then
					drag.speedY = 0
				end
			end

			if drag.speedX == 0 and drag.speedY == 0 then return end

			local rotX = cameraRotation.X + (drag.speedX * dt)
			local rotY = cameraRotation.Y + (drag.speedY * dt)

			-- keep rotX/Y between PI and -PI
			while rotX > math.pi do
				rotX = rotX - (math.pi * 2.0)
			end
			while rotX < -math.pi do
				rotX = rotX + (math.pi * 2.0)
			end
			while rotY > math.pi do
				rotY = rotY - (math.pi * 2.0)
			end
			while rotY < -math.pi do
				rotY = rotY + (math.pi * 2.0)
			end

			-- clamp rotation between 90° and -90° on X
			if rotX < -math.pi * 0.4999 then
				rotX = -math.pi * 0.4999
			elseif rotX > math.pi * 0.4999 then
				rotX = math.pi * 0.4999
			end

			cameraRotation = Number3(rotX, rotY, 0)
			Camera.Rotation = cameraRotation
		end
	end
end

Pointer.Down = function(e)

	drag = nil

	if currentMode == mode.points then
		moveArrows.unselect()
		rotArrows.unselect()
		if currentPointsSubmode == pointsSubmode.move then
			moveArrows.select(e)
		elseif currentPointsSubmode == pointsSubmode.rotate then
			rotArrows.select(e)
		end
	end

	if moveArrows.selected == nil and rotArrows.selected == nil then
		-- did not touch any arrow, start moving camera
		drag = {
			dragging = false,
			dx = 0,
			dy = 0,
			speedX = 0,
			speedY = 0
		}
		return
	end

end

Pointer.Up = function(e)

	if currentMode == mode.edit and drag ~= nil and drag.dragging == false then

		local impact = e:CastRay(item)

		if picking then
			pickCubeColor(impact)
		elseif currentEditSubmode == editSubmode.add then
			addBlockWithImpact(impact, currentFacemode)
		elseif currentEditSubmode == editSubmode.remove then
			removeBlockWithImpact(impact, currentFacemode)
		elseif currentEditSubmode == editSubmode.paint then
			replaceBlockWithImpact(impact, currentFacemode)
		elseif currentEditSubmode == editSubmode.mirror and not mirrorPlaced then
			placeMirror(impact)
		end
	end

	if drag ~= nil and drag.dragging == true then
		drag.dragging = false
	end

	if currentMode == mode.points then
		moveArrows.unselect()
	
		rotArrows.rotate(e)
		rotArrows.unselect()
		
		updateArrows()
	end
end


Pointer.Drag = function(e)

	if moveArrows.selected ~= nil then
		moveArrows.moveItem(e)

	elseif drag ~= nil then

		drag.speedX = 0
		drag.speedY = 0
		drag.dx = drag.dx + e.DX
		drag.dy = drag.dy + e.DY

		if drag.dragging == false then
			drag.dragging = true
		end
	end
end

Pointer.Drag2 = function(e)
	if currentMode ~= mode.points then

		drag2.dx = drag2.dx + e.DX
		drag2.dy = drag2.dy + e.DY
		
		if drag2.dragging == false then
			drag2.dragging = true
			item.PrivateDrawMode = 1 + (gridEnabled * 8)
		end
	end
end

Pointer.OnDrag2End = function(e)
	-- recenters on cube if hitting a cube
	-- + go to aroundCube mode if needed
	recenterOnCubeAfterPan()
	
	-- change draw mode back to 0 only in EDIT mode
	-- (in POINTS mode, the item stays transparent)
	if currentMode == mode.edit then
		item.PrivateDrawMode = 0 + (gridEnabled * 8)
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

		-- going form one mode to another
		if updatingMode then

			if newMode < 1 or newMode > mode.max then
				error("setMode - invalid change:" .. newMode .. " " .. newSubmode)
				return
			end

			cameraStateSave()

			currentMode = newMode

			if currentMode == mode.edit then

				if poiActiveName == "Hand" then
					Player:EquipRightHand(nil)
				elseif poiActiveName == "Hat" then
					Player:EquipHat(nil)
				elseif poiActiveName == "Backpack" then
					Player:EquipBackpack(nil)
				end

				-- remove avatar and arrows
				Player:RemoveFromParent()

				Map:AddChild(item)

				-- restore item state
				item.Position = editedItemState.position
				item.Rotation = editedItemState.rotation
				item.Pivot = editedItemState.itemPivot

				Client.DirectionalPad = function(x, y)
					if currentMode == mode.edit then
						Camera:SetModeFree()
						cameraMode = cameraModes.aroundCamera
						dPad.x = x
						dPad.y = y
						
						cameraTargetShape:RemoveFromParent()
					end
				end
				
			else -- place item points / preview

				-- save item state
				editedItemState.position = item.Position:Copy()
				editedItemState.rotation = item.Rotation:Copy()
				editedItemState.itemPivot = item.Pivot:Copy()
				
				-- hide the item
				Map:RemoveChild(item)

				-- make player appear in front of camera with item in hand
				Map:AddChild(Player)
				Player.LocalPosition = {0, 0, 0}
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

	recenterOnCubeAfterPan = function()
		if drag2.dragging then
			local impact = Camera:CastRay(item)
			
			if impact.Block ~= nil then
				-- switch to aroundBlock mode if there's a block impact
				cameraMode = cameraModes.aroundBlock
				-- "impact.Block.Position" is the corner of the cube.
				-- We add halfMapVoxel so that the Camera center of rotation is at the center of the cube.
				Camera.target = impact.Block.Position + halfMapVoxel
				Camera.dist = (Camera.Position - Camera.target).Length
				Camera:SetModeSatellite(Camera.target, Camera.dist)
				cameraMode = cameraModes.aroundBlock
			end
			drag2.dragging = false
			drag2.dx = 0.0
			drag2.dy = 0.0
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

		local wasInPointsMode = false

		cameraStateSave()

		cameraTargetShape.IsHidden = true
		moveArrows.hide()
		rotArrows.hide()

		if currentMode == mode.points then
			wasInPointsMode = true
			setMode(mode.edit, nil)
		end
		
		-- force drawmode 0 for save (needed for screenshot)
		local drawmode = item.PrivateDrawMode
		item.PrivateDrawMode = 0

		cameraRotation = {0.32, -0.81, 0.0}
		Camera.Rotation = cameraRotation
		Camera:FitToScreen(item, 0.8, false) -- sets Camera Position
		item:Save(Config.editedItemName)

		cameraStateSet(expectedCameraStateForCurrentState())

		changesSinceLastSave = false
		autoSaveDT = 0.0
		refreshScreenshotAndSaveButtons()

		item.PrivateDrawMode = drawmode -- restore drawmode

		if wasInPointsMode then
			setMode(mode.points, nil)
		end

		-- show mirror again
		if mirrorShape ~= nil then mirrorShape.IsHidden = false end
		cameraTargetShape.IsHidden = false
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
		checkAutoSave()
		refreshUndoRedoGridButtons()
	end

	addSingleBlock = function(block, faceTouched)
		local addedBlock = block:AddNeighbor(Block(getCurrentColorIndex()), faceTouched)

		if addedBlock ~= nil and mirrorShape ~= nil then
			local mirrorBlockCoords = mirrorCoords - {0.5, 0.5, 0.5}

			if currentMirrorAxis == mirrorAxes.x then
				item:AddBlock(getCurrentColorIndex(),
					mirrorBlockCoords.X - (addedBlock.Coordinates.X - mirrorBlockCoords.X),
					addedBlock.Coordinates.Y,
					addedBlock.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.y then
				item:AddBlock(getCurrentColorIndex(),
					addedBlock.Coordinates.X,
					mirrorBlockCoords.Y - (addedBlock.Coordinates.Y - mirrorBlockCoords.Y),
					addedBlock.Coordinates.Z)

			elseif currentMirrorAxis == mirrorAxes.z then
				item:AddBlock(getCurrentColorIndex(),
					addedBlock.Coordinates.X,
					addedBlock.Coordinates.Y,
					mirrorBlockCoords.Z - (addedBlock.Coordinates.Z - mirrorBlockCoords.Z))
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
		checkAutoSave()
		refreshUndoRedoGridButtons()
	end

	removeSingleBlock = function(block)
		block:Remove()

		if mirrorShape ~= nil then
			local mirrorBlockCoords = mirrorCoords - {0.5, 0.5, 0.5}

			if currentMirrorAxis == mirrorAxes.x then
				item:GetBlock(
					mirrorBlockCoords.X - (block.Coordinates.X - mirrorBlockCoords.X),
					block.Coordinates.Y,
					block.Coordinates.Z):Remove()

			elseif currentMirrorAxis == mirrorAxes.y then
				item:GetBlock(
					block.Coordinates.X,
					mirrorBlockCoords.Y - (block.Coordinates.Y - mirrorBlockCoords.Y),
					block.Coordinates.Z):Remove()

			elseif currentMirrorAxis == mirrorAxes.z then
				item:GetBlock(
					block.Coordinates.X,
					block.Coordinates.Y,
					mirrorBlockCoords.Z - (block.Coordinates.Z - mirrorBlockCoords.Z)):Remove()
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

		updateMirror()
		checkAutoSave()
		refreshUndoRedoGridButtons()
	end

	replaceSingleBlock = function(block)
		block:Replace(Block(getCurrentColorIndex()))

		if mirrorShape ~= nil then
			local mirrorBlockCoords = mirrorCoords - {0.5, 0.5, 0.5}

			if currentMirrorAxis == mirrorAxes.x then
				item:GetBlock(
					mirrorBlockCoords.X - (block.Coordinates.X - mirrorBlockCoords.X),
					block.Coordinates.Y,
					block.Coordinates.Z):Replace(Block(getCurrentColorIndex()))

			elseif currentMirrorAxis == mirrorAxes.y then
				item:GetBlock(
					block.Coordinates.X,
					mirrorBlockCoords.Y - (block.Coordinates.Y - mirrorBlockCoords.Y),
					block.Coordinates.Z):Replace(Block(getCurrentColorIndex()))

			elseif currentMirrorAxis == mirrorAxes.z then
				item:GetBlock(
					block.Coordinates.X,
					block.Coordinates.Y,
					mirrorBlockCoords.Z - (block.Coordinates.Z - mirrorBlockCoords.Z)):Replace(Block(getCurrentColorIndex()))
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

		-- construct new buttons
		local showUndoRedo = item.CanUndo or item.CanRedo
		undoBtn, redoBtn, gridModeBtn = Private:ItemEditorCreateUndoRedoAndGrid(showUndoRedo)

		gridModeBtn.TextColor = darkTextColor
		gridModeBtn.OnRelease = function()
			item.PrivateDrawMode = gridModeToggle(item.PrivateDrawMode)
		end
		gridModeBtnRefresh()

		if item.CanUndo then
			undoBtn.Color = defaultButtonColor
			undoBtn.TextColor = darkTextColor
			undoBtn.OnRelease = function()
				if item ~= nil and item.CanUndo then
					item:Undo()
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

			cameraTargetShape.IsHidden = true
			
			item.PrivateDrawMode = 0
			item:Capture()
			item.PrivateDrawMode = drawmode

			-- show mirror again after the screenshot
			if mirrorEnabled then
				mirrorShape.IsHidden = false
			end

			-- show camera target shape again
			cameraTargetShape.IsHidden = false
			
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
			local width = item.Width + mirrorMargin
			local height = item.Height + mirrorMargin
			local depth = item.Depth + mirrorMargin
			local center = item.Center
			local mirrorLocalPosition = item:BlockToLocal(mirrorCoords)
			
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
		local n = normal:Copy()
		local camera = Camera.Forward:Copy()
		n:Normalize()
		camera:Normalize()
		return math.abs(n:Dot(camera))
	end

	sqr_len = function(dx, dy)
		return dx * dx + dy * dy
	end

	expectedCameraStateForCurrentState = function()
		if currentMode == mode.points then
			return cameraStates.preview
		end
		return cameraStates.item
	end

	cameraStateSave = function()

		-- cameraRotation is common to all states
		cameraCurrentState.rotation = cameraRotation:Copy()

		if currentMode == mode.edit then

			cameraStates.item.mode = cameraMode

			if cameraMode == cameraModes.aroundBlock then
				cameraStates.item.target = Camera.target:Copy()
				cameraStates.item.dist = Camera.dist

				if cameraTargetShape:GetParent() ~= nil then
					cameraStates.item.targetShapePos = cameraTargetShape.Position
				else
					cameraStates.item.targetShapePos = nil
				end
			else
				-- aroundCamera only needs rotation + position
				cameraStates.item.position = Camera.Position:Copy()
			end
		else
			-- saving state from "points" mode
			cameraStates.preview.target = Camera.target:Copy()
			cameraStates.preview.dist = Camera.dist
		end
	end

	cameraStateSet = function(state)

		cameraRotation = state.rotation:Copy()
		Camera.Rotation = cameraRotation

		if state == cameraStates.preview then
			
			cameraTargetShape:RemoveFromParent()

			Camera.target = Player.Head.Position:Copy()

			Camera.dist = cameraStates.preview.dist
			if Camera.dist == nil then
				Camera.dist = 75.0
			end
			
			Camera:SetModeSatellite(Camera.target, Camera.dist)
			Pointer:Show()
			UI.Crosshair = false

		else
			cameraMode = cameraStates.item.mode

			if cameraMode == cameraModes.aroundBlock then

				Camera.target = cameraStates.item.target:Copy()
				Camera.dist = cameraStates.item.dist

				Camera:SetModeSatellite(Camera.target, Camera.dist)
				
				if cameraStates.item.targetShapePos ~= nil then
					World:AddChild(cameraTargetShape)
					cameraTargetShape.Position = cameraStates.item.targetShapePos
				end
			else
				Camera:SetModeFree()
				Camera.Position = cameraStates.item.position
			end
		end

		cameraCurrentState = state
	end

	cameraStateSetToExpected = function()
		local expectedState = expectedCameraStateForCurrentState()
		if expectedState ~= cameraCurrentState then
			cameraStateSet(expectedState)
		end
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

			local min = item:PositionLocalToWorld(item.Min)
			local max = item:PositionLocalToWorld(item.Max)
			min = moveArrows.object:PositionWorldToLocal(min)
			max = moveArrows.object:PositionWorldToLocal(max)

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

	Map:AddChild(moveArrows.impact) -- for transformations

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

	rotArrows = {
		object = Object(), -- object placed at center of item (not parented)
		arrowsRightAxis = Object(), -- to rotate around right axis
		arrowsUpAxis = Object(), -- to rotate around up axis
		arrowsForwardAxis = Object(), -- to rotate around forward axis
		arrowUp1 = Shape(Items.arrow_rot_up_norm_1),
		arrowUp2 = Shape(Items.arrow_rot_up_norm_2),
		arrowUp3 = Shape(Items.arrow_rot_up_norm_1),
		arrowUp4 = Shape(Items.arrow_rot_up_norm_2),
		arrowRight1 = Shape(Items.arrow_rot_right_norm_1),
		arrowRight2 = Shape(Items.arrow_rot_right_norm_2),
		arrowRight3 = Shape(Items.arrow_rot_right_norm_1),
		arrowRight4 = Shape(Items.arrow_rot_right_norm_2),
		arrowForward1 = Shape(Items.arrow_rot_forward_norm_1),
		arrowForward2 = Shape(Items.arrow_rot_forward_norm_2),
		arrowForward3 = Shape(Items.arrow_rot_forward_norm_1),
		arrowForward4 = Shape(Items.arrow_rot_forward_norm_2),
		poiActiveName = "",
		selected = nil, -- selected arrow, turns on pointer up while still on selected arrow

		destroy = function()
			if rotArrows ~= nil then
				rotArrows.object:RemoveFromParent()
				rotArrows = nil
			end
		end,

		hide = function()
			rotArrows.object.IsHidden = true
		end,

		show = function()
			rotArrows.object.IsHidden = false
		end,

		refresh = function()
			rotArrows.arrowsRightAxis.IsHidden = false
			rotArrows.arrowsUpAxis.IsHidden = false
			rotArrows.arrowsForwardAxis.IsHidden = false

			-- hide arrows aligned with Camera
			if getAlignment(rotArrows.object.Right) < showArrowThreshold then
				rotArrows.arrowsRightAxis.IsHidden = true
			end

			if getAlignment(rotArrows.object.Up) < showArrowThreshold then
					rotArrows.arrowsUpAxis.IsHidden = true
			end

			if getAlignment(rotArrows.object.Forward) < showArrowThreshold then			
				rotArrows.arrowsForwardAxis.IsHidden = true
			end
		end,

		hit = function(e)
			local impacts = {}

			local impactUp1 = e:CastRay(rotArrows.arrowUp1)
			if impactUp1 ~= nil then table.insert(impacts, impactUp1) end
			local impactUp2 = e:CastRay(rotArrows.arrowUp2)
			if impactUp2 ~= nil then table.insert(impacts, impactUp2) end
			local impactUp3 = e:CastRay(rotArrows.arrowUp3)
			if impactUp3 ~= nil then table.insert(impacts, impactUp3) end
			local impactUp4 = e:CastRay(rotArrows.arrowUp4)
			if impactUp4 ~= nil then table.insert(impacts, impactUp4) end

			local impactRight1 = e:CastRay(rotArrows.arrowRight1)
			if impactRight1 ~= nil then table.insert(impacts, impactRight1) end
			local impactRight2 = e:CastRay(rotArrows.arrowRight2)
			if impactRight2 ~= nil then table.insert(impacts, impactRight2) end
			local impactRight3 = e:CastRay(rotArrows.arrowRight3)
			if impactRight3 ~= nil then table.insert(impacts, impactRight3) end
			local impactRight4 = e:CastRay(rotArrows.arrowRight4)
			if impactRight4 ~= nil then table.insert(impacts, impactRight4) end

			local impactForward1 = e:CastRay(rotArrows.arrowForward1)
			if impactForward1 ~= nil then table.insert(impacts, impactForward1) end
			local impactForward2 = e:CastRay(rotArrows.arrowForward2)
			if impactForward2 ~= nil then table.insert(impacts, impactForward2) end
			local impactForward3 = e:CastRay(rotArrows.arrowForward3)
			if impactForward3 ~= nil then table.insert(impacts, impactForward3) end
			local impactForward4 = e:CastRay(rotArrows.arrowForward4)
			if impactForward4 ~= nil then table.insert(impacts, impactForward4) end

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

				if impact == impactUp1 then arrow = rotArrows.arrowUp1
				elseif impact == impactUp2 then arrow = rotArrows.arrowUp2
				elseif impact == impactUp3 then arrow = rotArrows.arrowUp3
				elseif impact == impactUp4 then arrow= rotArrows.arrowUp4
				elseif impact == impactRight1 then arrow = rotArrows.arrowRight1
				elseif impact == impactRight2 then arrow = rotArrows.arrowRight2
				elseif impact == impactRight3 then arrow = rotArrows.arrowRight3
				elseif impact == impactRight4 then arrow= rotArrows.arrowRight4
				elseif impact == impactForward1 then arrow = rotArrows.arrowForward1
				elseif impact == impactForward2 then arrow = rotArrows.arrowForward2
				elseif impact == impactForward3 then arrow = rotArrows.arrowForward3
				elseif impact == impactForward4 then arrow= rotArrows.arrowForward4 end

				return arrow
			end,

		select = function(e) -- see if an arrow is selected with pointer event
			rotArrows.selected = rotArrows.hit(e)
		end,

		rotate = function(e)
			if rotArrows.selected == nil then return end

			if rotArrows.selected == rotArrows.hit(e) then
					
				local selected = rotArrows.selected

				if selected == rotArrows.arrowUp1 then
					item:RotateLocal({0, 1, 0}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowUp2 then
					item:RotateLocal({0, 1, 0}, math.pi * 0.5)
				elseif selected == rotArrows.arrowUp3 then
					item:RotateLocal({0, 1, 0}, math.pi * 0.5)
				elseif selected == rotArrows.arrowUp4 then
					item:RotateLocal({0, 1, 0}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowRight1 then
					item:RotateLocal({1, 0, 0}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowRight2 then
					item:RotateLocal({1, 0, 0}, math.pi * 0.5)
				elseif selected == rotArrows.arrowRight3 then
					item:RotateLocal({1, 0, 0}, math.pi * 0.5)
				elseif selected == rotArrows.arrowRight4 then
					item:RotateLocal({1, 0, 0}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowForward1 then
					item:RotateLocal({0, 0, 1}, -math.pi * 0.5)
				elseif selected == rotArrows.arrowForward2 then
					item:RotateLocal({0, 0, 1}, math.pi * 0.5)
				elseif selected == rotArrows.arrowForward3 then
					item:RotateLocal({0, 0, 1}, math.pi * 0.5)
				elseif selected == rotArrows.arrowForward4 then
					item:RotateLocal({0, 0, 1}, -math.pi * 0.5)
				end

				savePOI()
			end
		end,
		
		unselect = function()
			rotArrows.selected = nil
		end
	}

	-- local rotation gizmo, so arrows must be in the same local space ie. same parent
	-- Note: we could have a world rotation gizmo mode using additional conversions
	rotArrows.object:SetParent(item:GetParent())
	rotArrows.object.LocalPosition = item.LocalPosition

	rotArrows.object:AddChild(rotArrows.arrowsRightAxis)
	rotArrows.object:AddChild(rotArrows.arrowsUpAxis)
	rotArrows.object:AddChild(rotArrows.arrowsForwardAxis)

	rotArrows.arrowsRightAxis:AddChild(rotArrows.arrowRight1)
	rotArrows.arrowsRightAxis:AddChild(rotArrows.arrowRight2)
	rotArrows.arrowsRightAxis:AddChild(rotArrows.arrowRight3)
	rotArrows.arrowsRightAxis:AddChild(rotArrows.arrowRight4)

	rotArrows.arrowsUpAxis:AddChild(rotArrows.arrowUp1)
	rotArrows.arrowsUpAxis:AddChild(rotArrows.arrowUp2)
	rotArrows.arrowsUpAxis:AddChild(rotArrows.arrowUp3)
	rotArrows.arrowsUpAxis:AddChild(rotArrows.arrowUp4)

	rotArrows.arrowsForwardAxis:AddChild(rotArrows.arrowForward1)
	rotArrows.arrowsForwardAxis:AddChild(rotArrows.arrowForward2)
	rotArrows.arrowsForwardAxis:AddChild(rotArrows.arrowForward3)
	rotArrows.arrowsForwardAxis:AddChild(rotArrows.arrowForward4)

	rotArrows.arrowRight1.Scale = arrowScale
	rotArrows.arrowRight2.Scale = arrowScale
	rotArrows.arrowRight3.Scale = arrowScale
	rotArrows.arrowRight4.Scale = arrowScale

	rotArrows.arrowUp1.Scale = arrowScale
	rotArrows.arrowUp2.Scale = arrowScale
	rotArrows.arrowUp3.Scale = arrowScale
	rotArrows.arrowUp4.Scale = arrowScale

	rotArrows.arrowForward1.Scale = arrowScale
	rotArrows.arrowForward2.Scale = arrowScale
	rotArrows.arrowForward3.Scale = arrowScale
	rotArrows.arrowForward4.Scale = arrowScale

	rotArrows.arrowRight1.Pivot.Z = 0
	rotArrows.arrowRight2.Pivot.Z = 0
	rotArrows.arrowRight3.Pivot.Z = 0
	rotArrows.arrowRight4.Pivot.Z = 0

	rotArrows.arrowUp1.Pivot.X = 0
	rotArrows.arrowUp2.Pivot.X = 0
	rotArrows.arrowUp3.Pivot.X = 0
	rotArrows.arrowUp4.Pivot.X = 0

	rotArrows.arrowForward1.Pivot.Y = 0
	rotArrows.arrowForward2.Pivot.Y = 0
	rotArrows.arrowForward3.Pivot.Y = 0
	rotArrows.arrowForward4.Pivot.Y = 0

	rotArrows.arrowRight1.Position = item:PositionLocalToWorld({ item.Center.X, item.Center.Y + arrowSpace, item.Max.Z + arrowMargin})
	rotArrows.arrowRight2.Position = item:PositionLocalToWorld({ item.Center.X, item.Center.Y - arrowSpace, item.Max.Z + arrowMargin})
	rotArrows.arrowRight3.Position = item:PositionLocalToWorld({ item.Center.X, item.Center.Y + arrowSpace, item.Min.Z - arrowMargin})
	rotArrows.arrowRight3.LocalRotation = { 0.0, math.pi, 0.0 }
	rotArrows.arrowRight4.Position = item:PositionLocalToWorld({ item.Center.X, item.Center.Y - arrowSpace, item.Min.Z - arrowMargin})
	rotArrows.arrowRight4.LocalRotation = { 0.0, math.pi, 0.0 }

	rotArrows.arrowUp1.Position = item:PositionLocalToWorld({ item.Max.X + arrowMargin, item.Center.Y, item.Center.Z + arrowSpace })
	rotArrows.arrowUp2.Position = item:PositionLocalToWorld({ item.Max.X + arrowMargin, item.Center.Y, item.Center.Z - arrowSpace})
	rotArrows.arrowUp3.Position = item:PositionLocalToWorld({ item.Min.X - arrowMargin, item.Center.Y, item.Center.Z + arrowSpace })
	rotArrows.arrowUp3.LocalRotation = { 0.0, 0.0, math.pi }
	rotArrows.arrowUp4.Position = item:PositionLocalToWorld({ item.Min.X - arrowMargin, item.Center.Y, item.Center.Z - arrowSpace })
	rotArrows.arrowUp4.LocalRotation = { 0.0, 0.0, math.pi }

	rotArrows.arrowForward1.Position = item:PositionLocalToWorld({ item.Center.X + arrowSpace, item.Max.Y + arrowMargin, item.Center.Z })
	rotArrows.arrowForward2.Position = item:PositionLocalToWorld({ item.Center.X - arrowSpace, item.Max.Y + arrowMargin, item.Center.Z })
	rotArrows.arrowForward3.Position = item:PositionLocalToWorld({ item.Center.X + arrowSpace, item.Min.Y - arrowMargin, item.Center.Z })
	rotArrows.arrowForward3.LocalRotation = { math.pi, 0.0, 0.0 }
	rotArrows.arrowForward4.Position = item:PositionLocalToWorld({ item.Center.X - arrowSpace, item.Min.Y - arrowMargin, item.Center.Z })
	rotArrows.arrowForward4.LocalRotation = { math.pi, 0.0, 0.0 }

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