local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local ShopService = {}

local function canAfford(profile, item): (boolean, string)
	if profile.cash < (item.costCash or 0) then
		return false, "Need " .. (item.costCash or 0) .. " Cash"
	end
	if item.costCurrency then
		for currencyId, need in item.costCurrency do
			local have = profile.bank[currencyId] or 0
			if have < need then
				local name = Config.CurrencyById[currencyId] and Config.CurrencyById[currencyId].name or currencyId
				return false, "Need " .. need .. "x " .. name .. " (banked)"
			end
		end
	end
	return true, ""
end

local function charge(profile, item)
	profile.cash -= item.costCash or 0
	if item.costCurrency then
		for currencyId, need in item.costCurrency do
			profile.bank[currencyId] = (profile.bank[currencyId] or 0) - need
		end
	end
end

function ShopService.buy(player: Player, itemId: string): (boolean, string)
	local item
	for _, s in Config.Shop do
		if s.id == itemId then
			item = s
			break
		end
	end
	if not item then
		return false, "Unknown item"
	end

	local profile = PlayerData.get(player)

	if item.kind == "pet" then
		local petId = item.petId
		if profile.pets[petId] then
			return false, "You already own this pet"
		end
		local ok, reason = canAfford(profile, item)
		if not ok then
			return false, reason
		end
		charge(profile, item)
		profile.pets[petId] = true
		profile.activePet = petId
		profile.owned[item.id] = true
		return true, "Pet unlocked: " .. (Config.PetById[petId] and Config.PetById[petId].name or petId)
	end

	if (item.kind == "trail" or item.kind == "title") and profile.owned[item.id] then
		return false, "Already owned"
	end

	if item.kind == "ticket" then
		local tier = item.ticketTier or "ga"
		if profile.concertTicket == "vip" then
			return false, "You already have VIP — enjoy the show at Red Rocks!"
		end
		if profile.concertTicket == tier then
			return false, "You already have a " .. string.upper(tier) .. " ticket"
		end
		local ok, reason = canAfford(profile, item)
		if not ok then
			return false, reason
		end
		charge(profile, item)
		profile.concertTicket = tier
		profile.owned[item.id] = true
		if tier == "vip" and item.titleText then
			profile.title = item.titleText
		end
		PlayerData.updateLeaderstats(player)
		return true, "🎟️ " .. item.name .. " purchased! Head to the Red Rocks gate."
	end

	local ok, reason = canAfford(profile, item)
	if not ok then
		return false, reason
	end
	charge(profile, item)

	if item.kind == "capacity" then
		profile.capacity += item.amount or 0
	elseif item.kind == "speed" then
		profile.speedBonus += item.amount or 0
	elseif item.kind == "magnet" then
		profile.magnetBonus += item.amount or 0
	elseif item.kind == "luck" then
		profile.luckBonus += item.amount or 0
	elseif item.kind == "trail" then
		profile.trail = item.amount or 1
		profile.owned[item.id] = true
	elseif item.kind == "title" then
		profile.title = item.titleText or "TYCOON"
		profile.owned[item.id] = true
	end

	PlayerData.updateLeaderstats(player)
	return true, "Purchased " .. item.name .. "!"
end

function ShopService.equipPet(player: Player, petId: string): (boolean, string)
	local profile = PlayerData.get(player)
	if petId == "" or petId == nil then
		profile.activePet = nil
		return true, "Pet unequipped"
	end
	if not profile.pets[petId] then
		return false, "You don't own that pet"
	end
	profile.activePet = petId
	return true, "Equipped " .. (Config.PetById[petId] and Config.PetById[petId].name or petId)
end

function ShopService.fuse(player: Player, fusionId: string): (boolean, string)
	local recipe
	for _, f in Config.Fusions do
		if f.id == fusionId then
			recipe = f
			break
		end
	end
	if not recipe then
		return false, "Unknown fusion"
	end
	local profile = PlayerData.get(player)
	for id, need in recipe.inputs do
		if (profile.bank[id] or 0) < need then
			local name = Config.CurrencyById[id] and Config.CurrencyById[id].name or id
			return false, "Need " .. need .. "x " .. name
		end
	end
	for id, need in recipe.inputs do
		profile.bank[id] = (profile.bank[id] or 0) - need
	end
	profile.bank[recipe.output] = (profile.bank[recipe.output] or 0) + 1
	local outName = Config.CurrencyById[recipe.output] and Config.CurrencyById[recipe.output].name or recipe.output
	return true, "Fused → " .. outName .. "!"
end

function ShopService.rebirth(player: Player): (boolean, string)
	local profile = PlayerData.get(player)
	local cost = PlayerData.rebirthCost(player)
	if profile.cash < cost then
		return false, "Need " .. cost .. " Cash to rebirth"
	end
	if #profile.carry > 0 then
		return false, "Deposit your stack first"
	end
	profile.cash = 0
	-- keep banked rares & pets & upgrades partial — full wipe cash only, keep progress items
	profile.rebirths += 1
	profile.capacity += Config.REBIRTH_CAPACITY_PER
	PlayerData.updateLeaderstats(player)
	return true, "REBIRTH x" .. profile.rebirths .. "! Multi now x" .. string.format("%.2f", PlayerData.cashMulti(player))
end

return ShopService
