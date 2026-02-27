-- ===================================================
-- DELTA MOBILE FULL FPS BOOST
-- 3-4GB RAM VERSION
-- ===================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

print("🔥 Mobile Boost Starting...")

-- ==============================
-- 1. FORCE LOW GRAPHICS (REAL METHOD)
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
-- 2. FPS COUNTER UI
-- ==============================

local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,120,0,40)
label.Position = UDim2.new(0,10,0,10)
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(0,255,0)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Parent = gui

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
-- 3. LOCK FPS 40 (If Supported)
-- ==============================

if setfpscap then
    setfpscap(40)
end

print("✅ FULL BOOST ENABLED")
