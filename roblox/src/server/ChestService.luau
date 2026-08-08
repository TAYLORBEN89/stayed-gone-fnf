local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local ChestService = {}
ChestService._toast = nil
ChestService._push = nil

function ChestService.setCallbacks(toast, push)
	ChestService._toast = toast
	ChestService._push = push
end

local function todayKey(): string
	local t = os.date("!*t")
	return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

function ChestService.claimDaily(player: Player): (boolean, string)
	local p = PlayerData.get(player)
	local today = todayKey()
	if p.lastDailyClaim == today then
		return false, "Daily chest already claimed today — come back tomorrow!"
	end
	p.lastDailyClaim = today
	local reward = Config.DAILY_CHEST_CASH or 500
	p.cash += reward
	PlayerData.updateLeaderstats(player)
	if ChestService._push then
		ChestService._push(player)
	end
	return true, "🎁 Daily chest: +" .. reward .. " Cash!"
end

function ChestService.claimPlaytime(player: Player): (boolean, string)
	local p = PlayerData.get(player)
	local need = Config.PLAYTIME_CHEST_SECONDS or 300
	local now = os.time()
	-- Need enough unclaimed playtime since last claim
	local earned = p.playtimeSeconds or 0
	if earned < need then
		local left = need - earned
		return false, ("⏱ Play %dm more for playtime chest (%ds left)"):format(math.ceil(left / 60), left)
	end
	p.playtimeSeconds = earned - need
	p.playtimePoints = (p.playtimePoints or 0) + (Config.PLAYTIME_POINTS_PER_TICK or 1)
	p.lastPlaytimeClaimAt = now
	local reward = Config.PLAYTIME_CHEST_CASH or 150
	-- bonus from points
	reward += math.floor((p.playtimePoints or 0) * 5)
	p.cash += reward
	PlayerData.updateLeaderstats(player)
	if ChestService._push then
		ChestService._push(player)
	end
	return true, ("⏱ Playtime chest: +%d Cash · Points %d"):format(reward, p.playtimePoints)
end

function ChestService.tickPlaytime()
	for _, plr in game:GetService("Players"):GetPlayers() do
		local p = PlayerData.get(plr)
		p.playtimeSeconds = (p.playtimeSeconds or 0) + 1
	end
end

function ChestService.start()
	task.spawn(function()
		while true do
			task.wait(1)
			ChestService.tickPlaytime()
		end
	end)
end

return ChestService
