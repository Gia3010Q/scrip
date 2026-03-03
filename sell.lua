-- =====================================================
-- AUTO PET SELL - Escape Tsunami for Brainrot
-- Custom GUI Tabbed Menu (khong dung WindUI)
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
    Interval     = 3,
    SkipLocked   = true,
    OnlySellPets = true,
    MaxSlots     = 3,
    RetryDelay   = 1,
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

-- =====================================================
-- SELL LOGIC
-- =====================================================
local isRunning   = false
local totalSold   = 0
local slotsFilled = 0
local queueIdx    = 1

local function tryListPet(pet)
    if not listRemote then return false end
    local ok = pcall(function() listRemote:InvokeServer(pet.uuid, CONFIG.SellPrice) end)
    if ok then totalSold += 1; slotsFilled += 1 end
    return ok
end

local function runLoop()
    queueIdx = 1; slotsFilled = 0
    while isRunning do
        if not listRemote then findRemote(); task.wait(2); continue end
        local pets = getPets()
        if #pets == 0 or queueIdx > #pets then
            queueIdx = 1; slotsFilled = 0; task.wait(CONFIG.Interval); continue
        end
        if slotsFilled >= CONFIG.MaxSlots then
            task.wait(CONFIG.Interval)
            slotsFilled = math.max(0, slotsFilled - 1)
            continue
        end
        local pet = pets[queueIdx]
        if not pet or not passFilter(pet) then queueIdx += 1; continue end
        if tryListPet(pet) then queueIdx += 1; task.wait(CONFIG.RetryDelay)
        else slotsFilled = CONFIG.MaxSlots; task.wait(CONFIG.Interval) end
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
-- STYLING
-- =====================================================
local C = {
    BG      = Color3.fromRGB(20, 20, 28),
    PANEL   = Color3.fromRGB(28, 28, 38),
    ROW     = Color3.fromRGB(36, 36, 50),
    ACCENT  = Color3.fromRGB(110, 90, 220),
    GREEN   = Color3.fromRGB(50, 200, 100),
    RED     = Color3.fromRGB(220, 60, 60),
    TEXT    = Color3.fromRGB(230, 230, 240),
    SUBTEXT = Color3.fromRGB(140, 135, 165),
    BORDER  = Color3.fromRGB(55, 50, 80),
}

local function corner(p, r) local c = Instance.new("UICorner",p); c.CornerRadius = UDim.new(0,r or 8); return c end
local function newLabel(parent, text, size, color, xa, bold)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1,0,1,0)
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or C.TEXT
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextTruncate = Enum.TextTruncate.AtEnd
    return l
end
local function tween(obj, props, t)
    TweenS:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad), props):Play()
end

-- =====================================================
-- MAIN GUI
-- =====================================================
local oldGui = PGui:FindFirstChild("AutoSellMenu")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui", PGui)
ScreenGui.Name = "AutoSellMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- MENU PANEL
local Menu = Instance.new("Frame", ScreenGui)
Menu.Name = "Menu"
Menu.Size = UDim2.new(0, 310, 0, 420)
Menu.Position = UDim2.new(0, 30, 0.5, -210)
Menu.BackgroundColor3 = C.BG
Menu.BorderSizePixel = 0
corner(Menu, 12)
local menuStroke = Instance.new("UIStroke", Menu)
menuStroke.Color = C.BORDER; menuStroke.Thickness = 1.5

-- HEADER
local Header = Instance.new("Frame", Menu)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = C.PANEL
Header.BorderSizePixel = 0
corner(Header, 12)
local HFix = Instance.new("Frame", Header)
HFix.Size = UDim2.new(1,0,0,12); HFix.Position = UDim2.new(0,0,1,-12)
HFix.BackgroundColor3 = C.PANEL; HFix.BorderSizePixel = 0

local TitleLbl = Instance.new("TextLabel", Header)
TitleLbl.Size = UDim2.new(1,-45, 1, 0); TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.Text="🐾 Auto Pet Sell"; TitleLbl.TextSize=13; TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextColor3=C.TEXT; TitleLbl.BackgroundTransparency=1; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Nut "-"
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0,26,0,26); MinBtn.Position = UDim2.new(1,-32,0.5,-13)
MinBtn.Text = "−"; MinBtn.TextSize = 18; MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = C.SUBTEXT; MinBtn.BackgroundColor3 = C.ROW; MinBtn.BorderSizePixel = 0
corner(MinBtn, 6)
MinBtn.MouseEnter:Connect(function() tween(MinBtn,{BackgroundColor3=C.RED}) end)
MinBtn.MouseLeave:Connect(function() tween(MinBtn,{BackgroundColor3=C.ROW}) end)

-- Drag menu
local dragMenu, dm_start, dm_pos
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMenu=true; dm_start=i.Position; dm_pos=Menu.Position
    end
end)
Header.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragMenu=false end
end)
UIS.InputChanged:Connect(function(i)
    if dragMenu and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dm_start
        Menu.Position = UDim2.new(dm_pos.X.Scale, dm_pos.X.Offset+d.X, dm_pos.Y.Scale, dm_pos.Y.Offset+d.Y)
    end
end)

-- TAB SYSTEM
local TabContainer = Instance.new("Frame", Menu)
TabContainer.Size = UDim2.new(1, -16, 0, 32)
TabContainer.Position = UDim2.new(0, 8, 0, 44)
TabContainer.BackgroundTransparency = 1

local TabsList = Instance.new("UIListLayout", TabContainer)
TabsList.FillDirection = Enum.FillDirection.Horizontal
TabsList.SortOrder = Enum.SortOrder.LayoutOrder
TabsList.Padding = UDim.new(0, 6)

local tabFrames = {}
local tabButtons = {}

local function createTabButton(name, idx)
    local btn = Instance.new("TextButton", TabContainer)
    btn.Size = UDim2.new(0, 90, 1, 0)
    btn.BackgroundColor3 = idx == 1 and C.ACCENT or C.ROW
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = idx == 1 and Color3.new(1,1,1) or C.SUBTEXT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.LayoutOrder = idx
    corner(btn, 6)

    local content = Instance.new("ScrollingFrame", Menu)
    content.Size = UDim2.new(1,-16, 1,-88); content.Position = UDim2.new(0,8,0,80)
    content.BackgroundTransparency = 1; content.BorderSizePixel = 0
    content.ScrollBarThickness = 3; content.ScrollBarImageColor3 = C.ACCENT
    content.Visible = (idx == 1)
    
    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
    end)

    tabFrames[idx] = content
    tabButtons[idx] = btn

    btn.MouseButton1Click:Connect(function()
        for i, f in pairs(tabFrames) do
            f.Visible = (i == idx)
            tween(tabButtons[i], {
                BackgroundColor3 = (i == idx) and C.ACCENT or C.ROW,
                TextColor3 = (i == idx) and Color3.new(1,1,1) or C.SUBTEXT
            })
        end
    end)

    return content
end

local TabMain   = createTabButton("CHÍNH", 1)
local TabConfig = createTabButton("CÀI ĐẶT", 2)
local TabFilter = createTabButton("BỘ LỌC", 3)

local function newRow(parent, h)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, h or 36)
    f.BackgroundColor3 = C.ROW; f.BorderSizePixel = 0
    corner(f, 8)
    return f
end

local function sectionTitle(parent, text)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,22); f.BackgroundTransparency = 1
    local l = newLabel(f, text, 11, C.SUBTEXT)
    l.Position = UDim2.new(0,4,0,0)
end

local function makeToggle(parent, labelText, default, onChange)
    local row = newRow(parent, 36)
    local lbl = newLabel(row, labelText, 12, C.TEXT)
    lbl.Size = UDim2.new(1,-54,1,0); lbl.Position = UDim2.new(0,10,0,0)

    local Track = Instance.new("Frame", row)
    Track.Size = UDim2.new(0,36,0,20); Track.Position = UDim2.new(1,-46,0.5,-10)
    Track.BackgroundColor3 = default and C.ACCENT or C.BORDER; Track.BorderSizePixel = 0
    corner(Track, 10)

    local Knob = Instance.new("Frame", Track)
    Knob.Size = UDim2.new(0,16,0,16); Knob.AnchorPoint = Vector2.new(0,0.5)
    Knob.Position = default and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0)
    Knob.BackgroundColor3 = Color3.new(1,1,1); Knob.BorderSizePixel = 0
    corner(Knob, 8)

    local state = default
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(Track, {BackgroundColor3 = state and C.ACCENT or C.BORDER})
        tween(Knob,  {Position = state and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0)})
        onChange(state)
    end)
    return row
end

local function makeButton(parent, labelText, color, onClick)
    local row = newRow(parent, 34)
    row.BackgroundColor3 = color or C.ACCENT
    local lbl = newLabel(row, labelText, 12, Color3.new(1,1,1), Enum.TextXAlignment.Center, true)
    lbl.Size = UDim2.new(1,0,1,0)
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseEnter:Connect(function() tween(row,{BackgroundColor3=(color or C.ACCENT):Lerp(Color3.new(1,1,1),0.15)}) end)
    btn.MouseLeave:Connect(function() tween(row,{BackgroundColor3=color or C.ACCENT}) end)
    btn.MouseButton1Click:Connect(onClick)
    return row
end

local function makeInput(parent, labelText, placeholder, onChange)
    local row = newRow(parent, 56)
    local lbl = newLabel(row, labelText, 11, C.SUBTEXT)
    lbl.Size = UDim2.new(1,-12,0,18); lbl.Position = UDim2.new(0,10,0,4)

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(1,-20,0,26); box.Position = UDim2.new(0,10,0,24)
    box.BackgroundColor3 = C.PANEL; box.BorderSizePixel = 0
    box.TextColor3 = C.TEXT; box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = C.SUBTEXT; box.TextSize = 12; box.Font = Enum.Font.Gotham
    box.Text = ""; box.ClearTextOnFocus = false
    corner(box, 6)
    local pad = Instance.new("UIPadding", box)
    pad.PaddingLeft = UDim.new(0,8)
    box.FocusLost:Connect(function()
        local val = box.Text
        local ok = onChange(val)
        box.Text = ""
        box.PlaceholderText = "Hiện tại: " .. tostring(CONFIG.SellPrice)
    end)
    return row
end

local function makeSlider(parent, labelText, min, max, default, onChange)
    local row = newRow(parent, 56)
    local valDisplay = tostring(default)

    local lbl = newLabel(row, labelText, 11, C.SUBTEXT)
    lbl.Size = UDim2.new(1,-50,0,18); lbl.Position = UDim2.new(0,10,0,4)

    local valLbl = newLabel(row, valDisplay, 11, C.ACCENT, Enum.TextXAlignment.Right, true)
    valLbl.Size = UDim2.new(0,40,0,18); valLbl.Position = UDim2.new(1,-48,0,4)

    local Track = Instance.new("Frame", row)
    Track.Size = UDim2.new(1,-20,0,6); Track.Position = UDim2.new(0,10,0,34)
    Track.BackgroundColor3 = C.BORDER; Track.BorderSizePixel = 0; corner(Track, 3)

    local Fill = Instance.new("Frame", Track)
    Fill.BackgroundColor3 = C.ACCENT; Fill.BorderSizePixel = 0; corner(Fill, 3)
    Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)

    local Knob = Instance.new("Frame", Track)
    Knob.Size = UDim2.new(0,14,0,14); Knob.AnchorPoint = Vector2.new(0.5,0.5)
    Knob.Position = UDim2.new((default-min)/(max-min),0,0.5,0)
    Knob.BackgroundColor3 = Color3.new(1,1,1); Knob.BorderSizePixel = 0; corner(Knob, 7)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.round(min + rel * (max - min))
        Fill.Size = UDim2.new(rel,0,1,0)
        Knob.Position = UDim2.new(rel,0,0.5,0)
        valLbl.Text = tostring(val)
        onChange(val)
    end
    Track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    Track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(UIS:GetMouseLocation().X)
        end
    end)
    return row
end

-- Bo chon kieu nut bam (1 2 3 4...)
local function makeSelector(parent, labelText, options, default, onChange)
    local row = newRow(parent, 56)
    local lbl = newLabel(row, labelText, 11, C.SUBTEXT)
    lbl.Size = UDim2.new(1,-12,0,18); lbl.Position = UDim2.new(0,10,0,4)

    local btnContainer = Instance.new("Frame", row)
    btnContainer.Size = UDim2.new(1,-20,0,26)
    btnContainer.Position = UDim2.new(0,10,0,26)
    btnContainer.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", btnContainer)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 3)

    local btns = {}
    local n = #options

    local function selectOpt(val)
        for _, b in pairs(btns) do
            local sel = b:GetAttribute("optval") == val
            tween(b, {BackgroundColor3 = sel and C.ACCENT or C.ROW})
            b.TextColor3 = sel and Color3.new(1,1,1) or C.SUBTEXT
        end
        onChange(val)
    end

    for idx, opt in ipairs(options) do
        local b = Instance.new("TextButton", btnContainer)
        b.Size = UDim2.new(1/n, -3, 1, 0)
        b.BackgroundColor3 = (opt == default) and C.ACCENT or C.ROW
        b.TextColor3 = (opt == default) and Color3.new(1,1,1) or C.SUBTEXT
        b.Text = tostring(opt)
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.LayoutOrder = idx
        b:SetAttribute("optval", opt)
        corner(b, 5)
        b.MouseButton1Click:Connect(function() selectOpt(opt) end)
        table.insert(btns, b)
    end
    return row
end

-- ===============================================
-- TAB: CHINH (MAIN)
sectionTitle(TabMain, "ĐIỀU KHIỂN BÁN")
local isAutoOn = false
makeToggle(TabMain, "Tự động treo bán", false, function(v)
    if v and not listRemote then findRemote() end
    if v and not listRemote then isAutoOn = false; return end
    isAutoOn = v; isRunning = v
    if v then task.spawn(runLoop) end
end)

sectionTitle(TabMain, "HỆ THỐNG")
makeToggle(TabMain, "🛡️ Anti-AFK", false, function(v)
    antiAFKEnabled = v
    print("[AutoSell] Anti-AFK:", v and "BẬT" or "TẮT")
end)
makeButton(TabMain, "🔍  Quét lại Remote", C.PANEL, function()
    local ok = findRemote()
    print("[AutoSell] Remote:", ok and listRemote:GetFullName() or "Không tìm thấy")
end)

-- ===============================================
-- TAB: CAI DAT (CONFIG)
sectionTitle(TabConfig, "THUỘC TÍNH PET")
makeInput(TabConfig, "Giá bán mỗi pet", "Nhập số... (vd: 5000)", function(v)
    local n = tonumber(v)
    if n and n > 0 then CONFIG.SellPrice = n end
end)
makeSelector(TabConfig, "Số khe gian hàng (MaxSlots)", {1,2,3,4,5,6,7,8}, 4, function(v) CONFIG.MaxSlots = v end)
makeSlider(TabConfig, "Thời gian đợi (giây)", 1, 30, 3, function(v) CONFIG.Interval = v end)
makeSelector(TabConfig, "Thời gian chờ lại (RetryDelay)", {0.5, 1, 1.5, 2, 3}, 1, function(v) CONFIG.RetryDelay = v end)

sectionTitle(TabConfig, "TÙY CHỌN BỎ QUA")
makeToggle(TabConfig, "Bỏ qua pet bị Khóa 🔒", true, function(v) CONFIG.SkipLocked = v end)
makeToggle(TabConfig, "Chỉ bán Pet (không bán Gear)", true, function(v) CONFIG.OnlySellPets = v end)

-- ===============================================
-- TAB: BO LOC (FILTER)
sectionTitle(TabFilter, "CÀI ĐẶT BỘ LỌC CẤP BẬC (RARITY)")
makeButton(TabFilter, "Reset Cấp Bậc", C.RED, function()
    for k in pairs(SELL_RARITIES) do SELL_RARITIES[k] = nil end
end)
for _, r in ipairs(ALL_RARITIES) do
    makeToggle(TabFilter, "Bán "..r, false, function(v)
        SELL_RARITIES[r] = v and true or nil
    end)
end

sectionTitle(TabFilter, "CÀI ĐẶT BỘ LỌC ĐỘT BIẾN (MUTATION)")
makeButton(TabFilter, "Reset Đột Biến", C.RED, function()
    for k in pairs(SELL_MUTATIONS) do SELL_MUTATIONS[k] = nil end
end)
for _, m in ipairs(ALL_MUTATIONS) do
    makeToggle(TabFilter, "Bán "..m, false, function(v)
        SELL_MUTATIONS[m] = v and true or nil
    end)
end

-- =====================================================
-- NUT RESTORE TRAY (Vien nho)
-- =====================================================
local RestoreBtn = Instance.new("TextButton", ScreenGui)
RestoreBtn.Name = "RestoreBtn"
RestoreBtn.Size = UDim2.new(0, 42, 0, 42)
RestoreBtn.Position = UDim2.new(1, -54, 0, 10)
RestoreBtn.BackgroundColor3 = C.BG
RestoreBtn.BorderSizePixel = 0
RestoreBtn.Text = "🐾"
RestoreBtn.TextSize = 20
RestoreBtn.Font = Enum.Font.GothamBold
RestoreBtn.Visible = false
corner(RestoreBtn, 8)
local rs = Instance.new("UIStroke", RestoreBtn)
rs.Color = C.ACCENT; rs.Thickness = 1.5

local dragR, ds, dp
RestoreBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragR=true; ds=i.Position; dp=RestoreBtn.Position end
end)
RestoreBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragR=false end
end)
UIS.InputChanged:Connect(function(i)
    if dragR and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        RestoreBtn.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
    end
end)

local function hideMenu() Menu.Visible = false; RestoreBtn.Visible = true end
local function showMenu() Menu.Visible = true; RestoreBtn.Visible = false end

MinBtn.MouseButton1Click:Connect(hideMenu)
RestoreBtn.MouseButton1Click:Connect(showMenu)

UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then
        if Menu.Visible then hideMenu() else showMenu() end
    end
end)

print("[AutoSell] ✅ Script loaded | RightShift = Án/Hien menu | Đã tách tab")
