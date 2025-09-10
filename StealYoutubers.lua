local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local TpPartName = "MultiplierPart"

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
	local anchorOnly = false
	local speedMode = false
	local gravityActive = false
	local teleportActive = false
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportSteps = 15

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

	-- Кнопка 1: Anchor
	local btn1 = Instance.new("TextButton", frame)
	btn1.Size = UDim2.new(0, 113, 0, 50)
	btn1.Position = UDim2.new(0, 10, 0, 212)
	btn1.TextScaled = true
	btn1.Font = Enum.Font.Arcade
	btn1.Text = "Anchor OFF"
	btn1.BackgroundColor3 = Color3.fromRGB(103, 103, 103)
	btn1.TextColor3 = Color3.new(0,0,0)
	
	btn1.MouseButton1Click:Connect(function()
		anchorOnly = not anchorOnly
		hrp.Anchored = anchorOnly -- просто управляем hrp.Anchored
		if anchorOnly then
			btn1.Text = "Anchor ON"
			btn1.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		else
			btn1.Text = "Anchor OFF"
			btn1.BackgroundColor3 = Color3.fromRGB(103, 103, 103)
		end
	end)
	
	local ui1 = Instance.new("UICorner")
	ui1.Parent = btn1
	ui1.CornerRadius = UDim.new(0, 8)

	-- Кнопка 2: Speed
	local btn2 = Instance.new("TextButton", frame)
	btn2.Size = UDim2.new(0, 113, 0, 50)
	btn2.Position = UDim2.new(0, 130, 0, 212)
	btn2.Text = "Speed OFF"
	btn2.BackgroundColor3 = Color3.fromRGB(103, 103, 103)
	btn2.TextScaled = true
	btn2.TextColor3 = Color3.new(0, 0, 0)
	btn2.Font = Enum.Font.Arcade
	local uibtn2 = Instance.new("UICorner")
	uibtn2.CornerRadius = UDim.new(0, 8)
	uibtn2.Parent = btn2
	
	btn2.MouseButton1Click:Connect(function()
		speedMode = not speedMode
		if speedMode then
			btn2.Text = "Speed ON"
			btn2.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			humanoid.WalkSpeed = originalSpeed + 20
			gravityActive = true
		else
			btn2.Text = "Speed OFF"
			btn2.BackgroundColor3 = Color3.fromRGB(103, 103, 103)
			humanoid.WalkSpeed = originalSpeed
			gravityActive = false
		end
	end)

	-- Кнопка 3: Teleport
	local btn3 = Instance.new("TextButton", frame)
	btn3.Size = UDim2.new(0, 113, 0, 50)
	btn3.Position = UDim2.new(0, 10, 0, 150)
	btn3.Text = "Teleport OFF"
	btn3.TextScaled = true
	btn3.Font = Enum.Font.Arcade
	btn3.BackgroundColor3 = Color3.fromRGB(103,103,103)
	btn3.TextColor3 = Color3.new(0,0,0)
	
	local uibtn3 = Instance.new("UICorner")
	uibtn3.CornerRadius = UDim.new(0, 8)
	uibtn3.Parent = btn3
	
	btn3.MouseButton1Click:Connect(function()
		teleportActive = not teleportActive
		if not teleportActive then
			-- Отмена телепортации
			teleportTarget = nil
			teleportProgress = 0
			btn3.Text = "Teleport OFF"
			btn3.BackgroundColor3 = Color3.fromRGB(103,103,103)
		else
			-- Подготовка к телепорту (ProximityPrompt запускает позже)
			btn3.Text = "Teleport ON"
			btn3.BackgroundColor3 = Color3.fromRGB(30,30,30)
		end
	end)
	
	local btn4 = Instance.new("TextButton", frame)
	btn4.Size = UDim2.new(0, 113, 0, 50)
	btn4.Position = UDim2.new(0, 130, 0, 150)
	btn4.Text = "On Noclip"
	btn4.TextScaled = true
	btn4.Font = Enum.Font.Arcade
	btn4.BackgroundColor3 = Color3.fromRGB(103,103,103)
	btn4.TextColor3 = Color3.new(0,0,0)

	local uibtn4 = Instance.new("UICorner")
	uibtn4.CornerRadius = UDim.new(0, 8)
	uibtn4.Parent = btn4
	
	btn4.MouseButton1Click:Connect(function()
		local char = game.Players.LocalPlayer.Character
		if not char then return end
		
		local hpr = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		if hpr.CanCollide then
			
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
			btn4.Text = "On Noclip"
			btn4.BackgroundColor3 = Color3.fromRGB(30,30,30)
		else
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
			btn4.Text = "Off Noclip"
			btn4.BackgroundColor3 = Color3.fromRGB(103,103,103)
		end
	end)
	
	local btn5 = Instance.new("TextButton", frame)
	btn5.Size = UDim2.new(0, 113, 0, 50)
	btn5.Position = UDim2.new(0, 130, 0, 90)
	btn5.Text = "Forward Tp wait While Update"
	btn5.TextScaled = true
	btn5.Font = Enum.Font.Arcade
	btn5.BackgroundColor3 = Color3.fromRGB(103,103,103)
	btn5.TextColor3 = Color3.new(0,0,0)

	local uibtn5 = Instance.new("UICorner")
	uibtn5.CornerRadius = UDim.new(0, 8)
	uibtn5.Parent = btn5
	
	local btn6 = Instance.new("TextButton", frame)
	btn6.Size = UDim2.new(0, 113, 0, 50)
	btn6.Position = UDim2.new(0, 10, 0, 90)
	btn6.Text = "Maybe Fast Speed With Steal"
	btn6.TextScaled = true
	btn6.Font = Enum.Font.Arcade
	btn6.BackgroundColor3 = Color3.fromRGB(103,103,103)
	btn6.TextColor3 = Color3.new(0,0,0)

	local uibtn6 = Instance.new("UICorner")
	uibtn6.CornerRadius = UDim.new(0, 8)
	uibtn6.Parent = btn6
		
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
				btn3.Text = "Teleport OFF"
				btn3.BackgroundColor3 = Color3.fromRGB(255,0,0)
			end
		end
	end)

	-- ProximityPrompt
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				if teleportActive then
					-- Отмена предыдущего прогресса
					teleportProgress = 0
					local tpPart = getPlayerPlotTpPart()
					if tpPart then
						local offset = Vector3.new(math.random(-3,3),3,math.random(-3,3))
						teleportTarget = tpPart.Position + offset
					else
						teleportActive = false
						btn3.Text = "Teleport OFF"
						btn3.BackgroundColor3 = Color3.fromRGB(255,0,0)
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
