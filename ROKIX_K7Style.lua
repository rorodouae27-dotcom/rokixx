-- ============================================================
--  KEY SYSTEM (Polsec)
-- ============================================================
local API = "EvOarUGwYIjAvNpF"
local USER_KEY = getgenv().Key or ""
local url = "https://api.getpolsec.com/verify?apikey="..API.."&key="..USER_KEY
local response = game:HttpGet(url)
if response == "valid" then
    print("Key valide")
else
    game.Players.LocalPlayer:Kick("Invalid Key")
    return
end
-- ============================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local isfile  = isfile  or (syn and syn.isfile)  or (getgenv and getgenv().isfile)
local readfile = readfile or (syn and syn.readfile) or (getgenv and getgenv().readfile)
local writefile= writefile or (syn and syn.writefile)or (getgenv and getgenv().writefile)
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

-- ============================================================
--  COLOURS (K7 palette â cyan accent)
-- ============================================================
local C = {
    BG        = Color3.fromRGB(10,10,13),
    PANEL     = Color3.fromRGB(14,14,18),
    ROW       = Color3.fromRGB(18,18,23),
    ROW_ON    = Color3.fromRGB(20,30,40),
    ACCENT    = Color3.fromRGB(0,191,255),
    ACCENT_DIM= Color3.fromRGB(0,130,180),
    TEXT      = Color3.fromRGB(220,220,220),
    TEXT_DIM  = Color3.fromRGB(110,110,130),
    DOT_OFF   = Color3.fromRGB(55,55,70),
    DOT_ON    = Color3.fromRGB(0,191,255),
    GREEN     = Color3.fromRGB(80,255,120),
    CLOSE     = Color3.fromRGB(200,40,60),
    WHITE     = Color3.fromRGB(255,255,255),
}

-- ============================================================
--  SCALE
-- ============================================================
local vp = workspace.CurrentCamera.ViewportSize
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local SC = math.clamp(vp.X/1920, 0.55, 1.4) * (isMobile and 1.9 or 1.0)
local function px(n) return math.floor(n*SC) end

-- ============================================================
--  STATE VARIABLES
-- ============================================================
local NORMAL_SPEED, CARRY_SPEED = 60, 30
local STEAL_SPEED = 29.4          -- vitesse pendant le steal (waypoints 3+)
local stealSpeedEnabled = false   -- si OFF = vitesse normale mÃªme en steal
local antiCollisionEnabled = false
local antiCollisionConn = nil
local speedToggled = false
local autoLeftEnabled, autoRightEnabled = false, false
local autoStealEnabled, antiRagdollEnabled = false, false
local unwalkEnabled, galaxyEnabled, hopsEnabled = false, false, false
local spinBotEnabled, espEnabled = false, true
local floatEnabled = false
local floatHeight = 8
local batAimbotToggled = false
local optimizerEnabled = false
local STEAL_RADIUS, STEAL_DURATION = 20, 0.2
local GALAXY_GRAVITY_PERCENT, GALAXY_HOP_POWER, SPIN_SPEED = 42, 35, 19
local INF_JUMP_POWER = 35
local GALAXY_HOP_COOLDOWN = 0.08
local DEFAULT_GRAVITY = 196.2
local originalJumpPower = 50
local spaceHeld, galaxyLastHop = false, 0
local isStealing, stealStartTime = false, nil
local StealData = {}
local espConnections, espObjects = {}, {}
local originalTransparency = {}
local ninePatrolMode = "none"
local nineCurrentWaypoint = 1
local AUTO_START_DELAY = 0.7
local savedAnimate = nil
local CONFIG_NAME = "RokixK7Config"

local rightWaypoints = {
    Vector3.new(-473.04,-6.99,29.71), Vector3.new(-483.57,-5.10,18.74),
    Vector3.new(-475.00,-6.99,26.43), Vector3.new(-474.67,-6.94,105.48),
}
local leftWaypoints = {
    Vector3.new(-472.49,-7.00,90.62), Vector3.new(-484.62,-5.10,100.37),
    Vector3.new(-475.08,-7.00,93.29), Vector3.new(-474.22,-6.96,16.18),
}

local char, hum, hrp = nil, nil, nil
local spinBAV, floatConn, floatOrigY = nil, nil, nil
local autoStealConn, antiRagdollConn, progressConn = nil, nil, nil
local galaxyVF, galaxyAtt = nil, nil
local batLookConn, batAtt, batAlignOri = nil, nil, nil
local BAT_MOVE_SPEED, BAT_ENGAGE_RANGE, BAT_LOOP_TIME = 56.5, 20, 0.3
local lastEquipTick, lastUseTick = 0, 0
local BAT_LOOK_DIST = 50

-- TP variables (Nine Hub style)
local tpFinalLeft  = Vector3.new(-483.59, -5.04, 104.24)
local tpFinalRight = Vector3.new(-483.51, -5.10, 18.89)
local tpCheckA     = Vector3.new(-472.60, -7.00, 57.52)
local tpCheckLeft  = Vector3.new(-472.65, -7.00, 95.69)
local tpCheckRight = Vector3.new(-471.76, -7.00, 26.22)
local lastTpSide        = "none"
local ragdollAutoActive = false
local ragdollWasActive  = false
local ragdollDetConn    = nil

-- ============================================================
--  KEYBINDS
-- ============================================================
local DEFAULT_KB = {
    ToggleGUI   = Enum.KeyCode.U,
    AutoLeft    = Enum.KeyCode.Z,
    AutoRight   = Enum.KeyCode.C,
    BatAimbot   = Enum.KeyCode.E,
    SpeedToggle = Enum.KeyCode.Q,
    Float       = Enum.KeyCode.F,
    Drop        = Enum.KeyCode.G,
    TPLeft      = Enum.KeyCode.T,
    TPRight     = Enum.KeyCode.Y,
}
local KB = {}
for k,v in pairs(DEFAULT_KB) do KB[k]=v end

-- ============================================================
--  SAVE / LOAD
-- ============================================================
local function saveConfig()
    if not writefile then return end
    local t = {
        NORMAL_SPEED=NORMAL_SPEED, CARRY_SPEED=CARRY_SPEED,
        STEAL_RADIUS=STEAL_RADIUS, STEAL_DURATION=STEAL_DURATION,
        STEAL_SPEED=STEAL_SPEED, stealSpeedEnabled=stealSpeedEnabled,
        antiCollisionEnabled=antiCollisionEnabled,
        GALAXY_GRAVITY_PERCENT=GALAXY_GRAVITY_PERCENT,
        GALAXY_HOP_POWER=GALAXY_HOP_POWER, SPIN_SPEED=SPIN_SPEED,
        floatHeight=floatHeight, espEnabled=espEnabled,
        antiRagdollEnabled=antiRagdollEnabled,
        spinBotEnabled=spinBotEnabled, galaxyEnabled=galaxyEnabled,
        optimizerEnabled=optimizerEnabled, KEYBINDS={}
    }
    for k,v in pairs(KB) do t.KEYBINDS[k]=v and v.Name or nil end
    pcall(function() writefile(CONFIG_NAME..".json", HttpService:JSONEncode(t)) end)
end

local function loadConfig()
    if not isfile or not readfile then return end
    local ok, r = pcall(function()
        if isfile(CONFIG_NAME..".json") then return HttpService:JSONDecode(readfile(CONFIG_NAME..".json")) end
    end)
    if ok and r then
        NORMAL_SPEED = r.NORMAL_SPEED or 60
        CARRY_SPEED  = r.CARRY_SPEED  or 30
        STEAL_RADIUS = r.STEAL_RADIUS or 20
        STEAL_DURATION = r.STEAL_DURATION or 0.2
        STEAL_SPEED = r.STEAL_SPEED or 29.4
        stealSpeedEnabled = r.stealSpeedEnabled or false
        antiCollisionEnabled = r.antiCollisionEnabled or false
        GALAXY_GRAVITY_PERCENT = r.GALAXY_GRAVITY_PERCENT or 42
        GALAXY_HOP_POWER = r.GALAXY_HOP_POWER or 35
        SPIN_SPEED = r.SPIN_SPEED or 19
        floatHeight = r.floatHeight or 8
        espEnabled = r.espEnabled ~= false
        antiRagdollEnabled = r.antiRagdollEnabled or false
        spinBotEnabled = r.spinBotEnabled or false
        galaxyEnabled = r.galaxyEnabled or false
        optimizerEnabled = r.optimizerEnabled or false
        if r.KEYBINDS then
            for k,v in pairs(r.KEYBINDS) do
                if KB[k]~=nil and v then
                    local kc = Enum.KeyCode[v]
                    if kc then KB[k]=kc end
                end
            end
        end
    end
end
loadConfig()

-- ============================================================
--  FEATURE FUNCTIONS
-- ============================================================
-- ESP
local function createESP(plr)
    if plr==LocalPlayer or not plr.Character then return end
    if plr.Character:FindFirstChild("_RESP") then return end
    local hrp2 = plr.Character:FindFirstChild("HumanoidRootPart"); if not hrp2 then return end
    local h2 = plr.Character:FindFirstChildOfClass("Humanoid")
    if h2 then h2.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    local b = Instance.new("BoxHandleAdornment")
    b.Name="_RESP"; b.Adornee=hrp2; b.Size=Vector3.new(4,6,2)
    b.Color3=C.ACCENT; b.Transparency=0.45; b.ZIndex=10; b.AlwaysOnTop=true; b.Parent=plr.Character
    espObjects[plr]={box=b}
end
local function removeESP(plr)
    pcall(function()
        if plr.Character then
            local b=plr.Character:FindFirstChild("_RESP"); if b then b:Destroy() end
            local h2=plr.Character:FindFirstChildOfClass("Humanoid")
            if h2 then h2.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Automatic end
        end
        espObjects[plr]=nil
    end)
end
local function enableESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            if p.Character then pcall(function() createESP(p) end) end
            table.insert(espConnections, p.CharacterAdded:Connect(function()
                task.wait(0.1); if espEnabled then pcall(function() createESP(p) end) end
            end))
        end
    end
    table.insert(espConnections, Players.PlayerAdded:Connect(function(p)
        if p==LocalPlayer then return end
        table.insert(espConnections, p.CharacterAdded:Connect(function()
            task.wait(0.1); if espEnabled then pcall(function() createESP(p) end) end
        end))
    end))
end
local function disableESP()
    for _,p in ipairs(Players:GetPlayers()) do pcall(function() removeESP(p) end) end
    for _,c in ipairs(espConnections) do if c and c.Connected then c:Disconnect() end end
    espConnections={}; espObjects={}
end

-- Player noclip
RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            for _,pt in ipairs(p.Character:GetDescendants()) do
                if pt:IsA("BasePart") then pt.CanCollide=false end
            end
        end
    end
end)

-- Spin Bot
local function cleanSpin()
    if spinBAV then spinBAV:Destroy(); spinBAV=nil end
    local c=LocalPlayer.Character; if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart"); if not r then return end
    for _,v in pairs(r:GetChildren()) do if v.Name=="SpinBAV" then v:Destroy() end end
end
local function startSpinBot()
    cleanSpin()
    local c=LocalPlayer.Character; if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart"); if not r then return end
    spinBAV=Instance.new("BodyAngularVelocity")
    spinBAV.Name="SpinBAV"; spinBAV.MaxTorque=Vector3.new(0,math.huge,0)
    spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0); spinBAV.Parent=r
end
local function stopSpinBot() cleanSpin() end

-- Anti Ragdoll
local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then return end
        local c=LocalPlayer.Character; if not c then return end
        local h2=c:FindFirstChildOfClass("Humanoid"); local r=c:FindFirstChild("HumanoidRootPart")
        if h2 then
            local st=h2:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                h2:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject=h2
                if r then r.Velocity=Vector3.zero; r.RotVelocity=Vector3.zero end
            end
        end
        for _,o in ipairs(c:GetDescendants()) do
            pcall(function() if o:IsA("Motor6D") and not o.Enabled then o.Enabled=true end end)
        end
    end)
end
local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn=nil end
end

-- ============================================================
--  ANTI COLLISION
--  DÃ©sactive la collision du HRP local pour passer Ã  travers les joueurs
--  et les objets qui bloquent pendant le steal.
-- ============================================================
local function startAntiCollision()
    if antiCollisionConn then return end
    antiCollisionConn = RunService.Heartbeat:Connect(function()
        if not antiCollisionEnabled then return end
        -- HRP du joueur local
        if hrp then
            pcall(function() hrp.CanCollide = false end)
        end
        -- Tous les parts du character local
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.CanCollide = false end)
                end
            end
        end
    end)
end

local function stopAntiCollision()
    if antiCollisionConn then antiCollisionConn:Disconnect(); antiCollisionConn = nil end
    -- Restore CanCollide on character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = true end)
            end
        end
    end
    if hrp then pcall(function() hrp.CanCollide = true end) end
end

-- Galaxy / Void Mode
local function setupGF()
    pcall(function()
        if not hrp then return end
        if galaxyVF then galaxyVF:Destroy() end
        if galaxyAtt then galaxyAtt:Destroy() end
        galaxyAtt=Instance.new("Attachment"); galaxyAtt.Parent=hrp
        galaxyVF=Instance.new("VectorForce")
        galaxyVF.Attachment0=galaxyAtt; galaxyVF.ApplyAtCenterOfMass=true
        galaxyVF.RelativeTo=Enum.ActuatorRelativeTo.World; galaxyVF.Force=Vector3.zero; galaxyVF.Parent=hrp
    end)
end
local function updateGF()
    if not galaxyEnabled or not galaxyVF or not char then return end
    pcall(function()
        local mass=0
        for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
        local tG=DEFAULT_GRAVITY*(GALAXY_GRAVITY_PERCENT/100)
        galaxyVF.Force=Vector3.new(0, mass*(DEFAULT_GRAVITY-tG)*0.95, 0)
    end)
end
local function adjGalaxyJump()
    if not hum then return end
    if galaxyEnabled then
        local ratio=math.sqrt((DEFAULT_GRAVITY*(GALAXY_GRAVITY_PERCENT/100))/DEFAULT_GRAVITY)
        hum.JumpPower=originalJumpPower*ratio
    else hum.JumpPower=originalJumpPower end
end
local function doGalaxyHop()
    if tick()-galaxyLastHop<GALAXY_HOP_COOLDOWN then return end
    galaxyLastHop=tick()
    if not hrp or not hum then return end
    if hum.FloorMaterial==Enum.Material.Air then
        hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X, INF_JUMP_POWER, hrp.AssemblyLinearVelocity.Z)
    end
end
local function startGalaxy()
    task.spawn(function()
        task.wait(2); galaxyEnabled=true; hopsEnabled=true; setupGF(); adjGalaxyJump()
    end)
end
local function stopGalaxy()
    galaxyEnabled=false; hopsEnabled=false
    if galaxyVF then galaxyVF:Destroy(); galaxyVF=nil end
    if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt=nil end
    adjGalaxyJump()
end

-- Unwalk
local function startUnwalk()
    if not char then return end
    local a=char:FindFirstChild("Animate")
    if a then savedAnimate=a:Clone(); a.Disabled=true; task.wait(); a:Destroy() end
    local h2=char:FindFirstChildOfClass("Humanoid")
    if h2 then for _,t in ipairs(h2:GetPlayingAnimationTracks()) do t:Stop() end end
end
local function stopUnwalk()
    if savedAnimate and char then local n=savedAnimate:Clone(); n.Parent=char; n.Disabled=false end
end

-- Float
local function startFloat()
    if not hrp or floatConn then return end
    floatOrigY=hrp.Position.Y; floatEnabled=true
    hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X, 500, hrp.AssemblyLinearVelocity.Z)
    floatConn=RunService.Heartbeat:Connect(function()
        if not floatEnabled or not hrp then return end
        local diff=(floatOrigY+floatHeight)-hrp.Position.Y
        if math.abs(diff)>0.1 then
            hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X, math.clamp(diff*25,-150,150), hrp.AssemblyLinearVelocity.Z)
        else
            hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end)
end
local function stopFloat()
    floatEnabled=false
    if floatConn then floatConn:Disconnect(); floatConn=nil end
    -- On remet juste Y Ã  0, pas de -500 qui fait tomber brutalement
    if hrp then
        hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
    end
end

-- Optimizer
local function enableOptimizer()
    if getgenv and getgenv().OPT_ON then return end
    if getgenv then getgenv().OPT_ON=true end
    pcall(function()
        settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
        Lighting.GlobalShadows=false; Lighting.Brightness=2; Lighting.FogEnd=9e9; Lighting.FogStart=9e9
        for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=false end end
    end)
    pcall(function()
        for _,o in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then
                    o.Enabled=false; o:Destroy()
                elseif o:IsA("BasePart") then
                    o.CastShadow=false; o.Material=Enum.Material.Plastic
                    for _,ch in ipairs(o:GetChildren()) do
                        if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then ch:Destroy() end
                    end
                elseif o:IsA("Sky") then o:Destroy() end
            end)
        end
    end)
    pcall(function()
        for _,o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and o.Anchored and (o.Name:lower():find("base") or (o.Parent and o.Parent.Name:lower():find("base"))) then
                originalTransparency[o]=o.LocalTransparencyModifier; o.LocalTransparencyModifier=0.88
            end
        end
    end)
end
local function disableOptimizer()
    if getgenv then getgenv().OPT_ON=false end
    for p,v in pairs(originalTransparency) do if p then p.LocalTransparencyModifier=v end end
    originalTransparency={}
end

-- Bat Aimbot
local function nearestBatTarget()
    if not hrp then return nil, math.huge end
    local best, bd = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local th=p.Character:FindFirstChild("HumanoidRootPart")
            local thm=p.Character:FindFirstChildOfClass("Humanoid")
            if th and thm and thm.Health>0 then
                local d=(th.Position-hrp.Position).Magnitude
                if d<bd then bd=d; best=th end
            end
        end
    end
    return best, bd
end
local function closestLookTgt()
    if not hrp then return nil end
    local best, bd=nil, BAT_LOOK_DIST
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d=(hrp.Position-p.Character.HumanoidRootPart.Position).Magnitude
            if d<bd then bd=d; best=p.Character.HumanoidRootPart end
        end
    end
    return best
end
local function startLookAt()
    if not hrp or not hum then return end
    hum.AutoRotate=false
    batAtt=Instance.new("Attachment",hrp)
    batAlignOri=Instance.new("AlignOrientation")
    batAlignOri.Attachment0=batAtt; batAlignOri.Mode=Enum.OrientationAlignmentMode.OneAttachment
    batAlignOri.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    batAlignOri.Responsiveness=1000; batAlignOri.RigidityEnabled=true; batAlignOri.Parent=hrp
    batLookConn=RunService.RenderStepped:Connect(function()
        if not hrp or not batAlignOri then return end
        local t=closestLookTgt(); if not t then return end
        batAlignOri.CFrame=CFrame.lookAt(hrp.Position,Vector3.new(t.Position.X,hrp.Position.Y,t.Position.Z))
    end)
end
local function stopLookAt()
    if batLookConn then batLookConn:Disconnect(); batLookConn=nil end
    if batAlignOri then batAlignOri:Destroy(); batAlignOri=nil end
    if batAtt then batAtt:Destroy(); batAtt=nil end
    if hum then hum.AutoRotate=true end
end
local function stopBatAimbot()
    batAimbotToggled=false; stopLookAt()
    if hrp then hrp.AssemblyLinearVelocity=Vector3.zero end
end
local function startBatAimbot()
    stopBatAimbot(); batAimbotToggled=true
    if not char or not hrp or not hum then return end
    startLookAt()
end

RunService.Heartbeat:Connect(function()
    if not batAimbotToggled or not char or not hrp or not hum then return end
    hrp.CanCollide=false
    local tgt, dist=nearestBatTarget(); if not tgt then return end
    hrp.AssemblyLinearVelocity=(tgt.Position-hrp.Position).Unit*BAT_MOVE_SPEED
    if dist<=BAT_ENGAGE_RANGE then
        if tick()-lastEquipTick>=BAT_LOOP_TIME then
            local bp=LocalPlayer:FindFirstChild("Backpack")
            local bat=char:FindFirstChild("Bat") or (bp and bp:FindFirstChild("Bat"))
            if bat and hum then hum:EquipTool(bat) end
            lastEquipTick=tick()
        end
        if tick()-lastUseTick>=BAT_LOOP_TIME then
            local bat=char:FindFirstChild("Bat"); if bat then bat:Activate() end
            lastUseTick=tick()
        end
    end
end)

-- Auto movement
local function nineStop()
    ninePatrolMode="none"; nineCurrentWaypoint=1
    if hrp then hrp.AssemblyLinearVelocity=Vector3.new(0,hrp.AssemblyLinearVelocity.Y,0) end
end
local function nineStart(mode) ninePatrolMode=mode; nineCurrentWaypoint=1 end

RunService.Heartbeat:Connect(function()
    if ninePatrolMode=="none" or not hrp then return end
    local wps = ninePatrolMode=="right" and rightWaypoints or leftWaypoints
    local tp=wps[nineCurrentWaypoint]; local cp=hrp.Position
    local txz=Vector3.new(tp.X,0,tp.Z); local cxz=Vector3.new(cp.X,0,cp.Z)
    local spd=nineCurrentWaypoint>=3 and (stealSpeedEnabled and STEAL_SPEED or NORMAL_SPEED) or NORMAL_SPEED
    if (txz-cxz).Magnitude>3 then
        local dir=(txz-cxz).Unit
        hrp.AssemblyLinearVelocity=Vector3.new(dir.X*spd, hrp.AssemblyLinearVelocity.Y, dir.Z*spd)
    else
        if nineCurrentWaypoint==#wps then
            local side=ninePatrolMode; nineStop()
            task.spawn(function()
                task.wait(AUTO_START_DELAY)
                if (side=="left" and autoLeftEnabled) or (side=="right" and autoRightEnabled) then nineStart(side) end
            end)
        else nineCurrentWaypoint=nineCurrentWaypoint+1 end
    end
end)

-- Auto steal
local function myPlot(pn)
    local plots=workspace:FindFirstChild("Plots"); if not plots then return false end
    local plot=plots:FindFirstChild(pn); if not plot then return false end
    local sign=plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb=sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled
end
local function findPrompt()
    if not hrp then return nil end
    local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end
    local bp, bd, bn = nil, math.huge, nil
    for _,plot in ipairs(plots:GetChildren()) do
        if myPlot(plot.Name) then continue end
        local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base=pod:FindFirstChild("Base"); local sp=base and base:FindFirstChild("Spawn")
                if sp then
                    local d=(sp.Position-hrp.Position).Magnitude
                    if d<bd and d<=STEAL_RADIUS then
                        local att=sp:FindFirstChild("PromptAttachment")
                        if att then
                            for _,ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then bp=ch;bd=d;bn=pod.Name;break end
                            end
                        end
                    end
                end
            end)
        end
    end
    return bp, bd, bn
end

local ProgFill, ProgPct, ProgLabel = nil, nil, nil
local function resetProg()
    if ProgLabel then ProgLabel.Text="" end
    if ProgPct then ProgPct.Text="0%" end
    if ProgFill then ProgFill.Size=UDim2.new(0,0,1,0) end
end
local function execSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt]={hold={},trigger={},ready=true}
        pcall(function()
            if getconnections then
                for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold,c.Function) end
                end
                for _,c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger,c.Function) end
                end
            end
        end)
    end
    local data=StealData[prompt]; if not data.ready then return end
    data.ready=false; isStealing=true; stealStartTime=tick()
    if ProgLabel then ProgLabel.Text=name or "STEALING..." end
    if progressConn then progressConn:Disconnect(); progressConn=nil end
    progressConn=RunService.Heartbeat:Connect(function()
        if not isStealing then if progressConn then progressConn:Disconnect();progressConn=nil end return end
        local prog=math.clamp((tick()-stealStartTime)/STEAL_DURATION,0,1)
        if ProgFill then ProgFill.Size=UDim2.new(prog,0,1,0) end
        if ProgPct then ProgPct.Text=math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        for _,f in ipairs(data.hold) do task.spawn(f) end
        task.wait(STEAL_DURATION)
        for _,f in ipairs(data.trigger) do task.spawn(f) end
        if progressConn then progressConn:Disconnect();progressConn=nil end
        resetProg(); data.ready=true; isStealing=false
    end)
end
local function startAutoSteal()
    if autoStealConn then return end
    autoStealConn=RunService.Heartbeat:Connect(function()
        if not autoStealEnabled or isStealing then return end
        local p,_,n=findPrompt(); if p then execSteal(p,n) end
    end)
end
local function stopAutoSteal()
    if autoStealConn then autoStealConn:Disconnect();autoStealConn=nil end
    isStealing=false; if progressConn then progressConn:Disconnect();progressConn=nil end; resetProg()
end

-- ============================================================
--  DROP BRAINROT
--  Monte en l'air rapidement puis redescend fort pour lÃ¢cher l'animal
-- ============================================================

local function dropBrainrot()
    if not hrp or not char then return end
    -- Monte haut en l'air rapidement
    hrp.AssemblyLinearVelocity = Vector3.new(
        hrp.AssemblyLinearVelocity.X,
        80,
        hrp.AssemblyLinearVelocity.Z
    )
    task.wait(0.3)
    -- Redescend d'un coup fort â c'est ce qui fait lÃ¢cher l'animal
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            -120,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end

-- ============================================================
--  TP SYSTEM (Nine Hub style)
-- ============================================================
local tpFinalLeft_  = Vector3.new(-483.59, -5.04, 104.24)
local tpFinalRight_ = Vector3.new(-483.51, -5.10, 18.89)
local tpCheckA_     = Vector3.new(-472.60, -7.00, 57.52)
local tpCheckLeft_  = Vector3.new(-472.65, -7.00, 95.69)
local tpCheckRight_ = Vector3.new(-471.76, -7.00, 26.22)

local function tpMove(pos)
    if not char then return end
    char:PivotTo(CFrame.new(pos))
    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
end

local function doTPLeft()
    tpMove(tpCheckA_);   task.wait(0.1)
    tpMove(tpCheckLeft_); task.wait(0.1)
    tpMove(tpFinalLeft_)
    lastTpSide = "left"
end

local function doTPRight()
    tpMove(tpCheckA_);    task.wait(0.1)
    tpMove(tpCheckRight_); task.wait(0.1)
    tpMove(tpFinalRight_)
    lastTpSide = "right"
end

local function isKnockedChar()
    if not char then return false end
    local h2 = char:FindFirstChildOfClass("Humanoid")
    if h2 then
        local st = h2:GetState()
        -- Tous les Ã©tats qui indiquent un coup reÃ§u
        if st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.FallingDown
        or st == Enum.HumanoidStateType.GettingUp then
            return true
        end
    end
    -- BoolValue "Ragdoll" / "IsRagdoll" que certains jeux utilisent
    local rv = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
    if rv and rv:IsA("BoolValue") and rv.Value then return true end
    -- VÃ©locitÃ© Y trÃ¨s nÃ©gative = on vient de se faire envoyer
    if hrp and hrp.AssemblyLinearVelocity.Y < -35 then return true end
    -- BallSocketConstraints = ragdoll physique actif
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") then return true end
    end
    return false
end

local lastKnockTime = 0
local function startRagdollDetector()
    if ragdollDetConn then ragdollDetConn:Disconnect() end
    ragdollDetConn = RunService.Heartbeat:Connect(function()
        if not ragdollAutoActive or not char then return end
        local nowKnocked = isKnockedChar()
        if nowKnocked and not ragdollWasActive then
            -- Anti-spam : pas plus d'un TP toutes les 1.5 secondes
            if tick() - lastKnockTime < 1.5 then return end
            lastKnockTime = tick()
            ragdollWasActive = true
            task.spawn(function()
                task.wait(0.1) -- laisser le jeu finir l'animation du coup
                if lastTpSide == "left" then
                    doTPLeft()
                    task.wait(0.15)
                    if not autoLeftEnabled then
                        autoLeftEnabled = true
                        nineStop(); nineStart("left")
                    end
                elseif lastTpSide == "right" then
                    doTPRight()
                    task.wait(0.15)
                    if not autoRightEnabled then
                        autoRightEnabled = true
                        nineStop(); nineStart("right")
                    end
                end
                task.wait(0.5)
                ragdollWasActive = false
            end)
        elseif not nowKnocked then
            ragdollWasActive = false
        end
    end)
end

local function stopRagdollDetector()
    if ragdollDetConn then ragdollDetConn:Disconnect(); ragdollDetConn = nil end
    ragdollWasActive = false
end

-- ============================================================
--  UI REFERENCES (buttons that need state sync)
-- ============================================================
local uiRows = {}       -- uiRows[name] = {row, dot, label, active}
local kbBadges = {}     -- kbBadges[keybindKey] = TextButton

local function setRowActive(name, state)
    local r=uiRows[name]; if not r then return end
    r.active=state
    r.row.BackgroundColor3 = state and C.ROW_ON or C.ROW
    r.dot.BackgroundColor3 = state and C.DOT_ON or C.DOT_OFF
    r.label.TextColor3 = state and C.ACCENT or C.TEXT
end

-- ============================================================
--  SET FUNCTIONS (with mutual exclusion)
-- ============================================================
local function setAutoLeft(state)
    if autoLeftEnabled==state then return end
    if state and batAimbotToggled then stopBatAimbot(); batAimbotToggled=false; setRowActive("Bat Aimbot",false) end
    if state and autoRightEnabled then autoRightEnabled=false; nineStop(); setRowActive("Auto Right",false) end
    autoLeftEnabled=state
    if state then nineStop(); nineStart("left") else nineStop() end
    setRowActive("Auto Left",autoLeftEnabled)
end
local function setAutoRight(state)
    if autoRightEnabled==state then return end
    if state and batAimbotToggled then stopBatAimbot(); batAimbotToggled=false; setRowActive("Bat Aimbot",false) end
    if state and autoLeftEnabled then autoLeftEnabled=false; nineStop(); setRowActive("Auto Left",false) end
    autoRightEnabled=state
    if state then nineStop(); nineStart("right") else nineStop() end
    setRowActive("Auto Right",autoRightEnabled)
end
local function setBatAimbot(state)
    if batAimbotToggled==state then return end
    if state then
        if autoLeftEnabled then autoLeftEnabled=false; nineStop(); setRowActive("Auto Left",false) end
        if autoRightEnabled then autoRightEnabled=false; nineStop(); setRowActive("Auto Right",false) end
    end
    batAimbotToggled=state
    if state then startBatAimbot() else stopBatAimbot() end
    setRowActive("Bat Aimbot",batAimbotToggled)
end

-- TP activate functions â placÃ©es ICI car elles ont besoin de setRowActive,
-- nineStop, nineStart, setAutoLeft, setAutoRight qui sont tous dÃ©finis avant
local function activateTPLeft()
    ragdollAutoActive = true
    setRowActive("TP Right", false)
    setRowActive("TP Left", true)
    startRagdollDetector()
    task.spawn(function()
        doTPLeft()
        task.wait(0.2)
        -- coupe l'autre cÃ´tÃ© et lance auto left
        if autoRightEnabled then autoRightEnabled=false; nineStop(); setRowActive("Auto Right",false) end
        autoLeftEnabled = true
        nineStop(); nineStart("left")
        setRowActive("Auto Left", true)
    end)
end

local function activateTPRight()
    ragdollAutoActive = true
    setRowActive("TP Left", false)
    setRowActive("TP Right", true)
    startRagdollDetector()
    task.spawn(function()
        doTPRight()
        task.wait(0.2)
        if autoLeftEnabled then autoLeftEnabled=false; nineStop(); setRowActive("Auto Left",false) end
        autoRightEnabled = true
        nineStop(); nineStart("right")
        setRowActive("Auto Right", true)
    end)
end

local function deactivateTP()
    ragdollAutoActive = false
    stopRagdollDetector()
    setRowActive("TP Left", false)
    setRowActive("TP Right", false)
end

-- ============================================================
--  CHARACTER SETUP
-- ============================================================
local function setupChar(c)
    char=c; hum=c:WaitForChild("Humanoid",5); hrp=c:WaitForChild("HumanoidRootPart",5)
    task.wait(0.5); if not hum or not hrp then return end
    -- speed label
    local head=c:FindFirstChild("Head")
    if head then
        local bb=Instance.new("BillboardGui",head)
        bb.Size=UDim2.new(0,140,0,22); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
        local sl=Instance.new("TextLabel",bb)
        sl.Size=UDim2.new(1,0,1,0); sl.BackgroundTransparency=1
        sl.TextColor3=C.ACCENT; sl.Font=Enum.Font.GothamBold; sl.TextScaled=true
        sl.TextStrokeTransparency=0.1; sl.TextStrokeColor3=Color3.new(0,0,0)
        RunService.RenderStepped:Connect(function()
            if hrp then pcall(function()
                local spd=math.sqrt(hrp.Velocity.X^2+hrp.Velocity.Z^2)
                sl.Text=string.format("%.1f",spd)
            end) end
        end)
    end
    if galaxyEnabled then setupGF(); adjGalaxyJump() end
    if unwalkEnabled then startUnwalk() end
    if spinBotEnabled then cleanSpin(); startSpinBot() end
    if espEnabled then enableESP() end
    if floatEnabled then if floatConn then floatConn:Disconnect();floatConn=nil end; startFloat() end
    if antiCollisionEnabled then
        if antiCollisionConn then antiCollisionConn:Disconnect(); antiCollisionConn=nil end
        startAntiCollision()
    end
    task.spawn(function() task.wait(1); if hum and hum.JumpPower>0 then originalJumpPower=hum.JumpPower end end)
end

-- ============================================================
--  BUILD GUI
-- ============================================================
local SG=Instance.new("ScreenGui")
SG.Name="RokixK7GUI"; SG.ResetOnSpawn=false; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset=true
local gp; pcall(function() if gethui then gp=gethui() elseif syn and syn.protect_gui then gp=LocalPlayer:WaitForChild("PlayerGui"); syn.protect_gui(SG) else gp=CoreGui end end)
if not gp then gp=LocalPlayer:WaitForChild("PlayerGui") end
SG.Parent=gp

-- ---- PROGRESS BAR ----
local PBC=Instance.new("Frame",SG)
PBC.Size=UDim2.new(0,px(380),0,px(58)); PBC.Position=UDim2.new(0.5,-px(190),1,-px(160))
PBC.BackgroundColor3=Color3.fromRGB(12,12,16); PBC.BackgroundTransparency=0.08; PBC.BorderSizePixel=0; PBC.ClipsDescendants=true
Instance.new("UICorner",PBC).CornerRadius=UDim.new(0,px(12))
local pbStr=Instance.new("UIStroke",PBC); pbStr.Thickness=1.5; pbStr.Color=C.ACCENT
ProgPct=Instance.new("TextLabel",PBC); ProgPct.Size=UDim2.new(0,px(50),0,px(18)); ProgPct.Position=UDim2.new(0,px(10),0,px(5))
ProgPct.BackgroundTransparency=1; ProgPct.Text="0%"; ProgPct.TextColor3=C.WHITE; ProgPct.Font=Enum.Font.GothamBold; ProgPct.TextSize=px(10); ProgPct.TextXAlignment=Enum.TextXAlignment.Left; ProgPct.ZIndex=3
ProgLabel=Instance.new("TextLabel",PBC); ProgLabel.Size=UDim2.new(0,px(200),0,px(18)); ProgLabel.Position=UDim2.new(0,px(65),0,px(5))
ProgLabel.BackgroundTransparency=1; ProgLabel.Text=""; ProgLabel.TextColor3=C.ACCENT; ProgLabel.Font=Enum.Font.GothamBold; ProgLabel.TextSize=px(10); ProgLabel.TextXAlignment=Enum.TextXAlignment.Left; ProgLabel.ZIndex=3
local pTrack=Instance.new("Frame",PBC); pTrack.Size=UDim2.new(0.88,0,0,px(14)); pTrack.Position=UDim2.new(0.06,0,1,-px(20))
pTrack.BackgroundColor3=Color3.fromRGB(28,28,35); pTrack.ZIndex=2; pTrack.BorderSizePixel=0; pTrack.BackgroundTransparency=0.25
Instance.new("UICorner",pTrack).CornerRadius=UDim.new(0,px(5))
ProgFill=Instance.new("Frame",pTrack); ProgFill.Size=UDim2.new(0,0,1,0); ProgFill.BackgroundColor3=C.ACCENT; ProgFill.ZIndex=2; ProgFill.BorderSizePixel=0
Instance.new("UICorner",ProgFill).CornerRadius=UDim.new(0,px(5))

-- ---- MAIN PANEL ----
local PANEL_W = px(240)
local Main=Instance.new("Frame",SG)
Main.Name="Main"; Main.Size=UDim2.new(0,PANEL_W,0,px(620))
Main.Position=UDim2.new(0.5,-PANEL_W/2,0.5,-px(310))
Main.BackgroundColor3=C.BG; Main.BorderSizePixel=0; Main.Active=true; Main.ClipsDescendants=true
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,px(14))
local mainStr=Instance.new("UIStroke",Main); mainStr.Color=C.ACCENT; mainStr.Thickness=1.5

-- Header
local Header=Instance.new("Frame",Main)
Header.Size=UDim2.new(1,0,0,px(52)); Header.BackgroundColor3=C.PANEL; Header.BorderSizePixel=0
Instance.new("UICorner",Header).CornerRadius=UDim.new(0,px(14))
local hFix=Instance.new("Frame",Header); hFix.Size=UDim2.new(1,0,0,px(14)); hFix.Position=UDim2.new(0,0,1,-px(14)); hFix.BackgroundColor3=C.PANEL; hFix.BorderSizePixel=0
-- Red close dot
local closeBtn=Instance.new("TextButton",Header); closeBtn.Size=UDim2.new(0,px(14),0,px(14))
closeBtn.Position=UDim2.new(0,px(10),0.5,-px(7)); closeBtn.BackgroundColor3=C.CLOSE; closeBtn.Text=""; closeBtn.BorderSizePixel=0
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function() Main.Visible=false end)
-- Title
local TitleLbl=Instance.new("TextLabel",Header); TitleLbl.Size=UDim2.new(1,-px(60),1,0); TitleLbl.Position=UDim2.new(0,px(30),0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="ROKIX HUB"; TitleLbl.TextColor3=C.ACCENT
TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=px(14); TitleLbl.TextXAlignment=Enum.TextXAlignment.Center

-- Scroll content
local Scroll=Instance.new("ScrollingFrame",Main)
Scroll.Size=UDim2.new(1,0,1,-px(56)); Scroll.Position=UDim2.new(0,0,0,px(56))
Scroll.BackgroundTransparency=1; Scroll.BorderSizePixel=0; Scroll.CanvasSize=UDim2.new(0,0,0,0)
Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; Scroll.ScrollBarThickness=px(3); Scroll.ScrollBarImageColor3=C.ACCENT_DIM
local SList=Instance.new("UIListLayout",Scroll); SList.Padding=UDim.new(0,0); SList.SortOrder=Enum.SortOrder.LayoutOrder

-- ---- BUILDER HELPERS ----
local ORDER = 0
local function nextOrder() ORDER=ORDER+1; return ORDER end

local function makeSectionLabel(text)
    local F=Instance.new("Frame",Scroll); F.Size=UDim2.new(1,0,0,px(28)); F.BackgroundTransparency=1; F.LayoutOrder=nextOrder()
    local line1=Instance.new("Frame",F); line1.Size=UDim2.new(0.18,0,0,1); line1.Position=UDim2.new(0,px(8),0.5,0); line1.BackgroundColor3=C.ACCENT_DIM; line1.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",F); lbl.Size=UDim2.new(0.64,0,1,0); lbl.Position=UDim2.new(0.18,0,0,0); lbl.BackgroundTransparency=1
    lbl.Text="â "..text:upper().." â"; lbl.TextColor3=C.ACCENT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=px(10); lbl.TextXAlignment=Enum.TextXAlignment.Center
    local line2=Instance.new("Frame",F); line2.Size=UDim2.new(0.18,0,0,1); line2.Position=UDim2.new(0.82,0,0.5,0); line2.BackgroundColor3=C.ACCENT_DIM; line2.BorderSizePixel=0
end

-- Toggle row (K7 style: dot + label + click whole row)
local function makeToggleRow(name, defaultState, onToggle)
    local ROW=Instance.new("Frame",Scroll)
    ROW.Size=UDim2.new(1,0,0,px(36)); ROW.BackgroundColor3=defaultState and C.ROW_ON or C.ROW; ROW.BorderSizePixel=0; ROW.LayoutOrder=nextOrder()
    local Dot=Instance.new("Frame",ROW); Dot.Size=UDim2.new(0,px(8),0,px(8)); Dot.Position=UDim2.new(0,px(10),0.5,-px(4))
    Dot.BackgroundColor3=defaultState and C.DOT_ON or C.DOT_OFF; Dot.BorderSizePixel=0
    Instance.new("UICorner",Dot).CornerRadius=UDim.new(1,0)
    local Lbl=Instance.new("TextLabel",ROW); Lbl.Size=UDim2.new(1,-px(70),1,0); Lbl.Position=UDim2.new(0,px(26),0,0)
    Lbl.BackgroundTransparency=1; Lbl.Text=name; Lbl.TextColor3=defaultState and C.ACCENT or C.TEXT
    Lbl.Font=Enum.Font.GothamBold; Lbl.TextSize=px(12); Lbl.TextXAlignment=Enum.TextXAlignment.Left
    -- status tag
    local Tag=Instance.new("TextLabel",ROW); Tag.Size=UDim2.new(0,px(40),0,px(18)); Tag.Position=UDim2.new(1,-px(46),0.5,-px(9))
    Tag.BackgroundColor3=defaultState and C.ACCENT or Color3.fromRGB(35,35,45); Tag.BorderSizePixel=0
    Tag.Text=defaultState and "ON" or "OFF"; Tag.TextColor3=defaultState and Color3.fromRGB(0,0,0) or C.TEXT_DIM
    Tag.Font=Enum.Font.GothamBold; Tag.TextSize=px(9)
    Instance.new("UICorner",Tag).CornerRadius=UDim.new(0,px(4))
    -- divider
    local div=Instance.new("Frame",ROW); div.Size=UDim2.new(1,0,0,1); div.Position=UDim2.new(0,0,1,-1); div.BackgroundColor3=Color3.fromRGB(25,25,32); div.BorderSizePixel=0
    uiRows[name]={row=ROW, dot=Dot, label=Lbl, tag=Tag, active=defaultState}
    local Btn=Instance.new("TextButton",ROW); Btn.Size=UDim2.new(1,0,1,0); Btn.BackgroundTransparency=1; Btn.Text=""
    Btn.MouseButton1Click:Connect(function()
        local ns=not uiRows[name].active
        uiRows[name].active=ns
        ROW.BackgroundColor3=ns and C.ROW_ON or C.ROW
        Dot.BackgroundColor3=ns and C.DOT_ON or C.DOT_OFF
        Lbl.TextColor3=ns and C.ACCENT or C.TEXT
        Tag.BackgroundColor3=ns and C.ACCENT or Color3.fromRGB(35,35,45)
        Tag.Text=ns and "ON" or "OFF"
        Tag.TextColor3=ns and Color3.fromRGB(0,0,0) or C.TEXT_DIM
        onToggle(ns)
    end)
end

-- Combat row with keybind badge (cyan pill, clickable to rebind)
local listeningFor=nil
local function makeCombatRow(name, keybindKey, defaultState, onToggle)
    local ROW=Instance.new("Frame",Scroll)
    ROW.Size=UDim2.new(1,0,0,px(36)); ROW.BackgroundColor3=defaultState and C.ROW_ON or C.ROW; ROW.BorderSizePixel=0; ROW.LayoutOrder=nextOrder()
    -- keybind badge
    local Badge=Instance.new("TextButton",ROW); Badge.Size=UDim2.new(0,px(32),0,px(20)); Badge.Position=UDim2.new(0,px(6),0.5,-px(10))
    Badge.BackgroundColor3=C.ACCENT; Badge.BorderSizePixel=0; Badge.Font=Enum.Font.GothamBold; Badge.TextSize=px(9)
    Badge.TextColor3=Color3.fromRGB(0,0,0); Badge.Text=KB[keybindKey] and KB[keybindKey].Name or "?"; Badge.ZIndex=3
    Instance.new("UICorner",Badge).CornerRadius=UDim.new(0,px(4))
    kbBadges[keybindKey]=Badge
    Badge.MouseButton1Click:Connect(function()
        if listeningFor then return end
        listeningFor=keybindKey; Badge.Text="..."; Badge.BackgroundColor3=Color3.fromRGB(40,40,55); Badge.TextColor3=C.WHITE
        local conn; conn=UserInputService.InputBegan:Connect(function(input)
            if listeningFor~=keybindKey then conn:Disconnect(); return end
            if input.UserInputType==Enum.UserInputType.Keyboard then
                KB[keybindKey]=input.KeyCode; Badge.Text=input.KeyCode.Name
                Badge.BackgroundColor3=C.ACCENT; Badge.TextColor3=Color3.fromRGB(0,0,0)
                listeningFor=nil; saveConfig(); conn:Disconnect()
                -- update keybinds section label too
                if kbBadges[keybindKey.."_section"] then kbBadges[keybindKey.."_section"].Text=input.KeyCode.Name end
            end
        end)
        task.delay(8,function()
            if listeningFor==keybindKey then
                Badge.Text=KB[keybindKey] and KB[keybindKey].Name or "?"; Badge.BackgroundColor3=C.ACCENT; Badge.TextColor3=Color3.fromRGB(0,0,0); listeningFor=nil
            end
        end)
    end)
    -- dot
    local Dot=Instance.new("Frame",ROW); Dot.Size=UDim2.new(0,px(6),0,px(6)); Dot.Position=UDim2.new(0,px(44),0.5,-px(3))
    Dot.BackgroundColor3=defaultState and C.DOT_ON or C.DOT_OFF; Dot.BorderSizePixel=0
    Instance.new("UICorner",Dot).CornerRadius=UDim.new(1,0)
    local Lbl=Instance.new("TextLabel",ROW); Lbl.Size=UDim2.new(1,-px(120),1,0); Lbl.Position=UDim2.new(0,px(56),0,0)
    Lbl.BackgroundTransparency=1; Lbl.Text=name; Lbl.TextColor3=defaultState and C.ACCENT or C.TEXT
    Lbl.Font=Enum.Font.GothamBold; Lbl.TextSize=px(12); Lbl.TextXAlignment=Enum.TextXAlignment.Left
    local Tag=Instance.new("TextLabel",ROW); Tag.Size=UDim2.new(0,px(36),0,px(18)); Tag.Position=UDim2.new(1,-px(42),0.5,-px(9))
    Tag.BackgroundColor3=defaultState and C.ACCENT or Color3.fromRGB(35,35,45); Tag.BorderSizePixel=0
    Tag.Text=defaultState and "ON" or "OFF"; Tag.TextColor3=defaultState and Color3.fromRGB(0,0,0) or C.TEXT_DIM
    Tag.Font=Enum.Font.GothamBold; Tag.TextSize=px(9)
    Instance.new("UICorner",Tag).CornerRadius=UDim.new(0,px(4))
    local div=Instance.new("Frame",ROW); div.Size=UDim2.new(1,0,0,1); div.Position=UDim2.new(0,0,1,-1); div.BackgroundColor3=Color3.fromRGB(25,25,32); div.BorderSizePixel=0
    uiRows[name]={row=ROW,dot=Dot,label=Lbl,tag=Tag,active=defaultState}
    local Btn=Instance.new("TextButton",ROW); Btn.Size=UDim2.new(1,0,1,0); Btn.BackgroundTransparency=1; Btn.Text=""; Btn.ZIndex=1
    Btn.MouseButton1Click:Connect(function()
        local ns=not uiRows[name].active
        uiRows[name].active=ns
        ROW.BackgroundColor3=ns and C.ROW_ON or C.ROW
        Dot.BackgroundColor3=ns and C.DOT_ON or C.DOT_OFF
        Lbl.TextColor3=ns and C.ACCENT or C.TEXT
        Tag.BackgroundColor3=ns and C.ACCENT or Color3.fromRGB(35,35,45)
        Tag.Text=ns and "ON" or "OFF"; Tag.TextColor3=ns and Color3.fromRGB(0,0,0) or C.TEXT_DIM
        onToggle(ns)
    end)
end

-- Value input row
local function makeValueRow(name, default, minV, maxV, decimals, onValue)
    local ROW=Instance.new("Frame",Scroll)
    ROW.Size=UDim2.new(1,0,0,px(36)); ROW.BackgroundColor3=C.ROW; ROW.BorderSizePixel=0; ROW.LayoutOrder=nextOrder()
    local Lbl=Instance.new("TextLabel",ROW); Lbl.Size=UDim2.new(1,-px(80),1,0); Lbl.Position=UDim2.new(0,px(14),0,0)
    Lbl.BackgroundTransparency=1; Lbl.Text=name; Lbl.TextColor3=C.TEXT; Lbl.Font=Enum.Font.GothamBold; Lbl.TextSize=px(12); Lbl.TextXAlignment=Enum.TextXAlignment.Left
    local Box=Instance.new("TextBox",ROW); Box.Size=UDim2.new(0,px(62),0,px(22)); Box.Position=UDim2.new(1,-px(70),0.5,-px(11))
    Box.BackgroundColor3=Color3.fromRGB(20,20,28); Box.TextColor3=C.ACCENT; Box.Font=Enum.Font.GothamBold; Box.TextSize=px(12)
    Box.TextXAlignment=Enum.TextXAlignment.Right; Box.BorderSizePixel=0; Box.ClearTextOnFocus=false
    local fmt=decimals and function(v) return string.format("%.1f",v) end or function(v) return tostring(math.floor(v)) end
    Box.Text=fmt(default)
    Instance.new("UICorner",Box).CornerRadius=UDim.new(0,px(5))
    local div=Instance.new("Frame",ROW); div.Size=UDim2.new(1,0,0,1); div.Position=UDim2.new(0,0,1,-1); div.BackgroundColor3=Color3.fromRGB(25,25,32); div.BorderSizePixel=0
    local cur=default
    Box.FocusLost:Connect(function()
        local n=tonumber(Box.Text)
        if n then cur=math.clamp(n,minV,maxV); if not decimals then cur=math.floor(cur) end; Box.Text=fmt(cur); onValue(cur)
        else Box.Text=fmt(cur) end
    end)
end

-- Keybind-only row (for settings section)
local function makeKBRow(label, keybindKey)
    local ROW=Instance.new("Frame",Scroll)
    ROW.Size=UDim2.new(1,0,0,px(36)); ROW.BackgroundColor3=C.ROW; ROW.BorderSizePixel=0; ROW.LayoutOrder=nextOrder()
    local Lbl=Instance.new("TextLabel",ROW); Lbl.Size=UDim2.new(0.5,0,1,0); Lbl.Position=UDim2.new(0,px(12),0,0)
    Lbl.BackgroundTransparency=1; Lbl.Text=label; Lbl.TextColor3=C.TEXT; Lbl.Font=Enum.Font.GothamBold; Lbl.TextSize=px(12); Lbl.TextXAlignment=Enum.TextXAlignment.Left
    local KeyBtn=Instance.new("TextButton",ROW); KeyBtn.Size=UDim2.new(0,px(100),0,px(22)); KeyBtn.Position=UDim2.new(1,-px(108),0.5,-px(11))
    KeyBtn.BackgroundColor3=Color3.fromRGB(20,20,28); KeyBtn.Font=Enum.Font.GothamBold; KeyBtn.TextSize=px(11); KeyBtn.BorderSizePixel=0
    KeyBtn.TextColor3=C.ACCENT; KeyBtn.Text=KB[keybindKey] and KB[keybindKey].Name or "None"
    Instance.new("UICorner",KeyBtn).CornerRadius=UDim.new(0,px(5))
    kbBadges[keybindKey.."_section"]=KeyBtn
    local div=Instance.new("Frame",ROW); div.Size=UDim2.new(1,0,0,1); div.Position=UDim2.new(0,0,1,-1); div.BackgroundColor3=Color3.fromRGB(25,25,32); div.BorderSizePixel=0
    KeyBtn.MouseButton1Click:Connect(function()
        if listeningFor then return end
        listeningFor=keybindKey.."_sect"; KeyBtn.Text="Appuie..."; KeyBtn.BackgroundColor3=Color3.fromRGB(35,35,50); KeyBtn.TextColor3=C.WHITE
        local conn; conn=UserInputService.InputBegan:Connect(function(input)
            if listeningFor~=keybindKey.."_sect" then conn:Disconnect(); return end
            if input.UserInputType==Enum.UserInputType.Keyboard then
                KB[keybindKey]=input.KeyCode; KeyBtn.Text=input.KeyCode.Name
                KeyBtn.BackgroundColor3=Color3.fromRGB(20,20,28); KeyBtn.TextColor3=C.ACCENT
                -- sync combat badge
                if kbBadges[keybindKey] then kbBadges[keybindKey].Text=input.KeyCode.Name end
                listeningFor=nil; saveConfig(); conn:Disconnect()
            end
        end)
        task.delay(8,function()
            if listeningFor==keybindKey.."_sect" then
                KeyBtn.Text=KB[keybindKey] and KB[keybindKey].Name or "None"
                KeyBtn.BackgroundColor3=Color3.fromRGB(20,20,28); KeyBtn.TextColor3=C.ACCENT; listeningFor=nil
            end
        end)
    end)
end

-- Save button row
local function makeSaveRow()
    local ROW=Instance.new("Frame",Scroll)
    ROW.Size=UDim2.new(1,0,0,px(44)); ROW.BackgroundTransparency=1; ROW.BorderSizePixel=0; ROW.LayoutOrder=nextOrder()
    local Btn=Instance.new("TextButton",ROW); Btn.Size=UDim2.new(1,-px(20),0,px(34)); Btn.Position=UDim2.new(0,px(10),0.5,-px(17))
    Btn.BackgroundColor3=C.ACCENT; Btn.BorderSizePixel=0; Btn.Text="Sauvegarder Config"
    Btn.TextColor3=Color3.fromRGB(0,0,0); Btn.Font=Enum.Font.GothamBold; Btn.TextSize=px(12)
    Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,px(8))
    Btn.MouseButton1Click:Connect(function()
        saveConfig(); Btn.Text="Sauvegarde !"
        task.delay(1.5,function() Btn.Text="Sauvegarder Config" end)
    end)
end

-- ============================================================
--  BUILD ALL ROWS
-- ============================================================
makeSectionLabel("Speed")
makeValueRow("Speed Boost", NORMAL_SPEED, 10, 70, true, function(v) NORMAL_SPEED=v end)
makeValueRow("Carry Speed", CARRY_SPEED, 10, 150, true, function(v) CARRY_SPEED=v end)

makeSectionLabel("Movement")
makeToggleRow("Void Mode", galaxyEnabled, function(v)
    galaxyEnabled=v; if v then startGalaxy() else stopGalaxy() end
end)
makeValueRow("Hop Power", GALAXY_HOP_POWER, 5, 100, true, function(v) GALAXY_HOP_POWER=v end)
makeValueRow("Gravity %", GALAXY_GRAVITY_PERCENT, 10, 100, true, function(v) GALAXY_GRAVITY_PERCENT=v; if galaxyEnabled then adjGalaxyJump() end end)
makeToggleRow("Spin Bot", spinBotEnabled, function(v) spinBotEnabled=v; if v then startSpinBot() else stopSpinBot() end end)
makeValueRow("Spin Speed", SPIN_SPEED, 5, 50, true, function(v) SPIN_SPEED=v; if spinBAV then spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0) end end)
makeToggleRow("Unwalk", unwalkEnabled, function(v) unwalkEnabled=v; if v and char then startUnwalk() else stopUnwalk() end end)
makeCombatRow("Float", "Float", false, function(v) if v then startFloat() else stopFloat() end; setRowActive("Float",floatEnabled) end)
makeValueRow("Float Height", floatHeight, 2, 20, true, function(v) floatHeight=v end)

makeSectionLabel("Combat")
makeCombatRow("Auto Left",    "AutoLeft",    false, function(v) setAutoLeft(v) end)
makeCombatRow("Auto Right",   "AutoRight",   false, function(v) setAutoRight(v) end)
makeCombatRow("TP Left",      "TPLeft",      false, function(v)
    if v then
        activateTPLeft()
    else
        deactivateTP()
    end
end)
makeCombatRow("TP Right",     "TPRight",     false, function(v)
    if v then
        activateTPRight()
    else
        deactivateTP()
    end
end)
makeCombatRow("Carry Mode",   "SpeedToggle", false, function(v) speedToggled=v end)
makeCombatRow("Bat Aimbot",   "BatAimbot",   false, function(v) setBatAimbot(v) end)
makeCombatRow("Drop Brainrot","Drop",        false, function(v)
    if v then
        dropBrainrot()
        task.delay(0.3, function() setRowActive("Drop Brainrot", false) end)
    end
end)
makeToggleRow("Anti Ragdoll", antiRagdollEnabled, function(v) antiRagdollEnabled=v; if v then startAntiRagdoll() else stopAntiRagdoll() end end)
makeToggleRow("Anti Collision", antiCollisionEnabled, function(v)
    antiCollisionEnabled=v
    if v then startAntiCollision() else stopAntiCollision() end
    -- Sync bouton flottant
    if floatBtns["AntiCollision"] then floatBtns["AntiCollision"].updateVisual(v) end
end)
makeToggleRow("Speed Stealing", stealSpeedEnabled, function(v)
    stealSpeedEnabled = v
    if floatBtns["StealSpeed"] then floatBtns["StealSpeed"].updateVisual(v) end
end)
makeValueRow("Vitesse Steal", STEAL_SPEED, 5, 100, true, function(v) STEAL_SPEED=v end)
makeToggleRow("Auto Steal", autoStealEnabled, function(v) autoStealEnabled=v; if v then startAutoSteal() else stopAutoSteal() end end)
makeValueRow("Steal Radius", STEAL_RADIUS, 5, 200, false, function(v) STEAL_RADIUS=v end)
makeValueRow("Steal Duration", STEAL_DURATION, 0.1, 30, true, function(v) STEAL_DURATION=math.max(0.1,v) end)

makeSectionLabel("Visuals")
makeToggleRow("Player ESP", espEnabled, function(v) espEnabled=v; if v then enableESP() else disableESP() end end)
makeToggleRow("Optimizer + XRay", optimizerEnabled, function(v) optimizerEnabled=v; if v then enableOptimizer() else disableOptimizer() end end)

makeSectionLabel("Keybinds")
makeKBRow("Toggle GUI",   "ToggleGUI")
makeKBRow("Auto Left",    "AutoLeft")
makeKBRow("Auto Right",   "AutoRight")
makeKBRow("TP Left",      "TPLeft")
makeKBRow("TP Right",     "TPRight")
makeKBRow("Bat Aimbot",   "BatAimbot")
makeKBRow("Carry Mode",   "SpeedToggle")
makeKBRow("Float",        "Float")
makeKBRow("Drop Brainrot","Drop")

makeSaveRow()

-- ============================================================
--  DRAG HEADER
-- ============================================================
local dragging,dragStart,startPos=false,nil,nil
Header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)

-- ============================================================
--  TOGGLE BUTTON
-- ============================================================
local TB=Instance.new("TextButton",SG); TB.Size=UDim2.new(0,px(70),0,px(70))
TB.Position=isMobile and UDim2.new(1,-px(80),0,px(8)) or UDim2.new(0,px(10),0.5,-px(35))
TB.BackgroundColor3=Color3.fromRGB(6,6,10); TB.Text="R"; TB.TextColor3=C.ACCENT
TB.Font=Enum.Font.GothamBold; TB.TextSize=px(28); TB.Active=true; TB.BorderSizePixel=0
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,px(14))
local tbStr=Instance.new("UIStroke",TB); tbStr.Color=C.ACCENT; tbStr.Thickness=1.5
TB.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)

-- ============================================================
--  FLOATING BUTTONS GRID (style image â visible PC + mobile)
-- ============================================================
-- Dimensions d'un bouton
local BW = px(52)   -- largeur
local BH = px(46)   -- hauteur
local BGAP = px(5)  -- gap entre boutons
local BCOLS = 2      -- 2 colonnes

-- Conteneur principal â ancrÃ© en bas Ã  droite
local FBGrid = Instance.new("Frame", SG)
FBGrid.Name = "FloatGrid"
FBGrid.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
FBGrid.BackgroundTransparency = 0.1
FBGrid.BorderSizePixel = 0
FBGrid.AutomaticSize = Enum.AutomaticSize.Y
FBGrid.Active = true
Instance.new("UICorner", FBGrid).CornerRadius = UDim.new(0, px(14))
local fgStroke = Instance.new("UIStroke", FBGrid)
fgStroke.Color = C.ACCENT; fgStroke.Thickness = 1.5

-- Layout grille 2 colonnes
local FBGridLayout = Instance.new("UIGridLayout", FBGrid)
FBGridLayout.CellSize = UDim2.new(0, BW, 0, BH)
FBGridLayout.CellPadding = UDim2.new(0, BGAP, 0, BGAP)
FBGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
FBGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
FBGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local FBPad = Instance.new("UIPadding", FBGrid)
FBPad.PaddingTop = UDim.new(0, BGAP)
FBPad.PaddingBottom = UDim.new(0, BGAP)
FBPad.PaddingLeft = UDim.new(0, BGAP)
FBPad.PaddingRight = UDim.new(0, BGAP)

-- Largeur totale = 2 boutons + 3 gaps
local GRID_W = BCOLS * BW + (BCOLS + 1) * BGAP
FBGrid.Size = UDim2.new(0, GRID_W, 0, 0)

-- Position : coin bas droit (dÃ©calÃ© selon le toggle button)
local function repositionGrid()
    local rows = math.ceil(#FBGridLayout:GetChildren() == 0 and 1 or 1)
    FBGrid.Position = UDim2.new(1, -(GRID_W + px(10)), 1, -px(10))
    FBGrid.AnchorPoint = Vector2.new(0, 1)
end
-- Position initiale bas droite
FBGrid.Position = UDim2.new(1, -(GRID_W + px(10)), 1, -px(10))
FBGrid.AnchorPoint = Vector2.new(0, 1)

-- Drag support pour la grille
local fbDragging, fbDragStart, fbStartPos2 = false, nil, nil
FBGrid.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        fbDragging = true; fbDragStart = i.Position; fbStartPos2 = FBGrid.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if fbDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fbDragStart
        FBGrid.Position = UDim2.new(fbStartPos2.X.Scale, fbStartPos2.X.Offset + d.X, fbStartPos2.Y.Scale, fbStartPos2.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then fbDragging = false end
end)

-- CrÃ©ateur de bouton grille
local floatBtns = {}
local function makeFB(name, topLabel, subLabel, order, cb)
    local Btn = Instance.new("TextButton", FBGrid)
    Btn.Name = name
    Btn.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Btn.BorderSizePixel = 0
    Btn.LayoutOrder = order
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, px(10))

    -- Label principal (ex: "BAT")
    local L1 = Instance.new("TextLabel", Btn)
    L1.Size = UDim2.new(1, -px(4), 0, px(13))
    L1.Position = UDim2.new(0, px(2), 0, px(5))
    L1.BackgroundTransparency = 1
    L1.Text = topLabel
    L1.TextColor3 = C.WHITE
    L1.Font = Enum.Font.GothamBold
    L1.TextSize = px(10)
    L1.TextXAlignment = Enum.TextXAlignment.Center

    -- Sous-label (ex: "MODE")
    local L2 = Instance.new("TextLabel", Btn)
    L2.Size = UDim2.new(1, -px(4), 0, px(9))
    L2.Position = UDim2.new(0, px(2), 0, px(19))
    L2.BackgroundTransparency = 1
    L2.Text = subLabel
    L2.TextColor3 = C.TEXT_DIM
    L2.Font = Enum.Font.Gotham
    L2.TextSize = px(7)
    L2.TextXAlignment = Enum.TextXAlignment.Center

    -- Point indicateur centrÃ© en bas
    local DSz = px(10)
    local Dot = Instance.new("TextButton", Btn)
    Dot.Size = UDim2.new(0, DSz, 0, DSz)
    Dot.Position = UDim2.new(0.5, -DSz/2, 1, -DSz - px(4))
    Dot.BackgroundColor3 = C.DOT_OFF
    Dot.BorderSizePixel = 0
    Dot.Text = ""
    Dot.AutoButtonColor = false
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    floatBtns[name] = {btn = Btn, dot = Dot, state = false}

    local function toggle()
        local ns = not floatBtns[name].state
        cb(ns)
    end

    Btn.MouseButton1Click:Connect(toggle)
    Dot.MouseButton1Click:Connect(toggle)

    local function updateVisual(on)
        floatBtns[name].state = on
        Dot.BackgroundColor3 = on and C.DOT_ON or C.DOT_OFF
        Btn.BackgroundColor3 = on and Color3.fromRGB(10, 28, 40) or Color3.fromRGB(12, 12, 18)
        L1.TextColor3 = on and C.ACCENT or C.WHITE
    end
    floatBtns[name].updateVisual = updateVisual
end

-- ---- CRÃER TOUS LES BOUTONS ----
makeFB("BatAimbot", "BAT", "MODE", 1, function(s)
    setBatAimbot(s)
    floatBtns["BatAimbot"].updateVisual(batAimbotToggled)
    if batAimbotToggled then
        if floatBtns["AutoLeft"] then floatBtns["AutoLeft"].updateVisual(false) end
        if floatBtns["AutoRight"] then floatBtns["AutoRight"].updateVisual(false) end
    end
end)

makeFB("Carry", "CARRY", "MODE", 2, function(s)
    speedToggled = s
    floatBtns["Carry"].updateVisual(speedToggled)
end)

makeFB("TPLeft", "TP", "LEFT", 3, function(s)
    if s then
        activateTPLeft()
        floatBtns["TPLeft"].updateVisual(true)
        if floatBtns["TPRight"] then floatBtns["TPRight"].updateVisual(false) end
    else
        deactivateTP()
        floatBtns["TPLeft"].updateVisual(false)
    end
end)

makeFB("Float", "FLOAT", "MODE", 4, function(s)
    if s then startFloat() else stopFloat() end
    floatBtns["Float"].updateVisual(floatEnabled)
    setRowActive("Float", floatEnabled)
end)

makeFB("AutoLeft", "FULL", "AUTO L", 5, function(s)
    setAutoLeft(s)
    floatBtns["AutoLeft"].updateVisual(autoLeftEnabled)
    if autoLeftEnabled then
        if floatBtns["AutoRight"] then floatBtns["AutoRight"].updateVisual(false) end
        if floatBtns["BatAimbot"] then floatBtns["BatAimbot"].updateVisual(false) end
    end
end)

makeFB("AutoRight", "FULL", "AUTO R", 6, function(s)
    setAutoRight(s)
    floatBtns["AutoRight"].updateVisual(autoRightEnabled)
    if autoRightEnabled then
        if floatBtns["AutoLeft"] then floatBtns["AutoLeft"].updateVisual(false) end
        if floatBtns["BatAimbot"] then floatBtns["BatAimbot"].updateVisual(false) end
    end
end)

makeFB("Drop", "DROP", "MODE", 7, function(s)
    dropBrainrot()
    floatBtns["Drop"].updateVisual(true)
    task.delay(0.4, function()
        if floatBtns["Drop"] then floatBtns["Drop"].updateVisual(false) end
    end)
end)

makeFB("TPRight", "TP", "RIGHT", 8, function(s)
    if s then
        activateTPRight()
        floatBtns["TPRight"].updateVisual(true)
        if floatBtns["TPLeft"] then floatBtns["TPLeft"].updateVisual(false) end
    else
        deactivateTP()
        floatBtns["TPRight"].updateVisual(false)
    end
end)

makeFB("AntiCollision", "ANTI", "COLLIDE", 9, function(s)
    antiCollisionEnabled = s
    if s then startAntiCollision() else stopAntiCollision() end
    floatBtns["AntiCollision"].updateVisual(antiCollisionEnabled)
    setRowActive("Anti Collision", antiCollisionEnabled)
end)

makeFB("StealSpeed", "STEAL", "SPEED", 10, function(s)
    stealSpeedEnabled = s
    floatBtns["StealSpeed"].updateVisual(stealSpeedEnabled)
    setRowActive("Speed Stealing", stealSpeedEnabled)
end)

-- ============================================================
--  INIT
-- ============================================================
task.spawn(function()
    task.wait(0.3)
    if galaxyEnabled then startGalaxy() end
    if antiRagdollEnabled then startAntiRagdoll() end
    if spinBotEnabled then startSpinBot() end
    if autoStealEnabled then startAutoSteal() end
    if optimizerEnabled then enableOptimizer() end
    if espEnabled then enableESP() end
    -- sync row states from config
    setRowActive("Void Mode", galaxyEnabled)
    setRowActive("Spin Bot", spinBotEnabled)
    setRowActive("Unwalk", unwalkEnabled)
    setRowActive("Anti Ragdoll", antiRagdollEnabled)
    setRowActive("Anti Collision", antiCollisionEnabled)
    setRowActive("Speed Stealing", stealSpeedEnabled)
    setRowActive("Auto Steal", autoStealEnabled)
    setRowActive("Player ESP", espEnabled)
    setRowActive("Optimizer + XRay", optimizerEnabled)
    if antiCollisionEnabled then startAntiCollision() end
    -- sync keybind section labels
    for _,def in ipairs({"ToggleGUI","AutoLeft","AutoRight","BatAimbot","SpeedToggle","Float","Drop","TPLeft","TPRight"}) do
        if kbBadges[def.."_section"] then kbBadges[def.."_section"].Text = KB[def] and KB[def].Name or "None" end
        if kbBadges[def] then kbBadges[def].Text = KB[def] and KB[def].Name or "?" end
    end
end)

-- ============================================================
--  INPUT HANDLER
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe and input.UserInputType==Enum.UserInputType.Keyboard then return end
    if listeningFor then return end
    local kc=input.KeyCode
    local isKB=input.UserInputType==Enum.UserInputType.Keyboard

    if isKB and KB.ToggleGUI and kc==KB.ToggleGUI then Main.Visible=not Main.Visible; return end
    if isKB and KB.SpeedToggle and kc==KB.SpeedToggle then
        speedToggled=not speedToggled; setRowActive("Carry Mode",speedToggled)
        if floatBtns["Carry"] then floatBtns["Carry"].state=speedToggled; floatBtns["Carry"].dot.BackgroundColor3=speedToggled and C.DOT_ON or C.DOT_OFF end
        return
    end
    if isKB and KB.BatAimbot and kc==KB.BatAimbot then setBatAimbot(not batAimbotToggled); return end
    if isKB and KB.AutoLeft and kc==KB.AutoLeft then setAutoLeft(not autoLeftEnabled); return end
    if isKB and KB.AutoRight and kc==KB.AutoRight then setAutoRight(not autoRightEnabled); return end
    if isKB and KB.Float and kc==KB.Float then
        if not floatEnabled then startFloat() else stopFloat() end
        setRowActive("Float",floatEnabled)
        if floatBtns["Float"] then floatBtns["Float"].state=floatEnabled; floatBtns["Float"].dot.BackgroundColor3=floatEnabled and C.DOT_ON or C.DOT_OFF end
        return
    end
    if isKB and KB.Drop and kc==KB.Drop then
        dropBrainrot()
        setRowActive("Drop Brainrot", true)
        task.delay(0.3, function() setRowActive("Drop Brainrot", false) end)
        return
    end
    if isKB and KB.TPLeft and kc==KB.TPLeft then
        if ragdollAutoActive and lastTpSide=="left" then
            deactivateTP()
        else
            setRowActive("TP Left", true)
            activateTPLeft()
        end
        return
    end
    if isKB and KB.TPRight and kc==KB.TPRight then
        if ragdollAutoActive and lastTpSide=="right" then
            deactivateTP()
        else
            setRowActive("TP Right", true)
            activateTPRight()
        end
        return
    end
    if isKB and kc==Enum.KeyCode.Space then spaceHeld=true end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.Space then spaceHeld=false end
end)

-- ============================================================
--  MAIN HEARTBEAT
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not char or not hum or not hrp then return end
    if spinBotEnabled and spinBAV and char.Parent then spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0) end
    if not batAimbotToggled and not (autoLeftEnabled or autoRightEnabled) then
        local md=hum.MoveDirection
        if md.Magnitude>0.1 then
            local spd=speedToggled and CARRY_SPEED or NORMAL_SPEED
            hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd, hrp.AssemblyLinearVelocity.Y, md.Z*spd)
        end
    end
    if galaxyEnabled then
        updateGF()
        if hopsEnabled and spaceHeld then doGalaxyHop() end
    end
end)

-- ============================================================
--  CHARACTER
-- ============================================================
if LocalPlayer.Character then setupChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    setupChar(c)
    -- Reset TP state on respawn
    ragdollWasActive = false
    -- Si un TP Ã©tait actif, on re-TP automatiquement du mÃªme cÃ´tÃ©
    if ragdollAutoActive then
        task.wait(0.5)
        if lastTpSide == "left" then
            doTPLeft()
            task.wait(0.2)
            autoLeftEnabled = true
            nineStop(); nineStart("left")
            if uiRows["Auto Left"] then setRowActive("Auto Left", true) end
        elseif lastTpSide == "right" then
            doTPRight()
            task.wait(0.2)
            autoRightEnabled = true
            nineStop(); nineStart("right")
            if uiRows["Auto Right"] then setRowActive("Auto Right", true) end
        end
        startRagdollDetector()
    end
end)
