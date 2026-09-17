-- ==========================================
-- part2: ましゅめろキック本体（キック・ラグ）
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- OrionLib ロード
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion'))()

-- ウィンドウ作成
local Window = OrionLib:MakeWindow({
    Name = "ましゅめろキック",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "ましゅめろキック",
    IntroEnabled = true,
    IntroText = "by ましゅめろ",
    Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        ElementBackground = Color3.fromRGB(30, 30, 30),
        TabBackground = Color3.fromRGB(25, 25, 25),
        TabBackgroundSelected = Color3.fromRGB(200, 200, 200),
        TextColor = Color3.fromRGB(240, 240, 240),
        Shadow = Color3.fromRGB(200, 200, 200),
        SliderProgress = Color3.fromRGB(200, 200, 200),
        ElementStroke = Color3.fromRGB(200, 200, 200),
        TabStroke = Color3.fromRGB(200, 200, 200),
        ToggleEnabled = Color3.fromRGB(200, 200, 200),
        ToggleBackground = Color3.fromRGB(80, 80, 80),
        InputBackground = Color3.fromRGB(40, 40, 40),
        DropdownSelected = Color3.fromRGB(60, 60, 60),
        DropdownUnselected = Color3.fromRGB(30, 30, 30),
        NotificationBackground = Color3.fromRGB(30, 30, 30),
        Topbar = Color3.fromRGB(25, 25, 25)
    }
})

-- ==========================================
-- キックタブ
-- ==========================================
local KickTab = Window:MakeTab({Name = "キック", Icon = "rbxassetid://4483362458", PremiumOnly = false})

local spawnedBlobman = nil
local isSpawning = false
local alreadyKicked = {}

local function spawnBlobman()
    if isSpawning then return end
    isSpawning = true
    local char = LocalPlayer.Character
    if not char then isSpawning = false return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then isSpawning = false return nil end
    local spawnPos = rootPart.CFrame * CFrame.new(0, 0, -8)
    pcall(function()
        ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 127, 0))
    end)
    local toyFolderName = LocalPlayer.Name .. "SpawnedInToys"
    local blobman = nil
    local startTime = tick()
    repeat
        local toyFolder = Workspace:FindFirstChild(toyFolderName)
        if toyFolder then
            blobman = toyFolder:FindFirstChild("CreatureBlobman")
            if blobman then break end
        end
        task.wait(0.1)
    until tick() - startTime > 3
    isSpawning = false
    if blobman then
        spawnedBlobman = blobman
        local seat = blobman:FindFirstChild("VehicleSeat")
        if seat then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then seat:Sit(humanoid) end
        end
        return blobman
    end
    return nil
end

local function destroyBlobman()
    if spawnedBlobman and spawnedBlobman.Parent then
        local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if destroyrem then pcall(function() destroyrem:FireServer(spawnedBlobman) end) else spawnedBlobman:Destroy() end
        spawnedBlobman = nil
    end
end

local function getBlobmanSeat()
    if spawnedBlobman and spawnedBlobman.Parent then
        return spawnedBlobman:FindFirstChild("VehicleSeat")
    end
    return nil
end

local function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.DisplayName .. " (" .. plr.Name .. ")")
        end
    end
    if #list == 0 then table.insert(list, "プレイヤーがいません") end
    return list
end

local function getPlayerFromSelection(selection)
    if not selection or selection == "" then return nil end
    if selection == "プレイヤーがいません" then return nil end
    local username = selection:match("%((.-)%)")
    if username then return Players:FindFirstChild(username) end
    return nil
end

local selectedKickPlayer = nil
local targetName = ""
local kickPlayerDropdown = nil

kickPlayerDropdown = KickTab:AddDropdown({
    Name = "ターゲット",
    Default = "",
    Options = getPlayerList(),
    Callback = function(Value)
        selectedKickPlayer = getPlayerFromSelection(Value)
        if selectedKickPlayer then
            targetName = selectedKickPlayer.Name
            alreadyKicked[targetName] = false
        end
    end
})

KickTab:AddButton({
    Name = "更新",
    Callback = function()
        kickPlayerDropdown:Refresh(getPlayerList(), true)
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    kickPlayerDropdown:Refresh(getPlayerList(), true)
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.2)
    kickPlayerDropdown:Refresh(getPlayerList(), true)
end)

-- ドリフトキック
local orbitRadius = 15
local orbitSpeed2 = 2
local orbitAngle = 0
local driftKickEnabled = false
local driftKickThread = nil

KickTab:AddSlider({
    Name = "半径",
    Min = 5, Max = 30, Default = 15, Increment = 1, ValueName = "m",
    Callback = function(Value) orbitRadius = Value end
})

KickTab:AddSlider({
    Name = "速度",
    Min = 1, Max = 10, Default = 2, Increment = 1, ValueName = "",
    Callback = function(Value) orbitSpeed2 = Value end
})

KickTab:AddToggle({
    Name = "ドリフトキック（両手）",
    Default = false,
    Callback = function(on)
        if driftKickThread then task.cancel(driftKickThread) driftKickThread = nil end
        driftKickEnabled = on

        if on then
            if not spawnedBlobman or not spawnedBlobman.Parent then
                spawnBlobman()
                task.wait(0.5)
            end
        else
            destroyBlobman()
            orbitAngle = 0
            return
        end

        if on and not selectedKickPlayer then
            OrionLib:MakeNotification({Name = "エラー", Content = "ターゲットを選択してください", Time = 2})
            driftKickEnabled = false
            return
        end

        local seat = getBlobmanSeat()
        if on and not seat then
            spawnBlobman()
            task.wait(0.5)
            seat = getBlobmanSeat()
            if not seat then driftKickEnabled = false return end
        end

        if not on then orbitAngle = 0 return end
        local target = selectedKickPlayer
        targetName = target.Name
        alreadyKicked[targetName] = false

        driftKickThread = task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local blob = spawnedBlobman
            if not blob or not blob.Parent then driftKickEnabled = false return end
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            if not blobRoot then driftKickEnabled = false return end
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
            local L_Det = blob:FindFirstChild("LeftDetector")
            local L_Weld = L_Det and (L_Det:FindFirstChild("LeftWeld") or L_Det:FindFirstChildWhichIsA("Weld"))
            local SavedPos = blobRoot.CFrame
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

            if tRoot and blobRoot then
                local bringStart = tick()
                while tick() - bringStart < 0.35 and driftKickEnabled do
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    pcall(function()
                        if CG and R_Det then CG:FireServer(R_Det, tRoot, R_Weld) end
                        if CG and L_Det then CG:FireServer(L_Det, tRoot, L_Weld) end
                        GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                    end)
                    RunService.Heartbeat:Wait()
                end
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
                task.wait(0.05)
            end

            local packetTimer = 0
            local handSwitch = 0

            while driftKickEnabled do
                local currentTarget = Players:FindFirstChild(targetName)
                if not currentTarget then
                    if not alreadyKicked[targetName] then
                        alreadyKicked[targetName] = true
                        OrionLib:MakeNotification({Name = "🎯 キック完了！", Content = targetName .. " を強制退去させました！", Time = 3})
                    end
                    break
                end
                if not blobRoot or not blobRoot.Parent then break end
                tChar = currentTarget.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")

                if tRoot and tHum and tHum.Health > 0 then
                    local lockPos = SavedPos * CFrame.new(0, 23, 0)
                    tRoot.CFrame = lockPos
                    tRoot.Velocity = Vector3.zero
                    tRoot.RotVelocity = Vector3.zero
                    local dt = RunService.Heartbeat:Wait()
                    orbitAngle = orbitAngle + (dt * orbitSpeed2)
                    local orbitX = math.cos(orbitAngle) * orbitRadius
                    local orbitZ = math.sin(orbitAngle) * orbitRadius
                    local orbitCFrame = lockPos * CFrame.new(orbitX, 0, orbitZ)
                    blobRoot.CFrame = CFrame.lookAt(orbitCFrame.Position, lockPos.Position)
                    blobRoot.Velocity = Vector3.zero
                    if tick() - packetTimer > 0.01 then
                        packetTimer = tick()
                        handSwitch = (handSwitch + 1) % 3
                        pcall(function()
                            tHum.PlatformStand = true
                            tHum.Sit = true
                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                            if handSwitch == 0 then
                                if R_Det then
                                    local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                    if weld then CD:FireServer(weld) end
                                    CG:FireServer(R_Det, tRoot, R_Weld)
                                end
                            elseif handSwitch == 1 then
                                if L_Det then
                                    local weld = L_Det:FindFirstChild("LeftWeld") or L_Det:FindFirstChildWhichIsA("Weld")
                                    if weld then CD:FireServer(weld) end
                                    CG:FireServer(L_Det, tRoot, L_Weld)
                                end
                            else
                                if R_Det then
                                    local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                    if weld then CD:FireServer(weld) end
                                    CG:FireServer(R_Det, tRoot, R_Weld)
                                end
                                if L_Det then
                                    local weld = L_Det:FindFirstChild("LeftWeld") or L_Det:FindFirstChildWhichIsA("Weld")
                                    if weld then CD:FireServer(weld) end
                                    CG:FireServer(L_Det, tRoot, L_Weld)
                                end
                            end
                            GE.DestroyGrabLine:FireServer(tRoot)
                            GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end)
                    end
                else
                    if blobRoot and blobRoot.Parent then
                        blobRoot.CFrame = SavedPos
                        blobRoot.Velocity = Vector3.zero
                    end
                end
                RunService.Heartbeat:Wait()
            end
            orbitAngle = 0
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})

-- ==========================================
-- ラグタブ
-- ==========================================
local LagTab = Window:MakeTab({
    Name = "ラグ",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local lineLagThread = nil
local lineLagEnabled = false
local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")

local function startLineLag()
    if lineLagEnabled then return end
    lineLagEnabled = true
    lineLagThread = task.spawn(function()
        if not GrabEvents then return end
        local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
        if not createLine then return end
        while lineLagEnabled do
            local target = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
            if target then
                for i = 1, 10 do
                    local randomX = math.random(-1e9, 1e9)
                    local randomZ = math.random(-1e9, 1e9)
                    pcall(function()
                        createLine:FireServer(target, CFrame.new(randomX, 0, randomZ))
                    end)
                end
            end
            task.wait(0.05)
        end
    end)
end

local function stopLineLag()
    lineLagEnabled = false
    if lineLagThread then task.cancel(lineLagThread) end
end

local LagToggle = LagTab:AddToggle({
    Name = "ラグ発生",
    Default = false,
    Callback = function(Value)
        if Value then
            startLineLag()
            OrionLib:MakeNotification({Name = "ラグ", Content = "開始しました", Time = 1})
        else
            stopLineLag()
            OrionLib:MakeNotification({Name = "ラグ", Content = "停止しました", Time = 1})
        end
    end
})

LagTab:AddButton({
    Name = "ラグ解除",
    Callback = function()
        stopLineLag()
        LagToggle:Set(false)
        OrionLib:MakeNotification({Name = "ラグ", Content = "完全に停止しました", Time = 1})
    end
})

-- ==========================================
-- 初期化
-- ==========================================
OrionLib:Init()

OrionLib:MakeNotification({
    Name = "起動完了！",
    Content = "ましゅめろキック（part2）",
    Time = 3
})