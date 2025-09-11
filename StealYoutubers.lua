local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local TpPartName = "MultiplierPart"

-- Папка для хранения состояний кнопок
local function getOrCreateButtonStates()
	local states = player:FindFirstChild("ButtonStates")
	if not states then
		states = Instance.new("Folder")
		states.Name = "ButtonStates"
		states.Parent = player

		local anchorBV = Instance.new("BoolValue")
		anchorBV.Name = "Anchor"
		anchorBV.Value = false
		anchorBV.Parent = states

		local speedBV = Instance.new("BoolValue")
		speedBV.Name = "Speed"
		speedBV.Value = false
		speedBV.Parent = states

		local teleportBV = Instance.new("BoolValue")
		teleportBV.Name = "Teleport"
		teleportBV.Value = false
		teleportBV.Parent = states

		local noclipBV = Instance.new("BoolValue")
		noclipBV.Name = "Noclip"
		noclipBV.Value = false
		noclipBV.Parent = states

		-- Кнопки 5 и 6
		local forwardTpBV = Instance.new("BoolValue")
		forwardTpBV.Name = "ForwardTp"
		forwardTpBV.Value = false
		forwardTpBV.Parent = states

		local fastSpeedBV = Instance.new("BoolValue")
		fastSpeedBV.Name = "FastSpeedSteal"
		fastSpeedBV.Value = false
		fastSpeedBV.Parent = states
	end
	return states
end

local buttonStates = getOrCreateButtonStates()

-- Функция поиска своей базы
local function getPlayerPlotTpPart()
	local plotsFolder = workspace:WaitForChild("Plots")
	for i = 1, 8 do
		local plot = plotsFolder:FindFirstChild("Plot"..i)
		if plot then
			local ownerValue = plot:FindFirstChild("Owner")
			local tpPart = plot:FindFirstChild(TpPartName)
			if ownerValue and ownerValue.Value == player.Name and tpPart then
				return tpPart
			end
		end
	end
	return nil
end

local function setupCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	local originalSpeed = humanoid.WalkSpeed

	-- Состояния кнопок
	local anchorOnly = buttonStates.Anchor.Value
	local speedMode = buttonStates.Speed.Value
	local teleportActive = buttonStates.Teleport.Value
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportSteps = 15

	local gravityActive = speedMode

	-- GUI
	local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	screenGui.Name = "AnchoredGUI"

	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 256, 0, 286)
	frame.Position = UDim2.new(0.5, -110, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.Active = true
	frame.Draggable = true

	local textLabel1 = Instance.new("TextLabel")
	textLabel1.Parent = frame
	textLabel1.TextScaled = true
	textLabel1.Font = Enum.Font.Arcade
	textLabel1.Text = "Saint Hub"
	textLabel1.Size = UDim2.new(0, 200, 0, 50)
	textLabel1.Position = UDim2.new(0, 30, 0, 0)
	textLabel1.TextColor3 = Color3.fromRGB(161, 163, 62)
	textLabel1.BackgroundTransparency = 1

	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Parent = frame
	textLabel2.TextScaled = true
	textLabel2.Font = Enum.Font.Arcade
	textLabel2.Text = "TT: @GG67439"
	textLabel2.Size = UDim2.new(0, 200, 0, 50)
	textLabel2.Position = UDim2.new(0, 30, 0, 30)
	textLabel2.TextColor3 = Color3.fromRGB(161, 163, 62)
	textLabel2.BackgroundTransparency = 1

	local uiframe = Instance.new("UICorner")
	uiframe.CornerRadius = UDim.new(0, 20)
	uiframe.Parent = frame

	-- Функция создания кнопки
	local function createButton(text, pos, bv, callback)
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0, 113, 0, 50)
		btn.Position = pos
		btn.TextScaled = true
		btn.Font = Enum.Font.Arcade
		btn.BackgroundColor3 = Color3.fromRGB(103, 103, 103)
		btn.TextColor3 = Color3.new(0, 0, 0)
		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0, 8)
		uic.Parent = btn

		-- Восстанавливаем текст/цвет по состоянию
		if bv.Value then
			callback(true, btn)
		else
			callback(false, btn)
		end

		btn.MouseButton1Click:Connect(function()
			bv.Value = not bv.Value
			callback(bv.Value, btn)
		end)
		return btn
	end

	-- Anchor
	createButton("Anchor OFF", UDim2.new(0,10,0,212), buttonStates.Anchor, function(state, btn)
		anchorOnly = state
		hrp.Anchored = state
		if state then
			btn.Text = "Anchor ON"
			btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
		else
			btn.Text = "Anchor OFF"
			btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)

	-- Speed
	createButton("Speed OFF", UDim2.new(0,130,0,212), buttonStates.Speed, function(state, btn)
		speedMode = state
		humanoid.WalkSpeed = state and originalSpeed + 20 or originalSpeed
		gravityActive = state
		if state then
			btn.Text = "Speed ON"
			btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		else
			btn.Text = "Speed OFF"
			btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)

	-- Teleport
	createButton("Teleport OFF", UDim2.new(0,10,0,150), buttonStates.Teleport, function(state, btn)
		teleportActive = state
		if not state then
			teleportTarget = nil
			teleportProgress = 0
			btn.Text = "Teleport OFF"
			btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		else
			btn.Text = "Teleport ON"
			btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		end
	end)

	-- Noclip
	createButton("On Noclip", UDim2.new(0,130,0,150), buttonStates.Noclip, function(state, btn)
		local char = player.Character
		if not char then return end
		local hpr = char:FindFirstChild("HumanoidRootPart")
		if not hpr then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not state
			end
		end
		if state then
			btn.Text = "On Noclip"
			btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		else
			btn.Text = "Off Noclip"
			btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)

	-- Кнопки 5 и 6 можно аналогично добавить сюда, сохраняя состояния
	-- Forward Tp wait While Update
	createButton("Forward Tp wait While Update", UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state, btn)
		if state then
			btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		else
			btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)

	-- Maybe Fast Speed With Steal
	createButton("Maybe Fast Speed With Steal", UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state, btn)
		if state then
			btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		else
			btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)

	-- RenderStepped для плавного телепорта
	RunService.RenderStepped:Connect(function(delta)
		if teleportActive and teleportTarget then
			teleportProgress = teleportProgress + delta
			local alpha = math.clamp(teleportProgress / (0.05 * teleportSteps), 0, 1)
			hrp.CFrame = CFrame.new(hrp.Position:Lerp(teleportTarget, alpha))
			if alpha >= 1 then
				teleportActive = false
				teleportTarget = nil
				teleportProgress = 0
				buttonStates.Teleport.Value = false
			end
		end
	end)

	-- ProximityPrompt
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				if teleportActive then
					teleportProgress = 0
					local tpPart = getPlayerPlotTpPart()
					if tpPart then
						local offset = Vector3.new(math.random(-3,3),3,math.random(-3,3))
						teleportTarget = tpPart.Position + offset
					else
						teleportActive = false
						buttonStates.Teleport.Value = false
					end
				end
			end)
		end
	end
end

if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

