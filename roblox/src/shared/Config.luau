--[[
	CASH EMPIRE — balance & catalogs
	Identity: stack absurd wealth, flex rarer currencies, rebirth into a tycoon god.
]]

local Config = {}

Config.GAME_NAME = "Cash Empire"
Config.TAGLINE = "Stack it to the sky. Bank it. Flex rarer."
Config.VERSION = "4.3.0"
-- While true: all Robux shop items grant instantly (no charge) for Studio/testing
Config.FREE_ROBUX_TEST = true

-- Billboard / label visibility (studs)
Config.LABEL_DISTANCE_PAD = 50 -- hub buildings / pads when near
Config.LABEL_DISTANCE_COIN = 28
Config.LABEL_DISTANCE_BUILDING = 55
Config.LABEL_DISTANCE_OPEN_BASE = 1400 -- free bases visible across the bigger map
Config.LABEL_DISTANCE_OWNED_BASE = 100 -- owned name only when closer

-- Map / spawn hub (far SW corner) — large map so mega-bases stay far apart
Config.MAP_HALF = 980
Config.SPAWN_HUB = Vector3.new(-860, 4, -860)
Config.SAFE_HUB_RADIUS = 80 -- around spawn compound only
-- Minimum spacing between base centers (studs)
Config.BASE_MIN_SEPARATION = 420

-- Chests
Config.DAILY_CHEST_CASH = 500
Config.PLAYTIME_CHEST_SECONDS = 300 -- 5 min play → can open
Config.PLAYTIME_CHEST_CASH = 150
Config.PLAYTIME_POINTS_PER_TICK = 1 -- +1 point per minute online

-- ── Part-tycoon + multi-story ─────────────────────────────────
Config.STORY_HEIGHT = 20
Config.MAX_STORIES = 6
-- Rarity rank allowed on each story (1 = ground)
Config.StoryMaxRarity = {
	[1] = 1, -- Common
	[2] = 2, -- Uncommon
	[3] = 3, -- Rare
	[4] = 5, -- Legendary
	[5] = 6, -- Mythic
	[6] = 7, -- Secret
}
-- Cash value multi for loot found on that story
Config.StoryCashMulti = {
	[1] = 1.0,
	[2] = 1.6,
	[3] = 2.4,
	[4] = 3.8,
	[5] = 6.0,
	[6] = 10.0,
}
Config.StoryLabels = {
	[1] = "Story 1 · Common courtyard",
	[2] = "Story 2 · Uncommon rooms",
	[3] = "Story 3 · Rare bridges",
	[4] = "Story 4 · Epic–Legendary",
	[5] = "Story 5 · Mythic loft",
	[6] = "Story 6 · Secret roof",
}
-- Visitor / elevator unlock (need maxStory from tycoon OR cash)
Config.StoryAccess = {
	[1] = { maxStory = 1, cash = 0 },
	[2] = { maxStory = 2, cash = 250 },
	[3] = { maxStory = 3, cash = 900 },
	[4] = { maxStory = 4, cash = 2500 },
	[5] = { maxStory = 5, cash = 8000 },
	[6] = { maxStory = 6, cash = 20000 },
}

-- Sequential tycoon buy-pads on your plot (classic part-tycoon)
Config.TycoonButtons = {
	{ id = "dropper1", name = "Coin Dropper I", cost = 40, kind = "dropper", rate = 3, desc = "Drops pennies at your base" },
	{ id = "walls", name = "Base Walls", cost = 80, kind = "build", desc = "Walls around your plot" },
	{ id = "dropper2", name = "Coin Dropper II", cost = 150, kind = "dropper", rate = 8, desc = "Faster cash drip" },
	{ id = "capacity", name = "Tycoon Pockets +20", cost = 200, kind = "capacity", amount = 20, desc = "Carry more loot" },
	{ id = "floor2", name = "Unlock Story Gate II", cost = 350, kind = "story", story = 2, desc = "Access floor 2 on any base" },
	{ id = "magnet", name = "Tycoon Magnet +4", cost = 450, kind = "magnet", amount = 4, desc = "Bigger pickup radius" },
	{ id = "dropper3", name = "Gold Dropper", cost = 800, kind = "dropper", rate = 20, desc = "Serious passive income" },
	{ id = "floor3", name = "Unlock Story Gate III", cost = 1200, kind = "story", story = 3, desc = "Access floor 3 anywhere" },
	{ id = "speed", name = "Tycoon Sneakers +3", cost = 600, kind = "speed", amount = 3, desc = "Move faster" },
	{ id = "floor4", name = "Unlock Story Gate IV", cost = 3500, kind = "story", story = 4, desc = "Access floor 4 anywhere" },
	{ id = "floor5", name = "Unlock Story Gate V", cost = 9000, kind = "story", story = 5, desc = "Mythic loft access" },
	{ id = "floor6", name = "Unlock Story Gate VI", cost = 22000, kind = "story", story = 6, desc = "Secret roof access" },
}

-- Walkover pad hide distance
Config.PAD_HIDE_DIST = 7

--[[
	ROBUX MONETIZATION
	1) Publish your game on Roblox (see PUBLISH.md)
	2) Create Game Passes + Developer Products in Creator Dashboard
	3) Paste the numeric IDs below (leave 0 until created — buttons show "SET ID")
]]
Config.Monetization = {
	-- Game Passes (permanent powerups)
	GamePasses = {
		{
			key = "vip",
			name = "VIP",
			description = "+25% cash multi · gold nametag · VIP lounge",
			id = 0,
			robuxHint = 199,
			category = "powerup",
		},
		{
			key = "x2cash",
			name = "2x Cash",
			description = "Double all deposit cash forever",
			id = 0,
			robuxHint = 399,
			category = "powerup",
		},
		{
			key = "auto",
			name = "Auto Collector",
			description = "+12 magnet range forever",
			id = 0,
			robuxHint = 149,
			category = "powerup",
		},
		{
			key = "starter",
			name = "Tycoon Starter",
			description = "+50 capacity · +4 speed forever",
			id = 0,
			robuxHint = 99,
			category = "powerup",
		},
		{
			key = "lucky",
			name = "Lucky Tycoon",
			description = "+30% rare loot weight forever",
			id = 0,
			robuxHint = 249,
			category = "powerup",
		},
		{
			key = "tank",
			name = "Zombie Tank",
			description = "+40 max HP · less zombie steal",
			id = 0,
			robuxHint = 179,
			category = "gear",
		},
		{
			key = "yz65",
			name = "YZ65 Dirtbike",
			description = "Fast dirtbike upgrade · ~10x walk speed · spawn anytime · jump lips",
			id = 0,
			robuxHint = 349,
			category = "gear",
			vehicle = "yz65",
		},
	},
	-- Developer Products (repeatable)
	Products = {
		{
			key = "yz65_spawn",
			name = "Spawn YZ65 Now",
			description = "Instant dirtbike drop (own the YZ65 pass for free recalls)",
			id = 0,
			robuxHint = 25,
			category = "gear",
			vehicle = "yz65",
		},
		{
			key = "cash_s",
			name = "Cash Pack S",
			description = "+2,500 Cash instant",
			id = 0,
			robuxHint = 49,
			cash = 2500,
			category = "cash",
		},
		{
			key = "cash_m",
			name = "Cash Pack M",
			description = "+15,000 Cash instant",
			id = 0,
			robuxHint = 149,
			cash = 15000,
			category = "cash",
		},
		{
			key = "cash_l",
			name = "Cash Pack L",
			description = "+75,000 Cash instant",
			id = 0,
			robuxHint = 399,
			cash = 75000,
			category = "cash",
		},
		{
			key = "skip_rebirth",
			name = "Instant Rebirth Token",
			description = "One free rebirth (no cash cost)",
			id = 0,
			robuxHint = 99,
			freeRebirth = true,
			category = "powerup",
		},
		{
			key = "speed_burst",
			name = "Speed Burst Gear",
			description = "+6 walk speed forever",
			id = 0,
			robuxHint = 79,
			speed = 6,
			category = "gear",
		},
		{
			key = "mega_pockets",
			name = "Mega Pockets",
			description = "+80 carry capacity forever",
			id = 0,
			robuxHint = 129,
			capacity = 80,
			category = "gear",
		},
		{
			key = "magnet_pro",
			name = "Magnet Pro",
			description = "+10 magnet range forever",
			id = 0,
			robuxHint = 99,
			magnet = 10,
			category = "gear",
		},
		{
			key = "fit_gold",
			name = "Gold Empire Fit",
			description = "Gold trail + title EMPIRE GOLD",
			id = 0,
			robuxHint = 89,
			trail = 1,
			titleText = "EMPIRE GOLD",
			category = "clothing",
		},
		{
			key = "fit_neon",
			name = "Neon Flex Fit",
			description = "Neon trail + title NEON FLEX",
			id = 0,
			robuxHint = 89,
			trail = 2,
			titleText = "NEON FLEX",
			category = "clothing",
		},
		{
			key = "fit_void",
			name = "Void Banker Fit",
			description = "Title VOID BANKER + luck boost",
			id = 0,
			robuxHint = 149,
			titleText = "VOID BANKER",
			luck = 0.2,
			category = "clothing",
		},
		{
			key = "bat_pro",
			name = "Cash Bat Pro",
			description = "Stronger zombie-slaying tool",
			id = 0,
			robuxHint = 59,
			gear = "bat_pro",
			category = "gear",
		},
	},
}

-- ── Carry / movement ──────────────────────────────────────────
Config.STACK_HEIGHT_PER_ITEM = 1.15
Config.STACK_VISUAL_CAP = 100
Config.BASE_WALK_SPEED = 20
Config.MIN_WALK_SPEED = 7
Config.SLOW_PER_ITEM = 0.1
Config.START_CAPACITY = 35
Config.PICKUP_RANGE = 11 -- grab radius
Config.MAX_WORLD_COLLECTIBLES = 380
Config.SUBURB_SPAWN_WEIGHT = 0.62 -- majority of loot on open ground / starter routes
Config.COMBO_WINDOW = 1.35 -- seconds between pickups to keep combo
Config.COMBO_BONUS_PER = 0.02 -- +2% value per combo step when depositing (cap)
Config.COMBO_BONUS_CAP = 0.5

-- ── Zombies ───────────────────────────────────────────────────
Config.ZOMBIE_MAX = 28
Config.ZOMBIE_SPEED = 11
Config.ZOMBIE_DAMAGE = 12
Config.ZOMBIE_HIT_COOLDOWN = 1.1
Config.ZOMBIE_HEALTH = 40
Config.ZOMBIE_PLAYER_DPS = 28 -- melee DPS when near zombie
Config.ZOMBIE_AGGRO = 55
Config.ZOMBIE_ATTACK_RANGE = 4.5
Config.ZOMBIE_MELEE_RANGE = 7
Config.ZOMBIE_STEAL_CHANCE = 0.35 -- chance to yeet 1 carried item on hit
Config.ZOMBIE_CASH_DROP_MIN = 8
Config.ZOMBIE_CASH_DROP_MAX = 35

-- ── Rebirth ───────────────────────────────────────────────────
Config.REBIRTH_BASE_COST = 25000
Config.REBIRTH_COST_MULT = 1.85
Config.REBIRTH_MULTI_PER = 0.35 -- +35% cash multi per rebirth
Config.REBIRTH_CAPACITY_PER = 5

Config.RarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Secret = 7,
	Meme = 4,
}

Config.RarityColor = {
	Common = Color3.fromRGB(200, 200, 210),
	Uncommon = Color3.fromRGB(80, 220, 130),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 50),
	Mythic = Color3.fromRGB(255, 55, 100),
	Secret = Color3.fromRGB(255, 255, 255),
	Meme = Color3.fromRGB(255, 120, 200),
}

-- minStory = lowest building floor this coin may appear on (1 = ground)
Config.Currencies = {
	{ id = "penny", name = "Penny", rarity = "Common", value = 4, color = Color3.fromRGB(180, 110, 60), weight = 38, zone = "suburbs", minStory = 1, emoji = "🪙", description = "Every empire starts with copper." },
	{ id = "dollar", name = "Dollar Bill", rarity = "Common", value = 18, color = Color3.fromRGB(70, 170, 95), weight = 34, zone = "suburbs", minStory = 1, emoji = "💵", description = "Crisp stack fuel." },
	{ id = "fiver", name = "Five Spot", rarity = "Common", value = 30, color = Color3.fromRGB(90, 160, 100), weight = 22, zone = "suburbs", minStory = 1, emoji = "💶", description = "Slightly thicker brag." },
	{ id = "twenty", name = "Twenty Stack", rarity = "Common", value = 55, color = Color3.fromRGB(50, 140, 80), weight = 14, zone = "suburbs", minStory = 1, emoji = "💸", description = "Neighborhood flex." },
	{ id = "coin_jar", name = "Coin Jar", rarity = "Uncommon", value = 90, color = Color3.fromRGB(220, 180, 60), weight = 8, zone = "suburbs", minStory = 2, emoji = "🏺", description = "Grandma's emergency fund." },
	{ id = "zombie_tooth", name = "Zombie Tooth", rarity = "Uncommon", value = 45, color = Color3.fromRGB(120, 200, 90), weight = 0, zone = "suburbs", minStory = 1, emoji = "🦷", description = "Looted from the undead." },
	{ id = "chuck_e", name = "Chuck E. Token", rarity = "Meme", value = 14, color = Color3.fromRGB(255, 95, 55), weight = 12, zone = "arcade", minStory = 1, emoji = "🧀", description = "Arcade royalty." },
	{ id = "monopoly", name = "McD Monopoly Piece", rarity = "Meme", value = 20, color = Color3.fromRGB(255, 220, 55), weight = 9, zone = "arcade", minStory = 2, emoji = "🎲", description = "Park Place delusions." },
	{ id = "ticket", name = "Prize Ticket", rarity = "Meme", value = 16, color = Color3.fromRGB(255, 80, 160), weight = 10, zone = "arcade", minStory = 1, emoji = "🎟️", description = "Won't buy a bike. Still flex." },
	{ id = "doubloon", name = "Gold Doubloon", rarity = "Uncommon", value = 28, color = Color3.fromRGB(255, 200, 45), weight = 14, zone = "harbor", minStory = 1, emoji = "🪙", description = "Pirate payroll." },
	{ id = "pearl", name = "Black Pearl", rarity = "Uncommon", value = 40, color = Color3.fromRGB(40, 40, 55), weight = 7, zone = "harbor", minStory = 2, emoji = "🖤", description = "Ocean rare." },
	{ id = "denarius", name = "Roman Denarius", rarity = "Uncommon", value = 35, color = Color3.fromRGB(210, 210, 220), weight = 11, zone = "ruins", minStory = 1, emoji = "🏛️", description = "Caesar's pocket change." },
	{ id = "laurel", name = "Golden Laurel", rarity = "Rare", value = 95, color = Color3.fromRGB(230, 190, 60), weight = 5, zone = "ruins", minStory = 2, emoji = "🌿", description = "Emperor vibes only." },
	{ id = "platinum_coin", name = "Platinum Coin", rarity = "Rare", value = 90, color = Color3.fromRGB(200, 220, 235), weight = 7, zone = "vault", minStory = 2, emoji = "⚪", description = "Cold. Heavy. Loud." },
	{ id = "platinum_bar", name = "Platinum Bar", rarity = "Rare", value = 160, color = Color3.fromRGB(175, 195, 215), weight = 4, zone = "vault", minStory = 3, emoji = "▬", description = "Ingots that mean business." },
	{ id = "vault_key", name = "Vault Keycard", rarity = "Epic", value = 200, color = Color3.fromRGB(120, 255, 200), weight = 3, zone = "vault", minStory = 3, emoji = "💳", description = "Access is wealth." },
	{ id = "bitcoin", name = "Bitcoin", rarity = "Epic", value = 280, color = Color3.fromRGB(245, 165, 35), weight = 3.5, zone = "cyber", minStory = 3, emoji = "₿", description = "To the moon — after the walk." },
	{ id = "ethereum", name = "Ethereum", rarity = "Epic", value = 250, color = Color3.fromRGB(120, 145, 255), weight = 3.5, zone = "cyber", minStory = 3, emoji = "Ξ", description = "Gas fees paid in sweat." },
	{ id = "nft_duck", name = "JPEG Duck", rarity = "Epic", value = 310, color = Color3.fromRGB(255, 200, 80), weight = 2, zone = "cyber", minStory = 3, emoji = "🦆", description = "Worthless. Priceless. Perfect." },
	{ id = "star_fragment", name = "Star Fragment", rarity = "Legendary", value = 550, color = Color3.fromRGB(255, 245, 170), weight = 1.8, zone = "cosmos", minStory = 3, emoji = "⭐", description = "Fallen star currency." },
	{ id = "nebula_shard", name = "Nebula Shard", rarity = "Legendary", value = 700, color = Color3.fromRGB(180, 100, 255), weight = 1.2, zone = "cosmos", minStory = 4, emoji = "🌌", description = "Galaxy dust, bagged." },
	{ id = "dragon_egg", name = "Dragon Egg", rarity = "Mythic", value = 1400, color = Color3.fromRGB(255, 70, 90), weight = 0.7, zone = "cosmos", minStory = 5, emoji = "🥚", description = "Don't drop it. Ever." },
	{ id = "infinity_cent", name = "Infinity Cent", rarity = "Secret", value = 5000, color = Color3.fromRGB(255, 255, 255), weight = 0.15, zone = "secret", minStory = 6, emoji = "∞", description = "Rumor. Legend. Jackpot." },
	{ id = "mythic_crown", name = "Mythic Crown", rarity = "Mythic", value = 2200, color = Color3.fromRGB(255, 120, 40), weight = 0.5, zone = "cosmos", minStory = 5, emoji = "👑", description = "Only the loft." },
	{ id = "secret_ledger", name = "Secret Ledger", rarity = "Secret", value = 8000, color = Color3.fromRGB(240, 240, 255), weight = 0.08, zone = "secret", minStory = 6, emoji = "📓", description = "The books that shouldn't exist." },
}

Config.CurrencyById = {}
for _, c in Config.Currencies do
	Config.CurrencyById[c.id] = c
end

-- Zone gates — centered on open world (spawn hub is SW corner at SPAWN_HUB)
Config.Zones = {
	{ id = "hub", name = "Spawn Hub", center = Config.SPAWN_HUB, radius = Config.SAFE_HUB_RADIUS, color = Color3.fromRGB(90, 90, 130), unlockCash = 0, unlockRebirth = 0 },
	{ id = "suburbs", name = "Copper Suburbs", center = Vector3.new(0, 0, 0), radius = 420, color = Color3.fromRGB(70, 120, 65), unlockCash = 0, unlockRebirth = 0 },
	{ id = "arcade", name = "Neon Arcade", center = Vector3.new(380, 0, 260), radius = 120, color = Color3.fromRGB(220, 50, 130), unlockCash = 40, unlockRebirth = 0 },
	{ id = "harbor", name = "Pirate Harbor", center = Vector3.new(-280, 0, 280), radius = 120, color = Color3.fromRGB(30, 110, 170), unlockCash = 120, unlockRebirth = 0 },
	{ id = "ruins", name = "Roman Ruins", center = Vector3.new(260, 0, -360), radius = 110, color = Color3.fromRGB(155, 145, 120), unlockCash = 280, unlockRebirth = 0 },
	{ id = "vault", name = "Platinum Vault", center = Vector3.new(-160, 0, -360), radius = 110, color = Color3.fromRGB(160, 185, 205), unlockCash = 700, unlockRebirth = 0 },
	{ id = "cyber", name = "Crypto District", center = Vector3.new(480, 0, -240), radius = 110, color = Color3.fromRGB(55, 45, 150), unlockCash = 1800, unlockRebirth = 0 },
	{ id = "cosmos", name = "Starfall Crater", center = Vector3.new(-480, 0, -280), radius = 120, color = Color3.fromRGB(90, 25, 120), unlockCash = 4500, unlockRebirth = 1 },
	{ id = "secret", name = "??? Chamber", center = Vector3.new(160, 0, 620), radius = 90, color = Color3.fromRGB(20, 20, 25), unlockCash = 20000, unlockRebirth = 3 },
	-- Red Rocks Amphitheatre (Colorado-style outdoor venue — ticket required)
	{ id = "redrocks", name = "Red Rocks Amphitheatre", center = Vector3.new(280, 0, -280), radius = 200, color = Color3.fromRGB(180, 70, 45), unlockCash = 0, unlockRebirth = 0, requiresTicket = true },
}

--[[
	RED ROCKS AMPHITHEATRE
	Inspired by the real Morrison, CO venue: stage carved into Stage Rock,
	flanked by Creation Rock (N) & Ship Rock (S), sandstone seating bowl.
]]
Config.RedRocks = {
	center = Vector3.new(280, 0, -280),
	-- Ticket booth / box office (outside gate)
	ticketCost = 500, -- Cash general admission
	vipTicketCost = 2500, -- better seats + title flex
	ticketName = "Red Rocks GA Ticket",
	vipTicketName = "Red Rocks VIP Ticket",
	-- Stage show loop
	showLength = 90, -- seconds of "set"
	encoreMulti = 1.5, -- deposit multi while inside during encore (optional buff)
}

-- Pets (follow + multi). Bought or hatched later — shop unlock
Config.Pets = {
	{ id = "piggy", name = "Piggy Bank", multi = 0.1, color = Color3.fromRGB(255, 140, 170), costCash = 500, description = "+10% deposit multi" },
	{ id = "bull", name = "Wall Street Bull", multi = 0.2, color = Color3.fromRGB(200, 200, 210), costCash = 2500, costCurrency = { doubloon = 15 }, description = "+20% deposit multi" },
	{ id = "shiba", name = "Doge", multi = 0.35, color = Color3.fromRGB(220, 180, 100), costCash = 8000, costCurrency = { bitcoin = 2 }, description = "+35% multi · meme power" },
	{ id = "dragon", name = "Vault Dragon", multi = 0.6, color = Color3.fromRGB(255, 80, 60), costCash = 25000, costCurrency = { dragon_egg = 1 }, description = "+60% multi · apex flex" },
	{ id = "void", name = "Void Wallet", multi = 1.0, color = Color3.fromRGB(30, 0, 50), costCash = 100000, costCurrency = { infinity_cent = 1, nebula_shard = 3 }, description = "+100% multi · endgame" },
}

Config.PetById = {}
for _, p in Config.Pets do
	Config.PetById[p.id] = p
end

-- Shop catalog
Config.Shop = {
	{ id = "cap_1", name = "Bigger Pockets", description = "+15 capacity", costCash = 120, kind = "capacity", amount = 15 },
	{ id = "cap_2", name = "Duffel Bag", description = "+30 capacity", costCash = 500, kind = "capacity", amount = 30 },
	{ id = "cap_3", name = "Vault Backpack", description = "+60 capacity", costCash = 2200, costCurrency = { platinum_coin = 5 }, kind = "capacity", amount = 60 },
	{ id = "cap_4", name = "Wormhole Pack", description = "+100 capacity", costCash = 12000, costCurrency = { star_fragment = 2 }, kind = "capacity", amount = 100 },
	{ id = "spd_1", name = "Sneakers", description = "+2 speed", costCash = 250, kind = "speed", amount = 2 },
	{ id = "spd_2", name = "Rocket Cleats", description = "+4 speed", costCash = 1200, costCurrency = { bitcoin = 1 }, kind = "speed", amount = 4 },
	{ id = "spd_3", name = "Photon Boots", description = "+6 speed", costCash = 8000, costCurrency = { ethereum = 2 }, kind = "speed", amount = 6 },
	{ id = "mag_1", name = "Coin Magnet I", description = "+5 auto-pickup radius", costCash = 700, costCurrency = { doubloon = 8 }, kind = "magnet", amount = 5 },
	{ id = "mag_2", name = "Coin Magnet II", description = "+8 radius", costCash = 4500, costCurrency = { platinum_bar = 3 }, kind = "magnet", amount = 8 },
	{ id = "luck_1", name = "Lucky Charm", description = "+15% rare loot weight", costCash = 3000, kind = "luck", amount = 0.15 },
	{ id = "trail_gold", name = "Gold Rush Trail", description = "Golden haul trail", costCash = 400, kind = "trail", amount = 1 },
	{ id = "trail_neon", name = "Neon Flex Trail", description = "Arcade trail", costCash = 1500, costCurrency = { chuck_e = 20 }, kind = "trail", amount = 2 },
	{ id = "title_tycoon", name = "Title: Tycoon", description = "Nametag flex", costCash = 2000, kind = "title", amount = 1, titleText = "TYCOON" },
	{ id = "title_dragon", name = "Title: Dragon Banker", description = "Mythic nametag", costCash = 20000, costCurrency = { dragon_egg = 1 }, kind = "title", amount = 1, titleText = "DRAGON BANKER" },
	-- Red Rocks tickets (also sold at the box office on-site)
	{ id = "rr_ticket_ga", name = "Red Rocks GA Ticket", description = "General admission · enter the amphitheatre", costCash = 500, kind = "ticket", ticketTier = "ga" },
	{ id = "rr_ticket_vip", name = "Red Rocks VIP Ticket", description = "VIP row · enter + title ROCKS VIP", costCash = 2500, kind = "ticket", ticketTier = "vip", titleText = "ROCKS VIP" },
	-- pets as shop entries
	{ id = "pet_piggy", name = "Pet: Piggy Bank", description = "+10% multi", costCash = 500, kind = "pet", petId = "piggy" },
	{ id = "pet_bull", name = "Pet: Wall Street Bull", description = "+20% multi", costCash = 2500, costCurrency = { doubloon = 15 }, kind = "pet", petId = "bull" },
	{ id = "pet_shiba", name = "Pet: Doge", description = "+35% multi", costCash = 8000, costCurrency = { bitcoin = 2 }, kind = "pet", petId = "shiba" },
	{ id = "pet_dragon", name = "Pet: Vault Dragon", description = "+60% multi", costCash = 25000, costCurrency = { dragon_egg = 1 }, kind = "pet", petId = "dragon" },
	{ id = "pet_void", name = "Pet: Void Wallet", description = "+100% multi", costCash = 100000, costCurrency = { infinity_cent = 1, nebula_shard = 3 }, kind = "pet", petId = "void" },
}

-- Fusion recipes at bank (optional craft)
Config.Fusions = {
	{ id = "fuse_dollar", name = "Mint Dollar", inputs = { penny = 5 }, output = "dollar", description = "5 Pennies → 1 Dollar" },
	{ id = "fuse_plat", name = "Smelt Platinum", inputs = { doubloon = 8, denarius = 4 }, output = "platinum_coin", description = "Pirate + Rome → Platinum" },
	{ id = "fuse_star", name = "Constellation", inputs = { bitcoin = 2, ethereum = 2, vault_key = 1 }, output = "star_fragment", description = "Crypto → Star" },
}

-- Timed world events
Config.Events = {
	{ id = "gold_rush", name = "GOLD RUSH", duration = 45, multi = 2, color = Color3.fromRGB(255, 210, 50), weight = 3 },
	{ id = "meme_mania", name = "MEME MANIA", duration = 40, zoneBoost = "arcade", color = Color3.fromRGB(255, 100, 200), weight = 2 },
	{ id = "dragon_watch", name = "DRAGON WATCH", duration = 30, mythicBoost = 3, color = Color3.fromRGB(255, 60, 80), weight = 1 },
}

return Config
