-- Unified Anchor + Nova GUI (LocalScript)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- helper: ensure Character present
local function waitChar()
	return player.Character or player.CharacterAdded:Wait()
end

-- Create or get ButtonStates folder (persistent per player instance)
local function getOrCreateButtonStates()
	local states = player:FindFirstChild("ButtonStates")
	if not states then
		states = Instance.new("Folder")
		states.Name = "ButtonStates"
		states.Parent = player
		for _, name in ipairs({"Anchor","Speed","Teleport","Noclip","ForwardTp","FastSpeedSteal"}) do
			local bv = Instance.new("BoolValue")
			bv.Name = name
			bv.Value = false
			bv.Parent = states
		end
	end
	return states
end
local buttonStates = getOrCreateButtonStates()

-- Shared vars for Anchor GUI
local char = waitChar()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local anchorEnabled, vertControl, flySpeed = false, 0, 20
local storedWalkSpeed, storedJumpPower = hum.WalkSpeed, hum.JumpPower
local targetPos = root.Position
local toggleKey, tpKey = Enum.KeyCode.F, Enum.KeyCode.T

-- Create Anchor GUI (GUI1)
local gui1 = Instance.new("ScreenGui")
gui1.Name = "AnchorGUI"
gui1.ResetOnSpawn = false
gui1.Parent = player:WaitForChild("PlayerGui")
gui1.Enabled = buttonStates.FastSpeedSteal.Value -- initial visibility controlled by FastSpeedSteal

local frame1 = Instance.new("Frame", gui1)
frame1.Size = UDim2.new(0,256,0,120)
frame1.Position = UDim2.new(0.5,-350,0.5,-150)
frame1.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame1.Active = true
frame1.Draggable = true
local _ = Instance.new("UICorner", frame1); _.CornerRadius = UDim.new(0,10)
local _ = Instance.new("UIStroke", frame1); _.Thickness = 3; _.Color = Color3.fromRGB(255,149,57)

local function makeBtn1(pos,size,txt,parent)
	local b = Instance.new("TextButton")
	b.Parent = parent or frame1
	b.Size = size; b.Position = pos; b.Text = txt
	b.BackgroundColor3 = Color3.fromRGB(28,28,28); b.BackgroundTransparency = 0.15; b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.Arcade; b.TextScaled = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
	local s = Instance.new("UIStroke", b); s.Thickness = 2; s.Color = Color3.fromRGB(11,165,207)
	return b
end

local mainBtn = makeBtn1(UDim2.new(0,18,0,18), UDim2.new(0,180,0,42), "Anchor: OFF", frame1)
local upBtn = makeBtn1(UDim2.new(0,200,0,18), UDim2.new(0,40,0,42), "▲", frame1); upBtn.Visible = false
local downBtn = makeBtn1(UDim2.new(0,245,0,18), UDim2.new(0,40,0,42), "▼", frame1); downBtn.Visible = false
local tpBtn = makeBtn1(UDim2.new(0,290,0,18), UDim2.new(0,60,0,42), "Tp", frame1); tpBtn.Visible = false

local toggleBox = Instance.new("TextBox", frame1)
toggleBox.Size, toggleBox.Position, toggleBox.Text = UDim2.new(0,60,0,20), UDim2.new(0,16,0,60), "F"
toggleBox.Font = Enum.Font.Arcade; toggleBox.TextScaled = true
local tpBox = Instance.new("TextBox", frame1)
tpBox.Size, tpBox.Position, tpBox.Text = UDim2.new(0,60,0,20), UDim2.new(0,80,0,60), "T"
tpBox.Font = Enum.Font.Arcade; tpBox.TextScaled = true

local function parseKeyFromBox(box, assignTo)
	box.FocusLost:Connect(function()
		local s = box.Text:upper()
		local k = Enum.KeyCode[s]
		if k then
			if assignTo == "toggle" then toggleKey = k end
			if assignTo == "tp" then tpKey = k end
		end
	end)
end
parseKeyFromBox(toggleBox, "toggle")
parseKeyFromBox(tpBox, "tp")

-- Anchor toggle function (keeps in sync with buttonStates.Anchor)
local function setAnchor(state)
	anchorEnabled = state
	if anchorEnabled then
		storedWalkSpeed, storedJumpPower = hum.WalkSpeed, hum.JumpPower
		hum.WalkSpeed, hum.JumpPower = 0, 0
		mainBtn.Text = "Anchor: ON"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = true, true, true
		targetPos = (root and root.Position) or targetPos
	else
		hum.WalkSpeed, hum.JumpPower = storedWalkSpeed or 16, storedJumpPower or 50
		mainBtn.Text = "Anchor: OFF"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = false, false, false
		vertControl = 0
	end
	-- keep BoolValue in sync (but avoid recursion if BoolValue already this)
	if buttonStates.Anchor.Value ~= state then
		buttonStates.Anchor.Value = state
	end
end

-- respond to external changes to BoolValue Anchor
buttonStates.Anchor.Changed:Connect(function(n)
	-- ensure local anchor GUI is updated
	setAnchor(n)
end)

mainBtn.MouseButton1Click:Connect(function()
	setAnchor(not anchorEnabled)
end)

tpBtn.MouseButton1Click:Connect(function()
	if anchorEnabled and root then
		local look = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0,0,-1)
		targetPos = targetPos + look * 7
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)

upBtn.MouseButton1Down:Connect(function() vertControl = 1 end)
upBtn.MouseButton1Up:Connect(function() vertControl = 0 end)
downBtn.MouseButton1Down:Connect(function() vertControl = -1 end)
downBtn.MouseButton1Up:Connect(function() vertControl = 0 end)

UIS.InputBegan:Connect(function(inp, proc)
	if proc then return end
	if inp.KeyCode == toggleKey then setAnchor(not anchorEnabled)
	elseif inp.KeyCode == tpKey and anchorEnabled then
		local look = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0,0,-1)
		targetPos = targetPos + look * 7
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	elseif inp.KeyCode == Enum.KeyCode.Space and anchorEnabled then vertControl = 1
	elseif inp.KeyCode == Enum.KeyCode.LeftShift and anchorEnabled then vertControl = -1
	end
end)
UIS.InputEnded:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.LeftShift then vertControl = 0 end
end)

-- Keep GUI1 visibility synced with FastSpeedSteal BoolValue
buttonStates.FastSpeedSteal.Changed:Connect(function(new)
	gui1.Enabled = new
end)
gui1.Enabled = buttonStates.FastSpeedSteal.Value

-- track current GUI2 buttons refs so prompt handler can update them
local currentButtonsRefs = {}
local currentFrameRefs = {} -- store references to GUI1 mainBtn/upBtn/tpBtn for restore
currentFrameRefs.mainBtn = mainBtn
currentFrameRefs.upBtn = upBtn
currentFrameRefs.downBtn = downBtn
currentFrameRefs.tpBtn = tpBtn

-- Teleport prompt connections: connect once, track connected prompts
local connectedPrompts = {} -- [Prompt] = connection
local function connectPrompt(prompt, handler)
	if connectedPrompts[prompt] then return end
	local conn = prompt.Triggered:Connect(handler)
	connectedPrompts[prompt] = conn
end

-- connect existing prompts and future ones
local function setupPromptListeners(handler)
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			connectPrompt(desc, handler)
		end
	end
	Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then
			connectPrompt(desc, handler)
		end
	end)
end

-- Main per-character GUI2 builder and logic
local function setupCharacter(character)
	local hrp = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")
	local originalSpeed = humanoid.WalkSpeed

	-- local teleport state
	local teleportActive = false
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportSteps = 30

	-- build GUI2
	local gui2 = Instance.new("ScreenGui")
	gui2.Name = "NovaGUI"
	gui2.ResetOnSpawn = false
	gui2.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame", gui2)
	frame.Size = UDim2.new(0,256,0,286)
	frame.Position = UDim2.new(0.5,-130,0.5,-135)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.Active = true
	frame.Draggable = true
	frame.Visible = false

	local icon = Instance.new("ImageButton", gui2)
	icon.Size = UDim2.new(0,75,0,75)
	icon.Position = UDim2.new(0,50,0,300)
	icon.Image = "rbxassetid://71285066607329"
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0,15)
	icon.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

	local function label(text, pos)
		local l = Instance.new("TextLabel", frame)
		l.Text = text; l.TextScaled = true; l.Font = Enum.Font.Arcade
		l.Size = UDim2.new(0,200,0,50); l.Position = pos
		l.TextColor3 = Color3.fromRGB(39,151,211); l.BackgroundTransparency = 1
	end
	label("Nova Hub", UDim2.new(0,40,0,0)); label("TT: @novahub57", UDim2.new(0,20,0,30)); label("If bag Reset", UDim2.new(0,30,0,50))

	local function createButton(pos, bv, onChange)
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0,113,0,50)
		btn.Position = pos
		btn.Font = Enum.Font.Arcade
		btn.TextScaled = true
		btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		btn.TextColor3 = Color3.new(0,0,0)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

		-- call onChange to set initial visual state
		onChange(bv.Value, btn)
		-- keep reference by BoolValue name
		currentButtonsRefs[bv.Name] = btn

		btn.MouseButton1Click:Connect(function()
			bv.Value = not bv.Value
			-- onChange will be invoked by the .Changed below too, but call manually to immediately update visual
			onChange(bv.Value, btn)
			-- FastSpeedSteal controls GUI1 visibility
			if bv.Name == "FastSpeedSteal" then
				gui1.Enabled = bv.Value
			end
		end)

		-- respond to external changes (so prompt handler / other code toggles reflect)
		bv.Changed:Connect(function(new)
			onChange(new, btn)
			if bv.Name == "FastSpeedSteal" then
				gui1.Enabled = new
			end
		end)

		return btn
	end

	-- anchor button: control hrp.Anchored and reflect label
	createButton(UDim2.new(0,10,0,212), buttonStates.Anchor, function(state, btn)
		hrp.Anchored = state
		if state then btn.Text = "Anchor ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else btn.Text = "Anchor OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
	end)

	-- speed button
	createButton(UDim2.new(0,130,0,212), buttonStates.Speed, function(state, btn)
		if state then
			humanoid.WalkSpeed = originalSpeed + 20
			btn.Text = "Speed ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			humanoid.WalkSpeed = originalSpeed
			btn.Text = "Speed OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- teleport (InstantSteal) button
	createButton(UDim2.new(0,10,0,150), buttonStates.Teleport, function(state, btn)
		if state then
			btn.Text = "InstantSteal ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			btn.Text = "InstantSteal OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- noclip button
	createButton(UDim2.new(0,130,0,150), buttonStates.Noclip, function(state, btn)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not state
			end
		end
		if state then btn.Text = "On Noclip"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else btn.Text = "Off Noclip"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
	end)

	-- ForwardTp button
	createButton(UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state, btn)
		btn.Text = state and "Wait For Update" or "WaitForUpdate"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- FastSpeedSteal / NoclipBypass button
	createButton(UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state, btn)
		btn.Text = "Noclip Byppas"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		gui1.Enabled = state
	end)

	-- RenderStepped interpolation for teleport
	RunService.RenderStepped:Connect(function(delta)
		if teleportActive and teleportTarget then
			teleportProgress = teleportProgress + delta
			local alpha = math.clamp(teleportProgress / (0.05 * teleportSteps), 0, 1)
			local newPos = hrp.Position:Lerp(teleportTarget, alpha)
			-- keep orientation slightly toward forward vector to avoid camera jumps:
			hrp.CFrame = CFrame.new(newPos)
			if alpha >= 1 then
				teleportActive = false
				teleportTarget = nil
				teleportProgress = 0
				-- reflect BoolValue off
				if buttonStates.Teleport.Value then buttonStates.Teleport.Value = false end
				local tb = currentButtonsRefs.Teleport
				if tb then tb.Text = "InstantSteal OFF"; tb.BackgroundColor3 = Color3.fromRGB(150,150,150) end
			end
		end
	end)

	-- helper: find player's plot part
	local function getPlayerPlotTpPart()
		local ok, plotsFolder = pcall(function() return workspace:WaitForChild("Plots") end)
		if not ok or not plotsFolder then return nil end
		for i=1,8 do
			local plot = plotsFolder:FindFirstChild("Plot"..i)
			if plot then
				local ownerValue = plot:FindFirstChild("Owner")
				local tpPart = plot:FindFirstChild("MultiplierPart")
				if ownerValue and ownerValue.Value == player.Name and tpPart then return tpPart end
			end
		end
		return nil
	end

	-- ProximityPrompt handler (only perform teleport when buttonStates.Teleport.Value true)
	local function onPromptTriggered()
		-- require teleport button on
		if not buttonStates.Teleport.Value then return end
		local tpPart = getPlayerPlotTpPart()
		if not tpPart then return end

		-- prepare teleport target + start interpolation
		local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
		teleportTarget = tpPart.Position + offset
		teleportProgress = 0
		teleportActive = true

		-- update UI button text
		local tb = currentButtonsRefs.Teleport
		if tb then tb.Text = "InstantSteal ON"; tb.BackgroundColor3 = Color3.fromRGB(60,60,60) end

		-- temporarily enable Anchor and Noclip if they were off, and remember
		local anchorWasOn = buttonStates.Anchor.Value
		local noclipWasOn = buttonStates.Noclip.Value

		if not anchorWasOn then
			buttonStates.Anchor.Value = true
			hrp.Anchored = true
			-- update GUI1 to show anchor state
			setAnchor(true)
		end

		if not noclipWasOn then
			buttonStates.Noclip.Value = true
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
			local nb = currentButtonsRefs.Noclip
			if nb then nb.Text = "On Noclip"; nb.BackgroundColor3 = Color3.fromRGB(60,60,60) end
		end

		-- wait for teleport finish and then restore states
		task.spawn(function()
			while teleportActive do RunService.RenderStepped:Wait() end
			-- short wait to finalize
			task.wait(0.1)

			-- restore anchor
			if not anchorWasOn then
				buttonStates.Anchor.Value = false
				hrp.Anchored = false
				setAnchor(false)
				local ab = currentButtonsRefs.Anchor
				if ab then ab.Text = "Anchor OFF"; ab.BackgroundColor3 = Color3.fromRGB(150,150,150) end
			end

			-- restore noclip
			if not noclipWasOn then
				buttonStates.Noclip.Value = false
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = true end
				end
				local nb = currentButtonsRefs.Noclip
				if nb then nb.Text = "Off Noclip"; nb.BackgroundColor3 = Color3.fromRGB(150,150,150) end
			end
		end)
	end

	-- connect prompts for this character environment (once globally)
	setupPromptListeners(function()
		-- Because we connected all prompts to same handler factory, we only need to call onPromptTriggered
		-- but the ProximityPrompt .Triggered connection provides the player param and the object triggering.
		-- We can ignore provided args; our onPromptTriggered only needs to check Teleport BoolValue.
		onPromptTriggered()
	end)
end

-- ensure prompt connections exist once (handler wrapper that calls onPromptTriggered is created per-character,
-- but setupPromptListeners prevents duplicate connections in connectedPrompts)
-- However we already call setupPromptListeners() inside setupCharacter so the global list is built there.

-- Setup on current character and on respawn
if player.Character then
	char = player.Character
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end
setupCharacter(char)
player.CharacterAdded:Connect(function(c)
	char = c
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	targetPos = root.Position
	setupCharacter(char)
end)

-- Heartbeat moved anchored root using GUI1 controls
RunService.Heartbeat:Connect(function(dt)
	if anchorEnabled and root and hum then
		local move = hum.MoveDirection
		local hor = Vector3.new(move.X,0,move.Z) * (storedWalkSpeed or hum.WalkSpeed) * dt
		local vert = Vector3.new(0, vertControl * flySpeed * dt, 0)
		targetPos = targetPos + hor + vert
		local cam = Workspace.CurrentCamera
		local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)
