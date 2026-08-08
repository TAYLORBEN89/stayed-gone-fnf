--[[
	Zombies patrol outside the safe hub.
	- Chase players, bite (damage + chance to knock a carried coin)
	- Players auto-melee when close (or click Attack remote)
	- Kills drop cash + zombie teeth loot
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Util = require(game.ReplicatedStorage.Shared.Util)
local PlayerData = require(script.Parent.PlayerData)

local ZombieService = {}
ZombieService._folder = nil :: Folder?
ZombieService._zombies = {} :: { any }
ZombieService._onToast = nil :: ((Player, string, Color3?) -> ())?
ZombieService._onState = nil :: ((Player) -> ())?
ZombieService._onFX = nil :: ((Player, string, Color3?) -> ())?

local function inSafeHub(pos: Vector3): boolean
	local hub = Config.SPAWN_HUB or Vector3.zero
	local flat = Vector3.new(pos.X - hub.X, 0, pos.Z - hub.Z)
	return flat.Magnitude < (Config.SAFE_HUB_RADIUS or 70)
end

function ZombieService.setCallbacks(toast, pushState, fx)
	ZombieService._onToast = toast
	ZombieService._onState = pushState
	ZombieService._onFX = fx
end

local function makeZombieModel(pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Zombie"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = pos + Vector3.new(0, 3, 0)
	root.Color = Color3.fromRGB(70, 100, 55)
	root.Material = Enum.Material.SmoothPlastic
	root.CanCollide = true
	root.Anchored = false
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.2, 2.2, 1.1)
	torso.Color = Color3.fromRGB(55, 85, 45)
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Massless = true
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = Color3.fromRGB(90, 130, 70)
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Massless = true
	head.Parent = model

	local face = Instance.new("Decal")
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	-- glowing eyes
	for _, x in { -0.35, 0.35 } do
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(0.25, 0.25, 0.25)
		eye.Shape = Enum.PartType.Ball
		eye.Color = Color3.fromRGB(255, 50, 40)
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.Massless = true
		eye.Parent = model
		local w = Instance.new("Weld")
		w.Part0 = head
		w.Part1 = eye
		w.C0 = CFrame.new(x, 0.15, -0.7)
		w.Parent = eye
	end

	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.MaxHealth = Config.ZOMBIE_HEALTH
	hum.Health = Config.ZOMBIE_HEALTH
	hum.WalkSpeed = Config.ZOMBIE_SPEED
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	-- welds
	local function weld(a: BasePart, b: BasePart, c0: CFrame)
		local w = Instance.new("Weld")
		w.Part0 = a
		w.Part1 = b
		w.C0 = c0
		w.Parent = a
	end
	weld(root, torso, CFrame.new(0, 0.2, 0))
	weld(root, head, CFrame.new(0, 1.8, 0))

	-- arms
	for _, x in { -1.4, 1.4 } do
		local arm = Instance.new("Part")
		arm.Size = Vector3.new(0.7, 2, 0.7)
		arm.Color = Color3.fromRGB(80, 110, 60)
		arm.CanCollide = false
		arm.Massless = true
		arm.Parent = model
		weld(root, arm, CFrame.new(x, 0.3, -0.3) * CFrame.Angles(math.rad(-40), 0, 0))
	end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(90, 24)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 40
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(180, 255, 120)
	t.TextStrokeTransparency = 0.4
	t.Text = "🧟 ZOMBIE"
	t.Parent = bb

	model.PrimaryPart = root
	return model
end

local function spawnPos(): Vector3
	-- outside safe hub, in suburbs ring
	local ang = math.random() * math.pi * 2
	local hub = Config.SPAWN_HUB or Vector3.zero
	local r = (Config.SAFE_HUB_RADIUS or 70) + 80 + math.random() * 280
	-- ring around map center, not on spawn corner
	return Vector3.new(math.cos(ang) * r * 0.7, 6, math.sin(ang) * r * 0.7)
end

function ZombieService.spawnOne()
	if not ZombieService._folder then
		return
	end
	local model = makeZombieModel(spawnPos())
	model.Parent = ZombieService._folder

	local data = {
		model = model,
		hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid,
		root = model.PrimaryPart :: BasePart,
		lastBite = 0,
		dead = false,
	}
	table.insert(ZombieService._zombies, data)

	data.hum.Died:Connect(function()
		if data.dead then
			return
		end
		data.dead = true
		-- find killer: nearest player
		local killer: Player? = nil
		local best = 20
		for _, plr in Players:GetPlayers() do
			local char = plr.Character
			local r = char and char:FindFirstChild("HumanoidRootPart")
			if r then
				local d = (r.Position - data.root.Position).Magnitude
				if d < best then
					best = d
					killer = plr
				end
			end
		end
		if killer then
			local cash = math.random(Config.ZOMBIE_CASH_DROP_MIN, Config.ZOMBIE_CASH_DROP_MAX)
			local profile = PlayerData.get(killer)
			profile.cash += cash
			profile.bank["zombie_tooth"] = (profile.bank["zombie_tooth"] or 0) + 1
			-- chance of free carry loot
			if #profile.carry < profile.capacity and math.random() < 0.55 then
				table.insert(profile.carry, {
					uid = "z" .. tostring(os.clock()),
					currencyId = math.random() < 0.7 and "dollar" or "coin_jar",
				})
			end
			if ZombieService._onToast then
				ZombieService._onToast(
					killer,
					"🧟 Zombie down! +" .. cash .. " Cash + 🦷 tooth",
					Color3.fromRGB(140, 255, 100)
				)
			end
			if ZombieService._onFX then
				ZombieService._onFX(killer, "pickup", Color3.fromRGB(100, 255, 80))
			end
			if ZombieService._onState then
				ZombieService._onState(killer)
			end
			PlayerData.updateLeaderstats(killer)
		end
		task.delay(1.2, function()
			if model.Parent then
				model:Destroy()
			end
		end)
		-- remove from list later
		task.delay(1.5, function()
			for i, z in ZombieService._zombies do
				if z == data then
					table.remove(ZombieService._zombies, i)
					break
				end
			end
		end)
	end)

	return data
end

local function nearestPlayer(from: Vector3): (Player?, BasePart?)
	local bestPlr: Player? = nil
	local bestRoot: BasePart? = nil
	local best = Config.ZOMBIE_AGGRO
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			if inSafeHub(root.Position) then
				continue
			end
			local d = (root.Position - from).Magnitude
			if d < best then
				best = d
				bestPlr = plr
				bestRoot = root
			end
		end
	end
	return bestPlr, bestRoot
end

function ZombieService.playerMelee(player: Player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	for _, z in ZombieService._zombies do
		if z.dead or not z.root or not z.hum then
			continue
		end
		if (z.root.Position - root.Position).Magnitude <= Config.ZOMBIE_MELEE_RANGE then
			z.hum:TakeDamage(Config.ZOMBIE_PLAYER_DPS * 0.35)
			if ZombieService._onFX then
				ZombieService._onFX(player, "pickup", Color3.fromRGB(200, 255, 120))
			end
		end
	end
end

function ZombieService.start(folder: Folder)
	ZombieService._folder = folder
	for _ = 1, Config.ZOMBIE_MAX do
		ZombieService.spawnOne()
	end

	-- maintain population
	task.spawn(function()
		while true do
			task.wait(3)
			local alive = 0
			for _, z in ZombieService._zombies do
				if not z.dead and z.model.Parent then
					alive += 1
				end
			end
			while alive < Config.ZOMBIE_MAX do
				ZombieService.spawnOne()
				alive += 1
			end
		end
	end)

	-- AI + combat loop
	local meleeAcc: { [Player]: number } = {}
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for _, z in ZombieService._zombies do
			if z.dead or not z.model.Parent or not z.hum or z.hum.Health <= 0 then
				continue
			end
			if inSafeHub(z.root.Position) then
				-- shove out of hub
				z.hum:MoveTo(spawnPos())
				continue
			end

			local plr, target = nearestPlayer(z.root.Position)
			if target and plr then
				z.hum:MoveTo(target.Position)
				local dist = (target.Position - z.root.Position).Magnitude
				if dist <= Config.ZOMBIE_ATTACK_RANGE and now - z.lastBite >= Config.ZOMBIE_HIT_COOLDOWN then
					z.lastBite = now
					local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum:TakeDamage(Config.ZOMBIE_DAMAGE)
						if ZombieService._onToast then
							ZombieService._onToast(plr, "🧟 A zombie bit you!", Color3.fromRGB(255, 100, 80))
						end
						-- steal carry
						local profile = PlayerData.get(plr)
						if #profile.carry > 0 and math.random() < Config.ZOMBIE_STEAL_CHANCE then
							local idx = math.random(1, #profile.carry)
							table.remove(profile.carry, idx)
							if ZombieService._onToast then
								ZombieService._onToast(plr, "💸 Zombie knocked a coin off your stack!", Color3.fromRGB(255, 160, 60))
							end
							if ZombieService._onState then
								ZombieService._onState(plr)
							end
						end
					end
				end
			else
				-- wander
				if math.random() < 0.02 then
					z.hum:MoveTo(spawnPos())
				end
			end
		end

		-- player auto-melee
		for _, plr in Players:GetPlayers() do
			meleeAcc[plr] = (meleeAcc[plr] or 0) + dt
			if meleeAcc[plr] >= 0.35 then
				meleeAcc[plr] = 0
				ZombieService.playerMelee(plr)
			end
		end
	end)
end

return ZombieService
