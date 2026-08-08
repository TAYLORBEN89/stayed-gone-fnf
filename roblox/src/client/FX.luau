local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local FX = {}
local player = Players.LocalPlayer

function FX.pickup(color: Color3?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = color or Color3.fromRGB(255, 220, 80)
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = root.CFrame
	p.Parent = workspace
	local tw = TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(3, 3, 3),
		Transparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function()
		p:Destroy()
	end)
end

function FX.deposit()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local p = Instance.new("Part")
	p.Size = Vector3.new(1, 1, 1)
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(80, 255, 140)
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = root.CFrame
	p.Parent = workspace
	local tw = TweenService:Create(p, TweenInfo.new(0.5), {
		Size = Vector3.new(12, 12, 12),
		Transparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function()
		p:Destroy()
	end)
end

function FX.rebirth()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for i = 1, 8 do
		local p = Instance.new("Part")
		p.Size = Vector3.new(1, 1, 1)
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(180, 80, 255)
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = root.CFrame * CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, 4)
		p.Parent = workspace
		TweenService:Create(p, TweenInfo.new(0.7), {
			Position = p.Position + Vector3.new(0, 10, 0),
			Transparency = 1,
		}):Play()
		task.delay(0.75, function()
			p:Destroy()
		end)
	end
end

function FX.play(kind: string, color: Color3?)
	if kind == "pickup" then
		FX.pickup(color)
	elseif kind == "deposit" then
		FX.deposit()
	elseif kind == "rebirth" then
		FX.rebirth()
	end
end

return FX
