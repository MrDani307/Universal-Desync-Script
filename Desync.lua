local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Desync",
   LoadingTitle = "Open Source",
   LoadingSubtitle = "by Daniil",
   ConfigurationSaving = { Enabled = false }
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local char, root, hum, cam

getgenv().AuraActive = false
getgenv().ReachRadius = 15
getgenv().DesyncOn = false
getgenv().StreamOn = false
getgenv().InvisOn = false
getgenv().EspActive = false
getgenv().StreamDelay = 3
getgenv().fakePos = nil

local pathData = {}
local ghostPart = nil
local streamBall = nil
local reachCircle = nil
local lastRealCF = CFrame.new()
local camAnchor = Instance.new("Part")
camAnchor.Transparency = 1; camAnchor.CanCollide = false; camAnchor.Anchored = true; camAnchor.Parent = workspace

local originalTransparency = {}

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
            local highlight = pChar:FindFirstChild("GlowthosHighlight") or Instance.new("Highlight")
            highlight.Name = "GlowthosHighlight"
            highlight.Parent = pChar
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.FillColor = player.TeamColor.Color
            highlight.OutlineColor = Color3.new(1, 1, 1)
        end
    end
    player.CharacterAdded:Connect(createHighlight)
    if player.Character then createHighlight() end
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function createRemote(name, color, yPos)
    local sg = Instance.new("ScreenGui", CoreGui); sg.Enabled = false; sg.Name = name.."_Gui"
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

local Tab1 = Window:CreateTab("Main", 4483362458)
local Tab2 = Window:CreateTab("DelDesync", 4483362458)
local Tab3 = Window:CreateTab("invisible", 4483362458)
local Tab4 = Window:CreateTab("swordKillaura", 4483362458)
local Tab5 = Window:CreateTab("Esp", 4483362458)

Tab1:CreateButton({Name = "Show Desync Remote", Callback = function() r1_sg.Enabled = true end})
Tab1:CreateButton({Name = "Hide Desync Remote", Callback = function() r1_sg.Enabled = false end})

Tab2:CreateButton({Name = "Show DelDesync Remote", Callback = function() r2_sg.Enabled = true end})
Tab2:CreateButton({Name = "Hide DelDesync Remote", Callback = function() r2_sg.Enabled = false end})
Tab2:CreateInput({Name = "Delay Amount", PlaceholderText = "3", Callback = function(t) getgenv().StreamDelay = tonumber(t) or 3 end})

Tab3:CreateButton({Name = "Show invisible Remote", Callback = function() r3_sg.Enabled = true end})
Tab3:CreateButton({Name = "Hide invisible Remote", Callback = function() r3_sg.Enabled = false end})

Tab4:CreateToggle({Name = "Activate Killaura", CurrentValue = false, Callback = function(v) getgenv().AuraActive = v end})
Tab4:CreateInput({Name = "Reach Radius", PlaceholderText = "15", Callback = function(t) getgenv().ReachRadius = tonumber(t) or 15 end})

Tab5:CreateToggle({Name = "Highlight Players", CurrentValue = false, Callback = function(v) 
    getgenv().EspActive = v 
    if v then for _, p in pairs(Players:GetPlayers()) do applyEsp(p) end else
        for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("GlowthosHighlight") then p.Character.GlowthosHighlight:Destroy() end end
    end
end})

RunService.Heartbeat:Connect(function()
    if not root or not char then return end
    local cf = root.CFrame
    lastRealCF = cf
    if getgenv().DesyncOn then
        if not ghostPart then
            ghostPart = Instance.new("Part", workspace); ghostPart.Size = Vector3.new(4, 6, 1); ghostPart.Color = Color3.fromRGB(0, 255, 150); ghostPart.Material = "Neon"; ghostPart.Transparency = 0.6; ghostPart.Anchored = true; ghostPart.CanCollide = false
        end
        ghostPart.CFrame = getgenv().fakePos or cf; root.CFrame = getgenv().fakePos or cf
        RunService.RenderStepped:Wait(); root.CFrame = cf
    else if ghostPart then ghostPart:Destroy(); ghostPart = nil end end
    if getgenv().StreamOn then
        table.insert(pathData, {cf = cf, t = tick()})
        if #pathData > 0 and tick() - pathData[1].t >= getgenv().StreamDelay then
            local data = table.remove(pathData, 1)
            if not streamBall then
                streamBall = Instance.new("Part", workspace); streamBall.Shape = "Ball"; streamBall.Size = Vector3.new(1.5, 1.5, 1.5); streamBall.Color = Color3.fromRGB(0, 150, 255); streamBall.Material = "Neon"; streamBall.Anchored = true; streamBall.CanCollide = false
            end
            streamBall.CFrame = data.cf; root.CFrame = data.cf
            RunService.RenderStepped:Wait(); root.CFrame = cf
        end
    else if streamBall then streamBall:Destroy(); streamBall = nil end end
    if getgenv().InvisOn then
        root.CFrame = cf * CFrame.new(0, -100000, 0)
        RunService.RenderStepped:Wait(); root.CFrame = cf
        for _, v in pairs(char:GetDescendants()) do if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then v.Transparency = 0.3 end end
    else
        for part, trans in pairs(originalTransparency) do if part and part.Parent then part.Transparency = trans end end
    end
end)

RunService.RenderStepped:Connect(function()
    if not root or not getgenv().AuraActive then if reachCircle then reachCircle:Destroy(); reachCircle = nil end return end
    if not reachCircle then
        reachCircle = Instance.new("Part", workspace); reachCircle.Shape = "Ball"; reachCircle.Material = "ForceField"; reachCircle.Color = Color3.fromRGB(255, 50, 50); reachCircle.Transparency = 0.7; reachCircle.CastShadow = false; reachCircle.CanCollide = false; reachCircle.Anchored = true
    end
    reachCircle.Size = Vector3.new(getgenv().ReachRadius*2, getgenv().ReachRadius*2, getgenv().ReachRadius*2); reachCircle.CFrame = root.CFrame
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")) then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and (root.Position - tRoot.Position).Magnitude <= getgenv().ReachRadius then
                    tool:Activate()
                    for _, part in pairs(p.Character:GetChildren()) do if part:IsA("BasePart") then firetouchinterest(handle, part, 0); firetouchinterest(handle, part, 1) end end
                end
            end
        end
    end
end)

RunService:BindToRenderStep("CamFix", 201, function()
    if not cam or not hum then return end
    if getgenv().DesyncOn or getgenv().StreamOn or getgenv().InvisOn then
        camAnchor.CFrame = lastRealCF * CFrame.new(0, 1.5, 0); cam.CameraSubject = camAnchor
    else cam.CameraSubject = hum end
end)

Players.PlayerAdded:Connect(applyEsp)
r1_btn.MouseButton1Click:Connect(function() getgenv().DesyncOn = not getgenv().DesyncOn; r1_btn.Text = "DESYNC: "..(getgenv().DesyncOn and "ON" or "OFF"); if getgenv().DesyncOn then getgenv().fakePos = root.CFrame end end)
r2_btn.MouseButton1Click:Connect(function() getgenv().StreamOn = not getgenv().StreamOn; r2_btn.Text = "DELDESYNC: "..(getgenv().StreamOn and "ON" or "OFF") end)
r3_btn.MouseButton1Click:Connect(function() getgenv().InvisOn = not getgenv().InvisOn; r3_btn.Text = "INVIS: "..(getgenv().InvisOn and "ON" or "OFF") end)

Rayfield:Notify({Title = "Desync", Content = "Created by Daniil.", Duration = 5})
