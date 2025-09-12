-- Combined Anchor + GUI + InstantSteal
local Players, RunService, UIS, Workspace = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("Workspace")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum, root = char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
local TpPartName = "MultiplierPart"

-- CONFIG
local anchor, vertControl, flySpeed, speed, jump = false, 0, 20, hum.WalkSpeed, hum.JumpPower
local targetPos = root.Position
local toggleKey, tpKey = Enum.KeyCode.F, Enum.KeyCode.T
local buttonStatesFolder = "ButtonStates"

-- GUI 1
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); gui.ResetOnSpawn = false
local function makeBtn(name, pos, size, txt)
	local b = Instance.new("TextButton", gui)
	b.Size, b.Position, b.Text = size, pos, txt
	b.BackgroundColor3, b.BackgroundTransparency, b.TextColor3 = Color3.fromRGB(28,28,28),0.15,Color3.new(1,1,1)
	return b
end
local mainBtn = makeBtn("AnchorBtn",UDim2.new(0,16,0,16),UDim2.new(0,180,0,42),"Anchor: OFF")
local upBtn = makeBtn("Up",UDim2.new(0,200,0,16),UDim2.new(0,40,0,42),"▲"); upBtn.Visible=false
local downBtn = makeBtn("Down",UDim2.new(0,245,0,16),UDim2.new(0,40,0,42),"▼"); downBtn.Visible=false
local tpBtn = makeBtn("Tp",UDim2.new(0,290,0,16),UDim2.new(0,60,0,42),"Tp"); tpBtn.Visible=false

local toggleBox = Instance.new("TextBox",gui)
toggleBox.Size, toggleBox.Position, toggleBox.Text = UDim2.new(0,60,0,20),UDim2.new(0,16,0,60),"F"
local tpBox = Instance.new("TextBox",gui)
tpBox.Size, tpBox.Position, tpBox.Text = UDim2.new(0,60,0,20),UDim2.new(0,80,0,60),"T"

toggleBox.FocusLost:Connect(function()
	local key = Enum.KeyCode[toggleBox.Text:upper()]
	if key then toggleKey = key end
end)
tpBox.FocusLost:Connect(function()
	local key = Enum.KeyCode[tpBox.Text:upper()]
	if key then tpKey = key end
end)

-- Anchor функция
local function setAnchor(state)
	anchor = state
	if anchor then
		speed, jump = hum.WalkSpeed, hum.JumpPower
		hum.WalkSpeed, hum.JumpPower = 0, 0
		mainBtn.Text, upBtn.Visible, downBtn.Visible, tpBtn.Visible = "Anchor: ON", true, true, true
		targetPos = root.Position
	else
		hum.WalkSpeed, hum.JumpPower = speed, jump
		mainBtn.Text, upBtn.Visible, downBtn.Visible, tpBtn.Visible, vertControl = "Anchor: OFF", false,false,false,0
	end
end

mainBtn.MouseButton1Click:Connect(function() setAnchor(not anchor) end)
tpBtn.MouseButton1Click:Connect(function()
	if anchor and root then
		local look = Workspace.CurrentCamera.CFrame.LookVector
		targetPos += look*7
		root.CFrame = CFrame.new(targetPos,targetPos+look)
	end
end)

-- Управление кнопками
upBtn.MouseButton1Down:Connect(function() vertControl=1 end); upBtn.MouseButton1Up:Connect(function() vertControl=0 end)
downBtn.MouseButton1Down:Connect(function() vertControl=-1 end); downBtn.MouseButton1Up:Connect(function() vertControl=0 end)

-- Input
UIS.InputBegan:Connect(function(input,proc)
	if proc then return end
	if input.KeyCode==toggleKey then setAnchor(not anchor)
	elseif input.KeyCode==tpKey and anchor then
		local look=Workspace.CurrentCamera.CFrame.LookVector
		targetPos+=look*7
		root.CFrame=CFrame.new(targetPos,targetPos+look)
	elseif input.KeyCode==Enum.KeyCode.Space and anchor then vertControl=1
	elseif input.KeyCode==Enum.KeyCode.LeftShift and anchor then vertControl=-1
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.LeftShift then vertControl=0 end
end)

-- UICorner
for _, obj in ipairs({mainBtn, upBtn, downBtn, tpBtn, toggleBox, tpBox}) do
	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0, 10)
	uc.Parent = obj
end

-- ButtonStates Folder
local function getOrCreateButtonStates()
	local states = player:FindFirstChild(buttonStatesFolder)
	if not states then
		states = Instance.new("Folder")
		states.Name = buttonStatesFolder
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

-- Поиск своей базы
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

-- GUI из 2 скрипта
local function setupCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	local originalSpeed = humanoid.WalkSpeed

	local teleportActive = false
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportSteps = 30

	-- GUI для кнопок
	local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	screenGui.Name = "AnchoredGUI"

	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 256, 0, 286)
	frame.Position = UDim2.new(0.5, -130, 0.5, -135)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.Active = true
	frame.Draggable = true
	frame.Visible = false

	local function makeLabel(text,pos)
		local lbl = Instance.new("TextLabel")
		lbl.Parent = frame
		lbl.Text = text
		lbl.TextScaled = true
		lbl.Font = Enum.Font.Arcade
		lbl.Size = UDim2.new(0, 200, 0, 50)
		lbl.Position = pos
		lbl.TextColor3 = Color3.fromRGB(39, 151, 211)
		lbl.BackgroundTransparency = 1
		return lbl
	end
	makeLabel("Nova Hub", UDim2.new(0,40,0,0))
	makeLabel("TT: @novahub57", UDim2.new(0,20,0,30))
	makeLabel("If bag Reset", UDim2.new(0,30,0,50))

	-- Кнопка Toggle GUI
	local aidi = "rbxassetid://71285066607329"
	local textbuttonframe = Instance.new("ImageButton")
	textbuttonframe.Parent = screenGui
	textbuttonframe.Size = UDim2.new(0, 75, 0, 75)
	textbuttonframe.Position = UDim2.new(0, 50, 0, 300)
	textbuttonframe.Draggable = true
	textbuttonframe.Image = aidi
	local uibuttonframe = Instance.new("UICorner")
	uibuttonframe.CornerRadius = UDim.new(4, 15)
	uibuttonframe.Parent = textbuttonframe
	textbuttonframe.MouseButton1Click:Connect(function()
		frame.Visible = not frame.Visible
	end)

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
		onChange(bv.Value,btn)
		btn.MouseButton1Click:Connect(function()
			bv.Value = not bv.Value
			onChange(bv.Value,btn)
		end)
		return btn
	end

	-- Anchor Button
	createButton("Anchor OFF",UDim2.new(0,10,0,212),buttonStates.Anchor,function(state,btn)
		setAnchor(state)
		if state then btn.Text="Anchor ON"; btn.BackgroundColor3=Color3.fromRGB(60,60,60)
		else btn.Text="Anchor OFF"; btn.BackgroundColor3=Color3.fromRGB(150,150,150) end
	end)

	-- Teleport RenderStepped
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
			end
		end
		if anchor then
			local move=hum.MoveDirection
			local hor=Vector3.new(move.X,0,move.Z)*speed*delta
			local vert=Vector3.new(0,vertControl*flySpeed*delta,0)
			targetPos+=hor+vert
			root.CFrame=CFrame.new(targetPos,targetPos+Workspace.CurrentCamera.CFrame.LookVector)
		end
	end)

	-- ProximityPrompt для Instant Steal
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				local tpPart = getPlayerPlotTpPart()
				if not tpPart then return end
				local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
				teleportTarget = tpPart.Position + offset
				teleportProgress = 0
				teleportActive = true
				buttonStates.Teleport.Value = true
				-- Anchor / Noclip включаем временно
				local anchorWasOn = buttonStates.Anchor.Value
				local noclipWasOn = buttonStates.Noclip.Value
				if not anchorWasOn then buttonStates.Anchor.Value=true; hrp.Anchored=true end
				if not noclipWasOn then
					buttonStates.Noclip.Value=true
					for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
				end
				-- Ждём завершения и потом отключаем временно включенные
				task.spawn(function()
					while teleportActive do RunService.RenderStepped:Wait() end
					task.wait(8)
					if not anchorWasOn then buttonStates.Anchor.Value=false; hrp.Anchored=false end
					if not noclipWasOn then
						buttonStates.Noclip.Value=false
						for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=true end end
					end
				end)
			end)
		end
	end
end

setupCharacter(player.Character)
player.CharacterAdded:Connect(setupCharacter)

-- GUI 1 видимость по кнопке Wait For Update
local waitBV = buttonStates.FastSpeedSteal
waitBV:GetPropertyChangedSignal("Value"):Connect(function()
	gui.Enabled = waitBV.Value
end)

