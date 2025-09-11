local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local TpPartName = "MultiplierPart"

-- ===== Таблица состояния =====
local State = {
	anchorOnly = false,
	speedMode = false,
	teleportActive = false,
	teleportTarget = nil,
	teleportProgress = 0,
	teleportSteps = 15,
	noclip = false,
	originalSpeed = 16,
	humanoid = nil,
	hrp = nil,
	speedConn = nil,
	btnConnections = {}
}

-- ===== GUI =====
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("AnchoredGUI")
local btn1, btn2, btn3, btn4, btn5, btn6

if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AnchoredGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 256, 0, 286)
	frame.Position = UDim2.new(0.5, -110, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screenGui

	local uiframe = Instance.new("UICorner")
	uiframe.CornerRadius = UDim.new(0, 20)
	uiframe.Parent = frame

	local function createLabel(text, pos)
		local lbl = Instance.new("TextLabel")
		lbl.Parent = frame
		lbl.TextScaled = true
		lbl.Font = Enum.Font.Arcade
		lbl.Text = text
		lbl.Size = UDim2.new(0, 200, 0, 50)
		lbl.Position = pos
		lbl.TextColor3 = Color3.fromRGB(161, 163, 62)
		lbl.BackgroundTransparency = 1
		return lbl
	end

	createLabel("Saint Hub", UDim2.new(0,30,0,0))
	createLabel("TT: @GG67439", UDim2.new(0,30,0,30))

	local function createButton(text, pos)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 113, 0, 50)
		btn.Position = pos
		btn.TextScaled = true
		btn.Font = Enum.Font.Arcade
		btn.BackgroundColor3 = Color3.fromRGB(103,103,103)
		btn.TextColor3 = Color3.new(0,0,0)
		btn.Text = text
		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0,8)
		uic.Parent = btn
		btn.Parent = frame
		return btn
	end

	btn1 = createButton("Anchor OFF", UDim2.new(0,10,0,212))
	btn2 = createButton("Speed OFF", UDim2.new(0,130,0,212))
	btn3 = createButton("Teleport OFF", UDim2.new(0,10,0,150))
	btn4 = createButton("Off Noclip", UDim2.new(0,130,0,150))
	btn5 = createButton("Forward Tp wait While Update", UDim2.new(0,130,0,90))
	btn6 = createButton("Maybe Fast Speed With Steal", UDim2.new(0,10,0,90))
end

-- ===== Функция поиска своей базы =====
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

-- ===== Применение состояний =====
local function applyStates(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	State.hrp = hrp
	State.humanoid = humanoid
	State.originalSpeed = humanoid.WalkSpeed

	hrp.Anchored = State.anchorOnly
	btn1.Text = State.anchorOnly and "Anchor ON" or "Anchor OFF"
	btn1.BackgroundColor3 = State.anchorOnly and Color3.fromRGB(50,50,50) or Color3.fromRGB(103,103,103)

	humanoid.WalkSpeed = State.speedMode and (State.originalSpeed + 50) or State.originalSpeed
	btn2.Text = State.speedMode and "Speed ON" or "Speed OFF"
	btn2.BackgroundColor3 = State.speedMode and Color3.fromRGB(30,30,30) or Color3.fromRGB(103,103,103)

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not State.noclip
		end
	end
	btn4.Text = State.noclip and "On Noclip" or "Off Noclip"
	btn4.BackgroundColor3 = State.noclip and Color3.fromRGB(30,30,30) or Color3.fromRGB(103,103,103)
end

-- ===== Подключение кнопок =====
local function connectButtons(char)
	for _, conn in pairs(State.btnConnections) do
		conn:Disconnect()
	end
	State.btnConnections = {}

	-- Anchor
	table.insert(State.btnConnections, btn1.MouseButton1Click:Connect(function()
		State.anchorOnly = not State.anchorOnly
		if State.hrp then State.hrp.Anchored = State.anchorOnly end
		btn1.Text = State.anchorOnly and "Anchor ON" or "Anchor OFF"
		btn1.BackgroundColor3 = State.anchorOnly and Color3.fromRGB(50,50,50) or Color3.fromRGB(103,103,103)
	end))

	-- Speed
	table.insert(State.btnConnections, btn2.MouseButton1Click:Connect(function()
		State.speedMode = not State.speedMode
		if State.speedConn then State.speedConn:Disconnect() State.speedConn = nil end
		if State.speedMode then
			State.humanoid.WalkSpeed = State.originalSpeed + 50
		else
			State.humanoid.WalkSpeed = State.originalSpeed
		end
		btn2.Text = State.speedMode and "Speed ON" or "Speed OFF"
		btn2.BackgroundColor3 = State.speedMode and Color3.fromRGB(30,30,30) or Color3.fromRGB(103,103,103)
	end))

	-- Teleport
	table.insert(State.btnConnections, btn3.MouseButton1Click:Connect(function()
		State.teleportActive = not State.teleportActive
		btn3.Text = State.teleportActive and "Teleport ON" or "Teleport OFF"
		btn3.BackgroundColor3 = State.teleportActive and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
	end))

	-- Noclip
	table.insert(State.btnConnections, btn4.MouseButton1Click:Connect(function()
		State.noclip = not State.noclip
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not State.noclip
			end
		end
		btn4.Text = State.noclip and "On Noclip" or "Off Noclip"
		btn4.BackgroundColor3 = State.noclip and Color3.fromRGB(30,30,30) or Color3.fromRGB(103,103,103)
	end))

	-- btn5 и btn6 заглушки
	table.insert(State.btnConnections, btn5.MouseButton1Click:Connect(function()
		print("btn5 clicked — логика вперед/телепорт пока не реализована")
	end))
	table.insert(State.btnConnections, btn6.MouseButton1Click:Connect(function()
		print("btn6 clicked — логика Fast Speed пока не реализована")
	end))
end

-- ===== Настройка персонажа =====
local function setupCharacter(char)
	if State.speedConn then
		State.speedConn:Disconnect()
		State.speedConn = nil
	end
	applyStates(char)
	connectButtons(char)
end

-- ===== ProximityPrompt Teleport =====
local function setupProximityTeleport()
	local tpPart = getPlayerPlotTpPart()
	if not tpPart then return end

	local prompt = tpPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Teleport"
		prompt.ObjectText = "Plot"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.Parent = tpPart
	end

	prompt.Triggered:Connect(function(plr)
		if plr ~= player then return end
		if State.teleportActive and State.hrp then
			wait(0.2) -- задержка 0.2 секунды
			State.hrp.CFrame = tpPart.CFrame + Vector3.new(0,3,0)
		end
	end)
end

-- ===== RenderStepped для проверки ProximityPrompt =====
RunService.RenderStepped:Connect(function()
	if State.teleportActive then
		setupProximityTeleport()
	end
end)

-- ===== Подключаем персонаж =====
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)
