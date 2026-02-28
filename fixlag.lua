--[[
╔══════════════════════════════════════════════════════════════╗
║        ROBLOX LAG FIX PRO - Mobile Edition v3.0             ║
║        Tối ưu đặc biệt cho ĐIỆN THOẠI (Android/iOS)         ║
╠══════════════════════════════════════════════════════════════╣
║  ĐIỆN THOẠI → Nhấn nút trên màn hình                        ║
║  MÁY TÍNH   → F8 / F9 / F10                                 ║
╠══════════════════════════════════════════════════════════════╣
║  HƯỚNG DẪN:                                                  ║
║  1. Đặt vào StarterPlayer > StarterPlayerScripts            ║
║  2. Script tự nhận biết điện thoại hay máy tính             ║
║  3. Chỉnh CONFIG bên dưới nếu cần                           ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- ⚙️  CẤU HÌNH CHUNG
-- ============================================================
local CONFIG = {
    -- FPS Lock
    FPS_LOCK_ENABLED    = true,
    FPS_LOCK_TARGET     = 30,   -- 30 FPS mặc định cho mobile (đổi 60 cho pc)

    -- FPS Display
    FPS_DISPLAY_ENABLED = true,

    -- Lag Fix
    LAG_FIX_ENABLED     = true,

    -- Đồ họa
    DISABLE_SHADOWS     = true,
    DISABLE_PARTICLES   = true,
    DISABLE_TRAILS      = true,
    DISABLE_EFFECTS     = true,  -- Bloom, Blur, SunRays, ColorCorrection...
    DISABLE_DECALS      = false, -- Để false tránh lỗi map
    DISABLE_BEAMS       = true,  -- Beam (đường tia) - nặng trên mobile

    -- Mobile riêng
    MOBILE_EXTRA_OPT    = true,  -- Tối ưu extra chỉ bật khi phát hiện mobile
    MOBILE_REDUCE_LOD   = true,  -- Giảm Level of Detail
    MOBILE_HIDE_SKY     = false, -- Ẩn Sky (rầu hơn nhưng nhẹ hơn)

    -- PC: Phím tắt
    KEY_TOGGLE_FIX      = Enum.KeyCode.F8,
    KEY_TOGGLE_FPS      = Enum.KeyCode.F9,
    KEY_TOGGLE_LOCK     = Enum.KeyCode.F10,
}

-- ============================================================
-- 🔧 SERVICES
-- ============================================================
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local Settings          = UserSettings()
local GameSettings      = Settings:GetService("UserGameSettings")

local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- 📱 PHÁT HIỆN THIẾT BỊ
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IS_TABLET = UserInputService.TouchEnabled and UserInputService.KeyboardEnabled -- iPad với keyboard
local DEVICE    = IS_MOBILE and "📱 Mobile" or (IS_TABLET and "📱 Tablet" or "🖥️ PC")

print(string.format("[LagFixPro] Thiết bị: %s", DEVICE))

-- Nếu mobile → bật tất cả tối ưu nặng hơn
if IS_MOBILE then
    CONFIG.DISABLE_DECALS  = true  -- Mobile: tắt cả decal
    CONFIG.MOBILE_HIDE_SKY = false -- Giữ sky
    CONFIG.FPS_LOCK_TARGET = 30    -- Mobile luôn lock 30
end

-- ============================================================
-- 📊 STATE
-- ============================================================
local State = {
    lagFixEnabled     = CONFIG.LAG_FIX_ENABLED,
    fpsDisplayEnabled = CONFIG.FPS_DISPLAY_ENABLED,
    fpsLockEnabled    = CONFIG.FPS_LOCK_ENABLED,
    fpsLockTarget     = CONFIG.FPS_LOCK_TARGET,
    currentFPS        = 0,
    optimized         = false,
    guiExpanded       = true,  -- Mobile: panel mở/đóng
}

-- ============================================================
-- 🖥️  TẠO GUI - TỰ THÍCH ỨNG MOBILE / PC
-- ============================================================
local function createGui()
    local existing = PlayerGui:FindFirstChild("LagFixProGui")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LagFixProGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    -- ─── PANEL CHÍNH ────────────────────────────────────────
    -- Mobile: góc trái trên, rộng hơn; PC: góc phải trên
    local panelW = IS_MOBILE and 160 or 140
    local panelH = IS_MOBILE and 192 or 72  -- Mobile mở sẵn khi khởi động
    local posX   = IS_MOBILE and UDim2.new(0, 8, 0, 8) or UDim2.new(1, -(panelW + 8), 0, 8)

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, panelW, 0, panelH)
    panel.Position = posX
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 90, 160)
    stroke.Thickness = 1.2
    stroke.Parent = panel

    -- ─── HEADER BAR (bấm để mở/đóng trên mobile) ───────────
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.Text = IS_MOBILE and "⚡ FIX PRO  ▴" or "⚡ LAG FIX PRO"
    header.TextColor3 = Color3.fromRGB(180, 180, 240)
    header.TextSize = IS_MOBILE and 14 or 11
    header.Font = Enum.Font.GothamBold
    header.Parent = panel

    -- ─── FPS LABEL ──────────────────────────────────────────
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(1, 0, 0, IS_MOBILE and 28 or 24)
    fpsLabel.Position = UDim2.new(0, 0, 0, IS_MOBILE and 40 or 24)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(80, 230, 100)
    fpsLabel.TextSize = IS_MOBILE and 20 or 17
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.Parent = panel

    -- ─── STATUS LABEL ───────────────────────────────────────
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 14)
    statusLabel.Position = UDim2.new(0, 0, 0, IS_MOBILE and 70 or 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
    statusLabel.TextSize = IS_MOBILE and 11 or 10
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = panel

    -- ─── NÚT CẢM ỨNG (chỉ mobile) ──────────────────────────
    local btnFix, btnLock, btnFPS

    if IS_MOBILE then
        -- Panel nút (xuất hiện khi mở rộng)
        local btnFrame = Instance.new("Frame")
        btnFrame.Name = "BtnFrame"
        btnFrame.Size = UDim2.new(1, -8, 0, 90)
        btnFrame.Position = UDim2.new(0, 4, 0, 86)
        btnFrame.BackgroundTransparency = 1
        btnFrame.Parent = panel

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 4)
        layout.Parent = btnFrame

        local function makeBtn(emoji, label, order)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            btn.BackgroundTransparency = 0.3
            btn.TextColor3 = Color3.fromRGB(210, 210, 255)
            btn.TextSize = 13
            btn.Font = Enum.Font.GothamSemibold
            btn.Text = emoji .. " " .. label
            btn.LayoutOrder = order
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Parent = btnFrame

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 6)
            bc.Parent = btn
            return btn
        end

        btnFix  = makeBtn("✅", "Lag Fix: BẬT", 1)
        btnFPS  = makeBtn("👁", "FPS: BẬT", 2)
        btnLock = makeBtn("🔒", string.format("Lock %dFPS: BẬT", State.fpsLockTarget), 3)

        -- Hàm cập nhật text nút
        local function refreshBtns()
            btnFix.Text  = (State.lagFixEnabled and "✅" or "❌") .. " Lag Fix: " .. (State.lagFixEnabled and "BẬT" or "TẮT")
            btnFPS.Text  = (State.fpsDisplayEnabled and "👁" or "🚫") .. " FPS: " .. (State.fpsDisplayEnabled and "BẬT" or "TẮT")
            btnLock.Text = (State.fpsLockEnabled and "🔒" or "🔓") .. string.format(" Lock %dFPS: ", State.fpsLockTarget) .. (State.fpsLockEnabled and "BẬT" or "TẮT")
        end

        -- Kích thước panel khi mở: 40(header)+28(fps)+14(status)+8(gap)+90(nút)+12(padding) = 192
        local PANEL_CLOSED = 40
        local PANEL_OPEN   = 192

        -- Toggle mở/đóng panel khi bấm header
        header.MouseButton1Click:Connect(function()
            State.guiExpanded = not State.guiExpanded
            header.Text = State.guiExpanded and "⚡ FIX PRO  ▴" or "⚡ FIX PRO  ▾"
            local targetH = State.guiExpanded and PANEL_OPEN or PANEL_CLOSED
            TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, panelW, 0, targetH)
            }):Play()
        end)

        -- Sự kiện các nút
        btnFix.MouseButton1Click:Connect(function()
            State.lagFixEnabled = not State.lagFixEnabled
            if State.lagFixEnabled then applyFix() else removeFix() end
            refreshBtns()
        end)

        btnFPS.MouseButton1Click:Connect(function()
            State.fpsDisplayEnabled = not State.fpsDisplayEnabled
            refreshBtns()
        end)

        btnLock.MouseButton1Click:Connect(function()
            State.fpsLockEnabled = not State.fpsLockEnabled
            if State.fpsLockEnabled then startFPSLock() else stopFPSLock() end
            refreshBtns()
        end)
    end

    return screenGui, fpsLabel, statusLabel
end

-- ============================================================
-- 🎨 MÀU FPS
-- ============================================================
local function getFPSColor(fps)
    if fps >= 55 then
        return Color3.fromRGB(50, 230, 80)
    elseif fps >= 28 then
        return Color3.fromRGB(255, 200, 50)
    else
        return Color3.fromRGB(255, 60, 60)
    end
end

-- forward declare (dùng trong createGui callback)
local applyFix, removeFix, startFPSLock, stopFPSLock

-- Tạo GUI sau khi forward declare
local FPSGui, FPSLabel, StatusLabel = createGui()

-- ============================================================
-- 🔄 FPS COUNTER (RenderStepped)
-- ============================================================
local fpsAccum  = 0
local fpsFrames = 0
local FPS_INTERVAL = 0.5

RunService.RenderStepped:Connect(function(dt)
    fpsAccum  = fpsAccum + dt
    fpsFrames = fpsFrames + 1

    if fpsAccum >= FPS_INTERVAL then
        State.currentFPS = math.floor(fpsFrames / fpsAccum)
        fpsAccum  = 0
        fpsFrames = 0

        if State.fpsDisplayEnabled and FPSLabel and FPSLabel.Parent then
            FPSLabel.Text = string.format("FPS: %d", State.currentFPS)
            FPSLabel.TextColor3 = getFPSColor(State.currentFPS)

            local lockStr = State.fpsLockEnabled
                and string.format("🔒%d", State.fpsLockTarget) or "🔓Free"
            local fixStr  = State.lagFixEnabled and "✅Fix" or "❌Fix"
            StatusLabel.Text = fixStr .. "  " .. lockStr
        end

        if FPSGui then
            FPSGui.Enabled = State.fpsDisplayEnabled
        end
    end
end)

-- ============================================================
-- 🔒 FPS LOCK
-- Dùng task.wait() thay vì busy-wait → thân thiện với CPU mobile
-- ============================================================
local lockConnection

startFPSLock = function()
    if lockConnection then
        lockConnection:Disconnect()
        lockConnection = nil
    end
    if not State.fpsLockEnabled then return end

    local targetDT   = 1 / State.fpsLockTarget
    local accumulated = 0

    lockConnection = RunService.Heartbeat:Connect(function(dt)
        accumulated = accumulated + dt
        -- Nếu chưa đủ thời gian 1 frame → yield ngắn
        if accumulated < targetDT then
            -- task.wait nhẹ hơn busy-wait, phù hợp mobile
            local remaining = targetDT - accumulated
            if remaining > 0.001 then
                task.wait(remaining * 0.9) -- 90% để tránh overshoot
            end
        else
            -- Reset nếu quá 2 frame (tránh debt tích lũy)
            accumulated = accumulated - targetDT
            if accumulated > targetDT * 2 then
                accumulated = 0
            end
        end
    end)
end

stopFPSLock = function()
    if lockConnection then
        lockConnection:Disconnect()
        lockConnection = nil
    end
end

if State.fpsLockEnabled then
    startFPSLock()
end

-- ============================================================
-- 🗺️  TẮT EFFECTS (an toàn, không xóa object)
-- ============================================================
local EFFECT_CLASSES = {
    ParticleEmitter = function(o) o.Enabled = false; o.Rate = 0 end,
    Trail           = function(o) o.Enabled = false end,
    Smoke           = function(o) o.Enabled = false; o.RiseVelocity = 0; o.Size = 0 end,
    Fire            = function(o) o.Enabled = false; o.Size = 0 end,
    Sparkles        = function(o) o.Enabled = false end,
    Beam            = function(o) if CONFIG.DISABLE_BEAMS then o.Enabled = false end end,
}

local function disableObj(obj)
    local fn = EFFECT_CLASSES[obj.ClassName]
    if fn then
        pcall(fn, obj)
    elseif CONFIG.DISABLE_DECALS and obj.ClassName == "Decal" then
        pcall(function() obj.Transparency = 1 end)
    end
end

local function disableEffectsIn(parent)
    if not parent then return end
    pcall(function()
        for _, obj in ipairs(parent:GetDescendants()) do
            disableObj(obj)
        end
    end)
end

-- ============================================================
-- 💡 TỐI ƯU LIGHTING
-- ============================================================
local origLight = {}

local function optimizeLighting()
    pcall(function()
        origLight.GlobalShadows           = Lighting.GlobalShadows
        origLight.ShadowSoftness          = Lighting.ShadowSoftness
        origLight.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
        origLight.EnvironmentSpecularScale= Lighting.EnvironmentSpecularScale

        if CONFIG.DISABLE_SHADOWS then
            Lighting.GlobalShadows  = false
            Lighting.ShadowSoftness = 0
        end

        -- Mobile: giảm mạnh hơn
        Lighting.EnvironmentDiffuseScale  = IS_MOBILE and 0.2 or 0.5
        Lighting.EnvironmentSpecularScale = 0

        -- Tắt tất cả PostEffect
        if CONFIG.DISABLE_EFFECTS then
            for _, fx in ipairs(Lighting:GetChildren()) do
                pcall(function()
                    if fx:IsA("PostEffect") then fx.Enabled = false end
                    -- Mobile: ẩn cả Sky nếu bật
                    if IS_MOBILE and CONFIG.MOBILE_HIDE_SKY and fx:IsA("Sky") then
                        fx.Parent = nil -- Tạm di chuyển ra khỏi Lighting
                    end
                end)
            end
        end

        -- Mobile: tắt thêm Atmosphere
        if IS_MOBILE then
            pcall(function()
                local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then atm.Density = 0; atm.Glare = 0; atm.Haze = 0 end
            end)
        end
    end)
end

local function restoreLighting()
    pcall(function()
        for k, v in pairs(origLight) do
            pcall(function() Lighting[k] = v end)
        end
        for _, fx in ipairs(Lighting:GetChildren()) do
            pcall(function()
                if fx:IsA("PostEffect") then fx.Enabled = true end
            end)
        end
    end)
end

-- ============================================================
-- 🌍 TỐI ƯU WORKSPACE
-- ============================================================
local function optimizeWorkspace()
    -- Tắt effects hiện có
    disableEffectsIn(Workspace)

    -- Mobile: tắt thêm Camera Shake nặng nếu có
    pcall(function()
        if IS_MOBILE and Workspace.CurrentCamera then
            -- Không chỉnh Camera vì có thể ảnh hưởng gameplay
        end
    end)
end

-- ============================================================
-- 🎮 TỐI ƯU GRAPHICS
-- ============================================================
local origGraphics = nil

local function optimizeGraphics()
    pcall(function()
        origGraphics = GameSettings.SavedQualityLevel
        -- Mobile: Level 1 (thấp nhất); PC: Level 1 cũng ok
        GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
end

local function restoreGraphics()
    pcall(function()
        if origGraphics ~= nil then
            GameSettings.SavedQualityLevel = origGraphics
        end
    end)
end

-- ============================================================
-- 📱 TỐI ƯU THÊM CHO MOBILE
-- ============================================================
local function mobileExtraOptimize()
    if not IS_MOBILE or not CONFIG.MOBILE_EXTRA_OPT then return end

    pcall(function()
        -- Giảm mật độ chi tiết (LOD) nếu có thể
        for _, v in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                -- Giảm size Beam để giảm fillrate
                if v.ClassName == "Beam" then
                    v.Width0 = math.min(v.Width0, 0.5)
                    v.Width1 = math.min(v.Width1, 0.5)
                end
                -- Giảm CastShadow trên BasePart nhỏ
                if v:IsA("BasePart") and v.Size.Magnitude < 2 then
                    v.CastShadow = false
                end
            end)
        end
    end)

    print("[LagFixPro] 📱 Mobile extra optimization applied")
end

-- ============================================================
-- 🔧 APPLY / REMOVE FIX
-- ============================================================
local descendantConn

applyFix = function()
    if State.optimized then return end
    State.optimized = true

    optimizeLighting()
    optimizeWorkspace()
    optimizeGraphics()
    mobileExtraOptimize()

    -- Theo dõi instance mới thêm vào realtime
    if descendantConn then descendantConn:Disconnect() end
    descendantConn = Workspace.DescendantAdded:Connect(function(obj)
        if not State.lagFixEnabled then return end
        task.defer(function() -- task.defer để không block main thread
            disableObj(obj)
        end)
    end)

    print("[LagFixPro] ✅ Tối ưu đã áp dụng (" .. DEVICE .. ")")
end

removeFix = function()
    if not State.optimized then return end
    State.optimized = false

    if descendantConn then
        descendantConn:Disconnect()
        descendantConn = nil
    end

    restoreLighting()
    restoreGraphics()

    print("[LagFixPro] ❌ Đã tắt tối ưu")
end

-- ============================================================
-- ⌨️  PHÍM TẮT (chỉ PC)
-- ============================================================
if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == CONFIG.KEY_TOGGLE_FIX then
            State.lagFixEnabled = not State.lagFixEnabled
            if State.lagFixEnabled then applyFix() else removeFix() end
            print("[LagFixPro] Lag Fix:", State.lagFixEnabled and "BẬT" or "TẮT")

        elseif input.KeyCode == CONFIG.KEY_TOGGLE_FPS then
            State.fpsDisplayEnabled = not State.fpsDisplayEnabled
            print("[LagFixPro] FPS Display:", State.fpsDisplayEnabled and "BẬT" or "TẮT")

        elseif input.KeyCode == CONFIG.KEY_TOGGLE_LOCK then
            State.fpsLockEnabled = not State.fpsLockEnabled
            if State.fpsLockEnabled then startFPSLock() else stopFPSLock() end
            print(string.format("[LagFixPro] FPS Lock (%d):", State.fpsLockTarget),
                State.fpsLockEnabled and "BẬT" or "TẮT")
        end
    end)
end

-- ============================================================
-- 🚀 KHỞI ĐỘNG
-- ============================================================
print("╔════════════════════════════════════════╗")
print("║   ROBLOX LAG FIX PRO v3.0 - MOBILE    ║")
print(string.format("║   Thiết bị: %-27s║", DEVICE))
print(string.format("║   FPS Lock: %-27s║", State.fpsLockEnabled and (State.fpsLockTarget.."FPS") or "TẮT"))
print("╠════════════════════════════════════════╣")
if IS_MOBILE then
    print("║   📱 Nhấn [⚡ FIX PRO ▾] để mở menu  ║")
else
    print("║   F8 Fix  │  F9 FPS  │  F10 Lock     ║")
end
print("╚════════════════════════════════════════╝")

-- Khởi chạy
if State.lagFixEnabled then
    applyFix()
end

if FPSGui then
    FPSGui.Enabled = State.fpsDisplayEnabled
end
