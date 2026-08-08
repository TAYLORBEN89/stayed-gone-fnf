local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)

export type CarryItem = { uid: string, currencyId: string, story: number? }

export type Profile = {
	cash: number,
	bank: { [string]: number },
	capacity: number,
	speedBonus: number,
	magnetBonus: number,
	luckBonus: number,
	trail: number, -- 0 none, 1 gold, 2 neon
	title: string,
	owned: { [string]: boolean },
	pets: { [string]: boolean },
	activePet: string?,
	carry: { CarryItem },
	baseIndex: number,
	rebirths: number,
	combo: number,
	lastPickup: number,
	totalDeposited: number,
	totalPicked: number,
	statsLoaded: boolean,
	-- Robux gamepass flags (synced from MarketplaceService)
	passes: { [string]: boolean },
	passApplied: { [string]: boolean }, -- one-time grant tracking
	tycoonBought: { [string]: boolean },
	maxStory: number,
	dropperRate: number,
	tycoonWalls: boolean,
	discovered: { [string]: boolean },
	baseLocked: boolean, -- permanent base claim
	lastDailyClaim: string, -- "YYYY-MM-DD"
	playtimeSeconds: number,
	playtimePoints: number,
	lastPlaytimeClaimAt: number, -- os.time when last playtime chest claimed
	concertTicket: string?, -- nil | "ga" | "vip" (Red Rocks)
}

local PlayerData = {}
PlayerData._profiles = {} :: { [Player]: Profile }

function PlayerData.blank(): Profile
	return {
		cash = 0,
		bank = {},
		capacity = Config.START_CAPACITY,
		speedBonus = 0,
		magnetBonus = 0,
		luckBonus = 0,
		trail = 0,
		title = "",
		owned = {},
		pets = {},
		activePet = nil,
		carry = {},
		baseIndex = 0,
		rebirths = 0,
		combo = 0,
		lastPickup = 0,
		totalDeposited = 0,
		totalPicked = 0,
		statsLoaded = false,
		passes = {},
		passApplied = {},
		tycoonBought = {},
		maxStory = 1,
		dropperRate = 0,
		tycoonWalls = false,
		discovered = {},
		baseLocked = false,
		lastDailyClaim = "",
		playtimeSeconds = 0,
		playtimePoints = 0,
		lastPlaytimeClaimAt = 0,
		concertTicket = nil,
	}
end

function PlayerData.get(player: Player): Profile
	local p = PlayerData._profiles[player]
	if not p then
		p = PlayerData.blank()
		PlayerData._profiles[player] = p
	end
	return p
end

function PlayerData.set(player: Player, profile: Profile)
	PlayerData._profiles[player] = profile
end

function PlayerData.cashMulti(player: Player): number
	local p = PlayerData.get(player)
	local multi = 1 + p.rebirths * Config.REBIRTH_MULTI_PER
	if p.activePet and Config.PetById[p.activePet] then
		multi += Config.PetById[p.activePet].multi
	end
	if p.passes.vip then
		multi += 0.25
	end
	if p.passes.x2cash then
		multi *= 2
	end
	return multi
end

function PlayerData.rebirthCost(player: Player): number
	local p = PlayerData.get(player)
	return math.floor(Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_MULT ^ p.rebirths))
end

function PlayerData.carryValue(player: Player): number
	local total = 0
	for _, item in PlayerData.get(player).carry do
		local def = Config.CurrencyById[item.currencyId]
		if def then
			local sm = (Config.StoryCashMulti and Config.StoryCashMulti[item.story or 1]) or 1
			total += def.value * sm
		end
	end
	return total
end

function PlayerData.summary(player: Player)
	local p = PlayerData.get(player)
	local multi = PlayerData.cashMulti(player)
	local comboBonus = math.min(p.combo * Config.COMBO_BONUS_PER, Config.COMBO_BONUS_CAP)
	return {
		cash = p.cash,
		capacity = p.capacity,
		carryCount = #p.carry,
		carryValue = PlayerData.carryValue(player),
		speedBonus = p.speedBonus,
		magnetBonus = p.magnetBonus,
		luckBonus = p.luckBonus,
		trail = p.trail,
		title = p.title,
		owned = p.owned,
		pets = p.pets,
		activePet = p.activePet,
		bank = p.bank,
		stackHeight = #p.carry * Config.STACK_HEIGHT_PER_ITEM,
		rebirths = p.rebirths,
		rebirthCost = PlayerData.rebirthCost(player),
		multi = multi,
		combo = p.combo,
		comboBonus = comboBonus,
		totalDeposited = p.totalDeposited,
		version = Config.VERSION,
		gameName = Config.GAME_NAME,
		passes = p.passes,
		monetization = Config.Monetization,
		tycoonBought = p.tycoonBought,
		maxStory = p.maxStory or 1,
		dropperRate = p.dropperRate or 0,
		discovered = p.discovered,
		coinIndex = Config.Currencies,
		storyLabels = Config.StoryLabels,
		baseIndex = p.baseIndex or 0,
		baseLocked = p.baseLocked == true,
		playtimePoints = p.playtimePoints or 0,
		playtimeSeconds = p.playtimeSeconds or 0,
		lastDailyClaim = p.lastDailyClaim or "",
		concertTicket = p.concertTicket,
	}
end

function PlayerData.resetCarry(player: Player)
	PlayerData.get(player).carry = {}
	PlayerData.get(player).combo = 0
end

function PlayerData.serialize(player: Player): { [string]: any }
	local p = PlayerData.get(player)
	return {
		cash = p.cash,
		bank = p.bank,
		capacity = p.capacity,
		speedBonus = p.speedBonus,
		magnetBonus = p.magnetBonus,
		luckBonus = p.luckBonus,
		trail = p.trail,
		title = p.title,
		owned = p.owned,
		pets = p.pets,
		activePet = p.activePet,
		rebirths = p.rebirths,
		totalDeposited = p.totalDeposited,
		totalPicked = p.totalPicked,
		passApplied = p.passApplied,
		tycoonBought = p.tycoonBought,
		maxStory = p.maxStory,
		dropperRate = p.dropperRate,
		tycoonWalls = p.tycoonWalls,
		discovered = p.discovered,
		baseIndex = p.baseIndex,
		baseLocked = p.baseLocked,
		lastDailyClaim = p.lastDailyClaim,
		playtimeSeconds = p.playtimeSeconds,
		playtimePoints = p.playtimePoints,
		lastPlaytimeClaimAt = p.lastPlaytimeClaimAt,
		concertTicket = p.concertTicket,
	}
end

function PlayerData.applySave(player: Player, data: any)
	if type(data) ~= "table" then
		return
	end
	local p = PlayerData.get(player)
	p.cash = data.cash or 0
	p.bank = data.bank or {}
	p.capacity = data.capacity or Config.START_CAPACITY
	p.speedBonus = data.speedBonus or 0
	p.magnetBonus = data.magnetBonus or 0
	p.luckBonus = data.luckBonus or 0
	p.trail = data.trail or 0
	p.title = data.title or ""
	p.owned = data.owned or {}
	p.pets = data.pets or {}
	p.activePet = data.activePet
	p.rebirths = data.rebirths or 0
	p.totalDeposited = data.totalDeposited or 0
	p.totalPicked = data.totalPicked or 0
	p.passApplied = data.passApplied or {}
	p.tycoonBought = data.tycoonBought or {}
	p.maxStory = data.maxStory or 1
	p.dropperRate = data.dropperRate or 0
	p.tycoonWalls = data.tycoonWalls or false
	p.discovered = data.discovered or {}
	p.baseIndex = data.baseIndex or 0
	p.baseLocked = data.baseLocked == true or (data.baseIndex or 0) > 0
	p.lastDailyClaim = data.lastDailyClaim or ""
	p.playtimeSeconds = data.playtimeSeconds or 0
	p.playtimePoints = data.playtimePoints or 0
	p.lastPlaytimeClaimAt = data.lastPlaytimeClaimAt or 0
	p.concertTicket = data.concertTicket
	p.statsLoaded = true
end

function PlayerData.updateLeaderstats(player: Player)
	local p = PlayerData.get(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
		local cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Parent = ls
		local reb = Instance.new("IntValue")
		reb.Name = "Rebirths"
		reb.Parent = ls
		local multi = Instance.new("NumberValue")
		multi.Name = "Multi"
		multi.Parent = ls
	end
	local cash = ls:FindFirstChild("Cash") :: IntValue?
	local reb = ls:FindFirstChild("Rebirths") :: IntValue?
	local multi = ls:FindFirstChild("Multi") :: NumberValue?
	if cash then
		cash.Value = math.floor(p.cash)
	end
	if reb then
		reb.Value = p.rebirths
	end
	if multi then
		multi.Value = math.floor(PlayerData.cashMulti(player) * 100) / 100
	end
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData._profiles[player] = nil
end)

return PlayerData
