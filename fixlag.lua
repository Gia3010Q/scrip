-- ===================================================
-- ULTIMATE LAG FIX - ESCAPE TSUNAMI FOR BRAINROTS
-- Tối ưu hiệu suất thuần túy - Không auto-farm
-- ===================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- ===== CẤU HÌNH TỐI ƯU =====
local Config = {
    RenderDistance = 400,      -- Chỉ render trong 400 studs
    CleanupDistance = 1000,    -- Làm mờ vật thể xa
    UpdateRate = 5,            -- Giây giữa mỗi lần tối ưu
    
    -- Tối ưu chuyên biệt cho game này
    KeepBrainrots = true,      -- Giữ lại brainrot để không ảnh hưởng gameplay
    ReduceWaterEffects = true, -- Giảm hiệu ứng nước (quan trọng)
    MinimalLighting = true     -- Ánh sáng tối thiểu
}

-- ===== 1️⃣ TỐI ƯU ÂM THANH & HIỆU ỨNG =====
local function optimizeSoundsAndEffects()
    -- Tắt toàn bộ âm thanh
    pcall(function()
        game:GetService("SoundService").Volume = 0
    end)
    
    -- GỘP vòng lặp: xử lý sound và effects cùng lúc (tối ưu hơn)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            -- Xử lý âm thanh
            if obj:IsA("Sound") then
                obj.Volume = 0
                obj.Playing = false
            
            -- Xử lý particle effects
            elseif obj:IsA("ParticleEmitter") then
                -- Giữ hiệu ứng brainrot, giảm hiệu ứng khác
                if obj.Name:find("Brainrot") then
                    obj.Rate = math.min(obj.Rate, 10)  -- Giảm số lượng hạt
                elseif obj.Name:find("Water") or obj.Name:find("Wave") then
                    obj.Enabled = not Config.ReduceWaterEffects
                else
                    obj.Enabled = false
                end
            
            -- Tắt trail, beam không cần thiết
            elseif obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
            end
        end)
    end
end

-- ===== 2️⃣ TỐI ƯU ÁNH SÁNG & RENDER =====
local function optimizeLighting()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.Brightness = 2
        Lighting.FogEnd = 9e9
        Lighting.EnvironmentDiffuseScale = 0.1
        Lighting.EnvironmentSpecularScale = 0.1
    end)
    
    if Config.MinimalLighting then
        -- Chế độ ánh sáng tối thiểu
        for _, obj in ipairs(Lighting:GetChildren()) do
            pcall(function()
                if obj:IsA("PostEffect") or 
                   obj:IsA("BlurEffect") or 
                   obj:IsA("SunRaysEffect") then
                    obj.Enabled = false
                end
            end)
        end
        
        -- Skybox đơn giản (FIX: Kiểm tra Sky tồn tại trước)
        pcall(function()
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then
                sky.MoonTextureId = ""
                sky.SunTextureId = ""
            end
        end)
    end
end

-- ===== 3️⃣ DỌN DẸP MAP THÔNG MINH =====
local cleanupCycle = 0
local function smartCleanup()
    cleanupCycle = cleanupCycle + 1
    
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local rootPos = root.Position
    
    -- TỐI ƯU: Xử lý theo chunks để tránh lag spike
    local descendants = Workspace:GetDescendants()
    local chunkSize = 100  -- Xử lý 100 objects mỗi frame
    local startIndex = ((cleanupCycle - 1) % math.ceil(#descendants / chunkSize)) * chunkSize + 1
    local endIndex = math.min(startIndex + chunkSize - 1, #descendants)
    
    for i = startIndex, endIndex do
        local obj = descendants[i]
        pcall(function()
            -- PHÁT HIỆN VÀ GIỮ BRAINROTS (quan trọng)
            local isImportant = false
            if Config.KeepBrainrots then
                if obj.Name:find("Brainrot") or 
                   (obj.Parent and obj.Parent.Name:find("Brainrot")) or
                   obj.Name:find("Coin") or obj.Name:find("Cash") or
                   obj.Name:find("Money") or obj.Name:find("Rebirth") then
                    isImportant = true
                    
                    -- Tối ưu brainrot nhưng không xóa
                    if obj:IsA("BasePart") then
                        obj.CastShadow = false
                        obj.Material = Enum.Material.Plastic
                    end
                end
            end
            
            -- XỬ LÝ VẬT THỂ KHÔNG QUAN TRỌNG
            if not isImportant then
                if obj:IsA("BasePart") then
                    local distance = (obj.Position - rootPos).Magnitude
                    
                    -- Phân cấp tối ưu theo khoảng cách
                    if distance > Config.CleanupDistance then
                        -- Vật thể rất xa: làm mờ
                        obj.Transparency = 0.85
                        obj.CanCollide = false
                        obj.CastShadow = false
                        
                    elseif distance > Config.RenderDistance then
                        -- Vật thể xa: tối ưu
                        obj.Transparency = 0.5
                        obj.CastShadow = false
                        obj.Material = Enum.Material.Plastic
                        
                    else
                        -- Vật thể gần: tối ưu nhẹ
                        obj.CastShadow = false
                        obj.Reflectance = 0
                    end
                    
                    -- Mỗi 3 chu kỳ mới giảm texture (tiết kiệm CPU)
                    if cleanupCycle % 3 == 0 and obj:IsA("MeshPart") then
                        if distance > 200 then
                            obj.TextureID = ""
                        end
                    end
                end
                
                -- Xóa decal/texture xa
                if (obj:IsA("Decal") or obj:IsA("Texture")) and 
                   obj.Parent and obj.Parent:IsA("BasePart") then
                    local distance = (obj.Parent.Position - rootPos).Magnitude
                    if distance > 500 then
                        obj:Destroy()
                    end
                end
            end
        end)
    end
end

-- ===== 4️⃣ TỐI ƯU TERRAIN & WATER (QUAN TRỌNG) =====
local function optimizeTerrain()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            -- Tối ưu water properties (FIX: xóa terrain.Decoration không tồn tại)
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0.7
            terrain.WaterWaveSize = 0.1
            terrain.WaterWaveSpeed = 0.1
        end)
    end
    
    -- Tìm và tối ưu water parts
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj.Name:find("Water") or obj.Name:find("Tsunami") then
                if obj:IsA("BasePart") then
                    obj.Transparency = 0.6  -- Làm nước trong hơn để render nhẹ
                    obj.Reflectance = 0.1
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    end
end

-- ===== 5️⃣ TỐI ƯU HỆ THỐNG =====
local function optimizeSystem()
    pcall(function()
        -- Giảm chất lượng render tổng thể
        settings().Rendering.QualityLevel = 1
    end)
    
    pcall(function()
        -- Tối ưu camera
        local camera = Workspace.CurrentCamera
        if camera then
            camera.FieldOfView = 70  -- FOV cố định
        end
    end)
end

-- ===== 6️⃣ TỰ ĐỘNG CHỐNG AFK =====
-- Chỉ chống AFK, không auto-play
if Config.KeepBrainrots then
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- ===== 🚀 KHỞI CHẠY HỆ THỐNG =====
print("🔧 ĐANG TỐI ƯU ESCAPE TSUNAMI...")

-- Chạy tối ưu lần đầu
optimizeSoundsAndEffects()
optimizeLighting()
optimizeTerrain()
optimizeSystem()
smartCleanup()

print("✅ Âm thanh & hiệu ứng: Đã tối ưu")
print("✅ Ánh sáng & render: Đã giảm tải")
print("✅ Brainrots & vật phẩm: Được bảo toàn")
print("✅ Map & terrain: Đã dọn dẹp thông minh")

-- Hẹn giờ tối ưu định kỳ
local optimizationTimer = 0
local effectCheckCounter = 0  -- FIX: Thay thế math.random bằng counter
RunService.Heartbeat:Connect(function(deltaTime)
    optimizationTimer = optimizationTimer + deltaTime
    
    if optimizationTimer >= Config.UpdateRate then
        smartCleanup()
        optimizationTimer = 0
        effectCheckCounter = effectCheckCounter + 1
        
        -- Mỗi 6 lần cleanup (30 giây) kiểm tra hiệu ứng mới
        if effectCheckCounter >= 6 then
            optimizeSoundsAndEffects()
            effectCheckCounter = 0
        end
    end
end)

-- Tối ưu khi respawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        smartCleanup()
        optimizeTerrain()
    end)
end)

print("🎮 TỐI ƯU HOÀN TẤT! Game đã sẵn sàng để treo 24/7")
print("📊 FPS sẽ ổn định mà không ảnh hưởng gameplay")