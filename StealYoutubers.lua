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
    frame.Size = UDim2.new(0, 220, 0, 150)
    frame.Position = UDim2.new(0.5, -110, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.Active = true
    frame.Draggable = true

    -- Кнопка 1: Anchor
    local btn1 = Instance.new("TextButton", frame)
    btn1.Size = UDim2.new(0, 200, 0, 40)
    btn1.Position = UDim2.new(0, 10, 0, 10)
    btn1.Text = "Anchor OFF"
    btn1.BackgroundColor3 = Color3.fromRGB(255,0,0)
    btn1.TextColor3 = Color3.new(1,1,1)
    btn1.MouseButton1Click:Connect(function()
        anchorOnly = not anchorOnly
        hrp.Anchored = anchorOnly -- просто управляем hrp.Anchored
        if anchorOnly then
            btn1.Text = "Anchor ON"
            btn1.BackgroundColor3 = Color3.fromRGB(0,255,0)
        else
            btn1.Text = "Anchor OFF"
            btn1.BackgroundColor3 = Color3.fromRGB(255,0,0)
        end
    end)

    -- Кнопка 2: Speed
    local btn2 = Instance.new("TextButton", frame)
    btn2.Size = UDim2.new(0, 200, 0, 40)
    btn2.Position = UDim2.new(0, 10, 0, 60)
    btn2.Text = "Speed OFF"
    btn2.BackgroundColor3 = Color3.fromRGB(255,0,0)
    btn2.TextColor3 = Color3.new(1,1,1)
    btn2.MouseButton1Click:Connect(function()
        speedMode = not speedMode
        if speedMode then
            btn2.Text = "Speed ON"
            btn2.BackgroundColor3 = Color3.fromRGB(0,255,0)
            humanoid.WalkSpeed = originalSpeed + 5
            gravityActive = true
        else
            btn2.Text = "Speed OFF"
            btn2.BackgroundColor3 = Color3.fromRGB(255,0,0)
            humanoid.WalkSpeed = originalSpeed
            gravityActive = false
        end
    end)

    -- Кнопка 3: Teleport
    local btn3 = Instance.new("TextButton", frame)
    btn3.Size = UDim2.new(0, 200, 0, 40)
    btn3.Position = UDim2.new(0, 10, 0, 110)
    btn3.Text = "Teleport OFF"
    btn3.BackgroundColor3 = Color3.fromRGB(255,0,0)
    btn3.TextColor3 = Color3.new(1,1,1)
    btn3.MouseButton1Click:Connect(function()
        teleportActive = not teleportActive
        if not teleportActive then
            -- Отмена телепортации
            teleportTarget = nil
            teleportProgress = 0
            btn3.Text = "Teleport OFF"
            btn3.BackgroundColor3 = Color3.fromRGB(255,0,0)
        else
            -- Подготовка к телепорту (ProximityPrompt запускает позже)
            btn3.Text = "Teleport ON"
            btn3.BackgroundColor3 = Color3.fromRGB(0,255,0)
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
