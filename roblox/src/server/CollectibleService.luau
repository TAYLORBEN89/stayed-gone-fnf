local CollectionService = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Util = require(game.ReplicatedStorage.Shared.Util)
local PropFactory = require(game.ReplicatedStorage.Shared.PropFactory)

local CollectibleService = {}
CollectibleService._lootFolder = nil :: Folder?
CollectibleService._floorSpawns = {} :: { { story: number, pos: Vector3 } }
CollectibleService._groundSpawns = {} :: { Vector3 }
CollectibleService._uid = 0
CollectibleService._event = nil :: any
CollectibleService._started = false

local TAG = "CashCollectible"

local function nextUid(): string
	CollectibleService._uid += 1
	return "c" .. tostring(CollectibleService._uid)
end

function CollectibleService.setEvent(ev)
	CollectibleService._event = ev
end

function CollectibleService.zoneUnlocked(zoneId: string, cash: number, rebirths: number): boolean
	for _, z in Config.Zones do
		if z.id == zoneId then
			local needCash = z.unlockCash or 0
			local needReb = z.unlockRebirth or 0
			if needReb > 0 then
				return cash >= needCash or rebirths >= needReb
			end
			return cash >= needCash
		end
	end
	return true
end

local function rarityRank(r: string): number
	return Config.RarityOrder[r] or 1
end

local function pickCurrencyForStory(story: number, zoneHint: string?, luckBonus: number)
	local maxRank = Config.StoryMaxRarity[story] or 1
	local pool = {}
	for _, c in Config.Currencies do
		if c.weight and c.weight > 0 then
			local minS = c.minStory or 1
			local rank = rarityRank(c.rarity)
			if minS <= story and rank <= maxRank then
				local w = c.weight or 1
				if zoneHint and c.zone == zoneHint then
					w *= 1.4
				end
				if rank >= story then
					w *= 1.3
				end
				table.insert(pool, {
					id = c.id,
					name = c.name,
					rarity = c.rarity,
					value = c.value,
					color = c.color,
					weight = w,
					zone = c.zone,
					minStory = minS,
					emoji = c.emoji,
				})
			end
		end
	end
	if #pool == 0 then
		for _, c in Config.Currencies do
			if (c.minStory or 1) <= 1 and rarityRank(c.rarity) <= 1 and (c.weight or 0) > 0 then
				table.insert(pool, c)
			end
		end
	end
	if #pool == 0 then
		return Config.Currencies[1]
	end

	local ev = CollectibleService._event
	local function scale(item)
		local w = 1
		if luckBonus > 0 and rarityRank(item.rarity) >= 3 then
			w += luckBonus * rarityRank(item.rarity)
		end
		if ev and ev.mythicBoost and (item.rarity == "Mythic" or item.rarity == "Secret") then
			w *= ev.mythicBoost
		end
		return w
	end
	return Util.weightedChoice(pool, "weight", scale)
end

local function simplePickup(currencyId: string, color: Color3, scale: number): BasePart
	local p = Instance.new("Part")
	p.Name = currencyId
	p.Anchored = true
	p.CanCollide = false
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.2, 2.2, 2.2) * scale
	p.Material = Enum.Material.Neon
	p.Color = color
	p.CastShadow = false
	return p
end

function CollectibleService.spawnAt(lootFolder: Folder, pos: Vector3, story: number, zoneId: string?)
	local def = pickCurrencyForStory(story, zoneId, 0)
	if not def then
		return nil
	end

	local rarity = def.rarity or "Common"
	local scale = 1.0 + math.min(story, 6) * 0.12
	if rarity == "Secret" then
		scale = 1.6
	end

	local cashMulti = (Config.StoryCashMulti and Config.StoryCashMulti[story]) or 1
	local value = math.floor((def.value or 1) * cashMulti)
	local color = def.color or Color3.fromRGB(255, 220, 80)
	local currencyId = def.id or "penny"

	local p: BasePart?
	local ok = pcall(function()
		p = PropFactory.createPickup(currencyId, color, scale)
	end)
	if not ok or not p then
		p = simplePickup(currencyId, color, scale)
	end

	p.Name = currencyId
	p.Anchored = true
	p.CanCollide = false
	-- Lift above ground / floors so nothing buries the pickup
	local y = math.max(pos.Y, 3)
	local finalPos = Vector3.new(pos.X, y, pos.Z)
	p.Position = finalPos
	p.Parent = lootFolder
	p:SetAttribute("CurrencyId", currencyId)
	p:SetAttribute("Uid", nextUid())
	p:SetAttribute("Value", value)
	p:SetAttribute("Rarity", rarity)
	p:SetAttribute("ZoneId", zoneId or "suburbs")
	p:SetAttribute("Story", story)

	local light = Instance.new("PointLight")
	light.Brightness = 1.4 + story * 0.15
	light.Range = 12 + story * 2
	light.Color = color
	light.Parent = p

	local billH = math.max(p.Size.X, p.Size.Y, p.Size.Z) * 0.55 + 1.4
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 42)
	gui.StudsOffset = Vector3.new(0, billH, 0)
	gui.AlwaysOnTop = story <= 1 -- ground loot easy to spot
	gui.MaxDistance = if story <= 1 then 90 else 40
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.35
	t.Text = (def.emoji or "🪙") .. " " .. (def.name or currencyId)
	t.Parent = gui

	local basePos = finalPos
	local isCoin = p:IsA("Part") and p.Shape == Enum.PartType.Cylinder
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent do
			local bob = math.sin((os.clock() - t0) * 3) * 0.35
			local spin = (os.clock() - t0) * 2
			if isCoin then
				p.CFrame = CFrame.new(basePos + Vector3.new(0, bob, 0)) * CFrame.Angles(0, spin, math.rad(90))
			else
				p.CFrame = CFrame.new(basePos + Vector3.new(0, bob, 0)) * CFrame.Angles(0, spin, 0)
			end
			task.wait(0.04)
		end
	end)

	CollectionService:AddTag(p, TAG)
	return p
end

local function groundY(): number
	return 4.5
end

--[[ Random ground position on the big map (avoids deep water/hub walls roughly) ]]
local function randomGroundPos(): Vector3
	local grounds = CollectibleService._groundSpawns
	if #grounds > 0 and math.random() < 0.55 then
		local g = grounds[math.random(1, #grounds)]
		return g + Vector3.new((math.random() - 0.5) * 10, 0, (math.random() - 0.5) * 10)
	end

	local hub = Config.SPAWN_HUB
	local half = Config.MAP_HALF or 560
	local roll = math.random()

	if roll < 0.28 then
		-- Near spawn hub / gate exit (starter loot players can actually see)
		local ang = math.random() * math.pi * 2
		local r = 25 + math.random() * 140
		return Vector3.new(hub.X + math.cos(ang) * r, groundY(), hub.Z + math.sin(ang) * r)
	elseif roll < 0.48 then
		-- Corridor from hub toward map center
		local t = math.random()
		local x = hub.X + (0 - hub.X) * t + (math.random() - 0.5) * 80
		local z = hub.Z + (0 - hub.Z) * t + (math.random() - 0.5) * 80
		return Vector3.new(x, groundY(), z)
	elseif roll < 0.72 then
		-- Map center suburbs
		local ang = math.random() * math.pi * 2
		local r = 40 + math.random() * 280
		return Vector3.new(math.cos(ang) * r, groundY(), math.sin(ang) * r)
	else
		-- Outer ring between bases
		local ang = math.random() * math.pi * 2
		local r = half * 0.35 + math.random() * half * 0.5
		return Vector3.new(math.cos(ang) * r, groundY(), math.sin(ang) * r)
	end
end

local function zoneForPos(pos: Vector3): string
	local bestId = "suburbs"
	local bestD = math.huge
	for _, z in Config.Zones do
		if z.id ~= "hub" then
			local c = z.center
			local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude
			if d < (z.radius or 100) and d < bestD then
				bestD = d
				bestId = z.id
			end
		end
	end
	return bestId
end

function CollectibleService.spawnOne(lootFolder: Folder)
	local floors = CollectibleService._floorSpawns
	local roll = math.random()

	-- Majority on the open ground so the world feels full
	if roll < 0.62 or #floors == 0 then
		local pos = randomGroundPos()
		return CollectibleService.spawnAt(lootFolder, pos, 1, zoneForPos(pos))
	end

	-- Prefer lower floors so more loot is actually pickable early
	local tries = 0
	local slot = floors[math.random(1, #floors)]
	while tries < 6 and slot.story and slot.story > 2 and math.random() < 0.65 do
		slot = floors[math.random(1, #floors)]
		tries += 1
	end
	local pos = slot.pos + Vector3.new((math.random() - 0.5) * 6, 0.5, (math.random() - 0.5) * 6)
	return CollectibleService.spawnAt(lootFolder, pos, slot.story or 1, "suburbs")
end

function CollectibleService.count(): number
	local folder = CollectibleService._lootFolder
	if not folder then
		return 0
	end
	return #folder:GetChildren()
end

function CollectibleService.start(lootFolder: Folder, floorSpawns: { any }?, groundSpawns: { Vector3 }?)
	CollectibleService._lootFolder = lootFolder
	CollectibleService._floorSpawns = floorSpawns or {}
	CollectibleService._groundSpawns = groundSpawns or {}
	CollectibleService._started = true

	local maxN = Config.MAX_WORLD_COLLECTIBLES or 320
	print(
		("[CashEmpire] Spawning collectibles · floors=%d groundPts=%d target=%d"):format(
			#CollectibleService._floorSpawns,
			#CollectibleService._groundSpawns,
			maxN
		)
	)

	-- Batch spawn so Studio doesn't hitch as hard
	task.spawn(function()
		local n = 0
		while n < maxN do
			local batch = math.min(25, maxN - n)
			for _ = 1, batch do
				local ok, err = pcall(function()
					CollectibleService.spawnOne(lootFolder)
				end)
				if not ok then
					warn("[CashEmpire] spawnOne failed:", err)
				end
				n += 1
			end
			task.wait()
		end
		print(("[CashEmpire] Collectibles ready: %d"):format(CollectibleService.count()))
	end)

	task.spawn(function()
		while true do
			task.wait(0.55)
			if not lootFolder.Parent then
				break
			end
			local cur = #lootFolder:GetChildren()
			if cur < maxN then
				local need = math.min(8, maxN - cur)
				for _ = 1, need do
					pcall(function()
						CollectibleService.spawnOne(lootFolder)
					end)
				end
			end
		end
	end)
end

function CollectibleService.tryPickupNear(
	player: Player,
	magnetBonus: number,
	_luckBonus: number,
	cash: number,
	rebirths: number,
	maxStory: number
): (boolean, string?, string?, number?)
	local char = player.Character
	if not char then
		return false, nil, nil, nil
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, nil, nil, nil
	end
	local range = Config.PICKUP_RANGE + magnetBonus
	local best: BasePart? = nil
	local bestDist = range

	for _, inst in CollectionService:GetTagged(TAG) do
		if inst:IsA("BasePart") and inst.Parent then
			local d = (inst.Position - root.Position).Magnitude
			if d <= bestDist then
				bestDist = d
				best = inst
			end
		end
	end
	if not best then
		return false, nil, nil, nil
	end

	local story = (best:GetAttribute("Story") :: number?) or 1

	if story > (maxStory or 1) then
		return false, nil, "LOCKED_STORY", story
	end

	local zoneId = (best:GetAttribute("ZoneId") :: string?) or "suburbs"
	if not CollectibleService.zoneUnlocked(zoneId, cash, rebirths) then
		return false, nil, "LOCKED_ZONE", story
	end

	local currencyId = best:GetAttribute("CurrencyId") :: string
	local rarity = best:GetAttribute("Rarity") :: string?
	best:Destroy()
	return true, currencyId, rarity, story
end

function CollectibleService.canAccessStory(playerMaxStory: number, playerCash: number, story: number): (boolean, string)
	if story <= 1 then
		return true, ""
	end
	local req = Config.StoryAccess and Config.StoryAccess[story]
	if not req then
		return playerMaxStory >= story, "Need Story Gate " .. story
	end
	if playerMaxStory >= (req.maxStory or story) then
		return true, ""
	end
	return false, ("🔒 Floor %d locked — buy Story Gate %d on YOUR tycoon pads"):format(story, story)
end

return CollectibleService
