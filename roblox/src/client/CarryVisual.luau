local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)

local CarryVisual = {}
CarryVisual._count = 0
CarryVisual._trail = 0
CarryVisual._value = 0

local player = Players.LocalPlayer

local function ensureFolder(char: Model): Folder
	local f = char:FindFirstChild("CarryStack")
	if f and f:IsA("Folder") then
		return f
	end
	if f then
		f:Destroy()
	end
	f = Instance.new("Folder")
	f.Name = "CarryStack"
	f.Parent = char
	return f
end

function CarryVisual.setState(state)
	CarryVisual._count = state.carryCount or 0
	CarryVisual._trail = state.trail or 0
	CarryVisual._value = state.carryValue or 0
	CarryVisual.rebuild()
end

function CarryVisual.rebuild()
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local folder = ensureFolder(char)
	for _, c in folder:GetChildren() do
		c:Destroy()
	end

	local visualCount = math.min(CarryVisual._count, Config.STACK_VISUAL_CAP)
	local h = Config.STACK_HEIGHT_PER_ITEM
	for i = 1, visualCount do
		local p = Instance.new("Part")
		p.Name = "Bill_" .. i
		p.Size = Vector3.new(2.4, h * 0.85, 1.5)
		p.CanCollide = false
		p.Massless = true
		p.Material = Enum.Material.SmoothPlastic
		local t = i / math.max(visualCount, 1)
		-- gold → emerald → diamond flex gradient
		p.Color = Color3.fromHSV((0.12 + t * 0.55) % 1, 0.7, 0.95)
		p.Parent = folder
		local y = 2.1 + (i - 0.5) * h
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = p
		weld.C0 = CFrame.new(0, y, 0.95) * CFrame.Angles(0, t * 0.4, 0)
		weld.Parent = p
	end

	if CarryVisual._count > 0 then
		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromOffset(140, 50)
		bill.StudsOffset = Vector3.new(0, 2.2 + visualCount * h, 0)
		bill.AlwaysOnTop = true -- only your own stack counter
		bill.MaxDistance = 40
		bill.Parent = folder
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(255, 230, 100)
		lbl.TextStrokeTransparency = 0.35
		lbl.Text = "x" .. CarryVisual._count .. "\n💰" .. tostring(CarryVisual._value)
		lbl.Parent = bill
	end

	local old = root:FindFirstChild("RichTrail")
	if old then
		old:Destroy()
	end
	if CarryVisual._trail and CarryVisual._trail > 0 then
		local att0 = root:FindFirstChild("TrailA0") :: Attachment?
		local att1 = root:FindFirstChild("TrailA1") :: Attachment?
		if not att0 then
			att0 = Instance.new("Attachment")
			att0.Name = "TrailA0"
			att0.Position = Vector3.new(-0.5, 1, 0)
			att0.Parent = root
		end
		if not att1 then
			att1 = Instance.new("Attachment")
			att1.Name = "TrailA1"
			att1.Position = Vector3.new(0.5, -1, 0)
			att1.Parent = root
		end
		local trail = Instance.new("Trail")
		trail.Name = "RichTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		if CarryVisual._trail == 2 then
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 60, 200), Color3.fromRGB(80, 200, 255))
		else
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 210, 60), Color3.fromRGB(255, 140, 40))
		end
		trail.Transparency = NumberSequence.new(0.15, 1)
		trail.Lifetime = 0.7
		trail.Parent = root
	end
end

function CarryVisual.start()
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		CarryVisual.rebuild()
	end)
end

return CarryVisual
