--[[
    Auto Wall Hop Script (Versão Suave e Natural)
    - Flick mais lento e natural (Interpolação suave)
    - Câmera mexe muito menos (ângulo reduzido)
    - Botão de arrastar mantido
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- --- UI da Tela ---
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoWallHopGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local TextButton = Instance.new("TextButton")
TextButton.Name = "WallHopToggleButton"
TextButton.Size = UDim2.new(0, 140, 0, 50)
TextButton.Position = UDim2.new(0.1, 0, 0.7, 0)
TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextButton.Text = "Wall Hop Off"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.Font = Enum.Font.GothamBold
TextButton.TextScaled = true
TextButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = TextButton

-- --- Lógica ---
local isWallHopEnabled = false
local isFlicking = false
local lastFlickTime = 0
local Camera = workspace.CurrentCamera

-- Flick mais suave e menos invasivo
local function performSmoothFlick()
    if isFlicking then return end
    isFlicking = true
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then isFlicking = false return end

    -- 1. Executa o Pulo
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    
    -- 2. Impulso vertical (pode diminuir o '50' se ainda achar que sobe muito rápido)
    hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)

    -- 3. Movimento de câmera suave e com ângulo menor
    local startCFrame = Camera.CFrame
    -- Gira apenas 60 graus (muito menos que os 180 originais)
    local targetCFrame = startCFrame * CFrame.Angles(0, math.rad(60), 0) 
    
    -- Animação de ida (suave)
    for i = 1, 5 do
        Camera.CFrame = startCFrame:Lerp(targetCFrame, i/5)
        task.wait(0.01)
    end
    
    -- Pausa minúscula para registrar no jogo
    task.wait(0.02) 
    
    -- Animação de volta (suave)
    for i = 1, 5 do
        Camera.CFrame = targetCFrame:Lerp(startCFrame, i/5)
        task.wait(0.01)
    end
    
    -- Garante que a câmera termine exatamente onde começou
    Camera.CFrame = startCFrame
    
    isFlicking = false
end

-- Detectar a parede
local lastHitInstance = nil
RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Raios para detectar a parede à frente
    local result = workspace:Raycast(hrp.Position, Camera.CFrame.LookVector * 3, raycastParams)

    if result and result.Instance.CanCollide then
        -- Se detectou uma mudança de bloco (costura da parede)
        if lastHitInstance and lastHitInstance ~= result.Instance then
            -- Aumentei o tempo de recarga (0.3s) para evitar que ele fique tremendo
            if tick() - lastFlickTime > 0.3 then 
                lastFlickTime = tick()
                performSmoothFlick()
            end
        end
        lastHitInstance = result.Instance
    else
        lastHitInstance = nil
    end
end)

-- Trocar estado no botão
TextButton.MouseButton1Click:Connect(function()
    isWallHopEnabled = not isWallHopEnabled
    TextButton.Text = isWallHopEnabled and "Wall Hop On" or "Wall Hop Off"
    TextButton.BackgroundColor3 = isWallHopEnabled and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(0, 0, 0)
end)

-- --- Arrastar UI ---
local dragging, dragStart, startPos
TextButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = TextButton.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        TextButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("Smooth Auto Wall Hop Loaded!")
