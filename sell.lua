-- =====================================================
-- AUTO PET SELL - Escape Tsunami for Brainrot
-- WindUI Menu
-- =====================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TweenS  = game:GetService("TweenService")
local player  = Players.LocalPlayer
local PGui    = player:WaitForChild("PlayerGui")

-- =====================================================
-- CONFIG
-- =====================================================
local CONFIG = {
    SellPrice    = 500,
    Interval     = 15,  -- gianđoạn chờ khi quầy đầy (giây)
    SkipLocked   = true,
    OnlySellPets = true,
    RetryDelay   = 1,   -- delay nhỏ giữa 2 lần treo thành công
}

local SELL_MUTATIONS = {}
local ALL_MUTATIONS  = {
    "None","Gold","Diamond","Emerald","Blood",
    "Gamer","Rainbow","Divine","Celestial","Ancient","Prismatic","Void",
}
local SELL_RARITIES  = {}
local ALL_RARITIES   = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", 
    "Mythical", "Cosmic", "Secret", "Celestial", "Divine", "Infinity"
}

-- Load bang tra cuu Cap Bac (Rarity) tu Config game
local BrainrotRarities = {}
do
    local ok, cfg = pcall(function()
        return require(RS.Shared.Config.Brainrots)
    end)
    if ok and type(cfg) == "table" and type(cfg.BrainrotRarities) == "table" then
        BrainrotRarities = cfg.BrainrotRarities
        print("[AutoSell] ✅ Da load BrainrotRarities tu Config game!")
    else
        print("[AutoSell] ⚠️ Khong load duoc BrainrotRarities - bo loc cap bac se bi vo hieu!")
    end
end

-- =====================================================
-- REMOTE
-- =====================================================
local listRemote = nil
local function findRemote()
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name:lower() == "rf/listboothoffering" then listRemote = v; return true end
    end
    return false
end
findRemote(); task.delay(3, findRemote)

-- =====================================================
-- PET DATA
-- =====================================================
local function getPets()
    local pets, bp = {}, player:FindFirstChild("Backpack")
    if not bp then return pets end
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            local brainrotName = tool:GetAttribute("BrainrotName")
            local locked       = tool:GetAttribute("Locked") == true
            
            if CONFIG.OnlySellPets and not brainrotName then continue end
            if CONFIG.SkipLocked  and locked            then continue end
            
            -- Tra cuu Cap Bac chinh xac tu bang BrainrotRarities cua game
            local rarity = BrainrotRarities[brainrotName] or "None"
            
            table.insert(pets, {
                uuid        = tool.Name,
                displayName = tool:GetAttribute("DisplayName") or tool.Name,
                level       = tool:GetAttribute("Level") or 0,
                mutation    = tool:GetAttribute("Mutation") or "None",
                rarity      = rarity or "None",
                locked      = locked,
            })
        end
    end
    table.sort(pets, function(a, b) return a.level > b.level end)
    return pets
end

local function passFilter(pet)
    local passMut = (next(SELL_MUTATIONS) == nil) or (SELL_MUTATIONS[pet.mutation] == true)
    local passRar = (next(SELL_RARITIES) == nil) or (SELL_RARITIES[pet.rarity] == true)
    return passMut and passRar
end

-- ===================================================
-- SELL LOGIC
-- =====================================================
local isRunning = false
local totalSold = 0
local queueIdx  = 1

local function tryListPet(pet)
    if not listRemote then return false end
    local pcallOk, result = pcall(function()
        return listRemote:InvokeServer(pet.uuid, CONFIG.SellPrice)
    end)
    -- Server trả false hoặc string = từ chối (quầy đầy / lỗi)
    local success = pcallOk and result ~= false and type(result) ~= "string"
    if success then totalSold += 1 end
    return success
end

local function runLoop()
    queueIdx = 1
    while isRunning do
        if not listRemote then findRemote(); task.wait(2); continue end

        local pets = getPets()
        if #pets == 0 or queueIdx > #pets then
            queueIdx = 1; task.wait(3); continue
        end

        local pet = pets[queueIdx]
        if not pet or not passFilter(pet) then queueIdx += 1; continue end

        if tryListPet(pet) then
            -- Thành công → sang pet kế
            print("[AutoSell] ✅ Treo:", pet.displayName or pet.uuid, "| Tổng đã bán:", totalSold)
            queueIdx += 1
            task.wait(CONFIG.RetryDelay)
        else
            -- Thất bại (quầy đầy) → chờ lâu hơn, ít gọi InvokeServer hơn
            task.wait(CONFIG.Interval)
        end
    end
end


-- =====================================================
-- ANTI AFK
-- =====================================================
local antiAFKEnabled = false
local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    if antiAFKEnabled then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        print("[AutoSell] 🛡️ Anti-AFK đã hoạt động!")
    end
end)

-- =====================================================
-- WINDUI MENU
-- =====================================================
local oldGui = PGui:FindFirstChild("AutoSellMenu")
if oldGui then
    oldGui:Destroy()
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Auto Pet Sell",
    Icon = "paw-print",
    Author = "by bạn + ChatGPT",
    Folder = "AutoPetSell_WindUI",
    Size = UDim2.fromOffset(600, 460),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 190,
})

pcall(function()
    Window:SetToggleKey(Enum.KeyCode.RightShift)
end)

local TabMain = Window:Tab({
    Title = "Chính",
    Icon = "play",
})

local TabConfig = Window:Tab({
    Title = "Cài đặt",
    Icon = "settings",
})

local TabFilter = Window:Tab({
    Title = "Bộ lọc",
    Icon = "funnel",
})

TabMain:Section({ Title = "Điều khiển bán" })
local isAutoOn = false
TabMain:Toggle({
    Title = "Tự động treo bán",
    Desc = "Bật để tự động list pet",
    Value = false,
    Callback = function(v)
        if v and not listRemote then findRemote() end
        if v and not listRemote then
            isAutoOn = false
            return
        end
        isAutoOn = v
        isRunning = v
        if v then task.spawn(runLoop) end
    end,
})

TabMain:Section({ Title = "Hệ thống" })
TabMain:Toggle({
    Title = "Anti-AFK",
    Desc = "Giữ nhân vật không bị AFK kick",
    Value = false,
    Callback = function(v)
        antiAFKEnabled = v
        print("[AutoSell] Anti-AFK:", v and "BẬT" or "TẮT")
    end,
})

TabMain:Button({
    Title = "Quét lại Remote",
    Desc = "Tìm lại rf/listboothoffering",
    Callback = function()
        local ok = findRemote()
        print("[AutoSell] Remote:", ok and listRemote:GetFullName() or "Không tìm thấy")
    end,
})

TabConfig:Section({ Title = "Thuộc tính pet" })
TabConfig:Input({
    Title = "Giá bán mỗi pet",
    Desc = "Nhập số, ví dụ 5000",
    Placeholder = "Nhập giá bán...",
    Value = tostring(CONFIG.SellPrice),
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            CONFIG.SellPrice = n
            print("[AutoSell] SellPrice =", CONFIG.SellPrice)
        end
    end,
})

TabConfig:Slider({
    Title = "Thời gian đợi khi quầy đầy (giây)",
    Value = {
        Min = 1,
        Max = 30,
        Default = CONFIG.Interval,
    },
    Callback = function(v)
        CONFIG.Interval = tonumber(v) or CONFIG.Interval
    end,
})

TabConfig:Dropdown({
    Title = "RetryDelay",
    Desc = "Delay giữa 2 lần treo thành công",
    Values = { "0.5", "1", "1.5", "2", "3" },
    Value = tostring(CONFIG.RetryDelay),
    Multi = false,
    Callback = function(selected)
        local picked = selected
        if type(selected) == "table" then
            picked = selected[1]
        end
        local n = tonumber(picked)
        if n then
            CONFIG.RetryDelay = n
            print("[AutoSell] RetryDelay =", CONFIG.RetryDelay)
        end
    end,
})

TabConfig:Section({ Title = "Tùy chọn bỏ qua" })
TabConfig:Toggle({
    Title = "Bỏ qua pet bị khóa",
    Value = CONFIG.SkipLocked,
    Callback = function(v)
        CONFIG.SkipLocked = v
    end,
})

TabConfig:Toggle({
    Title = "Chỉ bán pet (không bán gear)",
    Value = CONFIG.OnlySellPets,
    Callback = function(v)
        CONFIG.OnlySellPets = v
    end,
})

TabFilter:Section({ Title = "Lọc cấp bậc (Rarity)" })
TabFilter:Button({
    Title = "Reset Cấp Bậc",
    Callback = function()
        for k in pairs(SELL_RARITIES) do
            SELL_RARITIES[k] = nil
        end
        print("[AutoSell] Đã reset bộ lọc Rarity")
    end,
})

for _, r in ipairs(ALL_RARITIES) do
    TabFilter:Toggle({
        Title = "Bán " .. r,
        Value = false,
        Callback = function(v)
            SELL_RARITIES[r] = v and true or nil
        end,
    })
end

TabFilter:Section({ Title = "Lọc đột biến (Mutation)" })
TabFilter:Button({
    Title = "Reset Đột Biến",
    Callback = function()
        for k in pairs(SELL_MUTATIONS) do
            SELL_MUTATIONS[k] = nil
        end
        print("[AutoSell] Đã reset bộ lọc Mutation")
    end,
})

for _, m in ipairs(ALL_MUTATIONS) do
    TabFilter:Toggle({
        Title = "Bán " .. m,
        Value = false,
        Callback = function(v)
            SELL_MUTATIONS[m] = v and true or nil
        end,
    })
end

print("[AutoSell] ✅ Script loaded với WindUI | dùng nút Auto Pet Sell trên topbar hoặc RightShift")
