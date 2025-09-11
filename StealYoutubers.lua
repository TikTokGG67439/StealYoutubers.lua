local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local TpPartName = "MultiplierPart"

-- Состояния вынесены на уровень скрипта, чтобы сохранялись при ресете
local anchorOnly = false
local speedMode = false
local gravityActive = false
local teleportActive = false
local teleportTarget = nil
local teleportProgress = 0
local teleportSteps = 15
local originalSpeed = 16
local humanoid = nil
local hrp = nil

-- GUI создаём один раз
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("AnchoredGUI")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnchoredGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 256, 0, 286)
    frame.Position = UDim2.new(0.5, -110, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Active = true
    frame.Draggable = true
    local uiframe = Instance.new("UICorner")
    uiframe.CornerRadius = UDim.new(0, 20)
    uiframe.Parent = frame

    -- Лейблы
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

    -- Кнопки
    local function createButton(name, pos, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 113, 0, 50)
        btn.Position = pos
        btn.TextScaled = true
        btn.Font = Enum.Font.Arcade
        btn.BackgroundColor3 = Color3.fromRGB(103, 103, 103)
        btn.TextColor3 = Color3.new(0,0,0)
        btn.Text = name
        local uic = Instance.new("UICorner")
        uic.CornerRadius = UDim.new(0,8)
        uic.Parent = btn
        btn.Parent = parent
        return btn
    end

    btn1 = createButton("Anchor OFF", UDim2.new(0,10,0,212), frame)
    btn2 = createButton("Speed OFF", UDim2.new(0,130,0,212), frame)
    btn3 = createButton("Teleport OFF", UDim2.new(0,10,0,150), frame)
    btn4 = createButton("On Noclip", UDim2.new(0,130,0,150), frame)
    btn5 = createButton("Forward Tp wait While Update", UDim2.new(0,130,0,90), frame)
    btn6 = createButton("Maybe Fast Speed With Steal", UDim2.new(0,10,0,90), frame)
end

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

-- Основная настройка персонажа
local function setupCharacter(char)
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    originalSpeed = humanoid.WalkSpeed

    -- Сохраняем состояния при ресете
    hrp.Anchored = anchorOnly
    humanoid.WalkSpeed = speedMode and originalSpeed + 20 or originalSpeed
    if speedMode then gravityActive = true end

    -- Anchor
    btn1.MouseButton1Click:Connect(function()
        anchorOnly = not anchorOnly
        hrp.Anchored = anchorOnly
        if anchorOnly then
            btn1.Text = "Anchor ON"
            btn1.BackgroundColor3 = Color3.fromRGB(50,50,50)
        else
            btn1.Text = "Anchor OFF"
            btn1.BackgroundColor3 = Color3.fromRGB(103,103,103)
        end
    end)

    -- Speed
    btn2.MouseButton1Click:Connect(function()
        speedMode = not speedMode
        if speedMode then
            btn2.Text = "Speed ON"
            btn2.BackgroundColor3 = Color3.fromRGB(30,30,30)
            humanoid.WalkSpeed = originalSpeed + 20
            gravityActive = true
        else
            btn2.Text = "Speed OFF"
            btn2.BackgroundColor3 = Color3.fromRGB(103,103,103)
            humanoid.WalkSpeed = originalSpeed
            gravityActive = false
        end
    end)

    -- Teleport
    btn3.MouseButton1Click:Connect(function()
        teleportActive = not teleportActive
        if teleportActive then
            btn3.Text = "Teleport ON"
            btn3.BackgroundColor3 = Color3.fromRGB(30,30,30)
        else
            teleportTarget = nil
            teleportProgress = 0
            btn3.Text = "Teleport OFF"
            btn3.BackgroundColor3 = Color3.fromRGB(103,103,103)
        end
    end)

    -- Noclip
    btn4.MouseButton1Click:Connect(function()
        if not char then return end
        if hrp.CanCollide then
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
