local Players, RunService, UIS, Workspace = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("Workspace")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum, root = char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")

-- CONFIG
local anchor, vertControl, flySpeed, speed, jump = false, 0, 20, hum.WalkSpeed, hum.JumpPower
local targetPos = root.Position
local toggleKey, tpKey = Enum.KeyCode.F, Enum.KeyCode.T

-- STATES
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

-- GUI 1 (Anchor GUI)
local gui1 = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui1.ResetOnSpawn = false

local frame1 = Instance.new("Frame", gui1)
frame1.Size = UDim2.new(0, 256,0,100)
frame1.Position = UDim2.new(0.5,-350,0.5,-150) --{0.5, -464},{0.5, -204}
frame1.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame1.Active = true
frame1.Draggable = true
frame1.Visible = true

local uicorner3 = Instance.new("UICorner")
uicorner3.CornerRadius = UDim.new(0, 10)
uicorner3.Parent = frame1

local uiStroke3 = Instance.new("UIStroke")
uiStroke3.Color = Color3.fromRGB(255, 149, 57)
uiStroke3.Thickness = 3
uiStroke3.Parent = frame1

local function makeBtn1(name,pos,size,txt)
	local b = Instance.new("TextButton", frame1)
	b.Size, b.Position, b.Text = size, pos, txt
	b.BackgroundColor3, b.BackgroundTransparency, b.TextColor3 = Color3.fromRGB(28,28,28),0.15,Color3.new(1,1,1)
	return b
end



local mainBtn = makeBtn1("AnchorBtn",UDim2.new(0,18,0,18),UDim2.new(0,180,0,42),"Anchor: OFF")
local upBtn = makeBtn1("Up",UDim2.new(0,200,0,16),UDim2.new(0,40,0,42),"▲"); upBtn.Visible=false
local downBtn = makeBtn1("Down",UDim2.new(0,245,0,16),UDim2.new(0,40,0,42),"▼"); downBtn.Visible=false
local tpBtn = makeBtn1("Tp",UDim2.new(0,290,0,16),UDim2.new(0,60,0,42),"Tp"); tpBtn.Visible=false

-- Key TextBoxes
local toggleBox = Instance.new("TextBox",frame1)
toggleBox.Size, toggleBox.Position, toggleBox.Text = UDim2.new(0,60,0,20),UDim2.new(0,16,0,60),"F"
local tpBox = Instance.new("TextBox",frame1)
tpBox.Size, tpBox.Position, tpBox.Text = UDim2.new(0,60,0,20),UDim2.new(0,80,0,60),"T"

toggleBox.FocusLost:Connect(function()
	local key = Enum.KeyCode[toggleBox.Text:upper()]
	if key then toggleKey = key end
end)
tpBox.FocusLost:Connect(function()
	local key = Enum.KeyCode[tpBox.Text:upper()]
	if key then tpKey = key end
end)

-- Anchor toggle function
local function setAnchor(state)
	anchor = state
	if anchor then
		speed, jump = hum.WalkSpeed, hum.JumpPower
		hum.WalkSpeed, hum.JumpPower = 0,0
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
		root.CFrame = CFrame.new(targetPos, targetPos + look)
	end
end)

-- Up/Down buttons
upBtn.MouseButton1Down:Connect(function() vertControl=1 end)
upBtn.MouseButton1Up:Connect(function() vertControl=0 end)
downBtn.MouseButton1Down:Connect(function() vertControl=-1 end)
downBtn.MouseButton1Up:Connect(function() vertControl=0 end)

-- Input handling
UIS.InputBegan:Connect(function(input,proc)
	if proc then return end
	if input.KeyCode==toggleKey then setAnchor(not anchor)
	elseif input.KeyCode==tpKey and anchor then
		local look = Workspace.CurrentCamera.CFrame.LookVector
		targetPos += look*7
		root.CFrame = CFrame.new(targetPos,targetPos+look)
	elseif input.KeyCode==Enum.KeyCode.Space and anchor then vertControl=1
	elseif input.KeyCode==Enum.KeyCode.LeftShift and anchor then vertControl=-1
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.LeftShift then vertControl=0 end
end)

for _,btn in ipairs({mainBtn,upBtn,downBtn,tpBtn,toggleBox,tpBox}) do
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0,10)
	uiCorner.Parent = btn
end

for _, btns in ipairs({mainBtn, upBtn, downBtn, tpBtn, toggleBox, tpBox}) do
	btns.Font = Enum.Font.Arcade
	btns.TextScaled = true
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(11, 165, 207)
	uiStroke.Thickness = 2
	uiStroke.Parent = btns
end


player.CharacterAdded:Connect(function(c)
	char=c
	hum=c:WaitForChild("Humanoid")
	root=c:WaitForChild("HumanoidRootPart")
	targetPos=root.Position
end)

RunService.Heartbeat:Connect(function(dt)
	if anchor and root then
		local move=hum.MoveDirection
		local hor=Vector3.new(move.X,0,move.Z)*speed*dt
		local vert=Vector3.new(0,vertControl*flySpeed*dt,0)
		targetPos+=hor+vert
		root.CFrame=CFrame.new(targetPos,targetPos+Workspace.CurrentCamera.CFrame.LookVector)
	end
end)

-- GUI 2 (Main GUI)
local function setupCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	local originalSpeed = humanoid.WalkSpeed

	local anchorOnly = buttonStates.Anchor.Value
	local speedMode = buttonStates.Speed.Value
	local teleportActive = buttonStates.Teleport.Value
	local teleportTarget = nil
	local teleportProgress = 0
	local teleportSteps = 30
	local gravityActive = speedMode

	local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	screenGui.Name = "NovaGUI"
	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 256,0,286)
	frame.Position = UDim2.new(0.5,-130,0.5,-135)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.Active = true
	frame.Draggable = true
	frame.Visible = false

	local aidi = "rbxassetid://71285066607329"
	local textbuttonframe = Instance.new("ImageButton")
	textbuttonframe.Parent = screenGui
	textbuttonframe.Size = UDim2.new(0,75,0,75)
	textbuttonframe.Position = UDim2.new(0,50,0,300)
	textbuttonframe.Draggable = true
	textbuttonframe.Image = aidi
	local uibuttonframe = Instance.new("UICorner")
	uibuttonframe.CornerRadius = UDim.new(4,15)
	uibuttonframe.Parent = textbuttonframe
	textbuttonframe.MouseButton1Click:Connect(function()
		frame.Visible = not frame.Visible
	end)

	local function makeLabel(text,pos)
		local lbl = Instance.new("TextLabel")
		lbl.Parent = frame
		lbl.Text = text
		lbl.TextScaled = true
		lbl.Font = Enum.Font.Arcade
		lbl.Size = UDim2.new(0,200,0,50)
		lbl.Position = pos
		lbl.TextColor3 = Color3.fromRGB(39,151,211)
		lbl.BackgroundTransparency = 1
		return lbl
	end
	makeLabel("Nova Hub", UDim2.new(0,40,0,0))
	makeLabel("TT: @novahub57", UDim2.new(0,20,0,30))
	makeLabel("If bag Reset", UDim2.new(0,30,0,50))

	local uiframe = Instance.new("UICorner")
	uiframe.CornerRadius = UDim.new(0,20)
	uiframe.Parent = frame
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 4
	uiStroke.Color = Color3.fromRGB(211,79,35)
	uiStroke.Parent = frame

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

			-- Wait While Update кнопка теперь управляет GUI первого скрипта
			if bv.Name == "FastSpeedSteal" then
				gui1.Enabled = bv.Value
			end
		end)
		return btn
	end

	-- Anchor Button
	createButton("Anchor OFF", UDim2.new(0,10,0,212), buttonStates.Anchor, function(state,btn)
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

	-- Speed Button
	createButton("Speed OFF", UDim2.new(0,130,0,212), buttonStates.Speed, function(state,btn)
		speedMode = state
		humanoid.WalkSpeed = state and originalSpeed+20 or originalSpeed
		gravityActive = state
		if state then
			btn.Text = "Speed ON"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			btn.Text = "Speed OFF"
			btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Teleport / Instant Steal Button
	local teleportBtn
	teleportBtn = createButton("Teleport OFF", UDim2.new(0,10,0,150), buttonStates.Teleport, function(state,btn)
		teleportActive = state
		if state then
			btn.Text = "InstantSteal ON"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		else
			teleportTarget = nil
			teleportProgress = 0
			btn.Text = "InstantSteal OFF"
			btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
		end
	end)

	-- Noclip Button
	createButton("On Noclip", UDim2.new(0,130,0,150), buttonStates.Noclip, function(state,btn)
		for _,part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = not state end
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
	createButton("Forward Tp wait While Update", UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state,btn)
		btn.Text = state and "Wait For Update" or "WaitForUpdate"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
	end)

	-- Fast Speed / Wait While Update Button
	createButton("Noclip Byppas", UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state,btn)
		btn.Text = state and "Noclip Byppas" or "Noclip Byppas"
		btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)

		-- управляет видимостью GUI из первого скрипта
		gui1.Enabled = state
	end)

	-- RenderStepped для плавного телепорта
	RunService.RenderStepped:Connect(function(delta)
		if teleportActive and teleportTarget then
			teleportProgress += delta
			local alpha = math.clamp(teleportProgress / (0.05*teleportSteps),0,1)
			hrp.CFrame = CFrame.new(hrp.Position:Lerp(teleportTarget,alpha))
			if alpha >= 1 then
				teleportActive = false
				teleportTarget = nil
				teleportProgress = 0
				buttonStates.Teleport.Value = false
				if teleportBtn then
					teleportBtn.Text = "InstantSteal OFF"
					teleportBtn.BackgroundColor3 = Color3.fromRGB(150,150,150)
				end
			end
		end
	end)

	-- ProximityPrompt handling (Instant Steal всегда активен)
	local TpPartName = "MultiplierPart"
	local function getPlayerPlotTpPart()
		local plotsFolder = workspace:WaitForChild("Plots")
		for i = 1, 8 do
			local plot = plotsFolder:FindFirstChild("Plot"..i)
			if plot then
				local ownerValue = plot:FindFirstChild("Owner")
				local tpPart = plot:FindFirstChild(TpPartName)
				if ownerValue and ownerValue.Value == player.Name and tpPart then return tpPart end
			end
		end
		return nil
	end

	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				local tpPart = getPlayerPlotTpPart()
				if not tpPart then return end

				local offset = Vector3.new(math.random(-3,3),3,math.random(-3,3))
				teleportTarget = tpPart.Position + offset
				teleportProgress = 0
				teleportActive = true
				buttonStates.Teleport.Value = true
				if teleportBtn then
					teleportBtn.Text = "InstantSteal ON"
					teleportBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
				end

				-- Anchor / Noclip включаем временно
				local anchorWasOn = buttonStates.Anchor.Value
				local noclipWasOn = buttonStates.Noclip.Value
				if not anchorWasOn then buttonStates.Anchor.Value = true hrp.Anchored = true end
				if not noclipWasOn then
					buttonStates.Noclip.Value = true
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end

				-- Обновляем GUI кнопки Anchor/Noclip
				for _, btn in ipairs(frame:GetChildren()) do
					if btn:IsA("TextButton") then
						if btn.Text:find("Anchor") then btn.Text = "Anchor ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
						elseif btn.Text:find("Noclip") then btn.Text = "On Noclip"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
						end
					end
				end

				-- Ждём завершения телепорта и потом выключаем временные Anchor/Noclip
				task.spawn(function()
					while teleportActive do RunService.RenderStepped:Wait() end
					task.wait(8)
					if not anchorWasOn then buttonStates.Anchor.Value = false hrp.Anchored = false
						for _, btn in ipairs(frame:GetChildren()) do
							if btn:IsA("TextButton") and btn.Text:find("Anchor") then
								btn.Text = "Anchor OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
							end
						end
					end
					if not noclipWasOn then
						buttonStates.Noclip.Value = false
						for _, part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = true end
						end
						for _, btn in ipairs(frame:GetChildren()) do
							if btn:IsA("TextButton") and btn.Text:find("Noclip") then
								btn.Text = "Off Noclip"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
							end
						end
					end
				end)
			end)
		end
	end
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)
