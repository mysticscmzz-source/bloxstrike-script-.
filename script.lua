-- Bloxstrike Aimbot + ESP + RGB GUI
-- Execute with any executor that supports Drawing + mousemoverel

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Settings = {
    Enabled = true,
    TeamCheck = true,
    VisibleCheck = true,
    FOV = 150,
    Smoothness = 0.14,
    AimPart = "Head",          -- "Head" or "HumanoidRootPart"
    ShowFOV = true,
    ShowESP = true,
    Keybind = Enum.KeyCode.E,  -- toggle aimbot
    GUIKey = Enum.KeyCode.RightShift
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.8
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.FOV
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(0, 255, 170)
FOVCircle.Transparency = 0.25
FOVCircle.Visible = false

local ESPObjects = {}

local function GetClosestTarget()
    local closest = nil
    local shortest = Settings.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")

            if humanoid and humanoid.Health > 0 and root then
                if Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    continue
                end

                local part = (Settings.AimPart == "Head" and head) or root
                if not part then continue end

                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < shortest then
                        if Settings.VisibleCheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
                            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                            local origin = Camera.CFrame.Position
                            local direction = (part.Position - origin).Unit * 1000
                            local result = workspace:Raycast(origin, direction, rayParams)
                            if result and result.Instance and not result.Instance:IsDescendantOf(char) then
                                continue
                            end
                        end
                        shortest = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function AimAt(target)
    if not target then return end
    local targetPos = Camera:WorldToViewportPoint(target.Position)
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local delta = Vector2.new(targetPos.X, targetPos.Y) - mousePos
    local move = delta * Settings.Smoothness
    mousemoverel(move.X, move.Y)
end

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Box then obj.Box:Remove() end
        if obj.Name then obj.Name:Remove() end
        if obj.Tracer then obj.Tracer:Remove() end
    end
    table.clear(ESPObjects)
end

local function UpdateESP()
    ClearESP()
    if not Settings.ShowESP then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    continue
                end

                local box = Drawing.new("Square")
                box.Thickness = 1
                box.Filled = false
                box.Color = Color3.fromRGB(0, 255, 170)
                box.Transparency = 0.15
                box.Visible = true

                local nameTag = Drawing.new("Text")
                nameTag.Size = 14
                nameTag.Center = true
                nameTag.Outline = true
                nameTag.Color = Color3.fromRGB(255, 255, 255)
                nameTag.Text = player.Name
                nameTag.Visible = true

                local tracer = Drawing.new("Line")
                tracer.Thickness = 1
                tracer.Color = Color3.fromRGB(0, 255, 170)
                tracer.Transparency = 0.4
                tracer.Visible = true

                ESPObjects[player] = {
                    Box = box,
                    Name = nameTag,
                    Tracer = tracer,
                    Root = root
                }
            end
        end
    end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    -- FOV
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.ShowFOV and Settings.Enabled

    -- Auto lock
    if Settings.Enabled then
        local target = GetClosestTarget()
        if target then
            AimAt(target)
        end
    end

    -- ESP update positions
    local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    for player, data in pairs(ESPObjects) do
        if data.Root and data.Root.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(data.Root.Position)
            if onScreen then
                local size = math.clamp(2200 / pos.Z, 8, 120)
                data.Box.Size = Vector2.new(size * 0.65, size)
                data.Box.Position = Vector2.new(pos.X - data.Box.Size.X / 2, pos.Y - data.Box.Size.Y / 2)
                data.Box.Visible = true

                data.Name.Position = Vector2.new(pos.X, pos.Y - data.Box.Size.Y / 2 - 16)
                data.Name.Visible = true

                data.Tracer.From = screenBottom
                data.Tracer.To = Vector2.new(pos.X, pos.Y + data.Box.Size.Y / 2)
                data.Tracer.Visible = true
            else
                data.Box.Visible = false
                data.Name.Visible = false
                data.Tracer.Visible = false
            end
        else
            data.Box.Visible = false
            data.Name.Visible = false
            data.Tracer.Visible = false
        end
    end
end)

-- Refresh ESP periodically
task.spawn(function()
    while true do
        UpdateESP()
        task.wait(1.2)
    end
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Keybind then
        Settings.Enabled = not Settings.Enabled
    elseif input.KeyCode == Settings.GUIKey then
        if ScreenGui then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end
end)

-- ==================== RGB GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxstrikeAimbot"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 390)
Main.Position = UDim2.new(0.5, -160, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Main

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Transparency = 0.15
UIStroke.Parent = Main

local Accent, Title
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.45) % 360
    local rgb = Color3.fromHSV(hue / 360, 0.85, 1)
    UIStroke.Color = rgb
    if Accent then Accent.BackgroundColor3 = rgb end
    if Title then Title.TextColor3 = rgb end
    FOVCircle.Color = rgb
end)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLOXSTRIKE  •  AUTO LOCK"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 2)
Accent.Position = UDim2.new(0, 0, 1, -2)
Accent.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
Accent.BorderSizePixel = 0
Accent.Parent = TitleBar

local function CreateToggle(name, y, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -24, 0, 30)
    holder.Position = UDim2.new(0, 12, 0, y)
    holder.BackgroundTransparency = 1
    holder.Parent = Main

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 22)
    btn.Position = UDim2.new(1, -52, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 110) or Color3.fromRGB(35, 35, 45)
    btn.Text = default and "ON" or "OFF"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = holder

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 110) or Color3.fromRGB(35, 35, 45)
        callback(state)
    end)
end

CreateToggle("Auto Lock", 50, Settings.Enabled, function(v) Settings.Enabled = v end)
CreateToggle("Team Check", 88, Settings.TeamCheck, function(v) Settings.TeamCheck = v end)
CreateToggle("Visible Check", 126, Settings.VisibleCheck, function(v) Settings.VisibleCheck = v end)
CreateToggle("Show FOV", 164, Settings.ShowFOV, function(v) Settings.ShowFOV = v end)
CreateToggle("Show ESP", 202, Settings.ShowESP, function(v)
    Settings.ShowESP = v
    UpdateESP()
end)

-- FOV Slider
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -24, 0, 18)
FOVLabel.Position = UDim2.new(0, 12, 0, 245)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV: " .. Settings.FOV
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.TextSize = 13
FOVLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Parent = Main

local FOVSlider = Instance.new("TextButton")
FOVSlider.Size = UDim2.new(1, -24, 0, 8)
FOVSlider.Position = UDim2.new(0, 12, 0, 268)
FOVSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
FOVSlider.Text = ""
FOVSlider.AutoButtonColor = false
FOVSlider.Parent = Main

Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(0, 4)

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new(Settings.FOV / 300, 0, 1, 0)
FOVFill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
FOVFill.BorderSizePixel = 0
FOVFill.Parent = FOVSlider
Instance.new("UICorner", FOVFill).CornerRadius = UDim.new(0, 4)

local dragFOV = false
FOVSlider.MouseButton1Down:Connect(function() dragFOV = true end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragFOV = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragFOV and i.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = math.clamp((i.Position.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
        Settings.FOV = math.floor(rel * 300)
        FOVFill.Size = UDim2.new(rel, 0, 1, 0)
        FOVLabel.Text = "FOV: " .. Settings.FOV
        FOVCircle.Radius = Settings.FOV
    end
end)

-- Smoothness Slider
local SmoothLabel = Instance.new("TextLabel")
SmoothLabel.Size = UDim2.new(1, -24, 0, 18)
SmoothLabel.Position = UDim2.new(0, 12, 0, 290)
SmoothLabel.BackgroundTransparency = 1
SmoothLabel.Text = "Smoothness: " .. string.format("%.2f", Settings.Smoothness)
SmoothLabel.Font = Enum.Font.Gotham
SmoothLabel.TextSize = 13
SmoothLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
SmoothLabel.TextXAlignment = Enum.TextXAlignment.Left
SmoothLabel.Parent = Main

local SmoothSlider = Instance.new("TextButton")
SmoothSlider.Size = UDim2.new(1, -24, 0, 8)
SmoothSlider.Position = UDim2.new(0, 12, 0, 313)
SmoothSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
SmoothSlider.Text = ""
SmoothSlider.AutoButtonColor = false
SmoothSlider.Parent = Main
Instance.new("UICorner", SmoothSlider).CornerRadius = UDim.new(0, 4)

local SmoothFill = Instance.new("Frame")
SmoothFill.Size = UDim2.new(Settings.Smoothness, 0, 1, 0)
SmoothFill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
SmoothFill.BorderSizePixel = 0
SmoothFill.Parent = SmoothSlider
Instance.new("UICorner", SmoothFill).CornerRadius = UDim.new(0, 4)

local dragSmooth = false
SmoothSlider.MouseButton1Down:Connect(function() dragSmooth = true end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSmooth = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragSmooth and i.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = math.clamp((i.Position.X - SmoothSlider.AbsolutePosition.X) / SmoothSlider.AbsoluteSize.X, 0.05, 1)
        Settings.Smoothness = math.floor(rel * 100) / 100
        SmoothFill.Size = UDim2.new(rel, 0, 1, 0)
        SmoothLabel.Text = "Smoothness: " .. string.format("%.2f", Settings.Smoothness)
    end
end)

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, -24, 0, 18)
Footer.Position = UDim2.new(0, 12, 1, -26)
Footer.BackgroundTransparency = 1
Footer.Text = "E = Toggle  |  RightShift = Menu"
Footer.Font = Enum.Font.Gotham
Footer.TextSize = 11
Footer.TextColor3 = Color3.fromRGB(90, 90, 100)
Footer.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -34, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(40, 18, 18)
Close.Text = "×"
Close.Font = Enum.Font.GothamBold
Close.TextSize = 18
Close.TextColor3 = Color3.fromRGB(255, 90, 90)
Close.Parent = TitleBar
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

Close.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

print("[Bloxstrike] Auto Lock + ESP + RGB GUI loaded")
