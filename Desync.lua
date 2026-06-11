local WindUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/MrDani307/WindUi/refs/heads/main/WindUi.lua'))()

local Window = WindUI:CreateWindow({
    Title = "Desync",
    Icon = "code",
    Author = "by Daniil",
    Theme = "Dark",
    Size = UDim2.fromOffset(550, 400),
    Transparent = false,
    HasOutline = true,
    Folder = "DesyncConfig"
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local char, root, hum, cam

local function getQueue()
    return (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or (exploit and exploit.queue_on_teleport)
end

local function saveAutoExec(state)
    pcall(function() writefile("DesyncAutoExec.txt", tostring(state)) end)
end

local function loadAutoExec()
    local success, result = pcall(function()
        if isfile("DesyncAutoExec.txt") then
            return readfile("DesyncAutoExec.txt") == "true"
        end
        return false
    end)
    return success and result or false
end

getgenv().AutoExecEnabled = loadAutoExec()
getgenv().AuraActive = false
getgenv().ReachRadius = 15
getgenv().DesyncOn = false
getgenv().StreamOn = false
getgenv().InvisOn = false
getgenv().UndergroundOn = false
getgenv().EspActive = false
getgenv().StreamDelay = 3
getgenv().fakePos = nil
getgenv().UndergroundDepth = 10

local pathData, originalTransparency = {}, {}
local ghostPart, streamBall, reachCircle = nil, nil, nil
local lastRealCF = CFrame.new()
local camAnchor = Instance.new("Part")
camAnchor.Transparency = 1; camAnchor.CanCollide = false; camAnchor.Anchored = true; camAnchor.Parent = workspace

local function refreshVars(newChar)
    if not newChar then return end
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    cam = workspace.CurrentCamera
    originalTransparency = {}
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then originalTransparency[v] = v.Transparency end
    end
end
if lp.Character then refreshVars(lp.Character) end
lp.CharacterAdded:Connect(refreshVars)

local function applyEsp(player)
    if player == lp then return end
    local function createHighlight()
        if not getgenv().EspActive then return end
        local pChar = player.Character
        if pChar then
            local h = pChar:FindFirstChild("GlowHighlight") or Instance.new("Highlight")
            h.Name = "GlowHighlight"; h.Parent = pChar; h.FillTransparency = 0.5; h.OutlineTransparency = 0
            h.FillColor = player.TeamColor.Color; h.OutlineColor = Color3.new(1, 1, 1)
        end
    end
    player.CharacterAdded:Connect(createHighlight)
    if player.Character then createHighlight() end
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function createRemote(name, color, yPos)
    local sg = Instance.new("ScreenGui", CoreGui); sg.Enabled = false
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 140, 0, 60); main.Position = UDim2.new(0.5, -70, yPos, 0)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20); main.BackgroundTransparency = 0.3; main.Active = true
    Instance.new("UICorner", main); Instance.new("UIStroke", main).Color = color
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0, 126, 0, 42); btn.Position = UDim2.new(0.05, 0, 0.15, 0)
    btn.Text = name .. ": OFF"; btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    makeDraggable(main)
    return sg, btn
end

local r1_sg, r1_btn = createRemote("DESYNC", Color3.fromRGB(0, 255, 150), 0.1)
local r2_sg, r2_btn = createRemote("DELDESYNC", Color3.fromRGB(0, 150, 255), 0.2)
local r3_sg, r3_btn = createRemote("INVIS", Color3.fromRGB(255, 50, 50), 0.3)
local r4_sg, r4_btn = createRemote("UNDERGROUND", Color3.fromRGB(255, 150, 0), 0.4)

local Tab1 = Window:Tab({ Title = "Main", Icon = "home" })
local Tab2 = Window:Tab({ Title = "DelDesync", Icon = "zap" })
local Tab3 = Window:Tab({ Title = "Invisible", Icon = "eye-off" })
local Tab4 = Window:Tab({ Title = "Sword Killaura", Icon = "swords" })
local Tab5 = Window:Tab({ Title = "ESP", Icon = "user" })

Tab1:Toggle({
    Title = "Auto Execute",
    Desc = "Automatically executes on teleport",
    Value = getgenv().AutoExecEnabled,
    Callback = function(v) getgenv().AutoExecEnabled = v; saveAutoExec(v) end
})

Tab1:Button({
    Title = "Show Desync Remote",
    Desc = "Show the external Desync button",
    Callback = function() r1_sg.Enabled = true end
})

Tab1:Button({
    Title = "Hide Desync Remote",
    Desc = "Hide the external Desync button",
    Callback = function() r1_sg.Enabled = false end
})

Tab2:Button({
    Title = "Show DelDesync Remote",
    Desc = "Show the external DelDesync button",
    Callback = function() r2_sg.Enabled = true end
})

Tab2:Button({
    Title = "Hide DelDesync Remote",
    Desc = "Hide the external DelDesync button",
    Callback = function() r2_sg.Enabled = false end
})

Tab2:Input({
    Title = "Delay Amount",
    Desc = "Set delay amount (Default: 3)",
    Value = tostring(getgenv().StreamDelay),
    Placeholder = "3",
    Callback = function(t) getgenv().StreamDelay = tonumber(t) or 3 end
})

Tab3:Button({
    Title = "Show Invisible Remote",
    Desc = "Show the external Invisible button",
    Callback = function() r3_sg.Enabled = true end
})

Tab3:Button({
    Title = "Hide Invisible Remote",
    Desc = "Hide the external Invisible button",
    Callback = function() r3_sg.Enabled = false end
})

Tab3:Button({
    Title = "Show Underground Remote",
    Desc = "Show the external Underground Desync button",
    Callback = function() r4_sg.Enabled = true end
})

Tab3:Button({
    Title = "Hide Underground Remote",
    Desc = "Hide the external Underground Desync button",
    Callback = function() r4_sg.Enabled = false end
})

Tab3:Input({
    Title = "Underground Depth",
    Desc = "Глубина ухода под землю в студсах (Default: 10)",
    Value = tostring(getgenv().UndergroundDepth),
    Placeholder = "10",
    Callback = function(t) getgenv().UndergroundDepth = tonumber(t) or 10 end
})

Tab4:Toggle({
    Title = "Activate Killaura",
    Desc = "Enable automatic sword attacks",
    Value = false,
    Callback = function(v) getgenv().AuraActive = v end
})

Tab4:Input({
    Title = "Reach Radius",
    Desc = "Aura effective range (Default: 15)",
    Value = tostring(getgenv().ReachRadius),
    Placeholder = "15",
    Callback = function(t) getgenv().ReachRadius = tonumber(t) or 15 end
})

Tab5:Toggle({
    Title = "Highlight Players",
    Desc = "Enable player highlights (Wallhack)",
    Value = false,
    Callback = function(v) 
        getgenv().EspActive = v 
        if v then 
            for _, p in pairs(Players:GetPlayers()) do applyEsp(p) end 
        else
            for _, p in pairs(Players:GetPlayers()) do 
                if p.Character and p.Character:FindFirstChild("GlowHighlight") then 
                    p.Character.GlowHighlight:Destroy() 
                end 
            end
        end
    end
})

RunService.Heartbeat:Connect(function()
    if not root or not char then return end
    local cf = root.CFrame; lastRealCF = cf
    if getgenv().DesyncOn then
        if not ghostPart then ghostPart = Instance.new("Part", workspace); ghostPart.Size = Vector3.new(4, 6, 1); ghostPart.Color = Color3.fromRGB(0, 255, 150); ghostPart.Material = "Neon"; ghostPart.Transparency = 0.6; ghostPart.Anchored = true; ghostPart.CanCollide = false end
        ghostPart.CFrame = getgenv().fakePos or cf; root.CFrame = getgenv().fakePos or cf; RunService.RenderStepped:Wait(); root.CFrame = cf
    else if ghostPart then ghostPart:Destroy(); ghostPart = nil end end
    if getgenv().StreamOn then
        table.insert(pathData, {cf = cf, t = tick()})
        if #pathData > 0 and tick() - pathData[1].t >= getgenv().StreamDelay then
            local d = table.remove(pathData, 1)
            if not streamBall then streamBall = Instance.new("Part", workspace); streamBall.Shape = "Ball"; streamBall.Size = Vector3.new(1.5, 1.5, 1.5); streamBall.Color = Color3.fromRGB(0, 150, 255); streamBall.Material = "Neon"; streamBall.Anchored = true; streamBall.CanCollide = false end
            streamBall.CFrame = d.cf; root.CFrame = d.cf; RunService.RenderStepped:Wait(); root.CFrame = cf
        end
    else if streamBall then streamBall:Destroy(); streamBall = nil end end
    if getgenv().InvisOn then
        root.CFrame = cf * CFrame.new(0, -100000, 0); RunService.RenderStepped:Wait(); root.CFrame = cf
        for _, v in pairs(char:GetDescendants()) do if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then v.Transparency = 0.3 end end
    else for part, trans in pairs(originalTransparency) do if part and part.Parent then part.Transparency = trans end end end
    if getgenv().UndergroundOn then
        root.CFrame = cf * CFrame.new(0, -(getgenv().UndergroundDepth or 10), 0); RunService.RenderStepped:Wait(); root.CFrame = cf
    end
end)

RunService.RenderStepped:Connect(function()
    if not root or not getgenv().AuraActive then if reachCircle then reachCircle:Destroy(); reachCircle = nil end return end
    if not reachCircle then reachCircle = Instance.new("Part", workspace); reachCircle.Shape = "Ball"; reachCircle.Material = "ForceField"; reachCircle.Color = Color3.fromRGB(255, 50, 50); reachCircle.Transparency = 0.7; reachCircle.CanCollide = false; reachCircle.Anchored = true end
    reachCircle.Size = Vector3.new(getgenv().ReachRadius*2, getgenv().ReachRadius*2, getgenv().ReachRadius*2); reachCircle.CFrame = root.CFrame
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")) then
        local h = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local t = p.Character:FindFirstChild("HumanoidRootPart")
                if t and (root.Position - t.Position).Magnitude <= getgenv().ReachRadius then
                    tool:Activate()
                    for _, pt in pairs(p.Character:GetChildren()) do if pt:IsA("BasePart") then firetouchinterest(h, pt, 0); firetouchinterest(h, pt, 1) end end
                end
            end
        end
    end
end)

RunService:BindToRenderStep("CamFix", 201, function()
    if not cam or not hum then return end
    if getgenv().DesyncOn or getgenv().StreamOn or getgenv().InvisOn or getgenv().UndergroundOn then camAnchor.CFrame = lastRealCF * CFrame.new(0, 1.5, 0); cam.CameraSubject = camAnchor else cam.CameraSubject = hum end
end)

lp.OnTeleport:Connect(function(State)
    local qot = getQueue()
    if getgenv().AutoExecEnabled and qot and (State == Enum.TeleportState.Started or State == Enum.TeleportState.InProgress) then
        qot("loadstring(game:HttpGet('https://raw.githubusercontent.com/MrDani307/Universal-Desync-Script/main/Desync.lua'))()")
    end
end)

Players.PlayerAdded:Connect(applyEsp)
r1_btn.MouseButton1Click:Connect(function() getgenv().DesyncOn = not getgenv().DesyncOn; r1_btn.Text = "DESYNC: "..(getgenv().DesyncOn and "ON" or "OFF"); if getgenv().DesyncOn then getgenv().fakePos = root.CFrame end end)
r2_btn.MouseButton1Click:Connect(function() getgenv().StreamOn = not getgenv().StreamOn; r2_btn.Text = "DELDESYNC: "..(getgenv().StreamOn and "ON" or "OFF") end)
r3_btn.MouseButton1Click:Connect(function() getgenv().InvisOn = not getgenv().InvisOn; r3_btn.Text = "INVIS: "..(getgenv().InvisOn and "ON" or "OFF") end)
r4_btn.MouseButton1Click:Connect(function() getgenv().UndergroundOn = not getgenv().UndergroundOn; r4_btn.Text = "UNDERGROUND: "..(getgenv().UndergroundOn and "ON" or "OFF") end)

WindUI:Notify({
    Title = "Desync",
    Content = "Created by Daniil.",
    Duration = 5
})
