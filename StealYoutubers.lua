-- Unified Anchor + Nova GUI + InstantSteal fix (LocalScript)
-- Помещать как LocalScript в StarterPlayerScripts / PlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- Ensure character exists
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- CONFIG / STATE
local anchorEnabled = false
local vertControl = 0
local flySpeed = 20
local storedWalkSpeed, storedJumpPower = hum.WalkSpeed, hum.JumpPower
local targetPos = root.Position
local toggleKey, tpKey = Enum.KeyCode.F, Enum.KeyCode.T

-- ButtonStates folder (persistent BoolValues)
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

-- ---------------- GUI1: Anchor panel ----------------
local gui1 = Instance.new("ScreenGui")
gui1.Name = "AnchorGUI"
gui1.ResetOnSpawn = false
gui1.Parent = player:WaitForChild("PlayerGui")
-- visibility controlled by FastSpeedSteal BoolValue
gui1.Enabled = buttonStates.FastSpeedSteal.Value

local frame1 = Instance.new("Frame", gui1)
frame1.Size = UDim2.new(0,256,0,120)
frame1.Position = UDim2.new(0.5,-350,0.5,-150)
frame1.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame1.Active = true
frame1.Draggable = true
local _ = Instance.new("UICorner", frame1); _.CornerRadius = UDim.new(0,10)
local __ = Instance.new("UIStroke", frame1); __.Color = Color3.fromRGB(255,149,57); __.Thickness = 3

local function makeBtn1(pos, size, txt, parent)
    parent = parent or frame1
    local b = Instance.new("TextButton", parent)
    b.Size = size
    b.Position = pos
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(28,28,28)
    b.BackgroundTransparency = 0.15
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Arcade
    b.TextScaled = true
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke", b); s.Thickness = 2; s.Color = Color3.fromRGB(11,165,207)
    return b
end

local mainBtn = makeBtn1(UDim2.new(0,18,0,18), UDim2.new(0,180,0,42), "Anchor: OFF")
local upBtn = makeBtn1(UDim2.new(0,200,0,18), UDim2.new(0,40,0,42), "▲"); upBtn.Visible = false
local downBtn = makeBtn1(UDim2.new(0,245,0,18), UDim2.new(0,40,0,42), "▼"); downBtn.Visible = false
local tpBtn = makeBtn1(UDim2.new(0,290,0,18), UDim2.new(0,60,0,42), "Tp"); tpBtn.Visible = false

local toggleBox = Instance.new("TextBox", frame1)
toggleBox.Size = UDim2.new(0,60,0,20); toggleBox.Position = UDim2.new(0,16,0,60); toggleBox.Text = "F"
toggleBox.Font = Enum.Font.Arcade; toggleBox.TextScaled = true
local tpBox = Instance.new("TextBox", frame1)
tpBox.Size = UDim2.new(0,60,0,20); tpBox.Position = UDim2.new(0,80,0,60); tpBox.Text = "T"
tpBox.Font = Enum.Font.Arcade; tpBox.TextScaled = true

local function parseKeyFromBox(box, assignTo)
    box.FocusLost:Connect(function()
        local s = (box.Text or ""):upper()
        local k = Enum.KeyCode[s]
        if k then
            if assignTo == "toggle" then toggleKey = k end
            if assignTo == "tp" then tpKey = k end
        end
    end)
end
parseKeyFromBox(toggleBox, "toggle")
parseKeyFromBox(tpBox, "tp")

-- Anchor GUI functions
local function setAnchorState(state)
    anchorEnabled = state
    if anchorEnabled then
        storedWalkSpeed, storedJumpPower = hum.WalkSpeed, hum.JumpPower
        hum.WalkSpeed, hum.JumpPower = 0, 0
        mainBtn.Text = "Anchor: ON"
        upBtn.Visible, downBtn.Visible, tpBtn.Visible = true, true, true
        targetPos = root and root.Position or targetPos
    else
        hum.WalkSpeed, hum.JumpPower = storedWalkSpeed or 16, storedJumpPower or 50
        mainBtn.Text = "Anchor: OFF"
        upBtn.Visible, downBtn.Visible, tpBtn.Visible = false, false, false
        vertControl = 0
    end
end

mainBtn.MouseButton1Click:Connect(function() setAnchorState(not anchorEnabled) end)
tpBtn.MouseButton1Click:Connect(function()
    if anchorEnabled and root then
        local cam = Workspace.CurrentCamera
        local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
        targetPos = targetPos + look * 7
        root.CFrame = CFrame.new(targetPos, targetPos + look)
    end
end)

upBtn.MouseButton1Down:Connect(function() vertControl = 1 end)
upBtn.MouseButton1Up:Connect(function() vertControl = 0 end)
downBtn.MouseButton1Down:Connect(function() vertControl = -1 end)
downBtn.MouseButton1Up:Connect(function() vertControl = 0 end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == toggleKey then setAnchorState(not anchorEnabled)
    elseif input.KeyCode == tpKey and anchorEnabled then
        local cam = Workspace.CurrentCamera
        local look = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
        targetPos = targetPos + look * 7
        root.CFrame = CFrame.new(targetPos, targetPos + look)
    elseif input.KeyCode == Enum.KeyCode.Space and anchorEnabled then
        vertControl = 1
    elseif input.KeyCode == Enum.KeyCode.LeftShift and anchorEnabled then
        vertControl = -1
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then vertControl = 0 end
end)

-- keep gui1 enabled according to FastSpeedSteal
buttonStates.FastSpeedSteal.Changed:Connect(function(new)
    gui1.Enabled = new
end)
-- initialize
gui1.Enabled = buttonStates.FastSpeedSteal.Value

-- ---------------- GUI2: Nova GUI ----------------
local function setupNovaGUI(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local originalSpeed = humanoid.WalkSpeed

    local gui2 = Instance.new("ScreenGui")
    gui2.Name = "NovaGUI"
    gui2.ResetOnSpawn = false
    gui2.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui2)
    frame.Size = UDim2.new(0,256,0,286)
    frame.Position = UDim2.new(0.5,-130,0.5,-135)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.Active = true
    frame.Draggable = true
    frame.Visible = false

    local icon = Instance.new("ImageButton", gui2)
    icon.Size = UDim2.new(0,75,0,75)
    icon.Position = UDim2.new(0,50,0,300)
    icon.Image = "rbxassetid://71285066607329"
    local _uc = Instance.new("UICorner", icon); _uc.CornerRadius = UDim.new(0,15)
    icon.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

    local function label(text, pos)
        local l = Instance.new("TextLabel", frame)
        l.Text = text; l.TextScaled = true; l.Font = Enum.Font.Arcade
        l.Size = UDim2.new(0,200,0,50); l.Position = pos
        l.TextColor3 = Color3.fromRGB(39,151,211); l.BackgroundTransparency = 1
    end
    label("Nova Hub", UDim2.new(0,40,0,0)); label("TT: @novahub57", UDim2.new(0,20,0,30)); label("If bag Reset", UDim2.new(0,30,0,50))

    local buttonsRefs = {} -- map BoolValueName -> TextButton

    local function createButton(name, pos, bv, onChange)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0,113,0,50)
        btn.Position = pos
        btn.Font = Enum.Font.Arcade
        btn.TextScaled = true
        btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
        btn.TextColor3 = Color3.new(0,0,0)
        local uc = Instance.new("UICorner", btn); uc.CornerRadius = UDim.new(0,8)

        -- initial
        onChange(bv.Value, btn)
        buttonsRefs[bv.Name] = btn

        btn.MouseButton1Click:Connect(function()
            bv.Value = not bv.Value
            -- onChange will be invoked by bv.Changed listener below as well
        end)

        -- ensure UI updates also if BoolValue changed elsewhere
        bv.Changed:Connect(function(new)
            onChange(new, btn)
        end)

        return btn
    end

    -- Anchor button
    createButton("Anchor OFF", UDim2.new(0,10,0,212), buttonStates.Anchor, function(state, btn)
        hrp.Anchored = state
        if state then btn.Text = "Anchor ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        else btn.Text = "Anchor OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end

        -- Also reflect in GUI1 mainBtn text (so both UIs in sync)
        mainBtn.Text = state and "Anchor: ON" or "Anchor: OFF"
        upBtn.Visible, downBtn.Visible, tpBtn.Visible = state, state, state
    end)

    -- Speed button
    createButton("Speed OFF", UDim2.new(0,130,0,212), buttonStates.Speed, function(state, btn)
        if state then
            humanoid.WalkSpeed = originalSpeed + 20
            btn.Text = "Speed ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        else
            humanoid.WalkSpeed = originalSpeed
            btn.Text = "Speed OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
        end
    end)

    -- Teleport / InstantSteal button (controls BoolValue only)
    createButton("Teleport OFF", UDim2.new(0,10,0,150), buttonStates.Teleport, function(state, btn)
        if state then
            btn.Text = "InstantSteal ON"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        else
            btn.Text = "InstantSteal OFF"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
        end
    end)

    -- Noclip button
    createButton("On Noclip", UDim2.new(0,130,0,150), buttonStates.Noclip, function(state, btn)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not state
            end
        end
        if state then btn.Text = "On Noclip"; btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        else btn.Text = "Off Noclip"; btn.BackgroundColor3 = Color3.fromRGB(150,150,150) end
    end)

    -- Forward Tp button (just toggles bool)
    createButton("Forward Tp wait While Update", UDim2.new(0,130,0,90), buttonStates.ForwardTp, function(state, btn)
        btn.Text = state and "Wait For Update" or "WaitForUpdate"
        btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
    end)

    -- FastSpeedSteal / NoclipBypass button -> controls gui1 visibility
    createButton("Wait While Update", UDim2.new(0,10,0,90), buttonStates.FastSpeedSteal, function(state, btn)
        btn.Text = state and "Wait For Update" or "Wait for update"
        btn.BackgroundColor3 = state and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
        -- control GUI1 visibility
        gui1.Enabled = state
    end)

    -- Teleport interpolation local state
    local teleportInProgress = false
    local teleportTarget = nil
    local teleportProgress = 0
    local teleportSteps = 30

    -- Smooth interpolation
    RunService.RenderStepped:Connect(function(delta)
        if teleportInProgress and teleportTarget and hrp then
            teleportProgress = teleportProgress + delta
            local alpha = math.clamp(teleportProgress / (0.05 * teleportSteps), 0, 1)
            hrp.CFrame = CFrame.new(hrp.Position:Lerp(teleportTarget, alpha))
            if alpha >= 1 then
                teleportInProgress = false
                teleportTarget = nil
                teleportProgress = 0
                -- restore teleport button appearance (do not change BoolValue)
                local tb = buttonsRefs["Teleport"]
                if tb then
                    tb.Text = buttonStates.Teleport.Value and "InstantSteal ON" or "InstantSteal OFF"
                    tb.BackgroundColor3 = buttonStates.Teleport.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
                end
            end
        end
    end)

    -- Helper: find player's owned Plot MultiplierPart
    local function getPlayerPlotTpPart()
        local ok, plotsFolder = pcall(function() return workspace:WaitForChild("Plots") end)
        if not ok or not plotsFolder then return nil end
        for i = 1, 8 do
            local plot = plotsFolder:FindFirstChild("Plot"..i)
            if plot then
                local ownerValue = plot:FindFirstChild("Owner")
                local tpPart = plot:FindFirstChild("MultiplierPart")
                if ownerValue and ownerValue.Value == player.Name and tpPart then
                    return tpPart
                end
            end
        end
        return nil
    end

    -- ProximityPrompt binding: only perform teleport if the Teleport BoolValue is ON
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            prompt.Triggered:Connect(function(triggeringPlayer)
                -- ensure it was this local player who triggered it (ProximityPrompt passes player)
                if triggeringPlayer and triggeringPlayer ~= player then return end

                -- Only proceed when Teleport (InstantSteal) is enabled
                if not buttonStates.Teleport.Value then
                    return
                end

                local tpPart = getPlayerPlotTpPart()
                if not tpPart then return end

                -- compute target and start interpolation
                local offset = Vector3.new(math.random(-3,3), 3, math.random(-3,3))
                teleportTarget = tpPart.Position + offset
                teleportProgress = 0
                teleportInProgress = true

                -- update teleport button appearance locally (but DO NOT change BoolValue)
                local tb = buttonsRefs["Teleport"]
                if tb then
                    tb.Text = "InstantSteal (in progress)"
                    tb.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                end

                -- Temporarily enable Anchor and Noclip if they were off; remember previous states to restore
                local anchorWasOn = buttonStates.Anchor.Value
                local noclipWasOn = buttonStates.Noclip.Value

                if not anchorWasOn then
                    buttonStates.Anchor.Value = true
                    -- hrp.Anchored will be set by Anchor Changed handler (or we can set explicitly)
                end

                if not noclipWasOn then
                    buttonStates.Noclip.Value = true
                    -- parts CanCollide will be set by Noclip Changed handler
                end

                -- wait until teleport interpolation finishes, then restore states (in another thread)
                task.spawn(function()
                    while teleportInProgress do RunService.RenderStepped:Wait() end
                    task.wait(0.1) -- tiny delay to be safe

                    if not anchorWasOn then
                        buttonStates.Anchor.Value = false
                    end
                    if not noclipWasOn then
                        buttonStates.Noclip.Value = false
                    end

                    -- restore teleport button appearance (leave BoolValue intact)
                    if tb then
                        tb.Text = buttonStates.Teleport.Value and "InstantSteal ON" or "InstantSteal OFF"
                        tb.BackgroundColor3 = buttonStates.Teleport.Value and Color3.fromRGB(60,60,60) or Color3.fromRGB(150,150,150)
                    end
                end)
            end)
        end
    end
end

-- initial setup for current character and on respawn
local function onCharacterAdded(c)
    char = c
    hum = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    targetPos = root.Position

    -- When character changes, ensure ButtonValues re-apply (anchor / noclip effects)
    -- Anchor Bool influences hrp.Anchored
    buttonStates.Anchor.Changed:Connect(function(val)
        if root then root.Anchored = val end
        -- also update GUI1 mainBtn text to match
        mainBtn.Text = val and "Anchor: ON" or "Anchor: OFF"
        upBtn.Visible, downBtn.Visible, tpBtn.Visible = val, val, val
    end)
    -- Noclip Bool: set CanCollide on parts
    buttonStates.Noclip.Changed:Connect(function(val)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not val
            end
        end
        -- ensure Nova GUI noclip button (if present) matches; that handler in setupNovaGUI already listens to BoolValue changes
    end)

    -- FastSpeedSteal (Wait While Update) already wired to gui1.Enabled earlier, but if character respawns ensure gui1 still synced:
    gui1.Enabled = buttonStates.FastSpeedSteal.Value

    -- Setup Nova GUI for this character
    setupNovaGUI(char)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

-- Heartbeat: move anchored root according to GUI1 controls
RunService.Heartbeat:Connect(function(dt)
    if anchorEnabled and root and hum then
        local move = hum.MoveDirection
        local hor = Vector3.new(move.X,0,move.Z) * (storedWalkSpeed or hum.WalkSpeed) * dt
        local vert = Vector3.new(0, vertControl * flySpeed * dt, 0)
        targetPos = targetPos + hor + vert
        local camLook = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0,0,-1)
        root.CFrame = CFrame.new(targetPos, targetPos + camLook)
    end
end)
