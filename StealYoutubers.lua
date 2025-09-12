-- Unified Anchor + Nova GUI (LocalScript)
-- Поддерживает: Anchor GUI (GUI1) + Nova GUI (GUI2)
-- Исправляет: InstantSteal срабатывает только при включенной кнопке,
-- временное включение Anchor/Noclip и восстановление, одиночные подписки на ProximityPrompt,
-- синхронизация GUI <-> BoolValues, FastSpeedSteal управляет видимостью GUI1.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Helper: ensure character present
local function waitCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

-- Create / get ButtonStates folder with BoolValues
local function getOrCreateButtonStates()
	local states = player:FindFirstChild("ButtonStates")
	if not states then
		states = Instance.new("Folder")
		states.Name = "ButtonStates"
		states.Parent = player
		for _, name in ipairs({"Anchor","Speed","Teleport","Noclip","ForwardTp","FastSpeedSteal"}) do
			local b = Instance.new("BoolValue")
			b.Name = name
			b.Value = false
			b.Parent = states
		end
	end
	return states
end
local buttonStates = getOrCreateButtonStates()

-- Local references to current character parts (refreshed on respawn)
local char = waitCharacter()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- Anchor GUI (GUI1) variables
local anchorEnabled = false
local vertControl = 0
local flySpeed = 20
local storedWalkSpeed, storedJumpPower = hum.WalkSpeed, hum.JumpPower
local targetPos = root.Position
local toggleKey, tpKey = Enum.KeyCode.F, Enum.KeyCode.T

-- ---- GUI1 (Anchor) creation ----
-- remove previous if exist (safety)
local existingGui1 = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("AnchorGUI")
if existingGui1 then existingGui1:Destroy() end

local gui1 = Instance.new("ScreenGui")
gui1.Name = "AnchorGUI"
gui1.ResetOnSpawn = false
gui1.Parent = player:WaitForChild("PlayerGui")
-- GUI1 visibility controlled by FastSpeedSteal BoolValue
gui1.Enabled = buttonStates.FastSpeedSteal.Value

local frame1 = Instance.new("Frame", gui1)
frame1.Size = UDim2.new(0,256,0,120)
frame1.Position = UDim2.new(0.5,-350,0.5,-150)
frame1.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame1.Active = true
frame1.Draggable = true
Instance.new("UICorner", frame1).CornerRadius = UDim.new(0,10)
local _ = Instance.new("UIStroke", frame1); _.Thickness = 3; _.Color = Color3.fromRGB(255,149,57)

local function makeBtn1(pos, size, txt, parent)
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

local function parseKeyBox(box, which)
	box.FocusLost:Connect(function()
		local s = tostring(box.Text or ""):upper()
		local k = Enum.KeyCode[s]
		if k then
			if which == "toggle" then toggleKey = k end
			if which == "tp" then tpKey = k end
		end
	end)
end
parseKeyBox(toggleBox, "toggle")
parseKeyBox(tpBox, "tp")

-- set anchor state (updates both GUI1 and ButtonStates.Anchor)
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
	-- sync BoolValue if necessary
	if buttonStates.Anchor.Value ~= state then
		buttonStates.Anchor.Value = state
	end
end

-- respond to external bool changes for Anchor
buttonStates.Anchor.Changed:Connect(function(new)
	-- avoid double-work when setAnchor already wrote the same value: still safe
	setAnchor(new)
end)

mainBtn.MouseButton1Click:Connect(function()
	setAnchor(not anchorEnabled)
end)

tpBtn.MouseButton1Click:Connect(function()
	if anchorEnabled and root then
		local cam = Workspace.CurrentCamera
		local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
		targetPos = targetPos + look * 7
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)

upBtn.MouseButton1Down:Connect(function() vertControl = 1 end)
upBtn.MouseButton1Up:Connect(function() vertControl = 0 end)
downBtn.MouseButton1Down:Connect(function() vertControl = -1 end)
downBtn.MouseButton1Up:Connect(function() vertControl = 0 end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == toggleKey then setAnchor(not anchorEnabled)
	elseif input.KeyCode == tpKey and anchorEnabled then
		local cam = Workspace.CurrentCamera
		local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
		targetPos = targetPos + look * 7
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	elseif input.KeyCode == Enum.KeyCode.Space and anchorEnabled then
		vertControl = 1
	elseif input.KeyCode == Enum.KeyCode.LeftShift and anchorEnabled then
		vertControl = -1
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then vertControl = 0 end
end)

-- FastSpeedSteal controls GUI1 visibility and kept synced
buttonStates.FastSpeedSteal.Changed:Connect(function(n)
	gui1.Enabled = n
end)
gui1.Enabled = buttonStates.FastSpeedSteal.Value

-- ---- GUI2 (Nova) ----
-- Remove old GUI2 if exists (safety)
local existingGui2 = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("NovaGUI")
if existingGui2 then existingGui2:Destroy() end

-- We'll keep references to GUI2 buttons so prompt handler can update them directly
local gui2Buttons = {}

local function buildGui2ForCharacter(character)
	-- destroy old NovaGUI if exists for this player (avoid duplicates)
	local old = player.PlayerGui:FindFirstChild("NovaGUI")
	if old then old:Destroy() end

	local gui2 = Instance.new("ScreenGui")
	gui2.Name = "NovaGUI"
	gui2.ResetOnSpawn = false
	gui2.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame", gui2)
	frame.Size = UDim2.new(0,256,0,286)
	frame.Position = UDim2.new(0.5,-130,0.5,-135)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.Active = true; frame.Draggable = true; frame.Visible = false
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,20)
	local stroke = Instance.new("UIStroke", frame); stroke.Thickness = 4; stroke.Color = Color3.fromRGB(211,79,35)

	local icon = Instance.new("ImageButton", gui2)
	icon.Size = UDim2.new(0,75,0,75)
	icon.Position = UDim2.new(0,50,0,300)
	icon.Image = "rbxassetid://71285066607329"
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0,15)
	icon.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

	local function makeLabel(text, pos)
		local lbl = Instance.new("TextLabel", frame)
		lbl.Text = text; lbl.TextScaled = true; lbl.Font = Enum.Font.Arcade
		lbl.Size = UDim2.new(0,200,0,50); lbl.Position = pos
		lbl.TextColor3 = Color3.fromRGB(39,151,211); lbl.BackgroundTransparency = 1
	end
	makeLabel("Nova Hub", UDim2.new(0,40,0,0))
	makeLabel("TT: @novahub57", UDim2.new(0,20,0,30))
	makeLabel("If bag Reset", UDim2.new(0,30,0,50))

	-- generic create button that syncs with BoolValue and stores reference
	local function createButton(pos, boolValue, onChange)
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0,113,0,50)
		btn.Position = pos
		btn.Font = Enum.Font.Arcade
		btn.TextScaled = true
		btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		btn.TextColor3 = Color3.new(0,0,0)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

		-- initial visual via onChange
		onChange(boolValue.Value, btn)
		-- store ref
		gui2Buttons[boolValue.Name] = btn

		btn.MouseButton1Click:Connect(function()
			boolValue.Value = not boolValue.Value
			-- immediate update
			onChange(boolValue.Value, btn)
			-- FastSpeedSteal controls GUI1 visibility
			if boolValue.Name == "FastSpeedSteal" then gui1.Enabled = boolValue.Value end
		end)
		-- update when BoolValue changed externally
		boolValue.Changed:Connect(function(new)
			onChange(new, btn)
			if boolValue.Name == "FastSpeedSteal" then gui1.Enabled = new end
		end)
		return btn
	end

	-- Anchor button (controls hrp.Anchored)
	createButton(UDim2.new(0,10,0,212), buttonStates.Anchor, function(state, btn)
		if hrp then hrp.Anchored = state end
		if state then btn.Text = "Anchor ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else btn.Text = "Anchor OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
	end)

	-- Speed
	createButton(UDim2.new(0,130,0,212), buttonStates.Speed, function(state, btn)
		if state then
			hum.WalkSpeed = (hum and hum.WalkSpeed or 16) + 20
			btn.Text = "Speed ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			-- restore default stored by humanoid on spawn might vary, so set to 16 if missing
			hum.WalkSpeed = hum and hum.WalkSpeed or 16
			btn.Text = "Speed OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Teleport (InstantSteal)
	createButton(UDim2.new(0,10,0,150), buttonStates.Teleport, function(state, btn)
		if state then btn.Text = "InstantSteal ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else btn.Text = "InstantSteal OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
	end)

	-- Noclip
	createButton(UDim2.new(0,130,0,150), buttonStates.Noclip, function(state, btn)
		for _, p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = not state end
		end
		if state then btn.Text = "On Noclip"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else btn.Text = "Off Noclip"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
	end)

	-- ForwardTp
	createButton(UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state, btn)
		btn.Text = state and "Wait For Update" or "WaitForUpdate"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- FastSpeedSteal / NoclipBypass (controls GUI1)
	createButton(UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state, btn)
		btn.Text = "Noclip Byppas"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		gui1.Enabled = state
	end)
end

-- ---- ProximityPrompt hooking ----
-- We'll create one handler and attach it once per prompt, also attach to future prompts
local connectedPrompts = {}
local function connectPrompt(prompt)
	if connectedPrompts[prompt] then return end
	connectedPrompts[prompt] = prompt.Triggered:Connect(function(playerWhoTriggered)
		-- Only run if Teleport bool is ON
		if not buttonStates.Teleport.Value then return end

		-- ensure character's current hrp is valid
		local ch = player.Character
		if not ch then return end
		local hrp = ch:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- find player's plot part
		local function getPlayerPlotTpPart()
			local ok, plotsFolder = pcall(function() return workspace:WaitForChild("Plots") end)
			if not ok or not plotsFolder then return nil end
			for i = 1, 8 do
				local plot = plotsFolder:FindFirstChild("Plot"..i)
				if plot then
					local owner = plot:FindFirstChild("Owner")
					local tp = plot:FindFirstChild("MultiplierPart")
					if owner and owner.Value == player.Name and tp then return tp end
				end
			end
			return nil
		end

		local tpPart = getPlayerPlotTpPart()
		if not tpPart then return end

		-- prepare teleport
		local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
		local teleportTarget = tpPart.Position + offset

		-- update GUI2 teleport button visuals
		local tb = gui2Buttons.Teleport
		if tb then tb.Text = "InstantSteal ON"; tb.BackgroundColor3 = Color3.fromRGB(60,60,60) end

		-- record previous states
		local prevAnchor = buttonStates.Anchor.Value
		local prevNoclip = buttonStates.Noclip.Value

		-- temporarily enable Anchor and Noclip if needed
		if not prevAnchor then
			buttonStates.Anchor.Value = true
			if hrp then hrp.Anchored = true end
			-- also reflect GUI1
			setAnchor(true)
		end
		if not prevNoclip then
			buttonStates.Noclip.Value = true
			for _, p in ipairs(ch:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
			local nb = gui2Buttons.Noclip
			if nb then nb.Text = "On Noclip"; nb.BackgroundColor3 = Color3.fromRGB(60,60,60) end
		end

		-- smooth teleport interpolation
		local progress = 0
		local steps = 30
		local teleporting = true
		-- We'll perform interpolation on RenderStepped (temporary closure)
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			if not teleporting then
				conn:Disconnect()
				return
			end
			progress = progress + dt
			local alpha = math.clamp(progress / (0.05 * steps), 0, 1)
			local newPos = hrp.Position:Lerp(teleportTarget, alpha)
			-- set position; orientation set to camera forward to reduce camera mismatch
			local cam = Workspace.CurrentCamera
			local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
			hrp.CFrame = CFrame.new(newPos, newPos + look)
			if alpha >= 1 then
				teleporting = false
				-- finalize visuals / bools
				if buttonStates.Teleport.Value then buttonStates.Teleport.Value = false end
				if tb then tb.Text = "InstantSteal OFF"; tb.BackgroundColor3 = Color3.fromRGB(150,150,150) end
				-- restore anchor/noclip after short delay
				task.spawn(function()
					task.wait(0.1)
					if not prevAnchor then
						buttonStates.Anchor.Value = false
						if hrp then hrp.Anchored = false end
						setAnchor(false)
						local ab = gui2Buttons.Anchor
						if ab then ab.Text = "Anchor OFF"; ab.BackgroundColor3 = Color3.fromRGB(150,150,150) end
					end
					if not prevNoclip then
						buttonStates.Noclip.Value = false
						for _, p in ipairs(ch:GetDescendants()) do
							if p:IsA("BasePart") then p.CanCollide = true end
						end
						local nb2 = gui2Buttons.Noclip
						if nb2 then nb2.Text = "Off Noclip"; nb2.BackgroundColor3 = Color3.fromRGB(150,150,150) end
					end
				end)
			end
		end)
	end)
end

-- attach to existing prompts and to future ones
for _, d in ipairs(Workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		connectPrompt(d)
	end
end
Workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then connectPrompt(d) end
end)

-- On spawn / respawn: refresh references and build GUI2
local function onCharacterAdded(c)
	char = c
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	targetPos = root.Position
	-- build GUI2 fresh for this character
	buildGui2ForCharacter(char)
end

-- initial setup
if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

-- Heartbeat for Anchor movement (GUI1)
RunService.Heartbeat:Connect(function(dt)
	if anchorEnabled and root and hum then
		local move = hum.MoveDirection
		local hor = Vector3.new(move.X, 0, move.Z) * (storedWalkSpeed or 16) * dt
		local vert = Vector3.new(0, vertControl * flySpeed * dt, 0)
		targetPos = targetPos + hor + vert
		local cam = Workspace.CurrentCamera
		local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)
