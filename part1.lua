-- ==========================================
-- part1: ましゅめろHUB（旧れもにー）
-- ==========================================
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("MashumeroHub_Blocker") then
    return
end
local blocker = Instance.new("BoolValue")
blocker.Name = "MashumeroHub_Blocker"
blocker.Parent = CoreGui

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

print("✅ ましゅめろHUB 起動: " .. LocalPlayer.Name)

-- ブラッドムーン
local function createBloodMoon()
    local lighting = game:GetService("Lighting")
    lighting.Ambient = Color3.fromRGB(60,10,10)
    lighting.ColorShift_Top = Color3.fromRGB(200,40,40)
    lighting.ColorShift_Bottom = Color3.fromRGB(80,10,10)
    lighting.Brightness = 0.7
    lighting.OutdoorAmbient = Color3.fromRGB(100,20,20)
end
task.spawn(createBloodMoon)

-- Infinite Yield
loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()

-- チャット
local function sendChatMessage(msg)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then generalChannel:SendAsync(msg) end
        else
            local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if defaultChat then
                local sayMessage = defaultChat:FindFirstChild("SayMessageRequest")
                if sayMessage then sayMessage:FireServer(msg, "All") end
            end
        end
    end)
end
sendChatMessage("👾ましゅめろ")

-- Obsidianライブラリ
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles
Library.ForceCheckbox = false

local Window = Library:CreateWindow({
    Title = "👾 ましゅめろ",
    Footer = "Made by GR",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Defense = Window:AddTab("defense", "🛡️ 防御"),
    Target = Window:AddTab("target", "🎯 ターゲット"),
    Grab = Window:AddTab("grab", "✋ 掴み"),
    Player = Window:AddTab("player", "👤 プレイヤー"),
    Misc = Window:AddTab("misc", "📦 その他"),
    Build = Window:AddTab("build", "🔧 ビルド"),
    LagKick = Window:AddTab("lagkick", "⏱️ ラグキック"),
    Backpack = Window:AddTab("おんぶ", "🎒 おんぶ"),
    PlotBreak = Window:AddTab("プロットブレイク", "🏠 プロット破壊"),
    ["UI Settings"] = Window:AddTab("UI Settings", "⚙️ UI設定")
}

local PS = Players
local RS = ReplicatedStorage
local R = RunService
local Player = LocalPlayer
local Camera = Workspace.CurrentCamera

local function notify(title, content, duration)
    Library:Notify({ Title = title or "通知", Description = content or "", Time = duration or 5 })
end

local function getPlayerList()
    local list = {}
    for _, plr in ipairs(PS:GetPlayers()) do
        if plr ~= Player then table.insert(list, plr.DisplayName .. " (" .. plr.Name .. ")") end
    end
    return list
end
local function getPlayerFromSelection(selection)
    if not selection then return nil end
    local username = selection:match("%((.-)%)")
    if username then return PS:FindFirstChild(username) end
    return nil
end

-- =====================================================
-- Defense Tab
-- =====================================================
local DefenseGroup = Tabs.Defense:AddLeftGroupbox("🛡️ メイン防御")
local DefenseExtra = Tabs.Defense:AddRightGroupbox("🔧 追加防御")

DefenseGroup:AddToggle("AntiGrabObsidian", {
    Text = "アンチグラブ",
    Default = false,
    Callback = function(Value)
        local Struggle = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("Struggle")
        if Value then
            RunService.Heartbeat:Connect(function()
                local character = Player.Character
                if character and character:FindFirstChild("Head") then
                    local head = character.Head
                    if head:FindFirstChild("PartOwner") then
                        task.spawn(function()
                            if Struggle then Struggle:FireServer(Player) end
                            for _, part in pairs(character:GetChildren()) do
                                if part:IsA("BasePart") then part.Anchored = true end
                            end
                            local isHeld = Player:FindFirstChild("IsHeld")
                            while isHeld and isHeld.Value do task.wait() end
                            for _, part in pairs(character:GetChildren()) do
                                if part:IsA("BasePart") then part.Anchored = false end
                            end
                        end)
                    end
                end
            end)
        end
    end
})

-- アンチ炎上
local hookBurnConn
local function hookBurn(char)
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    char.PrimaryPart = hrp
    if hookBurnConn then hookBurnConn:Disconnect() end
    hookBurnConn = hum.FireDebounce.Changed:Connect(function(isBurning)
        if isBurning then
            local oldCF = hrp.CFrame
            local plots = workspace:FindFirstChild("Plots")
            if plots and plots:FindFirstChild("Plot2") then
                local barrier = plots.Plot2:FindFirstChild("Barrier")
                local pb = barrier and barrier:FindFirstChild("PlotBarrier")
                if pb then
                    char:SetPrimaryPartCFrame(pb.CFrame * CFrame.new(0,6,0))
                    task.wait(0.3)
                    local firePart = char:FindFirstChild("FirePlayerPart", true)
                    if firePart then
                        for _, obj in ipairs(firePart:GetChildren()) do
                            if obj:IsA("Sound") then obj:Stop() end
                            if obj:IsA("Light") or obj:IsA("ParticleEmitter") then obj.Enabled = false end
                        end
                        if firePart:FindFirstChild("CanBurn") then firePart.CanBurn.Value = false end
                        if hum:FindFirstChild("FireDebounce") then hum.FireDebounce.Value = false end
                    end
                    task.wait(0.6)
                    if char.PrimaryPart then char:SetPrimaryPartCFrame(oldCF) end
                end
            end
        end
    end)
end
DefenseGroup:AddToggle("AntiBurnToggle", {Text="アンチ炎上", Default=false, Callback=function(on) if on then hookBurn(Player.Character) elseif hookBurnConn then hookBurnConn:Disconnect() end end})

-- アンチ落下
local antiVoidConn
DefenseGroup:AddToggle("AntiVoidToggle", {Text="アンチ落下", Default=false, Callback=function(on)
    if on then
        if antiVoidConn then antiVoidConn:Disconnect() end
        antiVoidConn = R.Heartbeat:Connect(function()
            local char = Player.Character
            if char and char.PrimaryPart then
                local pos = char.PrimaryPart.Position
                if pos.Y < -50 then
                    char:SetPrimaryPartCFrame(CFrame.new(pos.X, pos.Y + 100, pos.Z))
                    char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    else
        if antiVoidConn then antiVoidConn:Disconnect() antiVoidConn = nil end
    end
end})

-- =====================================================
-- Target Tab
-- =====================================================
local TargetGroup = Tabs.Target:AddLeftGroupbox("🎯 ターゲット操作")
local BlobGroup = Tabs.Target:AddRightGroupbox("👾 ブロブマン操作")

local selectedKickPlayer = nil

TargetGroup:AddDropdown("KickPlayerDropdown", {
    Values = getPlayerList(),
    Default = 1,
    Multi = false,
    Text = "ターゲット選択",
    Callback = function(Value) selectedKickPlayer = getPlayerFromSelection(Value) end,
})

-- =====================================================
-- UI Settings
-- =====================================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("⚙️ メニュー設定")
MenuGroup:AddButton("アンロード", function() Library:Unload() end)
MenuGroup:AddLabel("メニューキーバインド"):AddKeyPicker("MenuKeybind", {Default="RightShift", NoUI=true, Text="メニューキー"})
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("MashumeroHub")
SaveManager:SetFolder("MashumeroHub/Configs")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

Library:Notify({Title="👾 ましゅめろ", Description="読み込み完了！", Time=3})