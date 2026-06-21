local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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

local isWallHopEnabled = false
local isFlicking = false
local lastFlickTime = 0
local Camera = workspace.CurrentCamera

local function performSmoothFlick()
    if isFlicking then return end
    isFlicking = true
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then isFlicking = false return end

    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    
    hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)

    local startCFrame = Camera.CFrame
    local targetCFrame = startCFrame * CFrame.Angles(0, math.rad(60), 0) 
    
    for i = 1, 5 do
        Camera.CFrame = startCFrame:Lerp(targetCFrame, i/5)
        task.wait(0.01)
    end
    
    task.wait(0.02) 
    
    for i = 1, 5 do
        Camera.CFrame = targetCFrame:Lerp(startCFrame, i/5)
        task.wait(0.01)
    end
    
    Camera.CFrame = startCFrame
    
    isFlicking = false
end

local lastHitInstance = nil
RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(hrp.Position, Camera.CFrame.LookVector * 3, raycastParams)

    if result and result.Instance.CanCollide then
        if lastHitInstance and lastHitInstance ~= result.Instance then
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

TextButton.MouseButton1Click:Connect(function()
    isWallHopEnabled = not isWallHopEnabled
    TextButton.Text = isWallHopEnabled and "Wall Hop On" or "Wall Hop Off"
    TextButton.BackgroundColor3 = isWallHopEnabled and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(0, 0, 0)
end)

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
