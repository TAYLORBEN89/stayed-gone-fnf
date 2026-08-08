local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local PlayerData = require(script.Parent.PlayerData)

local DataService = {}
local STORE_NAME = "CashEmpire_v2"
local store = nil
local canStore = true

pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

if RunService:IsStudio() then
	-- Studio API access may be off; still try, fail soft
end

function DataService.load(player: Player)
	if not store or not canStore then
		PlayerData.get(player).statsLoaded = true
		return
	end
	local key = "p_" .. player.UserId
	local ok, data = pcall(function()
		return store:GetAsync(key)
	end)
	if ok and data then
		PlayerData.applySave(player, data)
	else
		PlayerData.get(player).statsLoaded = true
		if not ok then
			warn("[DataService] load fail", data)
		end
	end
	PlayerData.updateLeaderstats(player)
end

function DataService.save(player: Player)
	if not store or not canStore then
		return
	end
	local key = "p_" .. player.UserId
	local payload = PlayerData.serialize(player)
	local ok, err = pcall(function()
		store:SetAsync(key, payload)
	end)
	if not ok then
		warn("[DataService] save fail", err)
	end
end

function DataService.bind(player: Player)
	-- Load synchronously so baseLocked / baseIndex exist before spawn logic
	DataService.load(player)
	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(game) then
			DataService.save(player)
		end
	end)
end

-- autosave
task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in game:GetService("Players"):GetPlayers() do
			task.spawn(DataService.save, plr)
		end
	end
end)

game:BindToClose(function()
	for _, plr in game:GetService("Players"):GetPlayers() do
		DataService.save(plr)
	end
	task.wait(2)
end)

return DataService
