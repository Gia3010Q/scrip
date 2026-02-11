-- ===================================================
-- SAFE LAG FIX - ESCAPE TSUNAMI FOR BRAINROTS
-- Phiên bản ổn định - Tối ưu hiệu suất KHÔNG tạo lag ngược
-- ===================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer

-- ===== CẤU HÌNH TỐI ƯU =====
local Config = {
    RenderDistance = 250,
    CleanupDistance = 600,
    UpdateRate = 10,
    ChunkSize = 30,

    KeepBrainrots = true,
    ReduceWaterEffects = true,
    MinimalLighting = true
}

-- ===== CACHE =====
local descendantsCache = {}
local cacheExpiry = 0

-- ===== 1️⃣ XÓA ÂM THANH - INITIAL CLEANUP =====
local function killSound(obj)
    pcall(function()
        if obj:IsA("Sound") then
            obj.Playing = false
            obj.Volume = 0
            obj:Stop()
            obj:Destroy()
        elseif obj:IsA("SoundGroup") then
            obj:Destroy()
        end
    end)
end

local function initialSoundCleanup()
    -- Tắt SoundService hoàn toàn
    pcall(function()
        SoundService.Volume = 0
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
        SoundService.DopplerScale = 0
        SoundService.RolloffScale = 0
    end)

    -- Quét SoundService
    for _, obj in ipairs(SoundService:GetDescendants()) do
        killSound(obj)
    end

    -- Quét tất cả services
    local servicesToScan = {
        Workspace,
        game:GetService("ReplicatedStorage"),
        Lighting
    }
    pcall(function() table.insert(servicesToScan, player:WaitForChild("PlayerGui", 5)) end)
    pcall(function() table.insert(servicesToScan, player:WaitForChild("PlayerScripts", 5)) end)
    pcall(function() table.insert(servicesToScan, player:WaitForChild("Backpack", 5)) end)

    local count = 0
    for _, service in ipairs(servicesToScan) do
        if service then
            pcall(function()
                for _, obj in ipairs(service:GetDescendants()) do
                    if obj:IsA("Sound") or obj:IsA("SoundGroup") then
                        killSound(obj)
                        count = count + 1
                    end
                end
            end)
        end
    end
end

-- ===== 2️⃣ EVENT LISTENERS - BẮT SOUNDS + EFFECTS MỚI =====
local function isEffect(obj)
    return obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")
end

local function killEffect(obj)
    pcall(function()
        if obj:IsA("ParticleEmitter") and obj.Name:find("Brainrot") then
            obj.Rate = math.min(obj.Rate, 8)
            return
        end
        obj:Destroy()
    end)
end

local function setupListeners()
    -- Workspace: bắt sounds + effects mới
    Workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj:IsA("Sound") then killSound(obj)
            elseif isEffect(obj) then killEffect(obj) end
        end)
    end)

    -- PlayerGui: bắt sounds + effects mới
    pcall(function()
        local pg = player:WaitForChild("PlayerGui", 5)
        if pg then
            pg.DescendantAdded:Connect(function(obj)
                task.defer(function()
                    if obj:IsA("Sound") then killSound(obj)
                    elseif isEffect(obj) then killEffect(obj) end
                end)
            end)
        end
    end)

    -- SoundService
    SoundService.ChildAdded:Connect(function(obj)
        if obj:IsA("Sound") or obj:IsA("SoundGroup") then
            task.defer(function() killSound(obj) end)
        end
    end)

    -- Lighting
    Lighting.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj:IsA("Sound") then killSound(obj)
            elseif isEffect(obj) then killEffect(obj) end
        end)
    end)
end

-- ===== 3️⃣ LOOP MỖI 0.5 GIÂY - SOUNDS ONLY =====
local function startCleanupLoop()
    task.spawn(function()
        while true do
            pcall(function()
                SoundService.Volume = 0
                for _, s in ipairs(SoundService:GetChildren()) do
                    killSound(s)
                end
            end)

            pcall(function()
                for _, s in ipairs(Workspace:GetChildren()) do
                    if s:IsA("Sound") then killSound(s) end
                    pcall(function()
                        for _, child in ipairs(s:GetChildren()) do
                            if child:IsA("Sound") then killSound(child) end
                        end
                    end)
                end
            end)

            task.wait(0.5)
        end
    end)
end

-- ===== 4️⃣ XÓA HIỆU ỨNG - FULL SCAN (1 LẦN) =====
local function cleanupEffects()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if isEffect(obj) then killEffect(obj) end
        end)
    end
end

-- ===== 5️⃣ TỐI ƯU ÁNH SÁNG =====
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

-- ===== 6️⃣ SMART CLEANUP =====
local cleanupCycle = 0

local function smartCleanup()
    cleanupCycle = cleanupCycle + 1

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local rootPos = root.Position

    -- Cache mỗi 15 giây
    local now = tick()
    if now > cacheExpiry then
        descendantsCache = Workspace:GetDescendants()
        cacheExpiry = now + 15
    end

    local startIdx = ((cleanupCycle - 1) % math.ceil(#descendantsCache / Config.ChunkSize)) * Config.ChunkSize + 1
    local endIdx = math.min(startIdx + Config.ChunkSize - 1, #descendantsCache)

    for i = startIdx, endIdx do
        local obj = descendantsCache[i]
        if not obj then break end

        pcall(function()
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

            if not isImportant and obj:IsA("BasePart") then
                local dist = (obj.Position - rootPos).Magnitude

                if dist > 1000 then
                    obj:Destroy()
                elseif dist > Config.CleanupDistance then
                    obj.Transparency = 0.95
                    obj.CanCollide = false
                    obj.CastShadow = false
                elseif dist > Config.RenderDistance then
                    obj.Transparency = math.min(obj.Transparency + 0.5, 0.85)
                    obj.CanCollide = false
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                else
                    obj.CastShadow = false
                    obj.Reflectance = 0
                end

                if cleanupCycle % 3 == 0 and obj:IsA("MeshPart") and dist > 200 then
                    obj.TextureID = ""
                end
            end

            if (obj:IsA("Decal") or obj:IsA("Texture")) and
               obj.Parent and obj.Parent:IsA("BasePart") then
                if (obj.Parent.Position - rootPos).Magnitude > 400 then
                    obj:Destroy()
                end
            end
        end)
    end
end

-- ===== 7️⃣ TỐI ƯU TERRAIN =====
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

-- ===== 8️⃣ TỐI ƯU GUI =====
local function optimizeGUI()
    pcall(function()
        local playerGui = player:WaitForChild("PlayerGui")
        for _, gui in ipairs(playerGui:GetChildren()) do
            pcall(function()
                if gui:IsA("ScreenGui") then
                    if gui.Name:find("Advertisement") or
                       gui.Name:find("Banner") or
                       gui.Name:find("Social") then
                        gui.Enabled = false
                    end
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

-- ===== 9️⃣ TỐI ƯU HỆ THỐNG =====
local function optimizeSystem()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end)
    pcall(function()
        settings().Physics.AllowSleep = true
        settings().Physics.ThrottleAdjustTime = 0
    end)
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then camera.FieldOfView = 70 end
    end)
    pcall(function()
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CastShadow = false end
            end
        end
    end)
end

-- ===== 🔟 FPS COUNTER =====
local function createFPSCounter()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FPSCounter"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 120, 0, 35)
    frame.Position = UDim2.new(1, -130, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "FPS: --"
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextSize = 18
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    gui.Parent = player:WaitForChild("PlayerGui")

    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - last >= 1 then
            local fps = math.floor(frames / (now - last))
            frames = 0
            last = now
            if fps >= 50 then
                label.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif fps >= 30 then
                label.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                label.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
            label.Text = "FPS: " .. fps
        end
    end)
end

-- ===== 🚀 KHỞI ĐỘNG =====
initialSoundCleanup()
setupListeners()
startCleanupLoop()
cleanupEffects()
optimizeLighting()
optimizeTerrain()
optimizeSystem()
optimizeGUI()
createFPSCounter()

-- Cleanup định kỳ
local timer = 0
local scanCounter = 0

RunService.Heartbeat:Connect(function(dt)
    timer = timer + dt
    if timer >= Config.UpdateRate then
        smartCleanup()
        timer = 0
        scanCounter = scanCounter + 1
        if scanCounter >= 5 then
            descendantsCache = Workspace:GetDescendants()
            scanCounter = 0
        end
    end
end)

-- Respawn handler
player.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        initialSoundCleanup()
        smartCleanup()
    end)
end)

print("✅ SAFE LAG FIX - ACTIVE")
