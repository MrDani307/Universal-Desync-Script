local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrDani307/WindUi/refs/heads/main/main%20(1).lua"))()

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
local char, root, hum, head, cam

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

local pathData = {}
local ghostPart, streamBall, reachCircle = nil, nil, nil
local lastRealCF = CFrame.new()

local function refreshVars(newChar)
    if not newChar then return end
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    head = char:WaitForChild("Head")
    cam = workspace.CurrentCamera
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

local Tab1 = Window:Tab({ Title = "Desync & Modes", Icon = "zap" })
local Tab2 = Window:Tab({ Title = "Combat & Visuals", Icon = "swords" })

Tab1:Toggle({
    Title = "Auto Execute",
    Desc = "Automatically executes on teleport",
    Value = getgenv().AutoExecEnabled,
    Callback = function(v) getgenv().AutoExecEnabled = v; saveAutoExec(v) end
})

Tab1:Toggle({
    Title = "Show Desync Remote",
    Desc = "Show external Desync button",
    Value = false,
    Callback = function(v) r1_sg.Enabled = v end
})

Tab1:Toggle({
    Title = "Show DelDesync Remote",
    Desc = "Show external DelDesync button",
    Value = false,
    Callback = function(v) r2_sg.Enabled = v end
})

Tab1:Toggle({
    Title = "Show Invisible Remote",
    Desc = "Show external Invisible button",
    Value = false,
    Callback = function(v) r3_sg.Enabled = v end
})

Tab1:Toggle({
    Title = "Show Underground Remote",
    Desc = "Show external Underground button",
    Value = false,
    Callback = function(v) r4_sg.Enabled = v end
})

Tab1:Input({
    Title = "DelDesync Delay",
    Desc = "Set stream delay amount (Default: 3)",
    Value = tostring(getgenv().StreamDelay),
    Placeholder = "3",
    Callback = function(t) getgenv().StreamDelay = tonumber(t) or 3 end
})

Tab1:Input({
    Title = "Underground Depth",
    Desc = "Depth in studs (Default: 10)",
    Value = tostring(getgenv().UndergroundDepth),
    Placeholder = "10",
    Callback = function(t) getgenv().UndergroundDepth = tonumber(t) or 10 end
})

Tab2:Toggle({
    Title = "Activate Killaura",
    Desc = "Enable automatic sword attacks",
    Value = false,
    Callback = function(v) getgenv().AuraActive = v end
})

Tab2:Input({
    Title = "Reach Radius",
    Desc = "Aura effective range (Default: 15)",
    Value = tostring(getgenv().ReachRadius),
    Placeholder = "15",
    Callback = function(t) getgenv().ReachRadius = tonumber(t) or 15 end
})

Tab2:Toggle({
    Title = "Highlight Players",
    Desc = "Enable player highlights (ESP)",
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
        local targetPos = getgenv().fakePos or cf
        if not ghostPart then ghostPart = Instance.new("Part", workspace); ghostPart.Size = Vector3.new(4, 6, 1); ghostPart.Color = Color3.fromRGB(0, 255, 150); ghostPart.Material = "Neon"; ghostPart.Transparency = 0.6; ghostPart.Anchored = true; ghostPart.CanCollide = false end
        ghostPart.CFrame = targetPos
        root.CFrame = targetPos; RunService.RenderStepped:Wait(); root.CFrame = cf
    else if ghostPart then ghostPart:Destroy(); ghostPart = nil end end

    if getgenv().StreamOn then
        table.insert(pathData, {cf = cf, t = tick()})
        if #pathData > 0 and tick() - pathData[1].t >= getgenv().StreamDelay then
            local d = table.remove(pathData, 1)
            getgenv().fakePos = d.cf
            if not streamBall then streamBall = Instance.new("Part", workspace); streamBall.Shape = "Ball"; streamBall.Size = Vector3.new(1.5, 1.5, 1.5); streamBall.Color = Color3.fromRGB(0, 150, 255); streamBall.Material = "Neon"; streamBall.Anchored = true; streamBall.CanCollide = false end
            streamBall.CFrame = d.cf
            root.CFrame = d.cf; RunService.RenderStepped:Wait(); root.CFrame = cf
        end
    else if streamBall then streamBall:Destroy(); streamBall = nil end end

    if getgenv().InvisOn then
        local targetPos = getgenv().fakePos or cf
        if not ghostPart then ghostPart = Instance.new("Part", workspace); ghostPart.Size = Vector3.new(4, 6, 1); ghostPart.Color = Color3.fromRGB(255, 50, 50); ghostPart.Material = "Neon"; ghostPart.Transparency = 0.6; ghostPart.Anchored = true; ghostPart.CanCollide = false end
        ghostPart.CFrame = targetPos
        root.CFrame = targetPos; RunService.RenderStepped:Wait(); root.CFrame = cf
    end

    if getgenv().UndergroundOn then
        local undergroundCF = cf * CFrame.new(0, -(getgenv().UndergroundDepth or 10), 0)
        getgenv().fakePos = undergroundCF
        root.CFrame = undergroundCF; RunService.RenderStepped:Wait(); root.CFrame = cf
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

RunService:BindToRenderStep("CamFix", Enum.RenderPriority.Camera.Value + 1, function()
    local isAnyDesyncActive = getgenv().DesyncOn or getgenv().StreamOn or getgenv().InvisOn or getgenv().UndergroundOn

    if isAnyDesyncActive and getgenv().fakePos and cam and root then
        cam.CameraSubject = nil
        local targetOffset = lastRealCF.Position - getgenv().fakePos.Position
        if targetOffset.Magnitude > 0.001 then
            cam.CFrame = cam.CFrame + targetOffset
        end
    end

    if getgenv().UndergroundOn then
        pcall(function()
            local playerModule = require(lp.PlayerScripts:WaitForChild("PlayerModule"))
            local cameraModule = playerModule:GetCameras()
            if cameraModule and cameraModule.activeCameraController then
                if cameraModule.activeCameraController.popper then
                    cameraModule.activeCameraController.popper.canPopper = false
                end
            end
        end)
    end
end)

local function resetDesyncState()
    getgenv().fakePos = nil
    if root then root.CFrame = lastRealCF end
    pcall(function()
        local playerModule = require(lp.PlayerScripts:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local cameraModule = playerModule:GetCameras()
        if cameraModule and cameraModule.activeCameraController then
            if cameraModule.activeCameraController.popper then
                cameraModule.activeCameraController.popper.canPopper = true
            end
        end
    end)
    if hum and cam then
        local savedCamType = cam.CameraType
        local currentCamCF = cam.CFrame
        
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = currentCamCF
        
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        
        task.defer(function()
            cam.CameraSubject = hum
            cam.CameraType = savedCamType
            cam.CFrame = currentCamCF
        end)
    end
end

lp.OnTeleport:Connect(function(State)
    local qot = getQueue()
    if getgenv().AutoExecEnabled and qot and (State == Enum.TeleportState.Started or State == Enum.TeleportState.InProgress) then
        qot("loadstring(game:HttpGet('https://raw.githubusercontent.com/MrDani307/Universal-Desync-Script/main/Desync.lua'))()")
    end
end)

Players.PlayerAdded:Connect(applyEsp)

r1_btn.MouseButton1Click:Connect(function() 
    getgenv().DesyncOn = not getgenv().DesyncOn
    r1_btn.Text = "DESYNC: "..(getgenv().DesyncOn and "ON" or "OFF")
    if getgenv().DesyncOn then 
        getgenv().fakePos = root.CFrame 
    else
        resetDesyncState()
    end 
end)

r2_btn.MouseButton1Click:Connect(function() 
    getgenv().StreamOn = not getgenv().StreamOn
    r2_btn.Text = "DELDESYNC: "..(getgenv().StreamOn and "ON" or "OFF")
    if not getgenv().StreamOn then
        pathData = {}
        resetDesyncState()
    end
end)

r3_btn.MouseButton1Click:Connect(function() 
    getgenv().InvisOn = not getgenv().InvisOn
    r3_btn.Text = "INVIS: "..(getgenv().InvisOn and "ON" or "OFF")
    if getgenv().InvisOn then
        getgenv().fakePos = root.CFrame * CFrame.new(0, -500, 0)
    else
        resetDesyncState()
    end
end)

r4_btn.MouseButton1Click:Connect(function() 
    getgenv().UndergroundOn = not getgenv().UndergroundOn
    r4_btn.Text = "UNDERGROUND: "..(getgenv().UndergroundOn and "ON" or "OFF")
    if not getgenv().UndergroundOn then
        resetDesyncState()
    end
end)

WindUI:Notify({
    Title = "Desync",
    Content = "Created by Daniil.",
    Duration = 5
})
