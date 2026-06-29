--[[
    ================================================================
    [ SCRIPT INFORMATION ]
    Project: Custom Script
    Author: OYB
    YouTube: https://www.youtube.com/channel/UCAlXXV1Hbvf7WbfXARuVtiQ
    
    [ TERMS AND CONDITIONS ]
    - You ARE allowed to use and modify this script for your own games.
    - You ARE NOT allowed to re-upload, redistribute, or claim 
      ownership of this script.
    - Removing or altering these credits is strictly prohibited.
    
    Copyright (c) 2026 OYB. All rights reserved.
    ================================================================
]]

-- ⚠️ IMPORTANT: Put this code at the VERY TOP of your Main Script (before obfuscating) ⚠️

local ProtectionConfig = {
    -- 🔴 CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "1234",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "Regret Hub"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end

-------------------------------------------------------------------------------
-- 👇 YOUR MAIN SCRIPT CODE STARTS HERE 👇
-------------------------------------------------------------------------------

print(ProtectionConfig.HubName .. " Loaded Successfully!")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========== CONFIG ==========
local Config = {
    Enabled = false,
    TPOffset = 3.5,
    TriggerDistance = 40,
    Cooldown = 0.12,
    TeamCheck = true, -- always on, not exposed in GUI
    AutoShoot = false,
    AutoShootCPS = 10,
    LookAtTarget = true,
    LookAtHead = true,
    ToggleKey = Enum.KeyCode.RightShift,
    RageKey = Enum.KeyCode.T,
}

local lastTP = 0
local lastShot = 0
local rebinding = false
local rebindingRage = false

-- ========== UTILITY ==========
local function getChar(p) return p and p.Character end
local function getRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p)
    local c = getChar(p); local h = getHum(c)
    return c and h and h.Health > 0
end

local function sameTeam(p)
    return p.Team ~= nil and p.Team == LocalPlayer.Team
end

local function getNearestEnemy()
    local myChar = getChar(LocalPlayer)
    local myRoot = getRoot(myChar)
    if not myRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) and not sameTeam(p) then
            local root = getRoot(getChar(p))
            if root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < nearestDist and d <= Config.TriggerDistance then
                    nearest, nearestDist = p, d
                end
            end
        end
    end
    return nearest
end

local function getBehindCF(targetRoot, offset)
    return targetRoot.CFrame * CFrame.new(0, 0, offset)
end

local function lookAtTarget(targetChar)
    if not Config.LookAtTarget then return end
    local part = Config.LookAtHead
        and (targetChar:FindFirstChild("Head") or getRoot(targetChar))
        or getRoot(targetChar)
    if part then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    end
end

local function tryShoot()
    if not Config.AutoShoot then return end
    local now = tick()
    local interval = 1 / Config.AutoShootCPS
    if now - lastShot < interval then return end
    lastShot = now
    local char = getChar(LocalPlayer)
    if not char then return end
    mouse1press()
    task.delay(0.05, mouse1release)
end

-- ========== CORE LOOP ==========
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    local now = tick()
    if now - lastTP < Config.Cooldown then return end

    local target = getNearestEnemy()
    if not target then return end

    local myChar = getChar(LocalPlayer)
    local myRoot = getRoot(myChar)
    if not myRoot then return end

    local targetRoot = getRoot(getChar(target))
    if not targetRoot then return end

    myRoot.CFrame = getBehindCF(targetRoot, Config.TPOffset)
    lookAtTarget(getChar(target))
    tryShoot()
    lastTP = now
end)

-- ========== GUI SETUP ==========
if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UE_RageBot") then
    LocalPlayer.PlayerGui.UE_RageBot:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UE_RageBot"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Palette
local C = {
    BG       = Color3.fromRGB(12, 12, 18),
    Panel    = Color3.fromRGB(18, 18, 26),
    Accent   = Color3.fromRGB(98, 0, 238),
    AccentHi = Color3.fromRGB(130, 60, 255),
    Border   = Color3.fromRGB(70, 0, 180),
    Text     = Color3.fromRGB(220, 220, 235),
    SubText  = Color3.fromRGB(130, 130, 155),
    On       = Color3.fromRGB(98, 0, 238),
    Off      = Color3.fromRGB(35, 35, 48),
    Red      = Color3.fromRGB(200, 30, 60),
}

-- ========== DELTA-STYLE OPEN BADGE ==========
local Badge = Instance.new("TextButton")
Badge.Name = "OpenBadge"
Badge.Size = UDim2.new(0, 42, 0, 42)
Badge.Position = UDim2.new(0, 16, 0.5, -21)
Badge.BackgroundColor3 = C.Panel
Badge.Text = "R"
Badge.TextColor3 = C.AccentHi
Badge.Font = Enum.Font.GothamBlack
Badge.TextSize = 20
Badge.BorderSizePixel = 0
Badge.Visible = false
Badge.ZIndex = 20
Badge.Parent = ScreenGui

local badgeCorner = Instance.new("UICorner", Badge)
badgeCorner.CornerRadius = UDim.new(0, 8)

local badgeStroke = Instance.new("UIStroke", Badge)
badgeStroke.Color = C.Border
badgeStroke.Thickness = 1.5

-- pulse glow on badge
local badgeGlow = Instance.new("UIStroke", Badge)
badgeGlow.Color = C.AccentHi
badgeGlow.Thickness = 0
TweenService:Create(badgeGlow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 2.5}):Play()

-- ========== MAIN WINDOW ==========
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 310, 0, 510)
Main.Position = UDim2.new(0, 24, 0.5, -255)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner", Main)
mainCorner.CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = C.Border
mainStroke.Thickness = 1.2

-- touch drag support for mobile
local dragging = false
local dragStart = nil
local startPos = nil

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ========== HEADER ==========
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = C.Panel
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local HeaderPatch = Instance.new("Frame")
HeaderPatch.Size = UDim2.new(1, 0, 0, 10)
HeaderPatch.Position = UDim2.new(0, 0, 1, -10)
HeaderPatch.BackgroundColor3 = C.Panel
HeaderPatch.BorderSizePixel = 0
HeaderPatch.Parent = Header

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0, 14, 0.5, -4)
Dot.BackgroundColor3 = C.AccentHi
Dot.BorderSizePixel = 0
Dot.Parent = Header
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 30, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Regret v1.0"
Title.TextColor3 = C.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(0, 80, 1, 0)
Sub.Position = UDim2.new(1, -88, 0, 0)
Sub.BackgroundTransparency = 1
Sub.Text = "RageBot"
Sub.TextColor3 = C.AccentHi
Sub.Font = Enum.Font.GothamBold
Sub.TextSize = 11
Sub.TextXAlignment = Enum.TextXAlignment.Right
Sub.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -15)
CloseBtn.BackgroundColor3 = C.Red
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Badge.Visible = true
end)
CloseBtn.TouchTap:Connect(function()
    Main.Visible = false
    Badge.Visible = true
end)

Badge.MouseButton1Click:Connect(function()
    Badge.Visible = false
    Main.Visible = true
end)
Badge.TouchTap:Connect(function()
    Badge.Visible = false
    Main.Visible = true
end)

-- ========== SCROLL CONTENT ==========
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -42)
Scroll.Position = UDim2.new(0, 0, 0, 42)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ScrollingEnabled = true
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

local Padding = Instance.new("UIPadding", Scroll)
Padding.PaddingLeft = UDim.new(0, 10)
Padding.PaddingRight = UDim.new(0, 10)
Padding.PaddingTop = UDim.new(0, 10)
Padding.PaddingBottom = UDim.new(0, 10)

-- ========== COMPONENT BUILDERS ==========
local order = 0
local function nextOrder() order += 1 return order end

local function makeSection(label)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder = nextOrder()
    f.Parent = Scroll

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = C.Border
    line.BorderSizePixel = 0
    line.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundColor3 = C.BG
    lbl.Text = "  " .. label .. "  "
    lbl.TextColor3 = C.AccentHi
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Parent = f
end

local function makeToggle(labelText, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 40)
    Row.BackgroundColor3 = C.Panel
    Row.BorderSizePixel = 0
    Row.LayoutOrder = nextOrder()
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.65, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = labelText
    Lbl.TextColor3 = C.Text
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local Pill = Instance.new("TextButton")
    Pill.Size = UDim2.new(0, 50, 0, 26)
    Pill.Position = UDim2.new(1, -60, 0.5, -13)
    Pill.BackgroundColor3 = default and C.On or C.Off
    Pill.Text = ""
    Pill.BorderSizePixel = 0
    Pill.Parent = Row
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 20, 0, 20)
    Knob.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Pill
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = default

    local function toggle()
        state = not state
        local goal = state and C.On or C.Off
        local kGoal = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        TweenService:Create(Pill, TweenInfo.new(0.15), {BackgroundColor3 = goal}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {Position = kGoal}):Play()
        callback(state)
    end

    Pill.MouseButton1Click:Connect(toggle)
    Pill.TouchTap:Connect(toggle)

    return Row, function(v)
        state = v
        local goal = state and C.On or C.Off
        local kGoal = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        TweenService:Create(Pill, TweenInfo.new(0.15), {BackgroundColor3 = goal}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {Position = kGoal}):Play()
    end
end

-- Mobile-friendly slider using both mouse and touch
local function makeSlider(labelText, min, max, default, suffix, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 60)
    Row.BackgroundColor3 = C.Panel
    Row.BorderSizePixel = 0
    Row.LayoutOrder = nextOrder()
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.65, 0, 0, 22)
    Lbl.Position = UDim2.new(0, 12, 0, 6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = labelText
    Lbl.TextColor3 = C.Text
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.new(0.35, -12, 0, 22)
    Val.Position = UDim2.new(0.65, 0, 0, 6)
    Val.BackgroundTransparency = 1
    Val.Text = tostring(default) .. (suffix or "")
    Val.TextColor3 = C.AccentHi
    Val.Font = Enum.Font.GothamBold
    Val.TextSize = 13
    Val.TextXAlignment = Enum.TextXAlignment.Right
    Val.Parent = Row

    -- Larger touch track area
    local TrackHitbox = Instance.new("TextButton")
    TrackHitbox.Size = UDim2.new(1, -24, 0, 28)
    TrackHitbox.Position = UDim2.new(0, 12, 0, 30)
    TrackHitbox.BackgroundTransparency = 1
    TrackHitbox.Text = ""
    TrackHitbox.BorderSizePixel = 0
    TrackHitbox.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, 0, 0, 8)
    Track.Position = UDim2.new(0, 0, 0.5, -4)
    Track.BackgroundColor3 = C.Off
    Track.BorderSizePixel = 0
    Track.Parent = TrackHitbox
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    local initPct = (default - min) / (max - min)
    Fill.Size = UDim2.new(initPct, 0, 1, 0)
    Fill.BackgroundColor3 = C.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 20, 0, 20)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new(initPct, 0, 0.5, 0)
    Knob.BackgroundColor3 = C.AccentHi
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 3
    Knob.Parent = Track
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local sliderActive = false

    local function updateFromX(x)
        local abs = Track.AbsolutePosition
        local sz = Track.AbsoluteSize
        local rel = math.clamp((x - abs.X) / sz.X, 0, 1)
        local val = math.floor(min + rel * (max - min))
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        Val.Text = tostring(val) .. (suffix or "")
        callback(val)
    end

    -- Mouse support
    TrackHitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderActive = true
            updateFromX(i.Position.X)
        end
    end)

    -- Touch support
    TrackHitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            sliderActive = true
            updateFromX(i.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliderActive = false
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if not sliderActive then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            updateFromX(i.Position.X)
        end
    end)
end

local function makeKeybind(labelText, currentKey, isRage, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 40)
    Row.BackgroundColor3 = C.Panel
    Row.BorderSizePixel = 0
    Row.LayoutOrder = nextOrder()
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.52, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = labelText
    Lbl.TextColor3 = C.Text
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size = UDim2.new(0, 118, 0, 26)
    KeyBtn.Position = UDim2.new(1, -126, 0.5, -13)
    KeyBtn.BackgroundColor3 = C.Off
    KeyBtn.Text = currentKey.Name
    KeyBtn.TextColor3 = C.AccentHi
    KeyBtn.Font = Enum.Font.GothamBold
    KeyBtn.TextSize = 12
    KeyBtn.BorderSizePixel = 0
    KeyBtn.Parent = Row
    Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 5)

    local function startRebind()
        if rebinding or rebindingRage then return end
        if isRage then rebindingRage = true else rebinding = true end
        KeyBtn.Text = "[ Press Key ]"
        KeyBtn.TextColor3 = Color3.fromRGB(255, 220, 60)

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if isRage then rebindingRage = false else rebinding = false end
            conn:Disconnect()
            if isRage then
                Config.RageKey = input.KeyCode
            else
                Config.ToggleKey = input.KeyCode
            end
            KeyBtn.Text = input.KeyCode.Name
            KeyBtn.TextColor3 = C.AccentHi
            callback(input.KeyCode)
        end)
    end

    KeyBtn.MouseButton1Click:Connect(startRebind)
    KeyBtn.TouchTap:Connect(startRebind)
end

local function makeStatus()
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = C.Panel
    Row.BorderSizePixel = 0
    Row.LayoutOrder = nextOrder()
    Row.Parent = Scroll
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Dot2 = Instance.new("Frame")
    Dot2.Size = UDim2.new(0, 8, 0, 8)
    Dot2.Position = UDim2.new(0, 10, 0.5, -4)
    Dot2.BackgroundColor3 = C.SubText
    Dot2.BorderSizePixel = 0
    Dot2.Parent = Row
    Instance.new("UICorner", Dot2).CornerRadius = UDim.new(1, 0)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -28, 1, 0)
    Lbl.Position = UDim2.new(0, 26, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = "Idle"
    Lbl.TextColor3 = C.SubText
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    RunService.Heartbeat:Connect(function()
        if Config.Enabled then
            local t = getNearestEnemy()
            if t then
                Lbl.Text = "Locked → " .. t.Name
                Lbl.TextColor3 = Color3.fromRGB(100, 255, 130)
                Dot2.BackgroundColor3 = Color3.fromRGB(100, 255, 130)
            else
                Lbl.Text = "Scanning..."
                Lbl.TextColor3 = Color3.fromRGB(255, 200, 60)
                Dot2.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
            end
        else
            Lbl.Text = "Disabled"
            Lbl.TextColor3 = C.SubText
            Dot2.BackgroundColor3 = C.SubText
        end
    end)
end

-- ========== BUILD UI ==========

makeSection("RAGEBOT")
local _, setRageToggle = makeToggle("Rage", false, function(v) Config.Enabled = v end)
makeKeybind("Rage Key  [default: T]", Config.RageKey, true, function(k) Config.RageKey = k end)

makeSection("TELEPORT")
makeSlider("Behind Offset", 1, 10, 3, " st", function(v) Config.TPOffset = v end)
makeSlider("Trigger Range", 10, 200, 40, " st", function(v) Config.TriggerDistance = v end)
makeSlider("Cooldown", 50, 500, 120, " ms", function(v) Config.Cooldown = v / 1000 end)

makeSection("AIM")
makeToggle("Lock Cam to Target", true, function(v) Config.LookAtTarget = v end)
makeToggle("Aim at Head", true, function(v) Config.LookAtHead = v end)

makeSection("MENU KEYBIND")
makeKeybind("Toggle Menu", Config.ToggleKey, false, function(k) Config.ToggleKey = k end)

makeSection("STATUS")
makeStatus()

-- ========== KEYBOARD TOGGLE ==========
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if rebinding or rebindingRage then return end

    -- Toggle menu
    if input.KeyCode == Config.ToggleKey then
        local visible = not Main.Visible
        Main.Visible = visible
        Badge.Visible = not visible
    end

    -- Toggle rage via RageKey
    if input.KeyCode == Config.RageKey then
        Config.Enabled = not Config.Enabled
        setRageToggle(Config.Enabled)
    end
end)
