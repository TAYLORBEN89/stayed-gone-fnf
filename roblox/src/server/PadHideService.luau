--[[ Walkover pads disappear while a player stands on them, return when empty. ]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local PadHideService = {}

local function flatDist(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

function PadHideService.start()
	local dist = Config.PAD_HIDE_DIST or 7
	RunService.Heartbeat:Connect(function()
		for _, pad in CollectionService:GetTagged("WalkoverPad") do
			if not pad:IsA("BasePart") then
				continue
			end
			local occupied = false
			for _, plr in Players:GetPlayers() do
				local char = plr.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and flatDist(root.Position, pad.Position) <= dist and math.abs(root.Position.Y - pad.Position.Y) < 8 then
					occupied = true
					break
				end
			end
			local baseT = pad:GetAttribute("BaseTransparency")
			if baseT == nil then
				baseT = 0
			end
			if occupied then
				pad.Transparency = 1
				pad.CanCollide = false
				local lab = pad:FindFirstChild("PadLabel")
				if lab and lab:IsA("BillboardGui") then
					lab.Enabled = false
				end
			else
				-- don't un-hide owned tycoon pads that tycoon set transparent
				if pad:GetAttribute("TycoonButton") and pad.Transparency >= 0.45 and pad.Color == Color3.fromRGB(60, 200, 100) then
					-- leave owned look
				else
					pad.Transparency = baseT
					pad.CanCollide = true
					local lab = pad:FindFirstChild("PadLabel")
					if lab and lab:IsA("BillboardGui") then
						lab.Enabled = true
					end
				end
			end
		end
	end)
end

return PadHideService
