-- ===================================================
-- DELTA MOBILE FULL FPS BOOST + MENU
-- 3-4GB RAM VERSION
-- ===================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Xóa GUI cũ nếu có
if PlayerGui:FindFirstChild("DELTA_FPS_GUI") then
    PlayerGui.DELTA_FPS_GUI:Destroy()
end

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
-- 2. FPS MENU UI
-- ==============================

local gui = Instance.new("ScreenGui")
gui.Name = "DELTA_FPS_GUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

-- FPS Label
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0,130,0,45)
fpsLabel.Position = UDim2.new(1,-150,0,100)
fpsLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
fpsLabel.BackgroundTransparency = 0.3
fpsLabel.TextColor3 = Color3.fromRGB(0,255,0)
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.Text = "FPS: ..."
fpsLabel.Parent = gui

Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0,12)

-- Toggle Button
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,80,0,35)
toggle.Position = UDim2.new(1,-100,0,160)
toggle.BackgroundColor3 = Color3.fromRGB(20,20,20)
toggle.TextColor3 = Color3.fromRGB(255,255,255)
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.Text = "Hide"
toggle.Parent = gui

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,10)

-- Kéo thả FPS
local dragging = false
local dragInput, dragStart, startPos

fpsLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = fpsLabel.Position
	end
end)

fpsLabel.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		fpsLabel.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

fpsLabel.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Toggle Show/Hide
toggle.MouseButton1Click:Connect(function()
	if fpsLabel.Visible then
		fpsLabel.Visible = false
		toggle.Text = "Show"
	else
		fpsLabel.Visible = true
		toggle.Text = "Hide"
	end
end)

-- ==============================
-- 3. FPS COUNTER
-- ==============================

local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	if tick() - last >= 1 then
		fpsLabel.Text = "FPS: "..frames
		
		if frames < 30 then
			fpsLabel.TextColor3 = Color3.fromRGB(255,0,0)
		elseif frames < 50 then
			fpsLabel.TextColor3 = Color3.fromRGB(255,255,0)
		else
			fpsLabel.TextColor3 = Color3.fromRGB(0,255,0)
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

print("✅ DELTA BOOST + MENU ENABLED")
