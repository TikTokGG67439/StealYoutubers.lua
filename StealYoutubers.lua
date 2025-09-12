-- Unified Anchor + Nova (LocalScript)
-- Поместить как LocalScript в StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- Ensure single run (в случае двойного старта)
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

-- ButtonStates (создаёт/возвращает Folder с BoolValues)
local function getOrCreateButtonStates()
	local states = player:FindFirstChild("ButtonStates")
	if not states then
		states = Instance.new("Folder")
		states.Name = "ButtonStates"
		states.Parent = player
		local names = {"Anchor","Speed","Teleport","Noclip","ForwardTp","FastSpeedSteal"}
		for _,n in ipairs(names) do
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
-- Я максимально сохранил исходный makeBtn/позиции/стиль
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

-- UICorners (немного стиля)
local function addCorner(inst)
	local c = Instance.new("UICorner", inst)
	c.CornerRadius = UDim.new(0,10)
end
addCorner(mainBtn); addCorner(upBtn); addCorner(downBtn); addCorner(tpBtn); addCorner(toggleBox); addCorner(tpBox)

-- parse key boxes
toggleBox.FocusLost:Connect(function()
	local key = (toggleBox.Text or ""):upper()
	if Enum.KeyCode[key] then toggleKey = Enum.KeyCode[key] end
end)
tpBox.FocusLost:Connect(function()
	local key = (tpBox.Text or ""):upper()
	if Enum.KeyCode[key] then tpKey = Enum.KeyCode[key] end
end)

-- При клике на mainBtn меняем общую BoolValue Anchor (источник истины)
mainBtn.MouseButton1Click:Connect(function()
	buttonStates.Anchor.Value = not buttonStates.Anchor.Value
end)
-- tpBtn: быстрый телепорт вперёд при включенном Anchor (меняем позицию root напрямую)
tpBtn.MouseButton1Click:Connect(function()
	if buttonStates.Anchor.Value and root and Workspace.CurrentCamera then
		local look = Workspace.CurrentCamera.CFrame.LookVector
		targetPos = targetPos + look * 7
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)
-- up / down controls
upBtn.MouseButton1Down:Connect(function() vertControl = 1 end)
upBtn.MouseButton1Up:Connect(function() vertControl = 0 end)
downBtn.MouseButton1Down:Connect(function() vertControl = -1 end)
downBtn.MouseButton1Up:Connect(function() vertControl = 0 end)

-- Синхронизация GUI1 с buttonStates.Anchor (истинное состояние)
buttonStates.Anchor.Changed:Connect(function(val)
	if val then
		mainBtn.Text = "Anchor: ON"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = true, true, true
		-- поставить targetPos на текущую позицию, чтобы не было скачков
		if root then targetPos = root.Position end
	else
		mainBtn.Text = "Anchor: OFF"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = false, false, false
		vertControl = 0
	end
end)
-- и сразу установить начальное значение
mainBtn.Text = buttonStates.Anchor.Value and "Anchor: ON" or "Anchor: OFF"
upBtn.Visible, downBtn.Visible, tpBtn.Visible = buttonStates.Anchor.Value, buttonStates.Anchor.Value, buttonStates.Anchor.Value

-- GUI1 включается/выключается кнопкой FastSpeedSteal
buttonStates.FastSpeedSteal.Changed:Connect(function(val)
	gui1.Enabled = val
end)
gui1.Enabled = buttonStates.FastSpeedSteal.Value

-- Input (F/T/Space/Shift) для Anchor
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

-- Heartbeat: перемещение при Anchor
RunService.Heartbeat:Connect(function(dt)
	if buttonStates.Anchor.Value and root and hum then
		local move = hum.MoveDirection
		-- если Speed включена, можно учитывать её эффект где нужно; здесь используем hum.WalkSpeed
		local hor = Vector3.new(move.X,0,move.Z) * hum.WalkSpeed * dt
		local vert = Vector3.new(0, vertControl * flySpeed * dt, 0)
		targetPos = targetPos + hor + vert
		local camLook = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0,0,-1)
		root.CFrame = CFrame.new(targetPos, targetPos + camLook)
	end
end)

-- ---------------- GUI2 (Nova) ----------------
-- Уникальное имя, чтобы не создавать дубликатов при респавне
local function createNovaGUI(character)
	-- Удалим старый Nova GUI, если он есть (при респавне)
	local existing = player:FindFirstChildOfClass("PlayerGui") and player.PlayerGui:FindFirstChild("NovaGUI_v2")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NovaGUI_v2"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

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
	icon.Position = UDim2.new(0,50,0,300)
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

	local buttonsMap = {} -- map name->button instance so we can change text/colors manually

	local function createButton(name, pos, bv, onChange)
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0,113,0,50)
		btn.Position = pos
		btn.TextScaled = true
		btn.Font = Enum.Font.Arcade
		btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		btn.TextColor3 = Color3.new(0,0,0)
		local uc = Instance.new("UICorner", btn); uc.CornerRadius = UDim.new(0,8)

		-- init appearance by calling onChange with current value
		onChange(bv.Value, btn)
		buttonsMap[bv.Name] = btn

		btn.MouseButton1Click:Connect(function()
			bv.Value = not bv.Value
			-- onChange handled via bv.Changed listener below, so no need to call onChange here
		end)

		-- Keep UI in sync even if BoolValue changed elsewhere
		bv.Changed:Connect(function(new)
			onChange(new, btn)
		end)
		return btn
	end

	-- Anchor button in Nova: toggles buttonStates.Anchor (and via Changed will set hrp.Anchored etc.)
	createButton("AnchorBtn_Nova", UDim2.new(0,10,0,212), buttonStates.Anchor, function(state, btn)
		btn.Text = state and "Anchor ON" or "Anchor OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		-- sync GUI1 mainBtn text too
		mainBtn.Text = state and "Anchor: ON" or "Anchor: OFF"
		upBtn.Visible, downBtn.Visible, tpBtn.Visible = state, state, state
		-- ensure actual root.Anchored matches
		if root then root.Anchored = state end
	end)

	-- Speed button
	createButton("SpeedBtn_Nova", UDim2.new(0,130,0,212), buttonStates.Speed, function(state, btn)
		btn.Text = state and "Speed ON" or "Speed OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		if hum then
			if state then hum.WalkSpeed = hum.WalkSpeed + 20 end
			-- When turning off: we don't know original base if user toggled multiple times; to be safe, reset to 16 if turning off
			if not state then hum.WalkSpeed = 16 end
		end
	end)

	-- Teleport / InstantSteal button (controls BoolValue only)
	createButton("TeleportBtn_Nova", UDim2.new(0,10,0,150), buttonStates.Teleport, function(state, btn)
		btn.Text = state and "InstantSteal ON" or "InstantSteal OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- Noclip button
	createButton("NoclipBtn_Nova", UDim2.new(0,130,0,150), buttonStates.Noclip, function(state, btn)
		btn.Text = state and "On Noclip" or "Off Noclip"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		-- apply to current character parts
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not state
			end
		end
	end)

	-- Forward Tp
	createButton("ForwardTpBtn", UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state, btn)
		btn.Text = state and "Wait For Update" or "WaitForUpdate"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- FastSpeedSteal -> controls GUI1 visibility
	createButton("FastSpeedBtn", UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state, btn)
		btn.Text = state and "Wait For Update" or "Wait for update"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
		gui1.Enabled = state
	end)

	-- TELEPORT INTERPOLATION STATE
	local teleportInProgress = false
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportDuration = 0.05 * 30 -- as before

	-- Smooth interpolation loop (RenderStepped)
	RunService.RenderStepped:Connect(function(delta)
		if teleportInProgress and teleportTarget and root then
			teleportProgress = teleportProgress + delta
			local alpha = math.clamp(teleportProgress / teleportDuration, 0, 1)
			root.CFrame = CFrame.new(root.Position:Lerp(teleportTarget, alpha))
			if alpha >= 1 then
				teleportInProgress = false
				teleportTarget = nil
				teleportProgress = 0
				-- restore teleport button visuals to match BoolValue
				local tb = buttonsMap["Teleport"]
				if tb then
					tb.Text = buttonStates.Teleport.Value and "InstantSteal ON" or "InstantSteal OFF"
					tb.BackgroundColor3 = buttonStates.Teleport.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
				end
			end
		end
	end)

	-- Helper to find player's own MultiplierPart in Plots
	local function getPlayerPlotTpPart()
		local ok, plots = pcall(function() return workspace:WaitForChild("Plots") end)
		if not ok or not plots then return nil end
		for i = 1, 8 do
			local plot = plots:FindFirstChild("Plot"..i)
			if plot then
				local owner = plot:FindFirstChild("Owner")
				local tpPart = plot:FindFirstChild("MultiplierPart")
				if owner and owner.Value == player.Name and tpPart then
					return tpPart
				end
			end
		end
		return nil
	end

	-- ProximityPrompt: срабатывает ТОЛЬКО если кнопка InstantSteal включена (BoolValue == true)
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function(triggeringPlayer)
				if triggeringPlayer ~= player then return end
				if not buttonStates.Teleport.Value then return end

				local tpPart = getPlayerPlotTpPart()
				if not tpPart then return end

				-- предотвращаем повторное срабатывание
				if teleportInProgress then return end
				teleportInProgress = true

				local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
				teleportTarget = tpPart.Position + offset

				-- GUI: кнопка в процессе
				local tb = buttonsMap["Teleport"]
				if tb then
					tb.Text = "InstantSteal (in progress)"
					tb.BackgroundColor3 = Color3.fromRGB(255,200,0)
				end

				-- Сохраняем исходное состояние Anchor/Noclip
				local anchorWasOn = buttonStates.Anchor.Value
				local noclipWasOn = buttonStates.Noclip.Value

				-- Сохраняем исходное состояние CanCollide всех частей
				local partsState = {}
				for _, p in ipairs(character:GetDescendants()) do
					if p:IsA("BasePart") then
						partsState[p] = p.CanCollide
					end
				end

				-- Временно включаем Anchor/Noclip, если они выключены
				if not anchorWasOn and root then
					root.Anchored = true
					local abtn = buttonsMap["Anchor"]
					if abtn then
						abtn.Text = "Anchor ON"
						abtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
					end
				end

				if not noclipWasOn then
					for p, _ in pairs(partsState) do
						p.CanCollide = false
					end
					local nbtn = buttonsMap["Noclip"]
					if nbtn then
						nbtn.Text = "On Noclip"
						nbtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
					end
				end

				-- Телепорт с плавной анимацией
				task.spawn(function()
					local duration = 0.5
					local elapsed = 0
					while elapsed < duration do
						local dt = RunService.RenderStepped:Wait()
						elapsed = elapsed + dt
						local alpha = math.clamp(elapsed / duration, 0, 1)
						root.CFrame = CFrame.new(root.Position:Lerp(teleportTarget, alpha))
					end

					task.wait(0.5) -- небольшая пауза после телепорта

					-- Синхронизация Anchor с текущим BoolValue
					if root then
						root.Anchored = buttonStates.Anchor.Value
						local abtn = buttonsMap["Anchor"]
						if abtn then
							abtn.Text = buttonStates.Anchor.Value and "Anchor ON" or "Anchor OFF"
							abtn.BackgroundColor3 = buttonStates.Anchor.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
						end
					end

					-- Синхронизация CanCollide с текущим BoolValue Noclip
					for p, _ in pairs(partsState) do
						if p and p.Parent then
							p.CanCollide = not buttonStates.Noclip.Value
						end
					end
					local nbtn = buttonsMap["Noclip"]
					if nbtn then
						nbtn.Text = buttonStates.Noclip.Value and "On Noclip" or "Off Noclip"
						nbtn.BackgroundColor3 = buttonStates.Noclip.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
					end

					-- Восстанавливаем кнопку Teleport
					if tb then
						tb.Text = buttonStates.Teleport.Value and "InstantSteal ON" or "InstantSteal OFF"
						tb.BackgroundColor3 = buttonStates.Teleport.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
					end

					teleportInProgress = false
				end)
			end)
		end
	end
end

-- Setup Nova GUI for current character
local novaGui, novaFrame, novaButtons = createNovaGUI(char)

-- On character respawn: refresh references and re-create Nova GUI
player.CharacterAdded:Connect(function(c)
	char = c
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	targetPos = root.Position

	-- Ensure hrp.Anchored follows buttonStates.Anchor on respawn
	if buttonStates.Anchor.Value then
		root.Anchored = true
	else
		root.Anchored = false
	end

	-- re-create Nova GUI bound to new character instance (so Noclip toggles correct parts)
	createNovaGUI(char)
end)

-- Final note:
-- 1) InstantSteal работает ТОЛЬКО если buttonStates.Teleport.Value == true
-- 2) ProximityPrompt не меняет BoolValue Teleport (теперь пользователь сам включает/выключает)
-- 3) Во время телепорта Anchor/Noclip применяются временно физически, но не записываются в BoolValues,
--    чтобы не ломать GUI/saved state. После телепорта всё восстанавливается.
-- 4) GUI1 показывается/скрывается кнопкой FastSpeedSteal (Wait While Update).

print("Unified Anchor+Nova script loaded.")
