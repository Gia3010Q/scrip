-- ===================================================
-- DELTA MOBILE LITE
-- FULL BOOST + SOUND OFF
-- 3-4GB RAM VERSION
-- ===================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Xóa GUI cũ nếu có
if PlayerGui:FindFirstChild("DELTA_FPS") then
    PlayerGui.DELTA_FPS:Destroy()
end

print("🔥 DELTA LITE STARTING...")

-- ==============================
-- 1. LOW GRAPHICS
-- ==============================

Lighting.GlobalShadows = false
Lighting.Brightness = 1
Lighting.FogEnd = 9e9

for _,v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v.Enabled = false
    end
end

for _,v in pairs(Workspace:GetDescendants()) do
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
-- 2. SOUND OFF (FULL)
-- ==============================

SoundService.Volume = 0

for _,v in pairs(game:GetDescendants()) do
    if v:IsA("Sound") then
        v.Volume = 0
        v.Playing = false
    end
end

-- ==============================
-- 3. FPS COUNTER
-- ==============================

local gui = Instance.new("ScreenGui")
gui.Name = "DELTA_FPS"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,130,0,45)
label.Position = UDim2.new(1,-150,0,100)
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0,255,0)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "FPS: ..."
label.Parent = gui

Instance.new("UICorner", label).CornerRadius = UDim.new(0,12)

local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
    frames += 1
    if tick() - last >= 1 then
        label.Text = "FPS: "..frames
        
        if frames < 30 then
            label.TextColor3 = Color3.fromRGB(255,0,0)
        elseif frames < 50 then
            label.TextColor3 = Color3.fromRGB(255,255,0)
        else
            label.TextColor3 = Color3.fromRGB(0,255,0)
        end
        
        frames = 0
        last = tick()
    end
end)

-- ==============================
-- 4. LOCK FPS 40
-- ==============================

if setfpscap then
    setfpscap(40)
end

print("✅ DELTA LITE ENABLED")
