-- H2N V9.8 | Modified | Anti-Ragdoll from Plasma | Unwalk | Full Save | Red Circle
repeat task.wait() until game:IsLoaded()
if not game.PlaceId then repeat task.wait(1) until game.PlaceId end

pcall(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name and (v.Name:find("H2N_WP_") or v.Name:find("H2N_Duel_")) then
            v:Destroy()
        end
    end
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Char, HRP, Hum

local function Setup(c)
    Char = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Hum = c:WaitForChild("Humanoid")
    pcall(function() HRP:SetNetworkOwner(LP) end)
end

if LP.Character then Setup(LP.Character) end
LP.CharacterAdded:Connect(function(c) task.wait(0.1); Setup(c) end)

-- ====== STATE ======
local State = {
    SpeedBoost = false,
    AutoPlayLeft = false,
    AutoPlayRight = false,
    AutoTrack = false,
    AutoGrab = false,
    AntiRagdoll = false,
    InfiniteJump = false,
    XrayBase = false,
    ESP = false,
    AntiSentry = false,
    SpinBody = false,
    DuelTP = false,
    FloatEnabled = false,
    Unwalk = false,
}

-- ====== SETTINGS ======
local TRACK_SPEED = 35
local GRAB_RATE = 0.06
local GRAB_RADIUS = 10
local SideButtonSize = 80
local menuW, menuH = 370, 320
local StealBarVisible = true
local ButtonPositions = {}
local sideHiddenMap = {}
local carryingBrainrot = false
local SPIN_SPEED = 25
local XRAY_TRANSPARENCY = 0.68
local DETECTION_DISTANCE = 60
local PULL_DISTANCE = -5
local DUEL_APPROACH_SPD = 60
local DUEL_RETURN_SPD = 29
local FloatHeight = 11

-- Unwalk
local savedAnimations = {}

-- ====== DUEL POINTS ======
local L1 = Vector3.new(-475, -5, 94)
local L2 = Vector3.new(-484, -4, 92)
local R1 = Vector3.new(-476, -6, 26)
local R2 = Vector3.new(-484, -4, 27)

local TP_SEQUENCE = { LEFT = {L1, L2}, RIGHT = {R1, R2} }
local STAND_POINTS = { LEFT = Vector3.new(-466, -6, 114), RIGHT = Vector3.new(-466, -6, 6) }

-- ====== RAGDOLL TP ======
local DuelTP = {
    Enabled = false,
    EnemySide = "LEFT",
    LastTPTime = 0,
    Cooldown = 2,
    StandPoints = STAND_POINTS,
    TPSequence = TP_SEQUENCE,
}

-- ====== WAYPOINTS ======
local WP_PARTS = {}
local WP_COLORS = {
    L1 = Color3.fromRGB(0, 120, 255), L2 = Color3.fromRGB(0, 220, 255),
    R1 = Color3.fromRGB(255, 130, 0), R2 = Color3.fromRGB(255, 50, 50),
}

local function createWPPart(name, pos, color)
    local old = workspace:FindFirstChild("H2N_WP_" .. name)
    if old then old:Destroy() end
    local part = Instance.new("Part")
    part.Name = "H2N_WP_" .. name
    part.Size = Vector3.new(1.5, 1.5, 1.5)
    part.Position = pos
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.1
    local bg = Instance.new("BillboardGui", part)
    bg.Size = UDim2.new(0, 60, 0, 24)
    bg.StudsOffset = Vector3.new(0, 1.8, 0)
    bg.AlwaysOnTop = true
    bg.LightInfluence = 0
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.BackgroundTransparency = 0.3
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
    part.Parent = workspace
    WP_PARTS[name] = part
    return part
end

local function getWP(name)
    local p = WP_PARTS[name]
    if p and p.Parent then return p.Position end
    if name == "L1" then return L1
    elseif name == "L2" then return L2
    elseif name == "R1" then return R1
    else return R2 end
end

-- ====== KEYBINDS ======
local Keys = {
    InfJump = Enum.KeyCode.J,
    AutoPlayLeft = Enum.KeyCode.G,
    AutoPlayRight = Enum.KeyCode.H,
    AutoTrack = Enum.KeyCode.T,
    DuelTP = Enum.KeyCode.R,
    Unwalk = Enum.KeyCode.U,
    Float = Enum.KeyCode.F,
}

-- ====== CONFIG (حفظ كل شيء) ======
local CONFIG_FILE = "H2N_Full_Config.json"

local function SaveEverything()
    local cfg = {
        TRACK_SPEED = TRACK_SPEED,
        GRAB_RATE = GRAB_RATE,
        GRAB_RADIUS = GRAB_RADIUS,
        SideButtonSize = SideButtonSize,
        ButtonPositions = ButtonPositions,
        menuW = menuW, menuH = menuH,
        DUEL_APPROACH_SPD = DUEL_APPROACH_SPD,
        DUEL_RETURN_SPD = DUEL_RETURN_SPD,
        FloatHeight = FloatHeight,
        L1 = { X = L1.X, Y = L1.Y, Z = L1.Z },
        L2 = { X = L2.X, Y = L2.Y, Z = L2.Z },
        R1 = { X = R1.X, Y = R1.Y, Z = R1.Z },
        R2 = { X = R2.X, Y = R2.Y, Z = R2.Z },
        DuelTP = { EnemySide = DuelTP.EnemySide },
        Keys = {
            InfJump = Keys.InfJump.Name, AutoPlayLeft = Keys.AutoPlayLeft.Name,
            AutoPlayRight = Keys.AutoPlayRight.Name, AutoTrack = Keys.AutoTrack.Name,
            DuelTP = Keys.DuelTP.Name, Unwalk = Keys.Unwalk.Name, Float = Keys.Float.Name
        },
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
        }
    }
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(cfg)) end)
end

local function LoadEverything()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.TRACK_SPEED then TRACK_SPEED = data.TRACK_SPEED end
            if data.GRAB_RATE then GRAB_RATE = data.GRAB_RATE end
            if data.GRAB_RADIUS then GRAB_RADIUS = data.GRAB_RADIUS end
            if data.SideButtonSize then SideButtonSize = data.SideButtonSize end
            if data.ButtonPositions then ButtonPositions = data.ButtonPositions end
            if data.menuW then menuW = data.menuW end
            if data.menuH then menuH = data.menuH end
            if data.DUEL_APPROACH_SPD then DUEL_APPROACH_SPD = data.DUEL_APPROACH_SPD end
            if data.DUEL_RETURN_SPD then DUEL_RETURN_SPD = data.DUEL_RETURN_SPD end
            if data.FloatHeight then FloatHeight = data.FloatHeight end
            if data.L1 then L1 = Vector3.new(data.L1.X, data.L1.Y, data.L1.Z) end
            if data.L2 then L2 = Vector3.new(data.L2.X, data.L2.Y, data.L2.Z) end
            if data.R1 then R1 = Vector3.new(data.R1.X, data.R1.Y, data.R1.Z) end
            if data.R2 then R2 = Vector3.new(data.R2.X, data.R2.Y, data.R2.Z) end
            TP_SEQUENCE = { LEFT = {L1, L2}, RIGHT = {R1, R2 } }
            DuelTP.TPSequence = TP_SEQUENCE
            if data.DuelTP then DuelTP.EnemySide = data.DuelTP.EnemySide or "LEFT" end
            if data.Keys then
                for k, v in pairs(data.Keys) do
                    local e = Enum.KeyCode[v]
                    if e and Keys[k] then Keys[k] = e end
                end
            end
            if data.State then
                for k, v in pairs(data.State) do
                    State[k] = v
                end
            end
        end
    end)
end

LoadEverything()

task.spawn(function() while true do task.wait(5); pcall(SaveEverything) end end)

-- ====== BRAINROT ======
local function updateBrainrot(char)
    if not char then return end
    local found = false
    for _, v in ipairs(char:GetDescendants()) do
        local n = (v.Name or ""):lower()
        if n:find("brainrot") or (n:find("brain") and n:find("rot")) then
            found = true
            break
        end
    end
    carryingBrainrot = found
end
local function setupBrainrotEvents(char)
    if not char then return end
    updateBrainrot(char)
    char.DescendantAdded:Connect(function() updateBrainrot(char) end)
    char.DescendantRemoving:Connect(function() updateBrainrot(char) end)
end
if Char then setupBrainrotEvents(Char) end
LP.CharacterAdded:Connect(function(c) task.wait(0.1); Char = c; setupBrainrotEvents(c) end)

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

-- ====== ANTI RAGDOLL (من Plasma) ======
local antiRagdollConn = nil
local antiRagdollActive = false
local lastRagdollTime = 0
local RAGDOLL_COOLDOWN = 0.5

local function StartAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollActive = true
    State.AntiRagdoll = true
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

                if tick() - lastRagdollTime > RAGDOLL_COOLDOWN then
                    lastRagdollTime = tick()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    pcall(function()
                        workspace.CurrentCamera.CameraSubject = hum
                    end)
                    if root then
                        local vel = root.AssemblyLinearVelocity
                        root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
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
    State.AntiRagdoll = false
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end

-- ====== UNWALK ======
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
        rayParams.FilterDescendantsInstances = { char }
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
        local groundY = result and result.Position.Y or (hrp.Position.Y - FloatHeight)
        local targetY = groundY + FloatHeight
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
    if FloatConn then
        FloatConn:Disconnect()
        FloatConn = nil
    end
end

-- ====== AUTO DUEL ======
local aplConn, aprConn = nil, nil
local aplPhase, aprPhase = 1, 1
local aplWaiting, aprWaiting = false, false
local aplWaitTime, aprWaitTime = 0, 0

local LEFT_ROUTE = { "L1", "L2", "L1", "R1", "R2" }
local RIGHT_ROUTE = { "R1", "R2", "R1", "L1", "L2" }

local function getHRP2() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end

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
    if aplConn then
        aplConn:Disconnect()
        aplConn = nil
    end
    aplPhase = 1
    aplWaiting = false
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    SaveEverything()
end

local function StopAutoPlayRight()
    State.AutoPlayRight = false
    if aprConn then
        aprConn:Disconnect()
        aprConn = nil
    end
    aprPhase = 1
    aprWaiting = false
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    SaveEverything()
end

local function updateAutoPlayLeft()
    if not State.AutoPlayLeft then return end
    local h = getHRP2()
    if not h then return end

    if aplWaiting then
        if tick() - aplWaitTime >= (aplPhase == 2 and 0.2 or 0.1) then
            aplWaiting = false
            aplPhase = aplPhase + 1
        end
        return
    end

    local spd = (aplPhase <= 2) and DUEL_APPROACH_SPD or DUEL_RETURN_SPD
    local target = LEFT_ROUTE[aplPhase]
    if target then
        if MoveToPoint(h, getWP(target), spd) then
            aplWaiting = true
            aplWaitTime = tick()
            h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
            if Hum then Hum:Move(Vector3.zero, false) end
        end
    else
        StopAutoPlayLeft()
    end
end

local function updateAutoPlayRight()
    if not State.AutoPlayRight then return end
    local h = getHRP2()
    if not h then return end

    if aprWaiting then
        if tick() - aprWaitTime >= (aprPhase == 2 and 0.2 or 0.1) then
            aprWaiting = false
            aprPhase = aprPhase + 1
        end
        return
    end

    local spd = (aprPhase <= 2) and DUEL_APPROACH_SPD or DUEL_RETURN_SPD
    local target = RIGHT_ROUTE[aprPhase]
    if target then
        if MoveToPoint(h, getWP(target), spd) then
            aprWaiting = true
            aprWaitTime = tick()
            h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
            if Hum then Hum:Move(Vector3.zero, false) end
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
    aplWaiting = false
    if Hum then Hum.AutoRotate = false end
    if aplConn then aplConn:Disconnect() end
    aplConn = RunService.Heartbeat:Connect(updateAutoPlayLeft)
    SaveEverything()
end

local function StartAutoPlayRight()
    StopAutoPlayRight()
    StopAutoPlayLeft()
    State.AutoPlayRight = true
    aprPhase = 1
    aprWaiting = false
    if Hum then Hum.AutoRotate = false end
    if aprConn then aprConn:Disconnect() end
    aprConn = RunService.Heartbeat:Connect(updateAutoPlayRight)
    SaveEverything()
end

-- ====== RAGDOLL TP ======
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

    local points = DuelTP.TPSequence[side]
    if not points or not points[1] or not points[2] then return false, nil end

    local char = LP.Character
    if not char then return false, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, nil end

    hrp.CFrame = CFrame.new(points[1])
    task.wait(0.1)
    hrp.CFrame = CFrame.new(points[2])
    DuelTP.LastTPTime = tick()
    task.wait(0.2)

    return true, points[2]
end

local function onRagdollHit()
    if not State.DuelTP then return false end
    if not DuelTP.EnemySide then return false end

    local side = DuelTP.EnemySide
    local success, finalPoint = teleportSequence(side)

    if success and finalPoint then
        local pointName = (side == "LEFT") and "L2" or "R2"

        if side == "LEFT" then
            if State.AutoPlayLeft then StopAutoPlayLeft() end
            if State.AutoPlayRight then StopAutoPlayRight() end
            State.AutoPlayLeft = true
            setPhaseFromPoint("LEFT", pointName)
            if Hum then Hum.AutoRotate = false end
            if aplConn then aplConn:Disconnect() end
            aplConn = RunService.Heartbeat:Connect(updateAutoPlayLeft)
            if Notify then Notify("⚡ TP → " .. pointName) end
        else
            if State.AutoPlayLeft then StopAutoPlayLeft() end
            if State.AutoPlayRight then StopAutoPlayRight() end
            State.AutoPlayRight = true
            setPhaseFromPoint("RIGHT", pointName)
            if Hum then Hum.AutoRotate = false end
            if aprConn then aprConn:Disconnect() end
            aprConn = RunService.Heartbeat:Connect(updateAutoPlayRight)
            if Notify then Notify("⚡ TP → " .. pointName) end
        end
        SaveEverything()
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
            if duelTPConn then
                duelTPConn:Disconnect()
                duelTPConn = nil
            end
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
    SaveEverything()
end

local function stopDuelTP()
    State.DuelTP = false
    if duelTPConn then
        duelTPConn:Disconnect()
        duelTPConn = nil
    end
    SaveEverything()
end

local function setTargetManual(side)
    DuelTP.EnemySide = side
    if Notify then Notify("Ragdoll TP: " .. (side == "LEFT" and "← LEFT" or "RIGHT →")) end
    SaveEverything()
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
                HRP.AssemblyLinearVelocity = flatDir.Unit * TRACK_SPEED
            end
        else
            HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
        end
    end)
    SaveEverything()
end

local function StopAutoTrack()
    State.AutoTrack = false
    if trackConn then
        trackConn:Disconnect()
        trackConn = nil
    end
    if HRP then HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end
    SaveEverything()
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
    SaveEverything()
end

local function StopInfiniteJump()
    State.InfiniteJump = false
    if jumpConn then
        jumpConn:Disconnect()
        jumpConn = nil
    end
    SaveEverything()
end

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

-- ====== AUTO GRAB (أصلي - بدون تغيير، لون الدائرة أحمر) ======
local grabBarRef = { fill = nil, pct = nil, radiusLbl = nil, rateLbl = nil }
local grabMainConn = nil
local grabTimer = 0
local stealCache = {}
local allAnimalsCache = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local IsStealing = false
local StealProgress = 0
local circleParts = {}
local CIRCLE_COLOR = Color3.fromRGB(255, 0, 0) -- أحمر
local PartsCount = 64

local function UpdateGrabBar(pct)
    if grabBarRef.fill then
        grabBarRef.fill.Size = UDim2.new(math.clamp(pct / 100, 0, 1), 0, 1, 0)
    end
    if grabBarRef.pct then
        grabBarRef.pct.Text = math.floor(pct) .. "%"
    end
    if grabBarRef.radiusLbl then
        grabBarRef.radiusLbl.Text = GRAB_RADIUS .. "st"
    end
    if grabBarRef.rateLbl then
        grabBarRef.rateLbl.Text = string.format("%.3f", GRAB_RATE) .. "s"
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
    local data = { holdCBs = {}, triggerCBs = {}, ready = true }
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
        while tick() - s < GRAB_RATE do
            StealProgress = (tick() - s) / GRAB_RATE
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

        local best, bestDist = nil, GRAB_RADIUS
        for _, a in ipairs(allAnimalsCache) do
            local d = (HRP.Position - a.worldPosition).Magnitude
            if d < bestDist then
                bestDist = d
                best = a
            end
        end

        if best then
            grabTimer = grabTimer + dt
            UpdateGrabBar((grabTimer / GRAB_RATE) * 100)
            if grabTimer >= GRAB_RATE then
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
    SaveEverything()
end

local function StopAutoGrab()
    State.AutoGrab = false
    if grabMainConn then
        grabMainConn:Disconnect()
        grabMainConn = nil
    end
    UpdateGrabBar(0)
    for _, p in ipairs(circleParts) do
        if p then pcall(function() p:Destroy() end) end
    end
    table.clear(circleParts)
    SaveEverything()
end

RunService.RenderStepped:Connect(function()
    if not State.AutoGrab then return end
    local hrp = getHRPGrab()
    if not hrp then return end
    if #circleParts == 0 then createCircle() end
    for i, p in ipairs(circleParts) do
        local a1 = math.rad((i - 1) / PartsCount * 360)
        local a2 = math.rad(i / PartsCount * 360)
        local p1 = Vector3.new(math.cos(a1), 0, math.sin(a1)) * GRAB_RADIUS
        local p2 = Vector3.new(math.cos(a2), 0, math.sin(a2)) * GRAB_RADIUS
        local c = (p1 + p2) / 2 + hrp.Position
        p.Size = Vector3.new((p2 - p1).Magnitude, 0.2, 0.3)
        p.CFrame = CFrame.new(c, c + Vector3.new(p2.X - p1.X, 0, p2.Z - p1.Z)) * CFrame.Angles(0, math.pi / 2, 0)
    end
end)

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
            p.Transparency = XRAY_TRANSPARENCY
        end
    end
    plotConns[plot] = plot.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Transparency < 0.6 then
            baseOT[plot][d] = d.Transparency
            d.Transparency = XRAY_TRANSPARENCY
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
    SaveEverything()
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
    SaveEverything()
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
    SaveEverything()
end

local function StopESP()
    State.ESP = false
    ClearESP()
    SaveEverything()
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
                if part and (rootPos - part.Position).Magnitude <= DETECTION_DISTANCE then
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
    local cf = root.CFrame * CFrame.new(0, 0, PULL_DISTANCE)
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
    SaveEverything()
end

local function StopAntiSentry()
    State.AntiSentry = false
    antiSentryTarget = nil
    SaveEverything()
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
    spinForce.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0)
    spinForce.MaxTorque = Vector3.new(0, math.huge, 0)
    spinForce.P = 1250
    spinForce.Parent = root
    SaveEverything()
end

local function StopSpinBody()
    State.SpinBody = false
    if spinForce then
        spinForce:Destroy()
        spinForce = nil
    end
    SaveEverything()
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
            root.AssemblyLinearVelocity = Vector3.new(moveDir.X * 60, root.AssemblyLinearVelocity.Y, moveDir.Z * 60)
        end
    end)
    SaveEverything()
end

local function StopSpeedBoost()
    State.SpeedBoost = false
    if speedBoostConn then
        speedBoostConn:Disconnect()
        speedBoostConn = nil
    end
    SaveEverything()
end

-- ====== GUI (نفس الشكل الأصلي) ======
local gui = Instance.new("ScreenGui")
gui.Name = "H2N"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

-- Discord Billboard
local function createDiscordBillboard(character)
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    local old = head:FindFirstChild("H2NDiscordLink")
    if old then old:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "H2NDiscordLink"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = head
    local bg = Instance.new("Frame", billboard)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    bg.BackgroundTransparency = 0.2
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(0, 120, 255)
    stroke.Thickness = 1.5
    local linkLabel = Instance.new("TextLabel", bg)
    linkLabel.Size = UDim2.new(1, -10, 1, 0)
    linkLabel.Position = UDim2.new(0, 5, 0, 0)
    linkLabel.BackgroundTransparency = 1
    linkLabel.Text = "discord.gg/UeKPQC7fq"
    linkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    linkLabel.Font = Enum.Font.GothamBold
    linkLabel.TextSize = 16
    linkLabel.TextScaled = true
end
local function setupDiscordLink(char) task.wait(0.5); createDiscordBillboard(char) end
if LP.Character then setupDiscordLink(LP.Character) end
LP.CharacterAdded:Connect(setupDiscordLink)

-- Steal Bar
local stealBarFrame = Instance.new("Frame", gui)
stealBarFrame.Name = "StealBar"
stealBarFrame.Size = UDim2.new(0, 340, 0, 36)
stealBarFrame.Position = UDim2.new(0.5, -170, 1, -55)
stealBarFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
stealBarFrame.ZIndex = 8
stealBarFrame.Visible = StealBarVisible
stealBarFrame.Active = true
Instance.new("UICorner", stealBarFrame).CornerRadius = UDim.new(0, 10)
local sbStr = Instance.new("UIStroke", stealBarFrame)
sbStr.Color = Color3.fromRGB(220, 0, 0)
sbStr.Thickness = 2

do
    local sbDrag, sbDS, sbPS = false, nil, nil
    stealBarFrame.InputBegan:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            sbDrag = true
            sbDS = inp.Position
            sbPS = stealBarFrame.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not sbDrag then return end
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = inp.Position - sbDS
            stealBarFrame.Position = UDim2.new(sbPS.X.Scale, sbPS.X.Offset + d.X, sbPS.Y.Scale, sbPS.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then sbDrag = false end
    end)
end

local sbLabel = Instance.new("TextLabel", stealBarFrame)
sbLabel.Size = UDim2.new(0, 48, 1, 0)
sbLabel.BackgroundTransparency = 1
sbLabel.Text = "GRAB"
sbLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
sbLabel.Font = Enum.Font.GothamBold
sbLabel.TextSize = 12
sbLabel.ZIndex = 9

local sbBG = Instance.new("Frame", stealBarFrame)
sbBG.Size = UDim2.new(1, -160, 0, 14)
sbBG.Position = UDim2.new(0, 48, 0.5, -7)
sbBG.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
sbBG.ZIndex = 9
Instance.new("UICorner", sbBG).CornerRadius = UDim.new(0, 6)

local sbFill = Instance.new("Frame", sbBG)
sbFill.Size = UDim2.new(0, 0, 1, 0)
sbFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
sbFill.ZIndex = 10
Instance.new("UICorner", sbFill).CornerRadius = UDim.new(0, 6)

local sbPct = Instance.new("TextLabel", stealBarFrame)
sbPct.Size = UDim2.new(0, 34, 1, 0)
sbPct.Position = UDim2.new(1, -110, 0, 0)
sbPct.BackgroundTransparency = 1
sbPct.Text = "0%"
sbPct.TextColor3 = Color3.fromRGB(255, 255, 255)
sbPct.Font = Enum.Font.GothamBold
sbPct.TextSize = 11
sbPct.ZIndex = 9

local sbRadius = Instance.new("TextLabel", stealBarFrame)
sbRadius.Size = UDim2.new(0, 38, 1, 0)
sbRadius.Position = UDim2.new(1, -76, 0, 0)
sbRadius.BackgroundTransparency = 1
sbRadius.Text = GRAB_RADIUS .. "st"
sbRadius.TextColor3 = Color3.fromRGB(255, 160, 0)
sbRadius.Font = Enum.Font.GothamBold
sbRadius.TextSize = 11
sbRadius.ZIndex = 9

local sbRate = Instance.new("TextLabel", stealBarFrame)
sbRate.Size = UDim2.new(0, 50, 1, 0)
sbRate.Position = UDim2.new(1, -50, 0, 0)
sbRate.BackgroundTransparency = 1
sbRate.Text = string.format("%.3f", GRAB_RATE) .. "s"
sbRate.TextColor3 = Color3.fromRGB(100, 255, 100)
sbRate.Font = Enum.Font.GothamBold
sbRate.TextSize = 10
sbRate.ZIndex = 9

grabBarRef.fill = sbFill
grabBarRef.pct = sbPct
grabBarRef.radiusLbl = sbRadius
grabBarRef.rateLbl = sbRate

-- Menu Button
local menuBtn = Instance.new("TextButton", gui)
menuBtn.Size = UDim2.new(0, 90, 0, 40)
menuBtn.Position = UDim2.new(0.5, -45, 0.07, 0)
menuBtn.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
menuBtn.Text = "H2N"
menuBtn.TextColor3 = Color3.fromRGB(255, 40, 40)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 18
menuBtn.Active = true
menuBtn.Draggable = true
menuBtn.ZIndex = 10
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", menuBtn).Color = Color3.fromRGB(220, 0, 0)

-- Menu Frame
local menu = Instance.new("Frame", gui)
menu.Size = UDim2.new(0, menuW, 0, menuH)
menu.Position = UDim2.new(0.5, 0, 0.52, 0)
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
menu.Visible = false
menu.Active = true
menu.Draggable = true
menu.ZIndex = 9
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", menu)
ms.Color = Color3.fromRGB(220, 0, 0)
ms.Thickness = 3

menuBtn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)

local tl = Instance.new("TextLabel", menu)
tl.Size = UDim2.new(1, -20, 0, 30)
tl.Position = UDim2.new(0, 10, 0, 6)
tl.BackgroundTransparency = 1
tl.Text = "H2N V9.8"
tl.TextColor3 = Color3.fromRGB(255, 40, 40)
tl.Font = Enum.Font.GothamBold
tl.TextSize = 17
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.ZIndex = 10

-- Tabs
local tabBar = Instance.new("Frame", menu)
tabBar.Size = UDim2.new(0, 110, 1, -44)
tabBar.Position = UDim2.new(0, 8, 0, 40)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
tabBar.ZIndex = 10
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local tabNames = { "Combat", "Protect", "Visual", "Settings" }
local tabFrames = {}
local tabBtns = {}

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton", tabBar)
    tb.Size = UDim2.new(1, -12, 0, 38)
    tb.Position = UDim2.new(0, 6, 0, (i - 1) * 44 + 8)
    tb.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    tb.Text = name
    tb.TextColor3 = Color3.fromRGB(255, 40, 40)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 14
    tb.ZIndex = 11
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
    tabBtns[name] = tb

    local sf = Instance.new("ScrollingFrame", menu)
    sf.Size = UDim2.new(1, -128, 1, -44)
    sf.Position = UDim2.new(0, 122, 0, 40)
    sf.BackgroundTransparency = 1
    sf.Visible = (i == 1)
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(220, 0, 0)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ZIndex = 10
    tabFrames[name] = sf

    tb.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(40, 0, 0) end
        sf.Visible = true
        tb.BackgroundColor3 = Color3.fromRGB(130, 0, 0)
    end)
end
tabBtns["Combat"].BackgroundColor3 = Color3.fromRGB(130, 0, 0)

local function Notify(txt)
    local f = Instance.new("Frame", gui)
    f.Size = UDim2.new(0, 270, 0, 42)
    f.Position = UDim2.new(1, -290, 1, -100)
    f.AnchorPoint = Vector2.new(0, 1)
    f.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
    f.ZIndex = 25
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local fs = Instance.new("UIStroke", f)
    fs.Color = Color3.fromRGB(220, 0, 0)
    fs.Thickness = 2
    local fl = Instance.new("TextLabel", f)
    fl.Size = UDim2.new(1, 0, 1, 0)
    fl.BackgroundTransparency = 1
    fl.Text = txt
    fl.TextColor3 = Color3.fromRGB(255, 255, 255)
    fl.Font = Enum.Font.GothamBold
    fl.TextSize = 14
    fl.ZIndex = 26
    task.spawn(function() task.wait(3); f:Destroy() end)
end

-- GUI Helpers
local function MakeToggle(parent, text, order, getState, onToggle)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, order * 44 + 4)
    row.BackgroundTransparency = 1
    row.ZIndex = 11

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.60, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 12

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0.34, 0, 0.75, 0)
    btn.Position = UDim2.new(0.63, 0, 0.12, 0)
    btn.BackgroundColor3 = getState() and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(50, 0, 0)
    btn.Text = getState() and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(180, 0, 0)

    local function update()
        local s = getState()
        btn.Text = s and "ON" or "OFF"
        btn.BackgroundColor3 = s and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(50, 0, 0)
    end

    btn.MouseButton1Click:Connect(function()
        onToggle(not getState())
        update()
    end)

    return btn, update
end

local function MakeNumberBox(parent, text, default, order, cb)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, order * 44 + 4)
    row.BackgroundTransparency = 1
    row.ZIndex = 11

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 12

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.36, 0, 0.75, 0)
    box.Position = UDim2.new(0.60, 0, 0.12, 0)
    box.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 16
    box.ZIndex = 12
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local bs = Instance.new("UIStroke", box)
    bs.Color = Color3.fromRGB(220, 0, 0)
    bs.Thickness = 2

    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            cb(n)
            box.Text = tostring(n)
        else
            box.Text = tostring(default)
        end
        SaveEverything()
    end)
    return box
end

local function MakeKeybind(parent, labelText, keyName, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, order * 44 + 4)
    row.BackgroundTransparency = 1
    row.ZIndex = 11

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 12

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0.36, 0, 0.75, 0)
    btn.Position = UDim2.new(0.60, 0, 0.12, 0)
    btn.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
    btn.Text = Keys[keyName] and Keys[keyName].Name or "?"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(220, 0, 0)

    local listening = false
    local listenConn

    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "..."
        btn.BackgroundColor3 = Color3.fromRGB(60, 20, 0)
        if listenConn then listenConn:Disconnect() end
        listenConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keys[keyName] = input.KeyCode
                btn.Text = input.KeyCode.Name
                btn.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
                listening = false
                listenConn:Disconnect()
                Notify("Key " .. labelText .. " = " .. input.KeyCode.Name)
                SaveEverything()
            end
        end)
    end)
    return btn
end

-- Combat Tab
local combat = tabFrames["Combat"]
local ci = 0

MakeToggle(combat, "Auto Track", ci, function() return State.AutoTrack end, function(s)
    if s then StartAutoTrack() else StopAutoTrack() end
end)
ci = ci + 1

MakeNumberBox(combat, "Track Speed", TRACK_SPEED, ci, function(v) TRACK_SPEED = math.clamp(v, 10, 200) end)
ci = ci + 1

MakeToggle(combat, "Auto Play Left", ci, function() return State.AutoPlayLeft end, function(s)
    if s then StartAutoPlayLeft() else StopAutoPlayLeft() end
end)
ci = ci + 1

MakeToggle(combat, "Auto Play Right", ci, function() return State.AutoPlayRight end, function(s)
    if s then StartAutoPlayRight() else StopAutoPlayRight() end
end)
ci = ci + 1

MakeToggle(combat, "Auto Grab", ci, function() return State.AutoGrab end, function(s)
    if s then StartAutoGrab() else StopAutoGrab() end
end)
ci = ci + 1

MakeNumberBox(combat, "Grab Radius", GRAB_RADIUS, ci, function(v)
    GRAB_RADIUS = math.clamp(v, 1, 100)
    if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = GRAB_RADIUS .. "st" end
    if State.AutoGrab then
        StopAutoGrab()
        task.wait(0.05)
        StartAutoGrab()
    end
end)
ci = ci + 1

MakeNumberBox(combat, "Grab Rate(s)", GRAB_RATE, ci, function(v)
    GRAB_RATE = math.max(v, 0.001)
    if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.3f", GRAB_RATE) .. "s" end
    if State.AutoGrab then
        StopAutoGrab()
        task.wait(0.05)
        StartAutoGrab()
    end
end)
ci = ci + 1

MakeNumberBox(combat, "Duel Approach Spd", DUEL_APPROACH_SPD, ci, function(v) DUEL_APPROACH_SPD = math.clamp(v, 1, 300) end)
ci = ci + 1

MakeNumberBox(combat, "Duel Return Spd", DUEL_RETURN_SPD, ci, function(v) DUEL_RETURN_SPD = math.clamp(v, 1, 300) end)
ci = ci + 1

MakeToggle(combat, "Anti Sentry", ci, function() return State.AntiSentry end, function(s)
    if s then StartAntiSentry() else StopAntiSentry() end
end)
ci = ci + 1

MakeToggle(combat, "Spin Body", ci, function() return State.SpinBody end, function(s)
    if s then StartSpinBody() else StopSpinBody() end
end)

-- Protect Tab
local protect = tabFrames["Protect"]
local pi = 0

MakeToggle(protect, "Anti Ragdoll", pi, function() return State.AntiRagdoll end, function(s)
    if s then StartAntiRagdoll() else StopAntiRagdoll() end
end)
pi = pi + 1

MakeToggle(protect, "Infinite Jump", pi, function() return State.InfiniteJump end, function(s)
    if s then StartInfiniteJump() else StopInfiniteJump() end
end)
pi = pi + 1

MakeToggle(protect, "RAGDOLL TP", pi, function() return State.DuelTP end, function(s)
    if s then startDuelTP() else stopDuelTP() end
end)
pi = pi + 1

MakeToggle(protect, "FLOAT", pi, function() return State.FloatEnabled end, function(s)
    if s then startFloat() else stopFloat() end
end)
pi = pi + 1

MakeToggle(protect, "UNWALK", pi, function() return State.Unwalk end, function(s)
    if s then StartUnwalk() else StopUnwalk() end
end)

-- Visual Tab
local visual = tabFrames["Visual"]
local vi = 0

MakeToggle(visual, "ESP", vi, function() return State.ESP end, function(s)
    if s then StartESP() else StopESP() end
end)
vi = vi + 1

MakeToggle(visual, "Xray Base", vi, function() return State.XrayBase end, function(s)
    if s then StartXrayBase() else StopXrayBase() end
end)
vi = vi + 1

-- Settings Tab
local sTab = tabFrames["Settings"]
local si = 0

MakeNumberBox(sTab, "Track Speed", TRACK_SPEED, si, function(v) TRACK_SPEED = math.clamp(v, 10, 200) end)
si = si + 1

-- Copy Discord Link
local copyBtn = Instance.new("TextButton", sTab)
copyBtn.Size = UDim2.new(1, -10, 0, 40)
copyBtn.Position = UDim2.new(0, 5, 0, si * 44 + 4)
copyBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
copyBtn.Text = "📋 COPY DISCORD LINK"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
copyBtn.MouseButton1Click:Connect(function()
    setclipboard("discord.gg/UeKPQC7fq")
    copyBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
    task.wait(0.5)
    copyBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    Notify("Discord link copied!")
end)
si = si + 1

-- Ragdoll TP Status
local row1 = Instance.new("Frame", sTab)
row1.Size = UDim2.new(1, -10, 0, 40)
row1.Position = UDim2.new(0, 5, 0, si * 44 + 4)
row1.BackgroundTransparency = 1
row1.ZIndex = 11

local lbl1 = Instance.new("TextLabel", row1)
lbl1.Size = UDim2.new(0.4, 0, 1, 0)
lbl1.BackgroundTransparency = 1
lbl1.Text = "RAGDOLL TP:"
lbl1.TextColor3 = Color3.fromRGB(255, 255, 255)
lbl1.Font = Enum.Font.GothamBold
lbl1.TextSize = 13
lbl1.TextXAlignment = Enum.TextXAlignment.Left
lbl1.ZIndex = 12

local tpSV = Instance.new("TextLabel", row1)
tpSV.Size = UDim2.new(0.33, 0, 0.75, 0)
tpSV.Position = UDim2.new(0.38, 0, 0.12, 0)
tpSV.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
tpSV.Text = (DuelTP.EnemySide == "LEFT") and "← LEFT" or "RIGHT →"
tpSV.TextColor3 = Color3.fromRGB(255, 255, 100)
tpSV.Font = Enum.Font.GothamBold
tpSV.TextSize = 12
tpSV.TextXAlignment = Enum.TextXAlignment.Center
tpSV.ZIndex = 12
Instance.new("UICorner", tpSV).CornerRadius = UDim.new(0, 6)

local swapMBtn = Instance.new("TextButton", row1)
swapMBtn.Size = UDim2.new(0.2, 0, 0.75, 0)
swapMBtn.Position = UDim2.new(0.77, 0, 0.12, 0)
swapMBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 0)
swapMBtn.Text = "SWAP"
swapMBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
swapMBtn.Font = Enum.Font.GothamBold
swapMBtn.TextSize = 12
swapMBtn.BorderSizePixel = 0
swapMBtn.ZIndex = 12
Instance.new("UICorner", swapMBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", swapMBtn).Color = Color3.fromRGB(220, 80, 0)

swapMBtn.MouseButton1Click:Connect(function()
    local newSide = (DuelTP.EnemySide == "RIGHT") and "LEFT" or "RIGHT"
    setTargetManual(newSide)
    tpSV.Text = (DuelTP.EnemySide == "LEFT") and "← LEFT" or "RIGHT →"
    swapMBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
    task.delay(0.3, function() swapMBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 0) end)
end)
si = si + 1

-- Duel Coords
do
    local wpSep = Instance.new("TextLabel", sTab)
    wpSep.Size = UDim2.new(1, -10, 0, 20)
    wpSep.Position = UDim2.new(0, 5, 0, si * 44 + 4)
    wpSep.BackgroundTransparency = 1
    wpSep.Text = "─── DUEL COORDS ───"
    wpSep.TextColor3 = Color3.fromRGB(0, 200, 255)
    wpSep.Font = Enum.Font.GothamBold
    wpSep.TextSize = 12
    wpSep.TextTransparency = 0.2
    wpSep.ZIndex = 11
    si = si + 1

    local WPS = {
        { name = "L1", label = "L1 pos", color = Color3.fromRGB(0, 120, 255) },
        { name = "L2", label = "L2 pos", color = Color3.fromRGB(0, 220, 255) },
        { name = "R1", label = "R1 pos", color = Color3.fromRGB(255, 130, 0) },
        { name = "R2", label = "R2 pos", color = Color3.fromRGB(255, 50, 50) },
    }
    for _, wp in ipairs(WPS) do
        local fr = Instance.new("Frame", sTab)
        fr.Size = UDim2.new(1, -10, 0, 40)
        fr.Position = UDim2.new(0, 5, 0, si * 44 + 4)
        fr.BackgroundTransparency = 1
        fr.ZIndex = 11

        local setBtn = Instance.new("TextButton", fr)
        setBtn.Size = UDim2.new(1, 0, 0.8, 0)
        setBtn.Position = UDim2.new(0, 0, 0.1, 0)
        setBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        setBtn.Font = Enum.Font.GothamBold
        setBtn.TextSize = 13
        setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        setBtn.ZIndex = 12
        Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0, 8)
        local bs = Instance.new("UIStroke", setBtn)
        bs.Color = wp.color
        bs.Thickness = 1.5

        local inner = Instance.new("TextLabel", setBtn)
        inner.Size = UDim2.new(1, -10, 1, 0)
        inner.Position = UDim2.new(0, 10, 0, 0)
        inner.BackgroundTransparency = 1
        inner.Font = Enum.Font.GothamBold
        inner.TextSize = 13
        inner.TextColor3 = Color3.fromRGB(255, 255, 255)
        inner.TextXAlignment = Enum.TextXAlignment.Left
        inner.ZIndex = 13
        inner.Text = wp.label

        local wn = wp.name
        local wc = wp.color
        setBtn.MouseButton1Click:Connect(function()
            if not HRP then Notify("No character!"); return end
            local pos = HRP.Position
            if wn == "L1" then L1 = pos
            elseif wn == "L2" then L2 = pos
            elseif wn == "R1" then R1 = pos
            elseif wn == "R2" then R2 = pos end
            TP_SEQUENCE = { LEFT = { L1, L2 }, RIGHT = { R1, R2 } }
            DuelTP.TPSequence = TP_SEQUENCE
            local part = WP_PARTS[wn]
            if part and part.Parent then
                part.Position = pos
            else
                createWPPart(wn, pos, wc)
            end
            setBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
            task.spawn(function()
                task.wait(1.5)
                setBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
            end)
            Notify(wn .. " set " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z))
            SaveEverything()
        end)
        si = si + 1
    end
end

-- Keybinds
local sep = Instance.new("TextLabel", sTab)
sep.Size = UDim2.new(1, -10, 0, 20)
sep.Position = UDim2.new(0, 5, 0, si * 44 + 4)
sep.BackgroundTransparency = 1
sep.Text = "───────── KEYBINDS ─────────"
sep.TextColor3 = Color3.fromRGB(0, 170, 255)
sep.Font = Enum.Font.GothamBold
sep.TextSize = 12
sep.TextTransparency = 0.3
si = si + 1

MakeKeybind(sTab, "Inf Jump Key", "InfJump", si)
si = si + 1
MakeKeybind(sTab, "Auto Left Key", "AutoPlayLeft", si)
si = si + 1
MakeKeybind(sTab, "Auto Right Key", "AutoPlayRight", si)
si = si + 1
MakeKeybind(sTab, "Auto Track Key", "AutoTrack", si)
si = si + 1
MakeKeybind(sTab, "RAGDOLL TP Key", "DuelTP", si)
si = si + 1
MakeKeybind(sTab, "Unwalk Key", "Unwalk", si)
si = si + 1
MakeKeybind(sTab, "Float Key", "Float", si)

-- Keybinds Input
UIS.InputBegan:Connect(function(input, gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode

    if k == Keys.InfJump then
        if State.InfiniteJump then StopInfiniteJump() else StartInfiniteJump() end
    elseif k == Keys.AutoPlayLeft then
        if State.AutoPlayLeft then StopAutoPlayLeft() else StartAutoPlayLeft() end
    elseif k == Keys.AutoPlayRight then
        if State.AutoPlayRight then StopAutoPlayRight() else StartAutoPlayRight() end
    elseif k == Keys.AutoTrack then
        if State.AutoTrack then StopAutoTrack() else StartAutoTrack() end
    elseif k == Keys.DuelTP then
        if State.DuelTP then stopDuelTP() else startDuelTP() end
    elseif k == Keys.Unwalk then
        if State.Unwalk then StopUnwalk() else StartUnwalk() end
    elseif k == Keys.Float then
        if State.FloatEnabled then stopFloat() else startFloat() end
    end
    SaveEverything()
end)

-- ====== Side Buttons (نفس الأصلي - 6 أزرار) ======
local activeTouchForDrag = nil

local function CreateSideButton(text, side, index, getState, startFn, stopFn)
    local btn = Instance.new("Frame", gui)
    btn.Name = "SideButton"
    btn:SetAttribute("ID", text)
    btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
    btn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    btn.Active = true
    btn.ZIndex = 5
    btn.Visible = not (sideHiddenMap[text .. "_individual"] == true)

    local sp = ButtonPositions[text]
    if sp then
        btn.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO)
    elseif side == "left" then
        btn.Position = UDim2.new(0, 10, 0.22 + index * 0.19, 0)
    else
        btn.Position = UDim2.new(1, -(SideButtonSize + 10), 0.22 + index * 0.19, 0)
    end

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(220, 0, 0)
    stroke.Thickness = 2

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -4, 0.55, 0)
    lbl.Position = UDim2.new(0, 2, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.ZIndex = 6

    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 1, -13)
    dot.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    dot.ZIndex = 6
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local function RefreshVisual()
        if getState() then
            dot.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        else
            dot.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        end
    end

    local pressing, hasMoved, dragStart, btnStart, activeInput = false, false, nil, nil, nil

    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if activeTouchForDrag ~= nil then return end
        if pressing then return end
        pressing = true
        hasMoved = false
        activeInput = input
        activeTouchForDrag = input
        dragStart = input.Position
        btnStart = btn.Position
    end)

    UIS.InputChanged:Connect(function(input)
        if not pressing or input ~= activeInput then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
        if not dragStart then return end
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then
            hasMoved = true
            btn.Position = UDim2.new(btnStart.X.Scale, btnStart.X.Offset + delta.X, btnStart.Y.Scale, btnStart.Y.Offset + delta.Y)
        end
    end)

    btn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if not pressing or input ~= activeInput then return end
        pressing = false
        activeInput = nil
        activeTouchForDrag = nil

        if not hasMoved then
            task.spawn(function()
                btn.Size = UDim2.new(0, SideButtonSize * 0.88, 0, SideButtonSize * 0.88)
                task.wait(0.07)
                btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
            end)
            if getState() then stopFn() else startFn() end
            RefreshVisual()
            SaveEverything()
        elseif hasMoved then
            local p = btn.Position
            ButtonPositions[text] = { X = p.X.Scale, XO = p.X.Offset, Y = p.Y.Scale, YO = p.Y.Offset }
            SaveEverything()
        end
        hasMoved = false
        dragStart = nil
    end)

    RunService.RenderStepped:Connect(function()
        if not pressing then RefreshVisual() end
    end)
end

-- الأزرار الجانبية (6 أزرار - بدون دمج)
CreateSideButton("AUTO PLAY LEFT", "left", 0, function() return State.AutoPlayLeft end, StartAutoPlayLeft, StopAutoPlayLeft)
CreateSideButton("AUTO PLAY RIGHT", "right", 0, function() return State.AutoPlayRight end, StartAutoPlayRight, StopAutoPlayRight)
CreateSideButton("AUTO TRACK", "right", 1, function() return State.AutoTrack end, StartAutoTrack, StopAutoTrack)
CreateSideButton("FLOAT", "right", 2, function() return State.FloatEnabled end, startFloat, stopFloat)
CreateSideButton("UNWALK", "left", 1, function() return State.Unwalk end, StartUnwalk, StopUnwalk)

-- زر RAGDOLL TP الجانبي (منفصل)
do
    local bSize = SideButtonSize

    local container = Instance.new("Frame", gui)
    container.Name = "SideButton"
    container:SetAttribute("ID", "RAGDOLL TP")
    container.Size = UDim2.new(0, bSize, 0, bSize)
    container.BackgroundTransparency = 1
    container.Active = true
    container.ZIndex = 5
    container.Visible = not (sideHiddenMap["RAGDOLL TP_individual"] == true)

    local sp = ButtonPositions["RAGDOLL TP"]
    if sp then
        container.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO)
    else
        container.Position = UDim2.new(1, -(bSize + 10), 0.22 + 2 * 0.19, 0)
    end

    local mainF = Instance.new("Frame", container)
    mainF.Size = UDim2.new(1, 0, 1, 0)
    mainF.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    mainF.Active = true
    mainF.ZIndex = 5
    Instance.new("UICorner", mainF).CornerRadius = UDim.new(0, 14)
    local mStroke = Instance.new("UIStroke", mainF)
    mStroke.Color = Color3.fromRGB(220, 0, 0)
    mStroke.Thickness = 2

    local nameLbl = Instance.new("TextLabel", mainF)
    nameLbl.Size = UDim2.new(1, -4, 0, 18)
    nameLbl.Position = UDim2.new(0, 2, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = "RAGDOLL TP"
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.ZIndex = 6

    local dirLbl = Instance.new("TextLabel", mainF)
    dirLbl.Size = UDim2.new(1, -4, 0, 14)
    dirLbl.Position = UDim2.new(0, 2, 0, 26)
    dirLbl.BackgroundTransparency = 1
    dirLbl.Text = (DuelTP.EnemySide == "RIGHT") and "→ R" or "← L"
    dirLbl.TextColor3 = Color3.fromRGB(255, 200, 0)
    dirLbl.Font = Enum.Font.GothamBold
    dirLbl.TextSize = 11
    dirLbl.ZIndex = 6

    local dot = Instance.new("Frame", mainF)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 1, -13)
    dot.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    dot.ZIndex = 6
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local arrowS = math.max(math.floor(bSize * 0.36), 22)
    local arrowBtn = Instance.new("TextButton", container)
    arrowBtn.Size = UDim2.new(0, arrowS, 0, arrowS)
    arrowBtn.Position = UDim2.new(1, -arrowS, 1, -arrowS)
    arrowBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 0)
    arrowBtn.Text = (DuelTP.EnemySide == "RIGHT") and "R" or "L"
    arrowBtn.TextColor3 = Color3.fromRGB(255, 160, 0)
    arrowBtn.Font = Enum.Font.GothamBold
    arrowBtn.TextSize = math.floor(arrowS * 0.55)
    arrowBtn.ZIndex = 8
    Instance.new("UICorner", arrowBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", arrowBtn).Color = Color3.fromRGB(220, 80, 0)

    arrowBtn.MouseButton1Click:Connect(function()
        local newSide = (DuelTP.EnemySide == "RIGHT") and "LEFT" or "RIGHT"
        setTargetManual(newSide)
        dirLbl.Text = (DuelTP.EnemySide == "RIGHT") and "→ R" or "← L"
        arrowBtn.Text = (DuelTP.EnemySide == "RIGHT") and "R" or "L"
        tpSV.Text = (DuelTP.EnemySide == "LEFT") and "← LEFT" or "RIGHT →"
        arrowBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
        task.delay(0.25, function() arrowBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 0) end)
        SaveEverything()
    end)
end

-- تطبيق الحالة المحفوظة
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
end

ApplyLoadedState()

-- إعداد الشخصية
local function setupChar(char)
    Hum = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then setupChar(LP.Character) end

print("H2N V9.8 - Fixed | Auto Dues Working | Red Circle | Side Buttons Separate | Full Save")