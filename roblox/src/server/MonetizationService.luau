--[[
	Robux monetization: Game Passes + Developer Products
	Config.FREE_ROBUX_TEST = true → all purchases grant free (Studio / testing)
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local VehicleService = require(script.Parent.VehicleService)

local MonetizationService = {}
MonetizationService._toast = nil :: ((Player, string, Color3?) -> ())?
MonetizationService._push = nil :: ((Player) -> ())?
MonetizationService._title = nil :: ((Player) -> ())?
MonetizationService._pet = nil :: ((Player) -> ())?
MonetizationService._speed = nil :: ((Player) -> ())?

function MonetizationService.setCallbacks(toast, push, titleFn, petFn, speedFn)
	MonetizationService._toast = toast
	MonetizationService._push = push
	MonetizationService._title = titleFn
	MonetizationService._pet = petFn
	MonetizationService._speed = speedFn
end

local function toast(player, msg, color)
	if MonetizationService._toast then
		MonetizationService._toast(player, msg, color)
	end
end

local function push(player)
	if MonetizationService._push then
		MonetizationService._push(player)
	end
end

local function freeTest(): boolean
	return Config.FREE_ROBUX_TEST == true or RunService:IsStudio()
end

local function productById(id: number)
	for _, p in Config.Monetization.Products do
		if p.id == id and id ~= 0 then
			return p
		end
	end
	return nil
end

local function passById(id: number)
	for _, p in Config.Monetization.GamePasses do
		if p.id == id and id ~= 0 then
			return p
		end
	end
	return nil
end

local function giveBat(player: Player, tier: string)
	local char = player.Character
	if not char then
		return
	end
	local old = char:FindFirstChild("CashBat")
	if old then
		old:Destroy()
	end
	local tool = Instance.new("Tool")
	tool.Name = "CashBat"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 0.6, 4)
	handle.Color = tier == "bat_pro" and Color3.fromRGB(255, 200, 40) or Color3.fromRGB(180, 120, 60)
	handle.Material = Enum.Material.Neon
	handle.Parent = tool
	tool.Parent = player.Backpack
end

function MonetizationService.applyGamePassRewards(player: Player, key: string, firstTime: boolean)
	local profile = PlayerData.get(player)
	profile.passes[key] = true

	if key == "vip" then
		if profile.title == "" then
			profile.title = "VIP"
		end
	elseif key == "auto" then
		if not profile.passApplied.auto then
			profile.magnetBonus += 12
			profile.passApplied.auto = true
		end
	elseif key == "starter" then
		if not profile.passApplied.starter then
			profile.capacity += 50
			profile.speedBonus += 4
			profile.passApplied.starter = true
		end
	elseif key == "lucky" then
		if not profile.passApplied.lucky then
			profile.luckBonus += 0.3
			profile.passApplied.lucky = true
		end
	elseif key == "tank" then
		if not profile.passApplied.tank then
			profile.passApplied.tank = true
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = math.max(hum.MaxHealth, 140)
				hum.Health = hum.MaxHealth
			end
		end
	elseif key == "yz65" then
		profile.passes.yz65 = true
		if firstTime or not profile.passApplied.yz65 then
			profile.passApplied.yz65 = true
			VehicleService.onOwned(player)
		else
			VehicleService.giveCallTool(player)
		end
	elseif key == "x2cash" then
		-- multi handled in PlayerData.cashMulti
	end

	if firstTime then
		if key == "yz65" then
			toast(player, "🏍️ YZ65 Dirtbike unlocked! Equip YZ65 Call tool to spawn/recall.", Color3.fromRGB(80, 160, 255))
		else
			toast(player, "💎 Unlocked " .. key:upper() .. "!", Color3.fromRGB(255, 220, 100))
		end
	end
	if MonetizationService._title then
		MonetizationService._title(player)
	end
	if MonetizationService._speed then
		MonetizationService._speed(player)
	end
	PlayerData.updateLeaderstats(player)
	push(player)
end

function MonetizationService.applyProduct(player: Player, prod: any)
	local profile = PlayerData.get(player)
	if prod.cash then
		profile.cash += prod.cash
		toast(player, "💰 +" .. prod.cash .. " Cash!", Color3.fromRGB(255, 220, 80))
	end
	if prod.freeRebirth then
		profile.rebirths += 1
		profile.capacity += Config.REBIRTH_CAPACITY_PER
		toast(player, "♻️ Instant Rebirth applied!", Color3.fromRGB(200, 140, 255))
	end
	if prod.speed then
		profile.speedBonus += prod.speed
		toast(player, "⚡ +" .. prod.speed .. " speed!", Color3.fromRGB(120, 220, 255))
	end
	if prod.capacity then
		profile.capacity += prod.capacity
		toast(player, "📦 +" .. prod.capacity .. " capacity!", Color3.fromRGB(120, 255, 160))
	end
	if prod.magnet then
		profile.magnetBonus += prod.magnet
		toast(player, "🧲 +" .. prod.magnet .. " magnet!", Color3.fromRGB(180, 255, 120))
	end
	if prod.luck then
		profile.luckBonus += prod.luck
		toast(player, "🍀 +" .. math.floor(prod.luck * 100) .. "% luck!", Color3.fromRGB(160, 255, 120))
	end
	if prod.trail then
		profile.trail = prod.trail
	end
	if prod.titleText then
		profile.title = prod.titleText
		if MonetizationService._title then
			MonetizationService._title(player)
		end
		toast(player, "👕 Fit: " .. prod.titleText, Color3.fromRGB(255, 200, 120))
	end
	if prod.gear == "bat_pro" then
		giveBat(player, "bat_pro")
		toast(player, "🏏 Cash Bat Pro equipped!", Color3.fromRGB(255, 220, 100))
	end
	if prod.vehicle == "yz65" then
		-- Product spawn: always drop a bike; permanent pass if from yz65 pass path
		profile.passes.yz65 = true
		VehicleService.onOwned(player)
		local ok, msg = VehicleService.spawnYZ65(player)
		toast(player, ok and msg or msg, Color3.fromRGB(80, 160, 255))
	end
	if MonetizationService._speed then
		MonetizationService._speed(player)
	end
	PlayerData.updateLeaderstats(player)
	push(player)
end

local function hasPass(player: Player, key: string): boolean
	return PlayerData.get(player).passes[key] == true
end

function MonetizationService.refreshPasses(player: Player)
	for _, gp in Config.Monetization.GamePasses do
		if gp.id == 0 then
			continue
		end
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.id)
		end)
		if ok and owns then
			local already = hasPass(player, gp.key)
			MonetizationService.applyGamePassRewards(player, gp.key, not already)
		end
	end
end

function MonetizationService.promptGamePass(player: Player, key: string): (boolean, string)
	key = string.lower(tostring(key or ""))
	for _, gp in Config.Monetization.GamePasses do
		if string.lower(gp.key) == key then
			if PlayerData.get(player).passes[gp.key] then
				-- Re-apply tools (e.g. YZ65 call) even if already owned
				if gp.key == "yz65" then
					VehicleService.giveCallTool(player)
					VehicleService.spawnYZ65(player)
					return true, "🏍️ YZ65 re-spawned!"
				end
				return false, "You already own " .. gp.name
			end
			if freeTest() or gp.id == 0 then
				MonetizationService.applyGamePassRewards(player, gp.key, true)
				return true, (freeTest() and "[FREE TEST] " or "") .. "✓ " .. gp.name
			end
			MarketplaceService:PromptGamePassPurchase(player, gp.id)
			return true, "Opening Roblox purchase for " .. gp.name
		end
	end
	return false, "Unknown pass: " .. key
end

function MonetizationService.promptProduct(player: Player, key: string): (boolean, string)
	key = string.lower(tostring(key or ""))
	for _, prod in Config.Monetization.Products do
		if string.lower(prod.key) == key then
			if freeTest() or prod.id == 0 then
				MonetizationService.applyProduct(player, prod)
				return true, (freeTest() and "[FREE TEST] " or "") .. "✓ " .. prod.name
			end
			MarketplaceService:PromptProductPurchase(player, prod.id)
			return true, "Opening Roblox purchase for " .. prod.name
		end
	end
	return false, "Unknown product: " .. key
end

function MonetizationService.start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local gp = passById(passId)
		if gp then
			MonetizationService.applyGamePassRewards(player, gp.key, true)
			toast(player, "Thanks for supporting Cash Empire! 💎 " .. gp.name, Color3.fromRGB(120, 255, 180))
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local prod = productById(receiptInfo.ProductId)
		if not prod then
			warn("[Monetization] Unknown product", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		MonetizationService.applyProduct(player, prod)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return MonetizationService
