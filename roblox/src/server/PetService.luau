local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local PetService = {}
local pets: { [Player]: BasePart } = {}

local function destroyPet(player: Player)
	local p = pets[player]
	if p then
		p:Destroy()
		pets[player] = nil
	end
end

function PetService.refresh(player: Player)
	destroyPet(player)
	local profile = PlayerData.get(player)
	local petId = profile.activePet
	if not petId or not Config.PetById[petId] then
		return
	end
	local def = Config.PetById[petId]
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local ball = Instance.new("Part")
	ball.Name = "CashPet"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2.2, 2.2, 2.2)
	ball.Color = def.color
	ball.Material = Enum.Material.Neon
	ball.CanCollide = false
	ball.Massless = true
	ball.Anchored = true
	ball.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = def.color
	light.Brightness = 1.5
	light.Range = 10
	light.Parent = ball

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(100, 28)
	gui.StudsOffset = Vector3.new(0, 1.8, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 35
	gui.Parent = ball
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.4
	t.Text = def.name
	t.Parent = gui

	pets[player] = ball
end

function PetService.start()
	RunService.Heartbeat:Connect(function()
		for player, ball in pets do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and ball.Parent then
				local target = root.CFrame * CFrame.new(3, 1.5 + math.sin(os.clock() * 3) * 0.4, 2)
				ball.CFrame = ball.CFrame:Lerp(target, 0.15)
			end
		end
	end)

	Players.PlayerRemoving:Connect(destroyPet)
end

return PetService
