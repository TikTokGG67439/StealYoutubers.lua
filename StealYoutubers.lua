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

	local function makeLabel(text,pos)
		local lbl = Instance.new("TextLabel")
		lbl.Parent = frame
		lbl.Text = text
		lbl.TextScaled = true
		lbl.Font = Enum.Font.Arcade
		lbl.Size = UDim2.new(0, 200, 0, 50)
		lbl.Position = pos
		lbl.TextColor3 = Color3.fromRGB(161,163,62)
		lbl.BackgroundTransparency = 1
		return lbl
	end

	makeLabel("Saint Hub", UDim2.new(0,30,0,0))
	makeLabel("TT: @GG67439", UDim2.new(0,30,0,30))

	local uiframe = Instance.new("UICorner")
	uiframe.CornerRadius = UDim.new(0,20)
	uiframe.Parent = frame

	-- Функция создания кнопки
	local function createButton(name,pos,bv,onChange)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0,113,0,50)
		btn.Position = pos
		btn.TextScaled = true
		btn.Font = Enum.Font.Arcade
		btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		btn.TextColor3 = Color3.new(0,0,0)
		btn.Parent = frame
		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0,8)
		uic.Parent = btn

		-- Устанавливаем изначальное состояние кнопки
		onChange(bv.Value,btn)

		btn.MouseButton1Click:Connect(function()
			bv.Value = not bv.Value
			onChange(bv.Value,btn)
		end)

		return btn
	end

	-- Anchor
	createButton("Anchor OFF",UDim2.new(0,10,0,212),buttonStates.Anchor,function(state,btn)
		anchorOnly = state
		hrp.Anchored = state
		if state then
			btn.Text = "Anchor ON"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			btn.Text = "Anchor OFF"
			btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Speed
	createButton("Speed OFF",UDim2.new(0,130,0,212),buttonStates.Speed,function(state,btn)
		speedMode = state
		humanoid.WalkSpeed = state and originalSpeed + 20 or originalSpeed
		gravityActive = state
		if state then
			btn.Text = "Speed ON"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			btn.Text = "Speed OFF"
			btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Teleport
	local teleportBtn
	teleportBtn = createButton("Teleport OFF",UDim2.new(0,10,0,150),buttonStates.Teleport,function(state,btn)
		teleportActive = state
		if state then
			btn.Text = "Teleport ON"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			teleportTarget = nil
			teleportProgress = 0
			btn.Text = "Teleport OFF"
			btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Noclip
	createButton("On Noclip",UDim2.new(0,130,0,150),buttonStates.Noclip,function(state,btn)
		for _,part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not state
			end
		end
		if state then
			btn.Text = "On Noclip"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			btn.Text = "Off Noclip"
			btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Forward Tp
	createButton("Forward Tp wait While Update",UDim2.new(0,130,0,90),buttonStates.ForwardTp,function(state,btn)
		btn.Text = state and "Forward Tp ON" or "Forward Tp OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- Fast Speed
	createButton("Maybe Fast Speed With Steal",UDim2.new(0,10,0,90),buttonStates.FastSpeedSteal,function(state,btn)
		btn.Text = state and "Fast Speed ON" or "Fast Speed OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- RenderStepped для плавного телепорта
	RunService.RenderStepped:Connect(function(delta)
		if teleportActive and teleportTarget then
			teleportProgress += delta
			local alpha = math.clamp(teleportProgress / (0.05 * teleportSteps),0,1)
			hrp.CFrame = CFrame.new(hrp.Position:Lerp(teleportTarget,alpha))
			if alpha >= 1 then
				teleportActive = false
				teleportTarget = nil
				teleportProgress = 0
				buttonStates.Teleport.Value = false
				if teleportBtn then
					teleportBtn.Text = "Teleport OFF"
					teleportBtn.BackgroundColor3 = Color3.fromRGB(150,150,150)
				end
			end
		end
	end)

	-- ProximityPrompt
for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				local tpPart = getPlayerPlotTpPart()
				if not tpPart then return end

				-- Телепорт
				local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
				teleportTarget = tpPart.Position + offset
				teleportProgress = 0
				teleportActive = true
				buttonStates.Teleport.Value = true
				if teleportBtn then
					teleportBtn.Text = "Teleport ON"
					teleportBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
				end

				-- Проверяем состояние Anchor
				local anchorWasOn = buttonStates.Anchor.Value
				if not anchorWasOn then
					-- Включаем временно
					buttonStates.Anchor.Value = true
					anchorOnly = true
					hrp.Anchored = true
					-- Обновляем текст кнопки Anchor
					for _, btn in ipairs(frame:GetChildren()) do
						if btn:IsA("TextButton") and btn.Text:find("Anchor") then
							btn.Text = "Anchor ON"
							btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
						end
					end
				end

				-- Ждём, пока телепорт завершится
				local teleWait = RunService.RenderStepped:Wait()
				spawn(function()
					while teleportActive do
						teleWait()
					end

					-- Выключаем Teleport
					buttonStates.Teleport.Value = false
					if teleportBtn then
						teleportBtn.Text = "Teleport OFF"
						teleportBtn.BackgroundColor3 = Color3.fromRGB(150,150,150)
					end

					-- Если Anchor был выключен до телепорта — выключаем после 0.1 секунды
					if not anchorWasOn then
						task.wait(0.1)
						buttonStates.Anchor.Value = false
						anchorOnly = false
						hrp.Anchored = false
						for _, btn in ipairs(frame:GetChildren()) do
							if btn:IsA("TextButton") and btn.Text:find("Anchor") then
								btn.Text = "Anchor OFF"
								btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
							end
						end
					end
				end)
			end)
		end
	end
end

if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)
