-- LocalScript: Anchor + InstantSteal
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- Ensure single run
if script:GetAttribute("Initialized") then return end
script:SetAttribute("Initialized", true)

-- Character refs
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

-- GUI1 (Anchor)
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

-- mainBtn toggle Anchor
mainBtn.MouseButton1Click:Connect(function()
    buttonStates.Anchor.Value = not buttonStates.Anchor.Value
end)

-- tpBtn forward teleport
tpBtn.MouseButton1Click:Connect(function()
    if buttonStates.Anchor.Value and root and Workspace.CurrentCamera then
        local look = Workspace.CurrentCamera.CFrame.LookVector
        targetPos = targetPos + look * 7
        root.CFrame = CFrame.new(targetPos, targetPos + look)
    end
end)

-- up/down buttons
upBtn.MouseButton1Down:Connect(function() vertControl = 1 end)
upBtn.MouseButton1Up:Connect(function() vertControl = 0 end)
downBtn.MouseButton1Down:Connect(function() vertControl = -1 end)
downBtn.MouseButton1Up:Connect(function() vertControl = 0 end)

-- sync GUI with Anchor state
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

-- GUI visibility controlled by FastSpeedSteal
buttonStates.FastSpeedSteal.Changed:Connect(function(val)
    gui1.Enabled = val
end)
gui1.Enabled = buttonStates.FastSpeedSteal.Value

-- Input
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

-- Heartbeat: Anchor movement
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

-- Helper to find player's MultiplierPart
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

-- InstantSteal logic via ProximityPrompt
local teleportInProgress = false
for _, prompt in ipairs(workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") then
        prompt.Triggered:Connect(function(triggeringPlayer)
            if triggeringPlayer ~= player then return end
            if not buttonStates.Teleport.Value then return end
            if teleportInProgress then return end
            teleportInProgress = true

            local tpPart = getPlayerPlotTpPart()
            if not tpPart then teleportInProgress = false return end
            local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
            local teleportTarget = tpPart.Position + offset

            -- Store state
            local anchorWasOn = buttonStates.Anchor.Value
            local noclipWasOn = buttonStates.Noclip.Value
            local partsState = {}
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    partsState[p] = p.CanCollide
                end
            end

            -- Enable Anchor/Noclip temporarily
            if not anchorWasOn and root then
                root.Anchored = true
                buttonStates.Anchor.Value = true
            end
            if not noclipWasOn then
                for p, _ in pairs(partsState) do p.CanCollide = false end
                buttonStates.Noclip.Value = true
            end

            -- Smooth teleport
            task.spawn(function()
                local duration = 0.5
                local elapsed = 0
                while elapsed < duration do
                    local dt = RunService.RenderStepped:Wait()
                    elapsed = elapsed + dt
                    local alpha = math.clamp(elapsed / duration, 0, 1)
                    root.CFrame = CFrame.new(root.Position:Lerp(teleportTarget, alpha))
                end

                -- Disable InstantSteal
                buttonStates.Teleport.Value = false
                task.wait(5)

                -- Restore Anchor/Noclip
                if root and not anchorWasOn then
                    root.Anchored = false
                    buttonStates.Anchor.Value = false
                end
                if not noclipWasOn then
                    for p, v in pairs(partsState) do
                        if p and p.Parent then p.CanCollide = v end
                    end
                    buttonStates.Noclip.Value = false
                end

                teleportInProgress = false
            end)
        end)
    end
end

-- Reconnect on respawn
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
end)


