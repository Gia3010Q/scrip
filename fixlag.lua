-- ===================================================
-- DELTA MOBILE FULL FPS BOOST
-- 3-4GB RAM VERSION + REMOVE ALL SOUND
-- ===================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

print("🔥 Mobile Boost Starting...")

-- ==============================
-- 1. FORCE LOW GRAPHICS
-- ==============================

Lighting.GlobalShadows = false
Lighting.Brightness = 1
Lighting.FogEnd = 9e9

for _,v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v.Enabled = false
    end
end

-- Giảm Material + Texture
local workspaceDescendants = Workspace:GetDescendants()
for i, v in ipairs(workspaceDescendants) do
    if i % 100 == 0 then task.wait() end -- Tránh freeze game
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
    end
    
    if v:IsA("Texture") or v:IsA("Decal") then
        v.Transparency = 1
    end
    
    if v:IsA("ParticleEmitter")
    or v:IsA("Trail")
    or v:IsA("Smoke")
    or v:IsA("Fire")
    or v:IsA("Sparkles") then
        v.Enabled = false
    end
end

-- ==============================
-- 2. REMOVE / DISABLE ALL SOUNDS
-- ==============================

SoundService.Volume = 0
SoundService.AmbientReverb = Enum.ReverbType.NoReverb

local servicesToScan = {Workspace, SoundService, Lighting, game:GetService("ReplicatedStorage")}
for _, service in ipairs(servicesToScan) do
    for _,v in ipairs(service:GetDescendants()) do
        if v:IsA("Sound") then
            v:Stop()
            v.Volume = 0
            v.Playing = false
        end
    end
end

-- Chỉ theo dõi Workspace và SoundService thay vì toàn bộ Game (giảm lag)
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Sound") then
        task.wait()
        obj:Stop()
        obj.Volume = 0
        obj.Playing = false
    end
end)
SoundService.DescendantAdded:Connect(function(obj)
    if obj:IsA("Sound") then
        task.wait()
        obj:Stop()
        obj.Volume = 0
        obj.Playing = false
    end
end)

-- ==============================
-- 3. FPS COUNTER UI
-- ==============================

local gui = Instance.new("ScreenGui")
gui.Name = "MobileFPSCounter"
gui.ResetOnSpawn = false

-- Đưa vào CoreGui nếu có thể, tránh bị game xóa
local success = pcall(function()
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 100, 0, 30)
frame.Position = UDim2.new(1, -110, 0, 10) -- Góc phải màn hình
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(0, 255, 0)
label.TextSize = 16
label.Font = Enum.Font.GothamBold
label.Parent = frame

local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - last >= 1 then
        label.Text = "FPS: " .. frames
        
        if frames < 30 then
            label.TextColor3 = Color3.fromRGB(255, 0, 0)
        elseif frames < 50 then
            label.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            label.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
        
        frames = 0
        last = now
    end
end)

-- ==============================
-- 4. LOCK FPS 30 (If Supported)
-- ==============================

if setfpscap then
    setfpscap(30)
end

print("✅ FULL BOOST ENABLED (SOUND REMOVED)")
