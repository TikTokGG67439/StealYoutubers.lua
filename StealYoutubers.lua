-- Unified Anchor + Nova (LocalScript)
-- Поместить как LocalScript в StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- Ensure single run
if script:GetAttribute("Initialized") then return end
script:SetAttribute("Initialized", true)

-- Character refs (будут обновляться)
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- CONFIG / STATE
local flySpeed = 20
local vertControl = 0
local targetPos = root.Position
local toggleKey, tpKey = Enum.KeyCode.F, Enum.KeyCode.T

-- ButtonStates
local function getOrCreateButtonStates()
	local states = player:FindFirstChild("ButtonStates")
	if not states then
		states = Instance.new("Folder")
		states.Name = "ButtonStates"
		states.Parent = player
		local names = {"Anchor","Speed","Teleport","Noclip","ForwardTp","FastSpeedSteal"}
		for _, n in ipairs(names) do
			local bv = Instance.new("BoolValue")
			bv.Name = n
			bv.Value = false
			bv.Parent = states
		end
	end
	return states
end
local buttonStates = getOrCreateButtonStates()

-- ---------------- GUI1 (Anchor) ----------------
local gui1 = Instance.new("ScreenGui")
gui1.Name = "AnchorGUI_v1"
gui1.ResetOnSpawn = false
gui1.Parent = player:WaitForChild("PlayerGui")

local function makeBtn(parent, name, pos, size, txt)
	local b = Instance.new("TextButton", parent)
	b.Name = name
	b.Size = size
	b.Position = pos
	b.Text = txt
	b.BackgroundColor3 = Color3.fromRGB(28,28,28)
	b.BackgroundTransparency = 0.15
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.ArialBold
	b.TextScaled = true
	return b
end

local mainBtn = makeBtn(gui1, "AnchorBtn", UDim2.new(0,16,0,16), UDim2.new(0,180,0,42), "Anchor: OFF")
local upBtn = makeBtn(gui1, "UpBtn", UDim2.new(0,200,0,16), UDim2.new(0,40,0,42), "▲"); upBtn.Visible = false
local downBtn = makeBtn(gui1, "DownBtn", UDim2.new(0,245,0,16), UDim2.new(0,40,0,42), "▼"); downBtn.Visible = false
local tpBtn = makeBtn(gui1, "TpBtn", UDim2.new(0,290,0,16), UDim2.new(0,60,0,42), "Tp"); tpBtn.Visible = false

local toggleBox = Instance.new("TextBox", gui1)
toggleBox.Size = UDim2.new(0,60,0,20); toggleBox.Position = UDim2.new(0,16,0,60); toggleBox.Text = "F"
toggleBox.Font = Enum.Font.Arial; toggleBox.TextScaled = true

local tpBox = Instance.new("TextBox", gui1)
tpBox.Size = UDim2.new(0,60,0,20); tpBox.Position = UDim2.new(0,80,0,60); tpBox.Text = "T"
tpBox.Font = Enum.Font.Arial; tpBox.TextScaled = true

-- UICorners
local function addCorner(inst)
	local c = Instance.new("UICorner", inst)
	c.CornerRadius = UDim.new(0,10)
end
addCorner(mainBtn); addCorner(upBtn); addCorner(downBtn); addCorner(tpBtn)
addCorner(toggleBox); addCorner(tpBox)

-- Key parsing
toggleBox.FocusLost:Connect(function()
	local key = (toggleBox.Text or ""):upper()
	if Enum.KeyCode[key] then toggleKey = Enum.KeyCode[key] end
end)
tpBox.FocusLost:Connect(function()
	local key = (tpBox.Text or ""):upper()
	if Enum.KeyCode[key] then tpKey = Enum.KeyCode[key] end
end)

-- Button actions
mainBtn.MouseButton1Click:Connect(function()
	buttonStates.Anchor.Value = not buttonStates.Anchor.Value
end)

tpBtn.MouseButton1Click:Connect(function()
	if buttonStates.Anchor.Value and root and Workspace.CurrentCamera then
		local look = Workspace.CurrentCamera.CFrame.LookVector
		targetPos = targetPos + look * 7
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)

upBtn.MouseButton1Down:Connect(function() vertControl = 1 end)
upBtn.MouseButton1Up:Connect(function() vertControl = 0 end)
downBtn.MouseButton1Down:Connect(function() vertControl = -1 end)
downBtn.MouseButton1Up:Connect(function() vertControl = 0 end)

-- Sync GUI1 with Anchor state
buttonStates.Anchor.Changed:Connect(function(val)
	if val then
		mainBtn.Text = "Anchor: ON"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = true, true, true
		if root then targetPos = root.Position end
	else
		mainBtn.Text = "Anchor: OFF"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = false, false, false
		vertControl = 0
	end
end)
mainBtn.Text = buttonStates.Anchor.Value and "Anchor: ON" or "Anchor: OFF"
upBtn.Visible, downBtn.Visible, tpBtn.Visible = buttonStates.Anchor.Value, buttonStates.Anchor.Value, buttonStates.Anchor.Value

-- GUI1 visibility controlled by FastSpeedSteal
buttonStates.FastSpeedSteal.Changed:Connect(function(val)
	gui1.Enabled = val
end)
gui1.Enabled = buttonStates.FastSpeedSteal.Value

-- Input controls
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == toggleKey then
		buttonStates.Anchor.Value = not buttonStates.Anchor.Value
	elseif input.KeyCode == tpKey and buttonStates.Anchor.Value then
		if root and Workspace.CurrentCamera then
			local look = Workspace.CurrentCamera.CFrame.LookVector
			targetPos = targetPos + look * 7
			root.CFrame = CFrame.new(targetPos, targetPos + look)
		end
	elseif input.KeyCode == Enum.KeyCode.Space and buttonStates.Anchor.Value then
		vertControl = 1
	elseif input.KeyCode == Enum.KeyCode.LeftShift and buttonStates.Anchor.Value then
		vertControl = -1
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then
		vertControl = 0
	end
end)

-- Heartbeat loop
RunService.Heartbeat:Connect(function(dt)
	if buttonStates.Anchor.Value and root and hum then
		local move = hum.MoveDirection
		local hor = Vector3.new(move.X,0,move.Z) * hum.WalkSpeed * dt
		local vert = Vector3.new(0, vertControl * flySpeed * dt, 0)
		targetPos = targetPos + hor + vert
		local camLook = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0,0,-1)
		root.CFrame = CFrame.new(targetPos, targetPos + camLook)
	end
end)

-- ---------------- GUI2 (Nova) ----------------
local function createNovaGUI(character)
	local existing = player.PlayerGui:FindFirstChild("NovaGUI_v2")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NovaGUI_v2"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0,256,0,286)
	frame.Position = UDim2.new(0.5,-130,0.5,-135)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.Active = true
	frame.Draggable = true
	frame.Visible = false
	local uiframe = Instance.new("UICorner", frame); uiframe.CornerRadius = UDim.new(0,20)
	local uiStroke = Instance.new("UIStroke", frame); uiStroke.Thickness = 4; uiStroke.Color = Color3.fromRGB(211,79,35)

	local icon = Instance.new("ImageButton", screenGui)
	icon.Size = UDim2.new(0,75,0,75)
	icon.Position = UDim2.new(0,200,0,200)
	icon.Image = "rbxassetid://71285066607329"
	icon.Draggable = true
	local uic = Instance.new("UICorner", icon); uic.CornerRadius = UDim.new(0,15)
	icon.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

	local function makeLabel(text,pos)
		local lbl = Instance.new("TextLabel", frame)
		lbl.Text = text; lbl.TextScaled = true; lbl.Font = Enum.Font.Arcade
		lbl.Size = UDim2.new(0,200,0,50); lbl.Position = pos
		lbl.TextColor3 = Color3.fromRGB(39,151,211); lbl.BackgroundTransparency = 1
	end
	makeLabel("Nova Hub", UDim2.new(0,40,0,0))
	makeLabel("TT: @novahub57", UDim2.new(0,20,0,30))
	makeLabel("If bag Reset", UDim2.new(0,30,0,50))

	local buttonsMap = {}
	local function createButton(name,pos,bv,onChange)
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0,113,0,50); btn.Position = pos
		btn.TextScaled = true; btn.Font = Enum.Font.Arcade
		btn.BackgroundColor3 = Color3.fromRGB(150,150,150); btn.TextColor3 = Color3.new(0,0,0)
		local uc = Instance.new("UICorner", btn); uc.CornerRadius = UDim.new(0,8)
		onChange(bv.Value, btn)
		buttonsMap[bv.Name] = btn
		btn.MouseButton1Click:Connect(function() bv.Value = not bv.Value end)
		bv.Changed:Connect(function(new) onChange(new, btn) end)
		return btn
	end

	-- Anchor
	createButton("AnchorBtn_Nova", UDim2.new(0,10,0,212), buttonStates.Anchor, function(state, btn)
		btn.Text = state and "Anchor ON" or "Anchor OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		mainBtn.Text = state and "Anchor: ON" or "Anchor: OFF"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = state, state, state
		if root then root.Anchored = state end
	end)

	-- Speed
	createButton("SpeedBtn_Nova", UDim2.new(0,130,0,212), buttonStates.Speed, function(state, btn)
		btn.Text = state and "Speed ON" or "Speed OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		if hum then
			if state then hum.WalkSpeed = hum.WalkSpeed + 20 end
			if not state then hum.WalkSpeed = 16 end
		end
	end)

	-- InstantSteal
	createButton("TeleportBtn_Nova", UDim2.new(0,10,0,150), buttonStates.Teleport, function(state, btn)
		btn.Text = state and "InstantSteal ON" or "InstantSteal OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- Noclip
	createButton("NoclipBtn_Nova", UDim2.new(0,130,0,150), buttonStates.Noclip, function(state, btn)
		btn.Text = state and "On Noclip" or "Off Noclip"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = not state end
		end
	end)

	-- Forward Tp
	createButton("ForwardTpBtn", UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state, btn)
		btn.Text = state and "Wait For Update" or "WaitForUpdate"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- FastSpeedSteal
	createButton("FastSpeedBtn", UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state, btn)
		btn.Text = state and "Wait For Update" or "Wait for update"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		gui1.Enabled = state
	end)

	-- Teleport interpolation
	local teleportInProgress = false
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportDuration = 0.05 * 30

	RunService.RenderStepped:Connect(function(delta)
		if teleportInProgress and teleportTarget and root then
			teleportProgress = teleportProgress + delta
			local alpha = math.clamp(teleportProgress / teleportDuration, 0, 1)
			root.CFrame = CFrame.new(root.Position:Lerp(teleportTarget, alpha))
			if alpha >= 1 then
				teleportInProgress = false
				teleportTarget = nil
				teleportProgress = 0
				local tb = buttonsMap["Teleport"]
				if tb then
					tb.Text = buttonStates.Teleport.Value and "InstantSteal ON" or "InstantSteal OFF"
					tb.BackgroundColor3 = buttonStates.Teleport.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
				end
			end
		end
	end)

	-- Helper: get player's MultiplierPart
	local function getPlayerPlotTpPart()
		local ok, plots = pcall(function() return workspace:WaitForChild("Plots") end)
		if not ok or not plots then return nil end
		for i = 1, 8 do
			local plot = plots:FindFirstChild("Plot"..i)
			if plot then
				local owner = plot:FindFirstChild("Owner")
				local tpPart = plot:FindFirstChild("MultiplierPart")
				if owner and owner.Value == player.Name and tpPart then return tpPart end
			end
		end
		return nil
	end

	-- ProximityPrompt handling (InstantSteal)
	-- ProximityPrompt handling (InstantSteal)
	local function setupInstantStealPrompts()
		-- Получаем все существующие ProximityPrompt в Workspace
		for _, prompt in ipairs(workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") then
				-- Подключаем один раз
				if not prompt:GetAttribute("InstantStealConnected") then
					prompt:SetAttribute("InstantStealConnected", true)

					prompt.Triggered:Connect(function(triggeringPlayer)
						if triggeringPlayer ~= player then return end
						-- Проверяем, включен ли Teleport
						if not buttonStates.Teleport.Value then return end

						-- Находим цель телепорта
						local tpPart = nil
						for i = 1, 8 do
							local plot = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Plot"..i)
							if plot then
								local owner = plot:FindFirstChild("Owner")
								local mp = plot:FindFirstChild("MultiplierPart")
								if owner and mp and owner.Value == player.Name then
									tpPart = mp
									break
								end
							end
						end
						if not tpPart then return end

						local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
						local teleportTarget = tpPart.Position + offset

						-- Обновляем кнопку InstantSteal
						local tb = buttonsMap["Teleport"]
						if tb then
							tb.Text = "InstantSteal (in progress)"
							tb.BackgroundColor3 = Color3.fromRGB(255,200,0)
						end

						-- Сохраняем состояние Anchor/Noclip
						local anchorWasOn = buttonStates.Anchor.Value
						local noclipWasOn = buttonStates.Noclip.Value
						local partsState = {}
						for _, p in ipairs(char:GetDescendants()) do
							if p:IsA("BasePart") then partsState[p] = p.CanCollide end
						end

						-- Временно включаем Anchor/Noclip
						if not anchorWasOn then
							root.Anchored = true
							buttonStates.Anchor.Value = true
							local abtn = buttonsMap["Anchor"]
							if abtn then abtn.Text = "Anchor ON"; abtn.BackgroundColor3 = Color3.fromRGB(60,60,60) end
						end
						if not noclipWasOn then
							for p,_ in pairs(partsState) do p.CanCollide = false end
							buttonStates.Noclip.Value = true
							local nbtn = buttonsMap["Noclip"]
							if nbtn then nbtn.Text = "On Noclip"; nbtn.BackgroundColor3 = Color3.fromRGB(60,60,60) end
						end

						-- Плавный телепорт
						task.spawn(function()
							local duration = 0.5
							local elapsed = 0
							while elapsed < duration do
								local dt = RunService.RenderStepped:Wait()
								elapsed = elapsed + dt
								local alpha = math.clamp(elapsed / duration, 0, 1)
								root.CFrame = CFrame.new(root.Position:Lerp(teleportTarget, alpha))
							end

							-- Завершаем InstantSteal
							if tb then
								tb.Text = "InstantSteal OFF"
								tb.BackgroundColor3 = Color3.fromRGB(150,150,150)
							end

							task.wait(5)

							-- Восстанавливаем Anchor/Noclip
							if root and not anchorWasOn then
								root.Anchored = false
								buttonStates.Anchor.Value = false
								local abtn = buttonsMap["Anchor"]
								if abtn then abtn.Text = "Anchor OFF"; abtn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
							end
							if not noclipWasOn then
								for p,v in pairs(partsState) do
									if p and p.Parent then p.CanCollide = v end
								end
								buttonStates.Noclip.Value = false
								local nbtn = buttonsMap["Noclip"]
								if nbtn then nbtn.Text = "Off Noclip"; nbtn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
							end
						end)
					end)
				end
			end
		end
	end

	-- Запускаем
	setupInstantStealPrompts()

	-- Авто-обновление при появлении новых промптов
	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then
			setupInstantStealPrompts()
		end
	end)

end

-- Setup Nova GUI for current character
createNovaGUI(char)

-- On character respawn
player.CharacterAdded:Connect(function(c)
	char = c
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	targetPos = root.Position

	if buttonStates.Anchor.Value then
		root.Anchored = true
	else
		root.Anchored = false
	end

	createNovaGUI(char)
end)

