local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local TpPartName = "MultiplierPart"

-- ===== Таблица состояния =====
local State = {
	anchorOnly = false,
	speedMode = false,
	gravityActive = false,
	teleportActive = false,
	teleportTarget = nil,
	teleportProgress = 0,
	teleportSteps = 15,
	noclip = false,
	originalSpeed = 16,
	humanoid = nil,
	hrp = nil
}

-- ===== GUI (создаём один раз) =====
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("AnchoredGUI")
local btn1, btn2, btn3, btn4, btn5, btn6

if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AnchoredGUI"
	screenGui.ResetOnSpawn = false -- 🔑 сохраняем GUI
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
	btn4 = createButton("On Noclip", UDim2.new(0,130,0,150))
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

-- ===== Настройка персонажа =====
local function setupCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	State.hrp = hrp
	State.humanoid = humanoid
	State.originalSpeed = humanoid.WalkSpeed

	-- Применяем сохранённые состояния
	hrp.Anchored = State.anchorOnly
	humanoid.WalkSpeed = State.speedMode and State.originalSpeed + 20 or State.originalSpeed
	if State.noclip then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end

	-- ===== Anchor =====
	btn1.MouseButton1Click:Connect(function()
		State.anchorOnly = not State.anchorOnly
		hrp.Anchored = State.anchorOnly
		if State.anchorOnly then
			btn1.Text = "Anchor ON"
			btn1.BackgroundColor3 = Color3.fromRGB(50,50,50)
		else
			btn1.Text = "Anchor OFF"
			btn1.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)

	-- ===== Speed =====
	btn2.MouseButton1Click:Connect(function()
		State.speedMode = not State.speedMode
		if State.speedMode then
			btn2.Text = "Speed ON"
			btn2.BackgroundColor3 = Color3.fromRGB(30,30,30)
			humanoid.WalkSpeed = State.originalSpeed + 20
		else
			btn2.Text = "Speed OFF"
			btn2.BackgroundColor3 = Color3.fromRGB(103,103,103)
			humanoid.WalkSpeed = State.originalSpeed
		end
	end)

	-- ===== Teleport =====
	btn3.MouseButton1Click:Connect(function()
		State.teleportActive = not State.teleportActive
		if not State.teleportActive then
			State.teleportTarget = nil
			State.teleportProgress = 0
			btn3.Text = "Teleport OFF"
			btn3.BackgroundColor3 = Color3.fromRGB(103,103,103)
		else
			btn3.Text = "Teleport ON"
			btn3.BackgroundColor3 = Color3.fromRGB(30,30,30)
		end
	end)

	-- ===== Noclip =====
	btn4.MouseButton1Click:Connect(function()
		State.noclip = not State.noclip
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not State.noclip
			end
		end
		if State.noclip then
			btn4.Text = "On Noclip"
			btn4.BackgroundColor3 = Color3.fromRGB(30,30,30)
		else
			btn4.Text = "Off Noclip"
			btn4.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)
end

-- ===== RenderStepped для плавного телепорта =====
RunService.RenderStepped:Connect(function(delta)
	if State.teleportActive and State.teleportTarget and State.hrp then
		State.teleportProgress = State.teleportProgress + delta
		local alpha = math.clamp(State.teleportProgress / (0.05 * State.teleportSteps), 0, 1)
		State.hrp.CFrame = CFrame.new(State.hrp.Position:Lerp(State.teleportTarget, alpha))
		if alpha >= 1 then
			State.teleportActive = false
			State.teleportTarget = nil
			State.teleportProgress = 0
			btn3.Text = "Teleport OFF"
			btn3.BackgroundColor3 = Color3.fromRGB(255,0,0)
		end
	end
end)

-- ===== ProximityPrompt =====
for _, prompt in ipairs(workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function()
			if State.teleportActive then
				State.teleportProgress = 0
				local tpPart = getPlayerPlotTpPart()
				if tpPart then
					local offset = Vector3.new(math.random(-3,3),3,math.random(-3,3))
					State.teleportTarget = tpPart.Position + offset
				else
					State.teleportActive = false
					btn3.Text = "Teleport OFF"
					btn3.BackgroundColor3 = Color3.fromRGB(255,0,0)
				end
			end
		end)
	end
end

-- ===== Подключаем персонаж =====
if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)
