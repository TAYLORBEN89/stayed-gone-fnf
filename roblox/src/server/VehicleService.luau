--[[
	YZ65 dirtbike — custom drive (VehicleSeat Throttle/Steer → velocity)
	Classic VehicleSeat physics is unreliable on welded props; we drive it ourselves.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local VehicleService = {}
VehicleService._bikes = {} :: { [Player]: Model }
VehicleService._folder = nil :: Folder?
VehicleService._toast = nil :: ((Player, string, Color3?) -> ())?
VehicleService._toolHooked = {} :: { [Player]: boolean }
VehicleService._driveBound = false

-- Drive numbers live on the client (YZ65Drive). Server only builds/spawns.

function VehicleService.setToast(fn)
	VehicleService._toast = fn
end

local function ensureFolder(): Folder
	if VehicleService._folder and VehicleService._folder.Parent then
		return VehicleService._folder
	end
	local f = workspace:FindFirstChild("CashEmpireVehicles")
	if not f then
		f = Instance.new("Folder")
		f.Name = "CashEmpireVehicles"
		f.Parent = workspace
	end
	VehicleService._folder = f
	return f
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function deco(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

--[[ Build YZ65 — collidable chassis + massless cosmetics ]]
function VehicleService.buildYZ65(): Model
	local model = Instance.new("Model")
	model.Name = "YZ65_Dirtbike"

	-- Drive seat (physics root)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriveSeat"
	seat.Size = Vector3.new(2.0, 0.9, 3.4)
	seat.Color = Color3.fromRGB(30, 30, 35)
	seat.Material = Enum.Material.SmoothPlastic
	seat.HeadsUpDisplay = true
	seat.MaxSpeed = MAX_SPEED -- unused by custom drive, kept for UI
	seat.Torque = 1
	seat.TurnSpeed = 1
	seat.Disabled = false
	seat.CanCollide = true
	seat.Massless = false
	-- density, friction, elasticity — low friction so drive velocity sticks
	seat.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.25, 0.1, 1, 1)
	seat:SetAttribute("IsYZ65", true)
	seat.Parent = model

	-- Wider floor plate so it doesn't tip / dig in
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(2.4, 0.5, 4.2)
	chassis.Color = Color3.fromRGB(40, 40, 48)
	chassis.Material = Enum.Material.Metal
	chassis.Anchored = false
	chassis.CanCollide = true
	chassis.Massless = false
	chassis.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.2, 0.1, 1, 1)
	chassis.CFrame = seat.CFrame * CFrame.new(0, -0.55, 0.1)
	chassis.Parent = model
	weld(seat, chassis)

	-- Cosmetics (no collide)
	local tank = deco({
		Name = "FuelTank",
		Size = Vector3.new(1.5, 1.0, 1.9),
		Color = Color3.fromRGB(40, 110, 220),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	tank.CFrame = seat.CFrame * CFrame.new(0, 0.85, 0.3)
	weld(seat, tank)

	local plate = deco({
		Name = "NumberPlate",
		Size = Vector3.new(0.85, 0.65, 0.12),
		Color = Color3.fromRGB(245, 245, 250),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	plate.CFrame = seat.CFrame * CFrame.new(0, 1.1, -1.5)
	weld(seat, plate)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = plate
	local lab = Instance.new("TextLabel")
	lab.Size = UDim2.fromScale(1, 1)
	lab.BackgroundTransparency = 1
	lab.Font = Enum.Font.GothamBlack
	lab.TextScaled = true
	lab.TextColor3 = Color3.fromRGB(20, 20, 30)
	lab.Text = "65"
	lab.Parent = gui

	local pad = deco({
		Name = "SeatPad",
		Size = Vector3.new(1.2, 0.4, 1.8),
		Color = Color3.fromRGB(25, 25, 30),
		Material = Enum.Material.Fabric,
		Parent = model,
	})
	pad.CFrame = seat.CFrame * CFrame.new(0, 0.7, 0.5)
	weld(seat, pad)

	local accent = deco({
		Name = "Accent",
		Size = Vector3.new(1.5, 0.18, 0.45),
		Color = Color3.fromRGB(255, 220, 40),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	accent.CFrame = seat.CFrame * CFrame.new(0, 1.15, 0.15)
	weld(seat, accent)

	local eng = deco({
		Name = "Engine",
		Size = Vector3.new(1.1, 0.9, 1.3),
		Color = Color3.fromRGB(80, 80, 90),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	eng.CFrame = seat.CFrame * CFrame.new(0, -0.05, -0.15)
	weld(seat, eng)

	local bars = deco({
		Name = "Bars",
		Size = Vector3.new(2.4, 0.22, 0.22),
		Color = Color3.fromRGB(200, 200, 210),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	bars.CFrame = seat.CFrame * CFrame.new(0, 1.55, -1.2)
	weld(seat, bars)

	local function wheel(name: string, offset: CFrame)
		local w = deco({
			Name = name,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.85, 2.2, 2.2),
			Color = Color3.fromRGB(25, 25, 28),
			Material = Enum.Material.Rubber,
			Parent = model,
		})
		w.CFrame = seat.CFrame * offset * CFrame.Angles(0, 0, math.rad(90))
		weld(seat, w)
	end
	wheel("FrontWheel", CFrame.new(0, -0.45, -2.35))
	wheel("RearWheel", CFrame.new(0, -0.45, 1.85))

	local fenderF = deco({
		Name = "FrontFender",
		Size = Vector3.new(1.3, 0.3, 1.4),
		Color = Color3.fromRGB(40, 110, 220),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	fenderF.CFrame = seat.CFrame * CFrame.new(0, 0.35, -2.2)
	weld(seat, fenderF)

	local fenderR = deco({
		Name = "RearFender",
		Size = Vector3.new(1.3, 0.28, 1.3),
		Color = Color3.fromRGB(40, 110, 220),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	fenderR.CFrame = seat.CFrame * CFrame.new(0, 0.5, 1.9)
	weld(seat, fenderR)

	model.PrimaryPart = seat

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(130, 30)
	bill.StudsOffset = Vector3.new(0, 3.4, 0)
	bill.MaxDistance = 90
	bill.Parent = seat
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(80, 160, 255)
	t.TextStrokeTransparency = 0.4
	t.Text = "🏍️ YZ65 · FAST"
	t.Parent = bill

	-- Sit prompt (more reliable than pure touch-sit)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RidePrompt"
	prompt.ActionText = "Ride YZ65"
	prompt.ObjectText = "Dirtbike"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(plr)
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			seat:Sit(hum)
			-- Client must own physics so local WASD drive can move the bike
			task.defer(function()
				pcall(function()
					seat:SetNetworkOwner(plr)
				end)
			end)
			if VehicleService._toast then
				VehicleService._toast(plr, "🏍️ HOLD W to drive · A/D turn · S brake", Color3.fromRGB(80, 180, 255))
			end
		end
	end)

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		if hum then
			local plr = Players:GetPlayerFromCharacter(hum.Parent)
			if plr then
				task.defer(function()
					pcall(function()
						seat:SetNetworkOwner(plr)
					end)
				end)
			end
		end
	end)

	return model
end

function VehicleService.destroyBike(player: Player)
	local bike = VehicleService._bikes[player]
	if bike then
		bike:Destroy()
		VehicleService._bikes[player] = nil
	end
end

--[[
	Driving is handled on the CLIENT (YZ65Drive.luau).
	Server only assigns network ownership so the rider can move the assembly.
]]
function VehicleService.startDriveLoop()
	if VehicleService._driveBound then
		return
	end
	VehicleService._driveBound = true
	-- Keep ownership sticky while someone is seated
	RunService.Heartbeat:Connect(function()
		for plr, bike in VehicleService._bikes do
			if not bike.Parent then
				continue
			end
			local seat = bike.PrimaryPart
			if seat and seat:IsA("VehicleSeat") and seat.Occupant then
				local hum = seat.Occupant
				local owner = Players:GetPlayerFromCharacter(hum.Parent)
				if owner then
					pcall(function()
						seat:SetNetworkOwner(owner)
					end)
				end
			end
		end
	end)
end

function VehicleService.spawnYZ65(player: Player): (boolean, string)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return false, "No character"
	end

	VehicleService.destroyBike(player)
	VehicleService.startDriveLoop()

	local bike = VehicleService.buildYZ65()
	local seat = bike.PrimaryPart :: VehicleSeat
	-- Spawn in front of player, slightly up so it doesn't clip
	local spawnCF = root.CFrame * CFrame.new(0, 2.5, -6)
	bike:PivotTo(spawnCF)
	bike.Parent = ensureFolder()

	bike:SetAttribute("OwnerUserId", player.UserId)
	VehicleService._bikes[player] = bike

	task.defer(function()
		if not seat.Parent then
			return
		end
		task.wait(0.2)
		if hum.Parent and seat.Parent then
			seat:Sit(hum)
			-- Rider owns physics → client YZ65Drive moves the bike
			pcall(function()
				seat:SetNetworkOwner(player)
			end)
		end
	end)

	task.spawn(function()
		while bike.Parent do
			task.wait(10)
			if not player.Parent then
				bike:Destroy()
				break
			end
		end
		if VehicleService._bikes[player] == bike then
			VehicleService._bikes[player] = nil
		end
	end)

	return true, "🏍️ YZ65 — sit + HOLD W to go (A/D turn). Much faster than running!"
end

function VehicleService.giveCallTool(player: Player)
	local function give()
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then
			return
		end
		if backpack:FindFirstChild("YZ65 Call") or (player.Character and player.Character:FindFirstChild("YZ65 Call")) then
			return
		end
		local tool = Instance.new("Tool")
		tool.Name = "YZ65 Call"
		tool.RequiresHandle = true
		tool.CanBeDropped = false
		tool.ToolTip = "Spawn / recall your YZ65 dirtbike"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.6, 0.6, 1.2)
		handle.Color = Color3.fromRGB(40, 110, 220)
		handle.Material = Enum.Material.Neon
		handle.Parent = tool
		tool.Parent = backpack

		tool.Activated:Connect(function()
			local ok, msg = VehicleService.spawnYZ65(player)
			if VehicleService._toast then
				VehicleService._toast(player, msg, ok and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(255, 160, 80))
			end
		end)
	end

	if VehicleService._toolHooked[player] then
		give()
		return
	end
	VehicleService._toolHooked[player] = true
	give()
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		local PlayerData = require(script.Parent.PlayerData)
		if PlayerData.get(player).passes.yz65 then
			give()
		end
	end)
end

function VehicleService.onOwned(player: Player)
	VehicleService.giveCallTool(player)
	task.delay(0.4, function()
		if player.Character then
			local ok, msg = VehicleService.spawnYZ65(player)
			if VehicleService._toast then
				VehicleService._toast(player, msg, ok and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(255, 160, 80))
			end
		end
	end)
end

function VehicleService.wireBoostPads(pads: { BasePart }?)
	local list = pads or {}
	if #list == 0 then
		for _, inst in CollectionService:GetTagged("JumpBoost") do
			if inst:IsA("BasePart") then
				table.insert(list, inst)
			end
		end
	end

	local cd: { [BasePart]: number } = {}

	local function applyBoost(hit: BasePart, pad: BasePart)
		local power = (pad:GetAttribute("BoostPower") :: number?) or 145
		local up = (pad:GetAttribute("BoostUp") :: number?) or (power * 0.42)
		local dir = pad.CFrame.LookVector
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude < 0.05 then
			flat = Vector3.new(0, 0, -1)
		else
			flat = flat.Unit
		end
		local impulse = flat * power + Vector3.new(0, up, 0)

		local model = hit:FindFirstAncestorOfClass("Model")
		local seat: VehicleSeat? = nil
		if model then
			local s = model:FindFirstChildWhichIsA("VehicleSeat", true)
			if s and s:IsA("VehicleSeat") then
				seat = s
			end
		end
		if seat and seat:GetAttribute("IsYZ65") then
			local now = os.clock()
			if (cd[seat] or 0) > now then
				return
			end
			cd[seat] = now + 1.1
			seat.AssemblyLinearVelocity = impulse * 1.15
			if VehicleService._toast and seat.Occupant then
				local hum = seat.Occupant
				local plr = Players:GetPlayerFromCharacter(hum.Parent)
				if plr then
					VehicleService._toast(plr, "🚀 LIP BOOST!", Color3.fromRGB(255, 160, 60))
				end
			end
			return
		end

		if model then
			local plr = Players:GetPlayerFromCharacter(model)
			local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if plr and root then
				local now = os.clock()
				if (cd[root] or 0) > now then
					return
				end
				cd[root] = now + 1.1
				root.AssemblyLinearVelocity = impulse * 0.85
				if VehicleService._toast then
					VehicleService._toast(plr, "🚀 Jump boost!", Color3.fromRGB(255, 160, 60))
				end
			end
		end
	end

	for _, pad in list do
		pad.Touched:Connect(function(hit)
			if hit:IsA("BasePart") then
				applyBoost(hit, pad)
			end
		end)
	end
	print(("[CashEmpire] Jump boost lips wired: %d"):format(#list))
end

Players.PlayerRemoving:Connect(function(player)
	VehicleService.destroyBike(player)
	VehicleService._toolHooked[player] = nil
end)

-- Start drive loop when module loads
VehicleService.startDriveLoop()

return VehicleService
