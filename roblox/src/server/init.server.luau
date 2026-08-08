--[[
	CASH EMPIRE v2 — market-ready loop
	Collect → combo stack → bank → shop/pets → rebirth multi → events
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local PlayerData = require(script.PlayerData)
local WorldBuilder = require(script.WorldBuilder)
local CollectibleService = require(script.CollectibleService)
local ShopService = require(script.ShopService)
local DataService = require(script.DataService)
local PetService = require(script.PetService)
local EventService = require(script.EventService)
local ZombieService = require(script.ZombieService)
local MonetizationService = require(script.MonetizationService)
local TycoonService = require(script.TycoonService)
local PadHideService = require(script.PadHideService)
local ChestService = require(script.ChestService)
local VehicleService = require(script.VehicleService)
local ConcertService = require(script.ConcertService)

print("[CashEmpire] Booting " .. Config.VERSION)

local existing = ReplicatedStorage:FindFirstChild("CashStackRemotes")
if existing then
	existing:Destroy()
end
local remotes = Instance.new("Folder")
remotes.Name = "CashStackRemotes"
remotes.Parent = ReplicatedStorage

local function RE(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local function RF(name: string): RemoteFunction
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = remotes
	return r
end

local RE_State = RE("State")
local RE_Toast = RE("Toast")
local RE_OpenShop = RE("OpenShop")
local RE_Announce = RE("Announce")
local RE_FX = RE("FX")
local RE_OpenFusion = RE("OpenFusion")
local RE_OpenIndex = RE("OpenIndex")
local RE_Attack = RE("Attack")
local RE_OpenRobux = RE("OpenRobux")
-- NOTE: do NOT create RemoteEvents named PromptPass/PromptProduct —
-- those names are reserved for RemoteFunctions the client InvokeServers.
local RF_Buy = RF("Buy")
local RF_Deposit = RF("Deposit")
local RF_GetState = RF("GetState")
local RF_Rebirth = RF("Rebirth")
local RF_Fuse = RF("Fuse")
local RF_EquipPet = RF("EquipPet")
local RF_PromptPass = RF("PromptPass")
local RF_PromptProduct = RF("PromptProduct")

local world = WorldBuilder.build()
CollectibleService.start(world.lootFolder, world.floorSpawns, world.groundSpawns)
PetService.start()
PadHideService.start()
TycoonService.bindWorld(world.bases)

-- Floor elevators: blue = up, orange = down (touch OR proximity prompt)
local elevCd: { [Player]: number } = {}
local function useElevator(plr: Player, pad: BasePart)
	local now = os.clock()
	if (elevCd[plr] or 0) > now then
		return
	end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end

	local targetY = pad:GetAttribute("TargetY")
	if typeof(targetY) ~= "number" then
		-- Fallback: one story height up/down from pad
		local H = Config.STORY_HEIGHT or 20
		local dir = pad:GetAttribute("ElevatorDir")
		targetY = pad.Position.Y + (dir == "down" and -H or H)
	end

	-- Optional story gate (only if RequiredStory > 1)
	local needStory = pad:GetAttribute("RequiredStory")
	local toStory = pad:GetAttribute("ToStory")
	if typeof(needStory) == "number" and needStory > 1 then
		local profile = PlayerData.get(plr)
		local ok, msg = CollectibleService.canAccessStory(profile.maxStory or 1, profile.cash or 0, needStory)
		if not ok then
			elevCd[plr] = now + 1.2
			RE_Toast:FireClient(plr, msg, Color3.fromRGB(255, 160, 80))
			return
		end
	end

	elevCd[plr] = now + 0.85
	-- Land on pad XZ of destination floor (same pad column) at TargetY
	local landX = pad.Position.X
	local landZ = pad.Position.Z
	-- Nudge slightly toward courtyard center so you don't stick in walls
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = CFrame.new(landX, targetY, landZ)
	local dir = pad:GetAttribute("ElevatorDir")
	local floorTxt = typeof(toStory) == "number" and ("Floor " .. toStory) or "next floor"
	RE_Toast:FireClient(
		plr,
		dir == "up" and ("⬆ " .. floorTxt) or ("⬇ " .. floorTxt),
		Color3.fromRGB(150, 220, 255)
	)
	local maxStory = PlayerData.get(plr).maxStory or 1
	if typeof(toStory) == "number" and toStory > maxStory then
		RE_Toast:FireClient(
			plr,
			"💡 Loot on this floor needs Story Gate " .. toStory .. " (buy on your tycoon deck)",
			Color3.fromRGB(255, 210, 120)
		)
	end
end

local elevCount = 0
for _, inst in world.folder:GetDescendants() do
	if inst:IsA("BasePart") and inst:GetAttribute("Elevator") then
		elevCount += 1
		inst.CanTouch = true
		inst.CanCollide = true
		inst.Touched:Connect(function(hit)
			if not hit:IsA("BasePart") then
				return
			end
			local model = hit:FindFirstAncestorOfClass("Model")
			local plr = model and Players:GetPlayerFromCharacter(model)
			if plr then
				useElevator(plr, inst)
			end
		end)
		local prompt = inst:FindFirstChild("ElevatorPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function(plr)
				useElevator(plr, inst)
			end)
		else
			-- Ensure prompt exists even on older worlds
			local p = Instance.new("ProximityPrompt")
			p.Name = "ElevatorPrompt"
			p.ActionText = inst:GetAttribute("ElevatorDir") == "down" and "Go down" or "Go up"
			p.ObjectText = "Elevator"
			p.HoldDuration = 0
			p.MaxActivationDistance = 16
			p.RequiresLineOfSight = false
			p.Parent = inst
			p.Triggered:Connect(function(plr)
				useElevator(plr, inst)
			end)
		end
	end
end
print("[CashEmpire] Elevators wired: " .. elevCount)

local function pushStateEarly(player: Player)
	PlayerData.updateLeaderstats(player)
	RE_State:FireClient(player, PlayerData.summary(player))
end

ZombieService.setCallbacks(
	function(player, msg, color)
		RE_Toast:FireClient(player, msg, color)
	end,
	pushStateEarly,
	function(player, kind, color)
		RE_FX:FireClient(player, kind, color)
	end
)
ZombieService.start(world.zombiesFolder)

RE_Attack.OnServerEvent:Connect(function(player)
	ZombieService.playerMelee(player)
end)

EventService.setAnnounce(function(msg, color)
	RE_Announce:FireAllClients(msg, color)
	for _, plr in Players:GetPlayers() do
		RE_Toast:FireClient(plr, msg, color)
	end
end)
EventService.start()

local function pushState(player: Player)
	pushStateEarly(player)
end

local function flatDist(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function nearAnyDeposit(root: BasePart): boolean
	if world.mainBank and flatDist(root.Position, world.mainBank.Position) <= 15 then
		return true
	end
	for _, s in world.bases do
		if flatDist(root.Position, s.deposit.Position) <= 13 then
			return true
		end
	end
	return false
end

local function applyWalkSpeed(player: Player)
	local profile = PlayerData.get(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local speed = Config.BASE_WALK_SPEED + profile.speedBonus - #profile.carry * Config.SLOW_PER_ITEM
	hum.WalkSpeed = math.clamp(speed, Config.MIN_WALK_SPEED, 55)
end

local function setTitleBillboard(player: Player)
	local profile = PlayerData.get(player)
	local char = player.Character
	if not char then
		return
	end
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("EmpireTitle")
	if old then
		old:Destroy()
	end
	local title = profile.title
	if profile.passes.vip and title == "" then
		title = "VIP"
	end
	if title == "" then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "EmpireTitle"
	bb.Size = UDim2.fromOffset(160, 30)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 50
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = profile.passes.vip and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(255, 215, 80)
	t.TextStrokeTransparency = 0.4
	t.Text = "【" .. title .. "】"
	t.Parent = bb
end

MonetizationService.setCallbacks(
	function(player, msg, color)
		RE_Toast:FireClient(player, msg, color)
	end,
	pushState,
	setTitleBillboard,
	PetService.refresh,
	applyWalkSpeed
)
MonetizationService.start()
VehicleService.setToast(function(player, msg, color)
	RE_Toast:FireClient(player, msg, color)
end)
VehicleService.wireBoostPads(world.boostPads)

ConcertService.setCallbacks(
	function(player, msg, color)
		RE_Toast:FireClient(player, msg, color)
	end,
	pushState,
	setTitleBillboard
)
if world.redRocks then
	ConcertService.wire(world.redRocks)
	print("[CashEmpire] Red Rocks Amphitheatre live — ticketed entry")
end

RF_PromptPass.OnServerInvoke = function(player, key: string)
	if type(key) ~= "string" then
		return false, "Invalid pass"
	end
	local ok, msg = MonetizationService.promptGamePass(player, key)
	if msg then
		RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 160, 80))
	end
	pushState(player)
	return ok, msg, PlayerData.summary(player)
end

RF_PromptProduct.OnServerInvoke = function(player, key: string)
	if type(key) ~= "string" then
		return false, "Invalid product"
	end
	local ok, msg = MonetizationService.promptProduct(player, key)
	if msg then
		RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 160, 80))
	end
	pushState(player)
	return ok, msg, PlayerData.summary(player)
end

local function updateBaseSign(slot, player: Player?)
	local bname = slot.name or ("Plot " .. slot.index)
	local biome = slot.biome or ""
	if slot.ownerText then
		if player then
			slot.ownerText.Text = "🏠 " .. bname:upper() .. "\n" .. biome .. "\nOWNED: " .. player.Name
			slot.ownerText.TextColor3 = Color3.fromRGB(255, 210, 80)
			-- owned = short distance
			local gui = slot.ownerText.Parent
			if gui and gui:IsA("BillboardGui") then
				gui.MaxDistance = Config.LABEL_DISTANCE_OWNED_BASE or 80
				gui.AlwaysOnTop = false
			end
		else
			slot.ownerText.Text = "🏠 " .. bname:upper() .. "\n" .. biome .. "\n✦ AVAILABLE — CLAIM ME"
			slot.ownerText.TextColor3 = Color3.fromRGB(120, 255, 150)
			local gui = slot.ownerText.Parent
			if gui and gui:IsA("BillboardGui") then
				gui.MaxDistance = Config.LABEL_DISTANCE_OPEN_BASE or 900
				gui.AlwaysOnTop = true
			end
		end
	end
	if slot.plot then
		slot.plot.Color = player and Color3.fromRGB(55, 85, 150) or Color3.fromRGB(55, 55, 70)
	end
	if slot.claimPad then
		if player then
			slot.claimPad.Color = Color3.fromRGB(80, 80, 100)
			slot.claimPad.Transparency = 0.55
			local lab = slot.claimPad:FindFirstChild("PadLabel")
			if lab then
				local t = lab:FindFirstChildWhichIsA("TextLabel")
				if t then
					t.Text = "OWNED BY\n" .. player.Name
				end
			end
			local pr = slot.claimPad:FindFirstChild("ClaimPrompt")
			if pr and pr:IsA("ProximityPrompt") then
				pr.Enabled = false
			end
		else
			slot.claimPad.Color = Color3.fromRGB(100, 255, 130)
			slot.claimPad.Transparency = 0
			local lab = slot.claimPad:FindFirstChild("PadLabel")
			if lab then
				local t = lab:FindFirstChildWhichIsA("TextLabel")
				if t then
					t.Text = "CLAIM " .. bname:upper() .. "\nPermanent — cannot change"
				end
			end
			local pr = slot.claimPad:FindFirstChild("ClaimPrompt")
			if pr and pr:IsA("ProximityPrompt") then
				pr.Enabled = true
			end
		end
	end
	if slot.deposit then
		local lab = slot.deposit:FindFirstChild("PadLabel")
		if lab then
			local t = lab:FindFirstChildWhichIsA("TextLabel")
			if t then
				t.Text = player and (player.Name .. "'s DEPOSIT") or "★ DEPOSIT ★"
			end
		end
	end
end

local function getPlayerSlot(player: Player)
	for _, s in world.bases do
		if s.owner == player then
			return s
		end
	end
	return nil
end

local function teleportToBase(player: Player, slot)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and slot then
		root.CFrame = CFrame.new(slot.spawn + Vector3.new(0, 3, 0))
	end
end

local function teleportToSpawn(player: Player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and world.spawnCF then
		root.CFrame = world.spawnCF
	end
end

--[[ Permanent claim of a specific free base. No switching. ]]
local function claimBase(player: Player, preferredIndex: number): (any, boolean, string)
	local profile = PlayerData.get(player)
	if profile.baseLocked and profile.baseIndex > 0 then
		local owned = getPlayerSlot(player)
		if owned then
			return owned, false, "You already own " .. (owned.name or ("Plot " .. owned.index)) .. " forever!"
		end
		-- rejoin session: re-attach to saved index
		for _, slot in world.bases do
			if slot.index == profile.baseIndex and (slot.owner == nil or slot.owner == player) then
				slot.owner = player
				updateBaseSign(slot, player)
				TycoonService.refreshButtons(player)
				return slot, true, "Welcome back to " .. (slot.name or "your base")
			end
		end
		return nil, false, "Your base is busy this session — try again later"
	end

	for _, slot in world.bases do
		if slot.index == preferredIndex then
			if slot.owner and slot.owner ~= player then
				return nil, false, (slot.name or "Base") .. " is already taken!"
			end
			slot.owner = player
			profile.baseIndex = slot.index
			profile.baseLocked = true
			updateBaseSign(slot, player)
			TycoonService.refreshButtons(player)
			return slot, true, "🏠 Claimed " .. (slot.name or ("Plot " .. slot.index)) .. " forever! Tycoon pads are outside."
		end
	end
	return nil, false, "Invalid base"
end

-- Free session ownership on leave, keep saved baseIndex/baseLocked
local function freeBase(player: Player)
	for _, slot in world.bases do
		if slot.owner == player then
			slot.owner = nil
			updateBaseSign(slot, nil)
		end
	end
end

local function onCharacter(player: Player, char: Model)
	local profile = PlayerData.get(player)
	local root = char:WaitForChild("HumanoidRootPart", 8) :: BasePart?

	-- Restore permanent base ownership if free
	if profile.baseLocked and profile.baseIndex > 0 then
		for _, slot in world.bases do
			if slot.index == profile.baseIndex and (slot.owner == nil or slot.owner == player) then
				slot.owner = player
				updateBaseSign(slot, player)
				break
			end
		end
	end

	local slot = getPlayerSlot(player)
	if root then
		if slot then
			root.CFrame = CFrame.new(slot.spawn + Vector3.new(0, 3, 0))
		elseif world.spawnCF then
			root.CFrame = world.spawnCF
		end
	end

	applyWalkSpeed(player)
	setTitleBillboard(player)
	PetService.refresh(player)
	if slot then
		TycoonService.refreshButtons(player)
	end
	pushState(player)

	local hum = char:WaitForChild("Humanoid", 8) :: Humanoid?
	if hum then
		hum.Died:Connect(function()
			local lost = PlayerData.carryValue(player)
			PlayerData.resetCarry(player)
			if lost > 0 then
				RE_Toast:FireClient(player, "💀 Dropped your empire stack! (-" .. Util.formatNumber(lost) .. ")", Color3.fromRGB(255, 90, 90))
				RE_FX:FireClient(player, "death")
			end
			pushState(player)
		end)
	end
end

local function setupPlayer(player: Player)
	PlayerData.get(player)
	DataService.bind(player) -- sync load: baseLocked / baseIndex ready
	-- NO auto-claim for new players — they start at spawn hub
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
	task.spawn(function()
		task.wait(0.5)
		MonetizationService.refreshPasses(player)
		-- Restore YZ65 tool if owned from save
		local p = PlayerData.get(player)
		if p.passes and p.passes.yz65 then
			VehicleService.giveCallTool(player)
		end
		pushState(player)
	end)
	task.delay(0.8, function()
		pushState(player)
		local profile = PlayerData.get(player)
		if profile.baseLocked and profile.baseIndex > 0 then
			-- Re-attach ownership if server reloaded while they were gone
			claimBase(player, profile.baseIndex)
			RE_Toast:FireClient(
				player,
				"Welcome back! Use ↩ MY BASE portal or walk to your estate.",
				Color3.fromRGB(120, 220, 255)
			)
		else
			RE_Toast:FireClient(
				player,
				"SPAWN HUB · claim Daily/Playtime chests · walk the green GATE · claim one free mega-base forever (names show from far away)!",
				Color3.fromRGB(255, 220, 100)
			)
			teleportToSpawn(player)
		end
	end)
end

local claimCd: { [Player]: number } = {}
local function tryClaim(player: Player, preferredIndex: number?)
	local now = os.clock()
	if (claimCd[player] or 0) > now then
		return
	end
	claimCd[player] = now + 1.25

	if not preferredIndex then
		RE_Toast:FireClient(
			player,
			"Walk through the GATE, then stand on a green CLAIM pad at a free mega-base (look for AVAILABLE names)!",
			Color3.fromRGB(180, 220, 255)
		)
		return
	end

	local slot, ok, msg = claimBase(player, preferredIndex)
	RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(100, 255, 140) or Color3.fromRGB(255, 160, 80))
	if ok and slot then
		teleportToBase(player, slot)
		RE_FX:FireClient(player, "deposit")
		pushState(player)
	elseif getPlayerSlot(player) then
		-- already owned — home teleport if they hit their pad
		local owned = getPlayerSlot(player)
		if owned and owned.index == preferredIndex then
			teleportToBase(player, owned)
		end
	end
end

if world.claimOffice then
	world.claimOffice.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if plr then
			tryClaim(plr, nil) -- info only
		end
	end)
end
if world.returnPad then
	world.returnPad.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if not plr then
			return
		end
		local slot = getPlayerSlot(plr)
		if slot then
			teleportToBase(plr, slot)
			RE_Toast:FireClient(plr, "↩ " .. (slot.name or "Your base"), Color3.fromRGB(120, 220, 255))
		else
			RE_Toast:FireClient(plr, "You need a base first — leave through the GATE and claim one!", Color3.fromRGB(255, 180, 80))
		end
	end)
end
for _, slot in world.bases do
	if slot.claimPad then
		slot.claimPad.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			local plr = model and Players:GetPlayerFromCharacter(model)
			if plr then
				tryClaim(plr, slot.index)
			end
		end)
	end
	if slot.claimPrompt and slot.claimPrompt:IsA("ProximityPrompt") then
		slot.claimPrompt.Triggered:Connect(function(plr)
			tryClaim(plr, slot.index)
		end)
	end
end

-- Chests
ChestService.setCallbacks(function(player, msg, color)
	RE_Toast:FireClient(player, msg, color)
end, pushState)
ChestService.start()
if world.dailyPrompt then
	world.dailyPrompt.Triggered:Connect(function(plr)
		local ok, msg = ChestService.claimDaily(plr)
		RE_Toast:FireClient(plr, msg, ok and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(255, 160, 80))
	end)
end
if world.playPrompt then
	world.playPrompt.Triggered:Connect(function(plr)
		local ok, msg = ChestService.claimPlaytime(plr)
		RE_Toast:FireClient(plr, msg, ok and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(255, 160, 80))
	end)
end

-- Init free base signs (far-visible AVAILABLE)
for _, slot in world.bases do
	updateBaseSign(slot, nil)
end

TycoonService.setCallbacks(
	function(player, msg, color)
		RE_Toast:FireClient(player, msg, color)
	end,
	pushState,
	applyWalkSpeed
)
TycoonService.wireButtons(world.bases)
TycoonService.startDroppers()

Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(setupPlayer, p)
end
Players.PlayerRemoving:Connect(function(player)
	DataService.save(player)
	freeBase(player)
end)

-- Pickup loop
local zoneLockToastAt: { [Player]: number } = {}
RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		local profile = PlayerData.get(player)
		if #profile.carry >= profile.capacity then
			continue
		end
		local ok, currencyId, meta, story = CollectibleService.tryPickupNear(
			player,
			profile.magnetBonus,
			profile.luckBonus,
			profile.cash,
			profile.rebirths,
			profile.maxStory or 1
		)
		if meta == "LOCKED_ZONE" then
			local now = os.clock()
			if (zoneLockToastAt[player] or 0) < now then
				zoneLockToastAt[player] = now + 3
				RE_Toast:FireClient(player, "🔒 Zone locked — earn more Cash!", Color3.fromRGB(255, 160, 80))
			end
		elseif meta == "LOCKED_STORY" then
			local now = os.clock()
			if (zoneLockToastAt[player] or 0) < now then
				zoneLockToastAt[player] = now + 2.5
				RE_Toast:FireClient(
					player,
					("🔒 Story %d loot locked — buy Story Gate %d on YOUR base tycoon pads"):format(story or 2, story or 2),
					Color3.fromRGB(255, 170, 90)
				)
			end
		elseif ok and currencyId then
			local now = os.clock()
			if now - profile.lastPickup <= Config.COMBO_WINDOW then
				profile.combo += 1
			else
				profile.combo = 1
			end
			profile.lastPickup = now
			table.insert(profile.carry, {
				uid = tostring(now) .. math.random(1, 9999),
				currencyId = currencyId,
				story = story or 1,
			})
			profile.totalPicked += 1
			profile.discovered = profile.discovered or {}
			profile.discovered[currencyId] = true
			local def = Config.CurrencyById[currencyId]
			local name = def and (def.emoji .. " " .. def.name) or currencyId
			local comboTxt = profile.combo > 1 and ("  COMBO x" .. profile.combo) or ""
			local sm = (Config.StoryCashMulti and Config.StoryCashMulti[story or 1]) or 1
			local storyTxt = story and (" · S" .. story .. " x" .. string.format("%.1f", sm)) or ""
			RE_Toast:FireClient(
				player,
				name .. storyTxt .. "  (" .. #profile.carry .. "/" .. profile.capacity .. ")" .. comboTxt,
				def and def.color or Color3.new(1, 1, 1)
			)
			RE_FX:FireClient(player, "pickup", def and def.color)
			if def and (def.rarity == "Mythic" or def.rarity == "Secret") then
				RE_Announce:FireAllClients("💎 " .. player.Name .. " found " .. def.name .. "!", def.color)
			end
			applyWalkSpeed(player)
			pushState(player)
			if #profile.carry >= profile.capacity then
				RE_Toast:FireClient(player, "📦 STACK FULL — haul to MAIN BANK!", Color3.fromRGB(255, 190, 60))
			end
		end
	end
end)

local function tryDeposit(player: Player, skipRange: boolean?): (boolean, string)
	local profile = PlayerData.get(player)
	if #profile.carry == 0 then
		return false, "Nothing to deposit — grab loot first!"
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, "No character"
	end
	if not skipRange and not nearAnyDeposit(root) then
		return false, "Stand on GREEN bank / vault"
	end

	local raw = 0
	for _, item in profile.carry do
		local def = Config.CurrencyById[item.currencyId]
		if def then
			local sm = (Config.StoryCashMulti and Config.StoryCashMulti[item.story or 1]) or 1
			raw += def.value * sm
			profile.bank[item.currencyId] = (profile.bank[item.currencyId] or 0) + 1
		end
	end

	local multi = PlayerData.cashMulti(player)
	local comboBonus = math.min(profile.combo * Config.COMBO_BONUS_PER, Config.COMBO_BONUS_CAP)
	local eventMulti = 1
	local ev = EventService.get()
	if ev and ev.multi then
		eventMulti = ev.multi
	end
	local gained = math.floor(raw * multi * (1 + comboBonus) * eventMulti)
	profile.cash += gained
	profile.totalDeposited += gained
	local n = #profile.carry
	local height = n * Config.STACK_HEIGHT_PER_ITEM
	local combo = profile.combo
	profile.carry = {}
	profile.combo = 0
	applyWalkSpeed(player)
	pushState(player)
	RE_FX:FireClient(player, "deposit")

	local msg = string.format(
		"🏦 +%s Cash (%d items · x%.2f multi · combo %d · ~%dst)",
		Util.formatNumber(gained),
		n,
		multi * (1 + comboBonus) * eventMulti,
		combo,
		math.floor(height)
	)
	return true, msg
end

local function doDeposit(player: Player, skip: boolean?)
	local ok, msg = tryDeposit(player, skip)
	RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 160, 80))
	return ok, msg, PlayerData.summary(player)
end

RF_Deposit.OnServerInvoke = function(player)
	return doDeposit(player, false)
end

for _, depositPart in world.allDepositParts do
	local prompt = depositPart:FindFirstChild("DepositPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(who)
			doDeposit(who, true)
		end)
	end
	depositPart.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if plr and #PlayerData.get(plr).carry > 0 then
			doDeposit(plr, true)
		end
	end)
end

if world.rebirthPrompt then
	world.rebirthPrompt.Triggered:Connect(function(player)
		local ok, msg = ShopService.rebirth(player)
		RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(220, 140, 255) or Color3.fromRGB(255, 140, 100))
		if ok then
			RE_Announce:FireAllClients("♻️ " .. player.Name .. " REBIRTHED!", Color3.fromRGB(200, 120, 255))
			RE_FX:FireClient(player, "rebirth")
			PetService.refresh(player)
			setTitleBillboard(player)
		end
		pushState(player)
	end)
end

RF_Buy.OnServerInvoke = function(player, itemId: string)
	local ok, msg = ShopService.buy(player, itemId)
	RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 120, 120))
	if ok then
		PetService.refresh(player)
		setTitleBillboard(player)
		applyWalkSpeed(player)
	end
	pushState(player)
	return ok, msg, PlayerData.summary(player)
end

RF_Rebirth.OnServerInvoke = function(player)
	local ok, msg = ShopService.rebirth(player)
	RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(220, 140, 255) or Color3.fromRGB(255, 140, 100))
	if ok then
		RE_Announce:FireAllClients("♻️ " .. player.Name .. " REBIRTHED!", Color3.fromRGB(200, 120, 255))
		PetService.refresh(player)
	end
	pushState(player)
	return ok, msg, PlayerData.summary(player)
end

RF_Fuse.OnServerInvoke = function(player, fusionId: string)
	local ok, msg = ShopService.fuse(player, fusionId)
	RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(255, 140, 100))
	pushState(player)
	return ok, msg, PlayerData.summary(player)
end

RF_EquipPet.OnServerInvoke = function(player, petId: string)
	local ok, msg = ShopService.equipPet(player, petId)
	RE_Toast:FireClient(player, msg, ok and Color3.fromRGB(160, 255, 180) or Color3.fromRGB(255, 140, 100))
	if ok then
		PetService.refresh(player)
	end
	pushState(player)
	return ok, msg, PlayerData.summary(player)
end

RF_GetState.OnServerInvoke = function(player)
	return PlayerData.summary(player)
end

-- Shop / fusion / index proximity (pads are far apart)
local shopCd: { [Player]: number } = {}
local fusCd: { [Player]: number } = {}
local idxCd: { [Player]: number } = {}
task.spawn(function()
	while true do
		task.wait(0.4)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				if flatDist(root.Position, world.shopPad.Position) < 12 then
					if (shopCd[player] or 0) < now then
						shopCd[player] = now + 5
						RE_OpenShop:FireClient(player, Config.Shop, PlayerData.summary(player), Config.Fusions)
					end
				end
				if world.fusionPad and flatDist(root.Position, world.fusionPad.Position) < 12 then
					if (fusCd[player] or 0) < now then
						fusCd[player] = now + 5
						RE_OpenFusion:FireClient(player, Config.Fusions, PlayerData.summary(player))
					end
				end
				if world.indexPad and flatDist(root.Position, world.indexPad.Position) < 12 then
					if (idxCd[player] or 0) < now then
						idxCd[player] = now + 4
						RE_OpenIndex:FireClient(player, PlayerData.summary(player))
					end
				end
				if world.robuxPad and flatDist(root.Position, world.robuxPad.Position) < 14 then
					if (idxCd[player] or 0) < now then
						idxCd[player] = now + 3
						local summary = PlayerData.summary(player)
						RE_State:FireClient(player, summary)
						RE_OpenRobux:FireClient(player, summary)
						RE_Toast:FireClient(
							player,
							Config.FREE_ROBUX_TEST and "💎 ROBUX STORE — everything FREE in test" or "💎 ROBUX STORE",
							Color3.fromRGB(100, 255, 140)
						)
					end
				end
				if #PlayerData.get(player).carry > 0 and nearAnyDeposit(root) then
					doDeposit(player, true)
				end
			end
		end
	end
end)

print("[CashEmpire] LIVE — " .. Config.TAGLINE)
