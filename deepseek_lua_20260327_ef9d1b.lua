-- H2N V9.8 | Full Features | Auto Save Everything
repeat task.wait() until game:IsLoaded()
if not game.PlaceId then repeat task.wait(1) until game.PlaceId end

pcall(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name and (v.Name:find("H2N_WP_") or v.Name:find("H2N_Duel_")) then
            v:Destroy()
        end
    end
end)

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- متغيرات أساسية
local Char, HRP, Hum

local function Setup(c)
    Char = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Hum = c:WaitForChild("Humanoid")
    pcall(function() HRP:SetNetworkOwner(LP) end)
end

if LP.Character then Setup(LP.Character) end
LP.CharacterAdded:Connect(function(c) task.wait(0.1); Setup(c) end)

-- ====== STATE (كل الميزات) ======
local State = {
    -- Combat
    AutoTrack = false,
    AutoPlayLeft = false,
    AutoPlayRight = false,
    AutoGrab = false,
    AntiSentry = false,
    SpinBody = false,
    -- Protect
    AntiRagdoll = false,
    InfiniteJump = false,
    DuelTP = false,
    FloatEnabled = false,
    Unwalk = false,
    -- Visual
    ESP = false,
    XrayBase = false,
    -- Settings
    SpeedBoost = false,
}

-- ====== إعدادات قابلة للتعديل ======
local Settings = {
    TRACK_SPEED = 35,
    GRAB_RATE = 0.06,
    GRAB_RADIUS = 10,
    DUEL_APPROACH_SPD = 60,
    DUEL_RETURN_SPD = 29,
    FloatHeight = 11,
    SPIN_SPEED = 25,
    XRAY_TRANSPARENCY = 0.68,
    DETECTION_DISTANCE = 60,
    PULL_DISTANCE = -5,
    SPEED_BOOST_VALUE = 60,
}

-- نقاط المبارزة
local DuelPoints = {
    L1 = Vector3.new(-475, -5, 94),
    L2 = Vector3.new(-484, -4, 92),
    R1 = Vector3.new(-476, -6, 26),
    R2 = Vector3.new(-484, -4, 27),
}

-- نقاط النقل لـ Ragdoll TP
local TP_POINTS = {
    LEFT = {DuelPoints.L1, DuelPoints.L2},
    RIGHT = {DuelPoints.R1, DuelPoints.R2},
}

-- ====== RAGDOLL TP ======
local DuelTP = {
    Active = false,
    TargetSide = "RIGHT",
    LastTPTime = 0,
    Cooldown = 2,
}

-- ====== ANTI RAGDOLL (من Plasma) ======
local antiRagdollConn = nil
local antiRagdollActive = false

local function StartAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollActive = true
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollActive then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        
        if hum then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Physics or 
               state == Enum.HumanoidStateType.Ragdoll or 
               state == Enum.HumanoidStateType.FallingDown then
                
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                
                if root then
                    root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then
                obj.Enabled = true
            end
        end
    end)
end

local function StopAntiRagdoll()
    antiRagdollActive = false
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end

-- ====== AUTO DUES (الأصلي) ======
local aplConn, aprConn = nil, nil
local aplPhase, aprPhase = 1, 1
local LEFT_ROUTE = {"L1","L2","L1","R1","R2"}
local RIGHT_ROUTE = {"R1","R2","R1","L1","L2"}

local function getWP(name)
    if name == "L1" then return DuelPoints.L1
    elseif name == "L2" then return DuelPoints.L2
    elseif name == "R1" then return DuelPoints.R1
    elseif name == "R2" then return DuelPoints.R2
    end
end

local function getHRP2() 
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") 
end

local function MoveToPoint(hrp, targetPos, speed)
    if not hrp or not targetPos then return true end
    local distance = (targetPos - hrp.Position).Magnitude
    if distance < 1.2 then
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        return true
    end
    local direction = (targetPos - hrp.Position).Unit
    hrp.AssemblyLinearVelocity = Vector3.new(direction.X * speed, hrp.AssemblyLinearVelocity.Y, direction.Z * speed)
    return false
end

local function StopAutoPlayLeft()
    State.AutoPlayLeft = false
    if aplConn then aplConn:Disconnect(); aplConn = nil end
    aplPhase = 1
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
end

local function StopAutoPlayRight()
    State.AutoPlayRight = false
    if aprConn then aprConn:Disconnect(); aprConn = nil end
    aprPhase = 1
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
end

local function updateAutoPlayLeft()
    if not State.AutoPlayLeft then return end
    local h = getHRP2()
    if not h then return end
    local spd = (aplPhase <= 2) and Settings.DUEL_APPROACH_SPD or Settings.DUEL_RETURN_SPD
    local target = LEFT_ROUTE[aplPhase]
    if target then
        if MoveToPoint(h, getWP(target), spd) then
            aplPhase = aplPhase + 1
            if aplPhase > #LEFT_ROUTE then StopAutoPlayLeft() end
        end
    else
        StopAutoPlayLeft()
    end
end

local function updateAutoPlayRight()
    if not State.AutoPlayRight then return end
    local h = getHRP2()
    if not h then return end
    local spd = (aprPhase <= 2) and Settings.DUEL_APPROACH_SPD or Settings.DUEL_RETURN_SPD
    local target = RIGHT_ROUTE[aprPhase]
    if target then
        if MoveToPoint(h, getWP(target), spd) then
            aprPhase = aprPhase + 1
            if aprPhase > #RIGHT_ROUTE then StopAutoPlayRight() end
        end
    else
        StopAutoPlayRight()
    end
end

local function StartAutoPlayLeft()
    StopAutoPlayLeft()
    StopAutoPlayRight()
    State.AutoPlayLeft = true
    aplPhase = 1
    if Hum then Hum.AutoRotate = false end
end

local function StartAutoPlayRight()
    StopAutoPlayRight()
    StopAutoPlayLeft()
    State.AutoPlayRight = true
    aprPhase = 1
    if Hum then Hum.AutoRotate = false end
end

-- ====== RAGDOLL TP (معدل) ======
local function setPhaseFromPoint(side, startPoint)
    if side == "LEFT" then
        if startPoint == "L2" then aplPhase = 2
        elseif startPoint == "L1" then aplPhase = 1
        elseif startPoint == "R1" then aplPhase = 4
        elseif startPoint == "R2" then aplPhase = 5
        else aplPhase = 1 end
    else
        if startPoint == "R2" then aprPhase = 2
        elseif startPoint == "R1" then aprPhase = 1
        elseif startPoint == "L1" then aprPhase = 4
        elseif startPoint == "L2" then aprPhase = 5
        else aprPhase = 1 end
    end
end

local function teleportSequence(side)
    local now = tick()
    if now - DuelTP.LastTPTime < DuelTP.Cooldown then return false, nil end
    
    local points = TP_POINTS[side]
    if not points or not points[1] or not points[2] then return false, nil end
    
    local char = LP.Character
    if not char then return false, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, nil end
    
    hrp.CFrame = CFrame.new(points[1])
    task.wait(0.1)
    hrp.CFrame = CFrame.new(points[2])
    DuelTP.LastTPTime = tick()
    task.wait(0.1)
    
    return true, points[2]
end

local function onRagdollHit()
    if not State.DuelTP then return false end
    
    local side = DuelTP.TargetSide
    local success, finalPoint = teleportSequence(side)
    
    if success and finalPoint then
        local pointName = (side == "LEFT") and "L2" or "R2"
        
        if side == "LEFT" then
            if State.AutoPlayLeft then StopAutoPlayLeft() end
            if State.AutoPlayRight then StopAutoPlayRight() end
            State.AutoPlayLeft = true
            setPhaseFromPoint("LEFT", pointName)
            if Hum then Hum.AutoRotate = false end
            Notify("⚡ TP → " .. pointName)
        else
            if State.AutoPlayLeft then StopAutoPlayLeft() end
            if State.AutoPlayRight then StopAutoPlayRight() end
            State.AutoPlayRight = true
            setPhaseFromPoint("RIGHT", pointName)
            if Hum then Hum.AutoRotate = false end
            Notify("⚡ TP → " .. pointName)
        end
        return true
    end
    return false
end

local duelTPConn = nil
local function startDuelTP()
    State.DuelTP = true
    if duelTPConn then duelTPConn:Disconnect() end
    duelTPConn = RunService.Heartbeat:Connect(function()
        if not State.DuelTP then
            if duelTPConn then duelTPConn:Disconnect(); duelTPConn = nil end
            return
        end
        
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Ragdoll or
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.Physics then
            onRagdollHit()
        end
    end)
end

local function stopDuelTP()
    State.DuelTP = false
    if duelTPConn then duelTPConn:Disconnect(); duelTPConn = nil end
end

local function setTargetManual(side)
    DuelTP.TargetSide = side
    Notify("Ragdoll TP: " .. (side == "LEFT" and "← LEFT" or "RIGHT →"))
end

-- ====== FLOAT ======
local FloatConn = nil

local function startFloat()
    if FloatConn then return end
    State.FloatEnabled = true
    FloatConn = RunService.Heartbeat:Connect(function()
        if not State.FloatEnabled or not HRP then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
        local groundY = result and result.Position.Y or (hrp.Position.Y - Settings.FloatHeight)
        local targetY = groundY + Settings.FloatHeight
        local diff = targetY - hrp.Position.Y
        
        if diff > 0.3 then
            local upSpeed = math.min(diff * 12, 25)
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, upSpeed, hrp.AssemblyLinearVelocity.Z)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end)
end

local function stopFloat()
    State.FloatEnabled = false
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
end

-- ====== UNWALK ======
local savedAnimations = {}

local function StartUnwalk()
    if State.Unwalk then return end
    State.Unwalk = true
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            t:Stop()
        end
    end
    local anim = char:FindFirstChild("Animate")
    if anim then
        savedAnimations.Animate = anim:Clone()
        anim:Destroy()
    end
end

local function StopUnwalk()
    State.Unwalk = false
    local char = LP.Character
    if char and savedAnimations.Animate then
        savedAnimations.Animate:Clone().Parent = char
        savedAnimations.Animate = nil
    end
end

-- ====== INFINITE JUMP ======
local jumpConn = nil
local function StartInfiniteJump()
    State.InfiniteJump = true
    if jumpConn then return end
    jumpConn = UIS.JumpRequest:Connect(function()
        if not State.InfiniteJump or not HRP or not Hum then return end
        if Hum:GetState() == Enum.HumanoidStateType.Dead then return end
        local v = HRP.AssemblyLinearVelocity
        HRP.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
    end)
end

local function StopInfiniteJump()
    State.InfiniteJump = false
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
end

-- ====== AUTO TRACK ======
local trackConn = nil

local function GetClosestPlayer()
    if not HRP then return nil end
    local closest, best = nil, 9999
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if r and hum and hum.Health > 0 then
                local d = (HRP.Position - r.Position).Magnitude
                if d < best then best = d; closest = r end
            end
        end
    end
    return closest
end

local function StartAutoTrack()
    State.AutoTrack = true
    if trackConn then trackConn:Disconnect() end
    trackConn = RunService.Heartbeat:Connect(function()
        if not State.AutoTrack or not HRP then return end
        local target = GetClosestPlayer()
        if target then
            local dir = target.Position - HRP.Position
            local flatDir = Vector3.new(dir.X, 0, dir.Z)
            if flatDir.Magnitude > 1 then
                HRP.AssemblyLinearVelocity = flatDir.Unit * Settings.TRACK_SPEED
            end
        else
            HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
        end
    end)
end

local function StopAutoTrack()
    State.AutoTrack = false
    if trackConn then trackConn:Disconnect(); trackConn = nil end
    if HRP then HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end
end

-- ====== SPEED BOOST ======
local speedBoostConn = nil

local function StartSpeedBoost()
    State.SpeedBoost = true
    if speedBoostConn then return end
    speedBoostConn = RunService.Heartbeat:Connect(function()
        if not State.SpeedBoost then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            root.AssemblyLinearVelocity = Vector3.new(moveDir.X * Settings.SPEED_BOOST_VALUE, root.AssemblyLinearVelocity.Y, moveDir.Z * Settings.SPEED_BOOST_VALUE)
        end
    end)
end

local function StopSpeedBoost()
    State.SpeedBoost = false
    if speedBoostConn then
        speedBoostConn:Disconnect()
        speedBoostConn = nil
    end
end

-- ====== SPIN BODY ======
local spinForce = nil

local function StartSpinBody()
    State.SpinBody = true
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or spinForce then return end
    spinForce = Instance.new("BodyAngularVelocity")
    spinForce.Name = "SpinForce"
    spinForce.AngularVelocity = Vector3.new(0, Settings.SPIN_SPEED, 0)
    spinForce.MaxTorque = Vector3.new(0, math.huge, 0)
    spinForce.P = 1250
    spinForce.Parent = root
end

local function StopSpinBody()
    State.SpinBody = false
    if spinForce then spinForce:Destroy(); spinForce = nil end
end

-- ====== ANTI SENTRY ======
local antiSentryTarget = nil

local function findSentryTarget()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local ownerId = obj.Name:match("Sentry_(%d+)")
            if ownerId and tonumber(ownerId) == LP.UserId then
                -- skip own sentry
            else
                local part = (obj:IsA("BasePart") and obj) or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                if part and (rootPos - part.Position).Magnitude <= Settings.DETECTION_DISTANCE then
                    return obj
                end
            end
        end
    end
end

local function moveSentry(obj)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in pairs(obj:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    local root = char.HumanoidRootPart
    local cf = root.CFrame * CFrame.new(0, 0, Settings.PULL_DISTANCE)
    if obj:IsA("BasePart") then
        obj.CFrame = cf
    elseif obj:IsA("Model") then
        local m = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if m then m.CFrame = cf end
    end
end

local function getWeapon()
    local char = LP.Character
    if not char then return nil end
    return LP.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
end

local function attackSentry()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local weapon = getWeapon()
    if not weapon then return end
    if weapon.Parent == LP.Backpack then hum:EquipTool(weapon); task.wait(0.1) end
    pcall(function() weapon:Activate() end)
    for _, r in pairs(weapon:GetDescendants()) do
        if r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
    end
end

local function StartAntiSentry()
    State.AntiSentry = true
    task.spawn(function()
        while State.AntiSentry do
            if antiSentryTarget and antiSentryTarget.Parent == workspace then
                moveSentry(antiSentryTarget)
                attackSentry()
            else
                antiSentryTarget = findSentryTarget()
            end
            task.wait(0.5)
        end
    end)
end

local function StopAntiSentry()
    State.AntiSentry = false
    antiSentryTarget = nil
end

-- ====== XRAY ======
local baseOT = {}
local plotConns = {}
local xrayCon = nil

local function applyXray(plot)
    if baseOT[plot] then return end
    baseOT[plot] = {}
    for _, p in ipairs(plot:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 0.6 then
            baseOT[plot][p] = p.Transparency
            p.Transparency = Settings.XRAY_TRANSPARENCY
        end
    end
    plotConns[plot] = plot.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Transparency < 0.6 then
            baseOT[plot][d] = d.Transparency
            d.Transparency = Settings.XRAY_TRANSPARENCY
        end
    end)
end

local function StartXrayBase()
    State.XrayBase = true
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        applyXray(plot)
    end
    xrayCon = plots.ChildAdded:Connect(function(p)
        task.wait(0.2)
        applyXray(p)
    end)
end

local function StopXrayBase()
    State.XrayBase = false
    for _, conn in pairs(plotConns) do
        conn:Disconnect()
    end
    plotConns = {}
    if xrayCon then
        xrayCon:Disconnect()
        xrayCon = nil
    end
    for _, parts in pairs(baseOT) do
        for part, orig in pairs(parts) do
            if part and part.Parent then
                part.Transparency = orig
            end
        end
    end
    baseOT = {}
end

-- ====== ESP ======
local espHL = {}

local function ClearESP()
    for _, h in pairs(espHL) do
        if h and h.Parent then h:Destroy() end
    end
    espHL = {}
end

local function StartESP()
    State.ESP = true
    task.spawn(function()
        while State.ESP do
            for player, h in pairs(espHL) do
                if not player or not player.Character then
                    if h and h.Parent then h:Destroy() end
                    espHL[player] = nil
                end
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and (not espHL[p] or not espHL[p].Parent) then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.Adornee = p.Character
                    h.Parent = p.Character
                    espHL[p] = h
                end
            end
            task.wait(0.5)
        end
    end)
end

local function StopESP()
    State.ESP = false
    ClearESP()
end

-- ====== AUTO GRAB ======
local grabMainConn = nil
local grabTimer = 0
local stealCache = {}
local grabBarRef = {fill = nil, pct = nil}
local circleParts = {}
local CIRCLE_COLOR = Color3.fromRGB(0, 170, 255)
local allAnimalsCache = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local IsStealing = false
local StealProgress = 0
local PartsCount = 64

local function UpdateGrabBar(pct)
    if grabBarRef.fill then
        grabBarRef.fill.Size = UDim2.new(math.clamp(pct / 100, 0, 1), 0, 1, 0)
    end
    if grabBarRef.pct then
        grabBarRef.pct.Text = math.floor(pct) .. "%"
    end
end

local function getHRPGrab()
    local c = LP.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
end

local function IsOwnPrompt(p) return Char and p:IsDescendantOf(Char) end

local function GetPromptPos(prompt)
    local pos
    pcall(function()
        local par = prompt.Parent
        if par:IsA("BasePart") then
            pos = par.Position
        elseif par:IsA("Attachment") then
            pos = par.WorldPosition
        elseif par:IsA("Model") then
            local pp = par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
            if pp then pos = pp.Position end
        else
            local bp = par:FindFirstChildWhichIsA("BasePart", true)
            if bp then pos = bp.Position end
        end
    end)
    return pos
end

local function buildCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = {holdCBs = {}, triggerCBs = {}, ready = true}
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then
                table.insert(data.holdCBs, conn.Function)
            end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then
                table.insert(data.triggerCBs, conn.Function)
            end
        end
    end
    if #data.holdCBs > 0 or #data.triggerCBs > 0 then
        InternalStealCache[prompt] = data
    end
end

local function execSteal(prompt)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    IsStealing = true
    StealProgress = 0
    task.spawn(function()
        for _, fn in ipairs(data.holdCBs) do
            task.spawn(fn)
        end
        local s = tick()
        while tick() - s < Settings.GRAB_RATE do
            StealProgress = (tick() - s) / Settings.GRAB_RATE
            task.wait()
        end
        for _, fn in ipairs(data.triggerCBs) do
            task.spawn(fn)
        end
        task.wait(0.05)
        IsStealing = false
        StealProgress = 0
        data.ready = true
    end)
    return true
end

local function firePrompt(prompt)
    local fired = false
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            fired = true
        end
    end)
    if fired then return end
    pcall(function()
        prompt:InputHoldBegin()
        task.delay(0.05, function()
            pcall(function() prompt:InputHoldEnd() end)
        end)
    end)
end

local function findPrompt(a)
    local c = PromptMemoryCache[a.uid]
    if c and c.Parent then return c end
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and plots:FindFirstChild(a.plot)
    local podiums = plot and plot:FindFirstChild("AnimalPodiums")
    local podium = podiums and podiums:FindFirstChild(a.slot)
    if not podium then return nil end
    local base = podium:FindFirstChild("Base")
    if not base then return nil end
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return nil end
    local attach = spawn:FindFirstChild("PromptAttachment")
    if not attach then return nil end
    for _, p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            PromptMemoryCache[a.uid] = p
            return p
        end
    end
    return nil
end

local function createCircle()
    for _, p in ipairs(circleParts) do
        if p then pcall(function() p:Destroy() end) end
    end
    table.clear(circleParts)
    for i = 1, PartsCount do
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = CIRCLE_COLOR
        part.Transparency = 0.35
        part.Size = Vector3.new(1, 0.2, 0.3)
        part.Parent = workspace
        table.insert(circleParts, part)
    end
end

-- تحديث الكاش
task.spawn(function()
    task.wait(2)
    while true do
        task.wait(5)
        if State.AutoGrab then
            table.clear(allAnimalsCache)
            local plots = workspace:FindFirstChild("Plots")
            if plots then
                for _, plot in ipairs(plots:GetChildren()) do
                    if plot:IsA("Model") then
                        local sign = plot:FindFirstChild("PlotSign")
                        local yourBase = sign and sign:FindFirstChild("YourBase")
                        if not (yourBase and yourBase.Enabled) then
                            local podiums = plot:FindFirstChild("AnimalPodiums")
                            if podiums then
                                for _, podium in ipairs(podiums:GetChildren()) do
                                    if podium:IsA("Model") and podium:FindFirstChild("Base") then
                                        table.insert(allAnimalsCache, {
                                            plot = plot.Name,
                                            slot = podium.Name,
                                            worldPosition = podium:GetPivot().Position,
                                            uid = plot.Name .. "_" .. podium.Name
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function StartAutoGrab()
    State.AutoGrab = true
    grabTimer = 0
    stealCache = {}
    createCircle()
    if grabMainConn then grabMainConn:Disconnect() end
    grabMainConn = RunService.Heartbeat:Connect(function(dt)
        if not State.AutoGrab then
            grabMainConn:Disconnect()
            grabMainConn = nil
            return
        end
        if not HRP then return end
        
        local best, bestDist = nil, Settings.GRAB_RADIUS
        for _, a in ipairs(allAnimalsCache) do
            local d = (HRP.Position - a.worldPosition).Magnitude
            if d < bestDist then
                bestDist = d
                best = a
            end
        end
        
        if best then
            grabTimer = grabTimer + dt
            UpdateGrabBar((grabTimer / Settings.GRAB_RATE) * 100)
            if grabTimer >= Settings.GRAB_RATE then
                grabTimer = 0
                local prompt = findPrompt(best)
                if prompt then
                    buildCallbacks(prompt)
                    if not execSteal(prompt) then firePrompt(prompt) end
                end
            end
        else
            grabTimer = 0
            UpdateGrabBar(0)
        end
    end)
end

local function StopAutoGrab()
    State.AutoGrab = false
    if grabMainConn then grabMainConn:Disconnect(); grabMainConn = nil end
    UpdateGrabBar(0)
    for _, p in ipairs(circleParts) do
        if p then pcall(function() p:Destroy() end) end
    end
    table.clear(circleParts)
end

-- تحديث الدائرة
RunService.RenderStepped:Connect(function()
    if not State.AutoGrab then return end
    local hrp = getHRPGrab()
    if not hrp then return end
    if #circleParts == 0 then createCircle() end
    for i, p in ipairs(circleParts) do
        local a1 = math.rad((i - 1) / PartsCount * 360)
        local a2 = math.rad(i / PartsCount * 360)
        local p1 = Vector3.new(math.cos(a1), 0, math.sin(a1)) * Settings.GRAB_RADIUS
        local p2 = Vector3.new(math.cos(a2), 0, math.sin(a2)) * Settings.GRAB_RADIUS
        local c = (p1 + p2) / 2 + hrp.Position
        p.Size = Vector3.new((p2 - p1).Magnitude, 0.2, 0.3)
        p.CFrame = CFrame.new(c, c + Vector3.new(p2.X - p1.X, 0, p2.Z - p1.Z)) * CFrame.Angles(0, math.pi / 2, 0)
    end
end)

-- ====== AUTO TAUNT ======
local function sendTauntMessage()
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:SendAsync("/H2N")
        else
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local sayMessage = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if sayMessage then
                sayMessage = sayMessage:FindFirstChild("SayMessageRequest")
                if sayMessage then sayMessage:FireServer("/H2N", "All") end
            end
        end
    end)
end

local function checkDuelWin()
    pcall(function()
        local gui = LP.PlayerGui:FindFirstChild("DuelsMachineTopFrame")
        if gui then
            local frame = gui:FindFirstChild("DuelsMachineTopFrame")
            if frame then
                local text = frame:FindFirstChild("TextLabel")
                if text and text.Text and text.Text:find("won the duel") then
                    sendTauntMessage()
                end
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    checkDuelWin()
end)

-- ====== ANTI DIE ======
local antiDieConn = nil
local function startPermanentAntiDie()
    if antiDieConn then antiDieConn:Disconnect() end
    antiDieConn = RunService.Heartbeat:Connect(function()
        if not Hum or not Hum.Parent then return end
        if Hum.Health <= 0 or Hum.Health < 1 then
            pcall(function() Hum.Health = Hum.MaxHealth * 0.9 end)
        end
        pcall(function() Hum.RequiresNeck = false end)
        if HRP and HRP.Position.Y < -10 then
            HRP.CFrame = CFrame.new(HRP.Position.X, -4, HRP.Position.Z)
        end
    end)
end
task.spawn(function() task.wait(0.5); startPermanentAntiDie() end)

-- ====== SAVE/LOAD (كل شيء) ======
local CONFIG_FILE = "H2N_Full_Config.json"

local function SaveEverything()
    local config = {
        -- State (الميزات)
        State = {
            AutoTrack = State.AutoTrack,
            AutoPlayLeft = State.AutoPlayLeft,
            AutoPlayRight = State.AutoPlayRight,
            AutoGrab = State.AutoGrab,
            AntiSentry = State.AntiSentry,
            SpinBody = State.SpinBody,
            AntiRagdoll = State.AntiRagdoll,
            InfiniteJump = State.InfiniteJump,
            DuelTP = State.DuelTP,
            FloatEnabled = State.FloatEnabled,
            Unwalk = State.Unwalk,
            ESP = State.ESP,
            XrayBase = State.XrayBase,
            SpeedBoost = State.SpeedBoost,
        },
        -- Settings (الإعدادات)
        Settings = Settings,
        -- نقاط المبارزة
        DuelPoints = {
            L1 = {X = DuelPoints.L1.X, Y = DuelPoints.L1.Y, Z = DuelPoints.L1.Z},
            L2 = {X = DuelPoints.L2.X, Y = DuelPoints.L2.Y, Z = DuelPoints.L2.Z},
            R1 = {X = DuelPoints.R1.X, Y = DuelPoints.R1.Y, Z = DuelPoints.R1.Z},
            R2 = {X = DuelPoints.R2.X, Y = DuelPoints.R2.Y, Z = DuelPoints.R2.Z},
        },
        -- Ragdoll TP
        DuelTP = {
            TargetSide = DuelTP.TargetSide,
        },
    }
    
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

local function LoadEverything()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            
            -- تحميل State
            if data.State then
                for k, v in pairs(data.State) do
                    State[k] = v
                end
            end
            
            -- تحميل Settings
            if data.Settings then
                for k, v in pairs(data.Settings) do
                    Settings[k] = v
                end
            end
            
            -- تحميل نقاط المبارزة
            if data.DuelPoints then
                if data.DuelPoints.L1 then
                    DuelPoints.L1 = Vector3.new(data.DuelPoints.L1.X, data.DuelPoints.L1.Y, data.DuelPoints.L1.Z)
                end
                if data.DuelPoints.L2 then
                    DuelPoints.L2 = Vector3.new(data.DuelPoints.L2.X, data.DuelPoints.L2.Y, data.DuelPoints.L2.Z)
                end
                if data.DuelPoints.R1 then
                    DuelPoints.R1 = Vector3.new(data.DuelPoints.R1.X, data.DuelPoints.R1.Y, data.DuelPoints.R1.Z)
                end
                if data.DuelPoints.R2 then
                    DuelPoints.R2 = Vector3.new(data.DuelPoints.R2.X, data.DuelPoints.R2.Y, data.DuelPoints.R2.Z)
                end
                TP_POINTS.LEFT = {DuelPoints.L1, DuelPoints.L2}
                TP_POINTS.RIGHT = {DuelPoints.R1, DuelPoints.R2}
            end
            
            -- تحميل Ragdoll TP
            if data.DuelTP then
                DuelTP.TargetSide = data.DuelTP.TargetSide or "RIGHT"
            end
        end
    end)
end

-- تشغيل الميزات حسب الحفظ
local function ApplyLoadedState()
    if State.AutoTrack then StartAutoTrack() end
    if State.AutoPlayLeft then StartAutoPlayLeft() end
    if State.AutoPlayRight then StartAutoPlayRight() end
    if State.AutoGrab then StartAutoGrab() end
    if State.AntiSentry then StartAntiSentry() end
    if State.SpinBody then StartSpinBody() end
    if State.AntiRagdoll then StartAntiRagdoll() end
    if State.InfiniteJump then StartInfiniteJump() end
    if State.DuelTP then startDuelTP() end
    if State.FloatEnabled then startFloat() end
    if State.Unwalk then StartUnwalk() end
    if State.ESP then StartESP() end
    if State.XrayBase then StartXrayBase() end
    if State.SpeedBoost then StartSpeedBoost() end
end

-- حفظ كل 5 ثواني
task.spawn(function()
    while true do
        task.wait(5)
        pcall(SaveEverything)
    end
end)

-- تحميل عند بدء التشغيل
LoadEverything()
ApplyLoadedState()

-- ====== GUI ======
local gui = Instance.new("ScreenGui")
gui.Name = "H2N"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

-- شريط السرقة
local stealBarFrame = Instance.new("Frame", gui)
stealBarFrame.Size = UDim2.new(0, 300, 0, 30)
stealBarFrame.Position = UDim2.new(0.5, -150, 1, -50)
stealBarFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
stealBarFrame.BackgroundTransparency = 0.3
stealBarFrame.Active = true
Instance.new("UICorner", stealBarFrame).CornerRadius = UDim.new(0, 8)

do
    local drag = false
    local ds, sp
    stealBarFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            ds = inp.Position
            sp = stealBarFrame.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - ds
            stealBarFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local sbLabel = Instance.new("TextLabel", stealBarFrame)
sbLabel.Size = UDim2.new(0, 50, 1, 0)
sbLabel.BackgroundTransparency = 1
sbLabel.Text = "GRAB"
sbLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
sbLabel.Font = Enum.Font.GothamBold
sbLabel.TextSize = 12

local sbBG = Instance.new("Frame", stealBarFrame)
sbBG.Size = UDim2.new(1, -110, 0, 12)
sbBG.Position = UDim2.new(0, 55, 0.5, -6)
sbBG.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
Instance.new("UICorner", sbBG).CornerRadius = UDim.new(1, 0)

local sbFill = Instance.new("Frame", sbBG)
sbFill.Size = UDim2.new(0, 0, 1, 0)
sbFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Instance.new("UICorner", sbFill).CornerRadius = UDim.new(1, 0)

local sbPct = Instance.new("TextLabel", stealBarFrame)
sbPct.Size = UDim2.new(0, 45, 1, 0)
sbPct.Position = UDim2.new(1, -50, 0, 0)
sbPct.BackgroundTransparency = 1
sbPct.Text = "0%"
sbPct.TextColor3 = Color3.fromRGB(255, 255, 255)
sbPct.Font = Enum.Font.GothamBold
sbPct.TextSize = 11

grabBarRef.fill = sbFill
grabBarRef.pct = sbPct

-- زر القائمة
local menuBtn = Instance.new("TextButton", gui)
menuBtn.Size = UDim2.new(0, 80, 0, 35)
menuBtn.Position = UDim2.new(0.5, -40, 0.05, 0)
menuBtn.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
menuBtn.Text = "H2N"
menuBtn.TextColor3 = Color3.fromRGB(255, 40, 40)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 16
menuBtn.Draggable = true
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 8)

-- إطار القائمة
local menu = Instance.new("Frame", gui)
menu.Size = UDim2.new(0, 350, 0, 500)
menu.Position = UDim2.new(0.5, -175, 0.5, -250)
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
menu.Visible = false
menu.Draggable = true
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)

menuBtn.MouseButton1Click:Connect(function()
    menu.Visible = not menu.Visible
end)

-- عنوان
local titleLbl = Instance.new("TextLabel", menu)
titleLbl.Size = UDim2.new(1, 0, 0, 35)
titleLbl.Position = UDim2.new(0, 10, 0, 5)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "H2N V9.8"
titleLbl.TextColor3 = Color3.fromRGB(255, 40, 40)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 18
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- تبويبات
local tabBar = Instance.new("Frame", menu)
tabBar.Size = UDim2.new(0, 100, 1, -45)
tabBar.Position = UDim2.new(0, 5, 0, 40)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)

local tabNames = {"Combat", "Protect", "Visual", "Settings"}
local tabFrames = {}
local tabBtns = {}
local uiButtons = {} -- لتخزين أزرار التبديل لتحديثها عند الحفظ

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton", tabBar)
    tb.Size = UDim2.new(1, -10, 0, 35)
    tb.Position = UDim2.new(0, 5, 0, (i - 1) * 40 + 5)
    tb.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    tb.Text = name
    tb.TextColor3 = Color3.fromRGB(255, 40, 40)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 12
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    tabBtns[name] = tb
    
    local sf = Instance.new("ScrollingFrame", menu)
    sf.Size = UDim2.new(1, -115, 1, -45)
    sf.Position = UDim2.new(0, 110, 0, 40)
    sf.BackgroundTransparency = 1
    sf.Visible = (i == 1)
    sf.ScrollBarThickness = 3
    sf.CanvasSize = UDim2.new(0, 0, 2.5, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabFrames[name] = sf
    
    tb.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(40, 0, 0) end
        sf.Visible = true
        tb.BackgroundColor3 = Color3.fromRGB(130, 0, 0)
    end)
end
tabBtns["Combat"].BackgroundColor3 = Color3.fromRGB(130, 0, 0)

-- دالة مساعدة لعمل أزرار التبديل
local function MakeToggle(parent, text, y, stateKey, onToggle)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 35)
    row.Position = UDim2.new(0, 5, 0, y)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0.3, 0, 0.7, 0)
    btn.Position = UDim2.new(0.65, 0, 0.15, 0)
    btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(50, 0, 0)
    btn.Text = State[stateKey] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local function update()
        local s = State[stateKey]
        btn.Text = s and "ON" or "OFF"
        btn.BackgroundColor3 = s and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(50, 0, 0)
    end
    
    btn.MouseButton1Click:Connect(function()
        onToggle(not State[stateKey])
        update()
        SaveEverything()
    end)
    
    uiButtons[stateKey] = update
    return btn
end

-- Combat Tab
local combat = tabFrames["Combat"]
local cy = 5

MakeToggle(combat, "Auto Track", cy, "AutoTrack", function(s)
    if s then StartAutoTrack() else StopAutoTrack() end
end)
cy = cy + 40

MakeToggle(combat, "Auto Play Left", cy, "AutoPlayLeft", function(s)
    if s then StartAutoPlayLeft() else StopAutoPlayLeft() end
end)
cy = cy + 40

MakeToggle(combat, "Auto Play Right", cy, "AutoPlayRight", function(s)
    if s then StartAutoPlayRight() else StopAutoPlayRight() end
end)
cy = cy + 40

MakeToggle(combat, "Auto Grab", cy, "AutoGrab", function(s)
    if s then StartAutoGrab() else StopAutoGrab() end
end)
cy = cy + 40

MakeToggle(combat, "Anti Sentry", cy, "AntiSentry", function(s)
    if s then StartAntiSentry() else StopAntiSentry() end
end)
cy = cy + 40

MakeToggle(combat, "Spin Body", cy, "SpinBody", function(s)
    if s then StartSpinBody() else StopSpinBody() end
end)

-- Protect Tab
local protect = tabFrames["Protect"]
local py = 5

MakeToggle(protect, "Anti Ragdoll", py, "AntiRagdoll", function(s)
    State.AntiRagdoll = s
    if s then StartAntiRagdoll() else StopAntiRagdoll() end
end)
py = py + 40

MakeToggle(protect, "Infinite Jump", py, "InfiniteJump", function(s)
    if s then StartInfiniteJump() else StopInfiniteJump() end
end)
py = py + 40

MakeToggle(protect, "RAGDOLL TP", py, "DuelTP", function(s)
    if s then startDuelTP() else stopDuelTP() end
end)
py = py + 40

MakeToggle(protect, "FLOAT", py, "FloatEnabled", function(s)
    if s then startFloat() else stopFloat() end
end)
py = py + 40

MakeToggle(protect, "UNWALK", py, "Unwalk", function(s)
    if s then StartUnwalk() else StopUnwalk() end
end)

-- Visual Tab
local visual = tabFrames["Visual"]
local vy = 5

MakeToggle(visual, "ESP", vy, "ESP", function(s)
    if s then StartESP() else StopESP() end
end)
vy = vy + 40

MakeToggle(visual, "Xray Base", vy, "XrayBase", function(s)
    if s then StartXrayBase() else StopXrayBase() end
end)
vy = vy + 40

MakeToggle(visual, "Speed Boost", vy, "SpeedBoost", function(s)
    if s then StartSpeedBoost() else StopSpeedBoost() end
end)

-- Settings Tab (مع زر Swap)
local settingsFrame = tabFrames["Settings"]

-- Swap Row
local swapRow = Instance.new("Frame", settingsFrame)
swapRow.Size = UDim2.new(1, -10, 0, 45)
swapRow.Position = UDim2.new(0, 5, 0, 5)
swapRow.BackgroundColor3 = Color3.fromRGB(15, 0, 20)
Instance.new("UICorner", swapRow).CornerRadius = UDim.new(0, 8)

local swapLabel = Instance.new("TextLabel", swapRow)
swapLabel.Size = UDim2.new(0.5, 0, 1, 0)
swapLabel.Position = UDim2.new(0, 10, 0, 0)
swapLabel.BackgroundTransparency = 1
swapLabel.Text = "Ragdoll TP Direction"
swapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
swapLabel.Font = Enum.Font.GothamBold
swapLabel.TextSize = 12
swapLabel.TextXAlignment = Enum.TextXAlignment.Left

local swapValue = Instance.new("TextLabel", swapRow)
swapValue.Size = UDim2.new(0, 70, 0, 28)
swapValue.Position = UDim2.new(1, -80, 0.5, -14)
swapValue.BackgroundColor3 = Color3.fromRGB(20, 0, 30)
swapValue.Text = DuelTP.TargetSide == "LEFT" and "← LEFT" or "RIGHT →"
swapValue.TextColor3 = Color3.fromRGB(255, 200, 100)
swapValue.Font = Enum.Font.GothamBold
swapValue.TextSize = 12
Instance.new("UICorner", swapValue).CornerRadius = UDim.new(0, 6)

local swapBtn = Instance.new("TextButton", swapRow)
swapBtn.Size = UDim2.new(1, 0, 1, 0)
swapBtn.BackgroundTransparency = 1
swapBtn.Text = ""

swapBtn.MouseButton1Click:Connect(function()
    local newSide = (DuelTP.TargetSide == "RIGHT") and "LEFT" or "RIGHT"
    setTargetManual(newSide)
    swapValue.Text = newSide == "LEFT" and "← LEFT" or "RIGHT →"
    SaveEverything()
end)

swapBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch then
        local newSide = (DuelTP.TargetSide == "RIGHT") and "LEFT" or "RIGHT"
        setTargetManual(newSide)
        swapValue.Text = newSide == "LEFT" and "← LEFT" or "RIGHT →"
        SaveEverything()
    end
end)

-- زر حفظ يدوي
local saveBtn = Instance.new("TextButton", settingsFrame)
saveBtn.Size = UDim2.new(1, -10, 0, 35)
saveBtn.Position = UDim2.new(0, 5, 0, 60)
saveBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
saveBtn.Text = "Save Config (Manual)"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 12
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)

saveBtn.MouseButton1Click:Connect(function()
    SaveEverything()
    saveBtn.Text = "Saved!"
    task.wait(1)
    saveBtn.Text = "Save Config (Manual)"
end)

-- دالة الإشعارات
local function Notify(txt)
    local f = Instance.new("Frame", gui)
    f.Size = UDim2.new(0, 250, 0, 35)
    f.Position = UDim2.new(1, -260, 1, -50)
    f.AnchorPoint = Vector2.new(0, 1)
    f.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local fl = Instance.new("TextLabel", f)
    fl.Size = UDim2.new(1, 0, 1, 0)
    fl.BackgroundTransparency = 1
    fl.Text = txt
    fl.TextColor3 = Color3.fromRGB(255, 255, 255)
    fl.Font = Enum.Font.GothamBold
    fl.TextSize = 12
    task.spawn(function() task.wait(3); f:Destroy() end)
end

-- Keybinds
local Keys = {
    InfJump = Enum.KeyCode.J,
    AutoPlayLeft = Enum.KeyCode.G,
    AutoPlayRight = Enum.KeyCode.H,
    AutoTrack = Enum.KeyCode.T,
    DuelTP = Enum.KeyCode.R,
    Unwalk = Enum.KeyCode.U,
    Float = Enum.KeyCode.F,
    SpeedBoost = Enum.KeyCode.V,
}

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    
    local k = input.KeyCode
    if k == Keys.InfJump then
        if State.InfiniteJump then StopInfiniteJump() else StartInfiniteJump() end
        if uiButtons.InfiniteJump then uiButtons.InfiniteJump() end
    elseif k == Keys.AutoPlayLeft then
        if State.AutoPlayLeft then StopAutoPlayLeft() else StartAutoPlayLeft() end
        if uiButtons.AutoPlayLeft then uiButtons.AutoPlayLeft() end
    elseif k == Keys.AutoPlayRight then
        if State.AutoPlayRight then StopAutoPlayRight() else StartAutoPlayRight() end
        if uiButtons.AutoPlayRight then uiButtons.AutoPlayRight() end
    elseif k == Keys.AutoTrack then
        if State.AutoTrack then StopAutoTrack() else StartAutoTrack() end
        if uiButtons.AutoTrack then uiButtons.AutoTrack() end
    elseif k == Keys.DuelTP then
        if State.DuelTP then stopDuelTP() else startDuelTP() end
        if uiButtons.DuelTP then uiButtons.DuelTP() end
    elseif k == Keys.Unwalk then
        if State.Unwalk then StopUnwalk() else StartUnwalk() end
        if uiButtons.Unwalk then uiButtons.Unwalk() end
    elseif k == Keys.Float then
        if State.FloatEnabled then stopFloat() else startFloat() end
        if uiButtons.FloatEnabled then uiButtons.FloatEnabled() end
    elseif k == Keys.SpeedBoost then
        if State.SpeedBoost then StopSpeedBoost() else StartSpeedBoost() end
        if uiButtons.SpeedBoost then uiButtons.SpeedBoost() end
    end
    SaveEverything()
end)

-- تهيئة أولية
task.spawn(function()
    task.wait(2)
    if not State.AutoGrab then
        StartAutoGrab()
        State.AutoGrab = true
        if uiButtons.AutoGrab then uiButtons.AutoGrab() end
        SaveEverything()
    end
end)

-- إعداد الشخصية
local function setupChar(char)
    Hum = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then setupChar(LP.Character) end

print("H2N V9.8 - Full Features | Ready")
print("✓ All features saved every 5 seconds")
print("✓ Unwalk in menu only (no side button)")
print("✓ Ragdoll TP: R1->R2 then starts from R2")
print("✓ Swap button changes direction with auto-save")