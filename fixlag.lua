-- ===================================================
-- SAFE LAG FIX - ESCAPE TSUNAMI FOR BRAINROTS
-- Phiên bản ổn định - Tối ưu hiệu suất KHÔNG tạo lag ngược
-- ===================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- ===== CẤU HÌNH AN TOÀN =====
local Config = {
    RenderDistance = 350,      -- Khoảng cách render hợp lý
    CleanupDistance = 800,     -- Khoảng cách cleanup
    UpdateRate = 12,           -- 12 giây giữa mỗi lần tối ưu (GIẢM TẦN SUẤT)
    ChunkSize = 50,            -- Xử lý 50 objects mỗi frame
    
    -- Tối ưu an toàn
    KeepBrainrots = true,      -- Giữ lại brainrot
    ReduceWaterEffects = true, -- Giảm hiệu ứng nước
    MinimalLighting = true     -- Ánh sáng tối thiểu
}

-- ===== CACHE OBJECTS ĐỂ TRÁNH GETDESCENDANTS =====
local soundsToDelete = {}
local effectsToDelete = {}
local lastFullScan = 0

-- ===== 1️⃣ XÓA ÂM THANH & HIỆU ỨNG (CHẠY 1 LẦN) =====
local function initialSoundEffectCleanup()
    print("🔧 Đang dọn dẹp âm thanh và hiệu ứng...")
    
    -- Tắt SoundService
    pcall(function()
        local soundService = game:GetService("SoundService")
        soundService.Volume = 0
        
        -- Xóa sounds trong SoundService
        for _, sound in ipairs(soundService:GetChildren()) do
            if sound:IsA("Sound") or sound:IsA("SoundGroup") then
                pcall(function() sound:Destroy() end)
            end
        end
    end)
    
    -- Xóa sounds và effects trong workspace (1 LẦN DUY NHẤT)
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Sound") then
                obj:Destroy()
                count = count + 1
            elseif obj:IsA("ParticleEmitter") then
                if obj.Name:find("Brainrot") then
                    -- Giữ brainrot nhưng giảm nhẹ
                    obj.Rate = math.min(obj.Rate, 8)
                else
                    obj:Destroy()
                    count = count + 1
                end
            elseif obj:IsA("Trail") or obj:IsA("Beam") or 
                   obj:IsA("Smoke") or obj:IsA("Fire") or
                   obj:IsA("Sparkles") then
                obj:Destroy()
                count = count + 1
            end
        end)
    end
    
    print("✅ Đã xóa " .. count .. " sounds/effects")
end

-- ===== 2️⃣ EVENT-DRIVEN: BẮT SOUNDS MỚI =====
local function setupSoundInterceptor()
    -- Bắt sounds mới NGAY KHI SPAWN thay vì polling
    Workspace.DescendantAdded:Connect(function(obj)
        task.wait(0.1) -- Đợi object load xong
        pcall(function()
            if obj:IsA("Sound") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") and not obj.Name:find("Brainrot") then
                obj:Destroy()
            elseif obj:IsA("Trail") or obj:IsA("Beam") or
                   obj:IsA("Smoke") or obj:IsA("Fire") then
                obj:Destroy()
            end
        end)
    end)
    
    print("✅ Đã kích hoạt Sound Interceptor (event-driven)")
end

-- ===== 3️⃣ TỐI ƯU ÁNH SÁNG =====
local function optimizeLighting()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.Brightness = 2
        Lighting.FogEnd = 9e9
        Lighting.EnvironmentDiffuseScale = 0.1
        Lighting.EnvironmentSpecularScale = 0.1
    end)
    
    if Config.MinimalLighting then
        for _, obj in ipairs(Lighting:GetChildren()) do
            pcall(function()
                if obj:IsA("PostEffect") or obj:IsA("BlurEffect") or 
                   obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
                    obj.Enabled = false
                end
            end)
        end
        
        pcall(function()
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then
                sky.MoonTextureId = ""
                sky.SunTextureId = ""
            end
        end)
    end
end

-- ===== 4️⃣ SMART CLEANUP (CHUNK-BASED, GIẢM TẦN SUẤT) =====
local cleanupCycle = 0
local descendantsCache = {}
local cacheExpiry = 0

local function smartCleanup()
    cleanupCycle = cleanupCycle + 1
    
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local rootPos = root.Position
    
    -- Cache descendants và chỉ refresh mỗi 15 giây
    local currentTime = tick()
    if currentTime > cacheExpiry then
        descendantsCache = Workspace:GetDescendants()
        cacheExpiry = currentTime + 15
    end
    
    local descendants = descendantsCache
    local chunkSize = Config.ChunkSize
    local startIndex = ((cleanupCycle - 1) % math.ceil(#descendants / chunkSize)) * chunkSize + 1
    local endIndex = math.min(startIndex + chunkSize - 1, #descendants)
    
    for i = startIndex, endIndex do
        if not descendants[i] then break end
        local obj = descendants[i]
        
        pcall(function()
            -- Giữ objects quan trọng
            local isImportant = false
            if Config.KeepBrainrots then
                if obj.Name:find("Brainrot") or 
                   (obj.Parent and obj.Parent.Name:find("Brainrot")) or
                   obj.Name:find("Coin") or obj.Name:find("Cash") or
                   obj.Name:find("Money") or obj.Name:find("Rebirth") then
                    isImportant = true
                    
                    if obj:IsA("BasePart") then
                        obj.CastShadow = false
                        obj.Material = Enum.Material.Plastic
                    end
                end
            end
            
            -- Tối ưu objects không quan trọng
            if not isImportant and obj:IsA("BasePart") then
                local distance = (obj.Position - rootPos).Magnitude
                
                if distance > Config.CleanupDistance then
                    obj.Transparency = math.min(obj.Transparency + 0.3, 0.9)
                    obj.CanCollide = false
                    obj.CastShadow = false
                elseif distance > Config.RenderDistance then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                else
                    obj.CastShadow = false
                    obj.Reflectance = 0
                end
                
                -- Xóa texture vật xa (mỗi 5 chu kỳ)
                if cleanupCycle % 5 == 0 and obj:IsA("MeshPart") and distance > 300 then
                    obj.TextureID = ""
                end
            end
            
            -- Xóa decal/texture xa
            if (obj:IsA("Decal") or obj:IsA("Texture")) and 
               obj.Parent and obj.Parent:IsA("BasePart") then
                local distance = (obj.Parent.Position - rootPos).Magnitude
                if distance > 600 then
                    obj:Destroy()
                end
            end
        end)
    end
end

-- ===== 5️⃣ TỐI ƯU TERRAIN =====
local function optimizeTerrain()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0.7
            terrain.WaterWaveSize = 0.1
            terrain.WaterWaveSpeed = 0.1
        end)
    end
    
    -- Tìm water parts (CHỈ 1 LẦN)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if (obj.Name:find("Water") or obj.Name:find("Tsunami")) and obj:IsA("BasePart") then
                obj.Transparency = 0.6
                obj.Reflectance = 0
                obj.Material = Enum.Material.SmoothPlastic
            end
        end)
    end
end

-- ===== 6️⃣ TỐI ƯU GUI =====
local function optimizeGUI()
    pcall(function()
        local playerGui = player:WaitForChild("PlayerGui")
        
        for _, gui in ipairs(playerGui:GetChildren()) do
            pcall(function()
                local keepGUI = {
                    ["Chat"] = true,
                    ["Brainrot"] = true,
                    ["Score"] = true,
                    ["Leaderboard"] = true,
                    ["Money"] = true,
                    ["Cash"] = true,
                    ["PlayerGui"] = true
                }
                
                if not keepGUI[gui.Name] and gui:IsA("ScreenGui") then
                    if gui.Name:find("Advertisement") or 
                       gui.Name:find("Banner") or
                       gui.Name:find("Social") then
                        gui.Enabled = false
                    end
                    
                    -- Giảm UI effects
                    for _, child in ipairs(gui:GetDescendants()) do
                        if child:IsA("UIStroke") or child:IsA("UIGradient") then
                            child.Enabled = false
                        end
                    end
                end
            end)
        end
    end)
end

-- ===== 7️⃣ TỐI ƯU HỆ THỐNG =====
local function optimizeSystem()
    pcall(function()
        settings().Rendering.QualityLevel = 1
    end)
    
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then
            camera.FieldOfView = 70
        end
    end)
end

-- ===== 8️⃣ FPS COUNTER UI =====
local function createFPSCounter()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Tạo ScreenGui
    local fpsGui = Instance.new("ScreenGui")
    fpsGui.Name = "FPSCounter"
    fpsGui.ResetOnSpawn = false
    fpsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Tạo Frame nền
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 60)
    frame.Position = UDim2.new(1, -160, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = fpsGui
    
    -- Bo góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Text FPS
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, -10, 0, 30)
    fpsLabel.Position = UDim2.new(0, 5, 0, 5)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabel.TextSize = 20
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame
    
    -- Text Script Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🟢 Optimized"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame
    
    fpsGui.Parent = playerGui
    
    -- Update FPS
    local lastTime = tick()
    local frameCount = 0
    local fps = 0
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        
        if deltaTime >= 1 then
            fps = math.floor(frameCount / deltaTime)
            frameCount = 0
            lastTime = currentTime
            
            -- Màu FPS theo mức
            if fps >= 50 then
                fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Vàng
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
            end
            
            fpsLabel.Text = "FPS: " .. fps
        end
    end)
    
    print("✅ FPS Counter đã được tạo!")
end

-- ===== 🚀 KHỞI ĐỘNG HỆ THỐNG =====
print("=========================================")
print("🎮 SAFE LAG FIX - ESCAPE TSUNAMI")
print("=========================================")

-- Chạy tối ưu ban đầu
initialSoundEffectCleanup()
task.wait(0.5)
setupSoundInterceptor()
task.wait(0.5)
optimizeLighting()
optimizeTerrain()
optimizeSystem()
optimizeGUI()
task.wait(0.3)
createFPSCounter()

print("✅ Ánh sáng & render: Đã tối ưu")
print("✅ Terrain & water: Đã tối ưu")
print("✅ GUI: Đã giảm tải")
print("✅ Sound Interceptor: ACTIVE")
print("✅ FPS Counter: ACTIVE")
print("💎 Brainrots: Được bảo toàn")

-- Cleanup định kỳ (12 GIÂY thay vì 3 giây)
local optimizationTimer = 0
local fullScanCounter = 0

RunService.Heartbeat:Connect(function(deltaTime)
    optimizationTimer = optimizationTimer + deltaTime
    
    -- Cleanup mỗi 12 giây
    if optimizationTimer >= Config.UpdateRate then
        smartCleanup()
        optimizationTimer = 0
        fullScanCounter = fullScanCounter + 1
        
        -- Mỗi 2.5 phút (60 giây) refresh cache
        if fullScanCounter >= 5 then
            descendantsCache = Workspace:GetDescendants()
            fullScanCounter = 0
        end
    end
end)

-- Tối ưu khi respawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        smartCleanup()
    end)
end)

print("=========================================")
print("🎮 KHỞI ĐỘNG THÀNH CÔNG!")
print("📊 Update Rate: mỗi 12 giây")
print("🎯 Event-Driven Sound Removal: ACTIVE")
print("⚡ Script an toàn cho 24/7!")
print("=========================================")
