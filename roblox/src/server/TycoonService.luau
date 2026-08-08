local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local TycoonService = {}
TycoonService._bases = nil
TycoonService._toast = nil
TycoonService._push = nil
TycoonService._speed = nil

function TycoonService.setCallbacks(toast, push, applySpeed)
	TycoonService._toast = toast
	TycoonService._push = push
	TycoonService._speed = applySpeed
end

function TycoonService.bindWorld(bases)
	TycoonService._bases = bases
end

local function buttonDef(id: string)
	for _, b in Config.TycoonButtons do
		if b.id == id then
			return b
		end
	end
	return nil
end

local function nextRequiredIndex(profile): number
	-- sequential: must buy in order
	local bought = profile.tycoonBought or {}
	for i, b in Config.TycoonButtons do
		if not bought[b.id] then
			return i
		end
	end
	return #Config.TycoonButtons + 1
end

function TycoonService.refreshButtons(player: Player)
	if not TycoonService._bases then
		return
	end
	local profile = PlayerData.get(player)
	local slot
	for _, s in TycoonService._bases do
		if s.owner == player or s.index == profile.baseIndex then
			slot = s
			break
		end
	end
	if not slot or not slot.tycoon then
		return
	end
	local nextIdx = nextRequiredIndex(profile)
	for _, btnPart in slot.tycoon.buttons do
		local order = btnPart:GetAttribute("Order") or 99
		local id = btnPart:GetAttribute("ButtonId")
		local owned = profile.tycoonBought and profile.tycoonBought[id]
		if owned then
			btnPart.Color = Color3.fromRGB(60, 200, 100)
			btnPart.Transparency = 0.5
			local lab = btnPart:FindFirstChild("PadLabel")
			if lab then
				local t = lab:FindFirstChildWhichIsA("TextLabel")
				if t then
					t.Text = "OWNED\n" .. (buttonDef(id) and buttonDef(id).name or id)
				end
			end
		elseif order == nextIdx then
			btnPart.Color = Color3.fromRGB(255, 80, 80)
			btnPart.Transparency = 0
			btnPart:SetAttribute("CanBuy", true)
		else
			btnPart.Color = Color3.fromRGB(80, 80, 90)
			btnPart.Transparency = 0.35
			btnPart:SetAttribute("CanBuy", false)
			local lab = btnPart:FindFirstChild("PadLabel")
			if lab then
				local t = lab:FindFirstChildWhichIsA("TextLabel")
				if t and buttonDef(id) then
					t.Text = "LOCKED\n" .. buttonDef(id).name
				end
			end
		end
	end
end

function TycoonService.tryBuy(player: Player, buttonId: string): (boolean, string)
	local def = buttonDef(buttonId)
	if not def then
		return false, "Unknown button"
	end
	local profile = PlayerData.get(player)
	profile.tycoonBought = profile.tycoonBought or {}
	if profile.tycoonBought[buttonId] then
		return false, "Already owned"
	end

	local nextIdx = nextRequiredIndex(profile)
	local thisIdx = 0
	for i, b in Config.TycoonButtons do
		if b.id == buttonId then
			thisIdx = i
			break
		end
	end
	if thisIdx ~= nextIdx then
		return false, "Buy the previous tycoon pad first!"
	end
	if profile.cash < def.cost then
		return false, "Need $" .. def.cost .. " Cash"
	end

	profile.cash -= def.cost
	profile.tycoonBought[buttonId] = true

	if def.kind == "capacity" then
		profile.capacity += def.amount or 0
	elseif def.kind == "magnet" then
		profile.magnetBonus += def.amount or 0
	elseif def.kind == "speed" then
		profile.speedBonus += def.amount or 0
	elseif def.kind == "story" then
		profile.maxStory = math.max(profile.maxStory or 1, def.story or 1)
	elseif def.kind == "dropper" then
		profile.dropperRate = (profile.dropperRate or 0) + (def.rate or 0)
	elseif def.kind == "build" then
		profile.tycoonWalls = true
	end

	if TycoonService._speed then
		TycoonService._speed(player)
	end
	TycoonService.refreshButtons(player)
	PlayerData.updateLeaderstats(player)
	if TycoonService._push then
		TycoonService._push(player)
	end
	return true, "Purchased " .. def.name .. "!"
end

function TycoonService.startDroppers()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, plr in game:GetService("Players"):GetPlayers() do
				local p = PlayerData.get(plr)
				local rate = p.dropperRate or 0
				if rate > 0 then
					p.cash += rate
					PlayerData.updateLeaderstats(plr)
					-- light push every few sec only
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(4)
			for _, plr in game:GetService("Players"):GetPlayers() do
				if (PlayerData.get(plr).dropperRate or 0) > 0 and TycoonService._push then
					TycoonService._push(plr)
				end
			end
		end
	end)
end

function TycoonService.wireButtons(bases, onBuy)
	for _, slot in bases do
		if not slot.tycoon then
			continue
		end
		for _, btn in slot.tycoon.buttons do
			local prompt = btn:FindFirstChild("BuyPrompt")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Triggered:Connect(function(player)
					if slot.owner and slot.owner ~= player then
						if TycoonService._toast then
							TycoonService._toast(player, "Not your tycoon plot!", Color3.fromRGB(255, 140, 80))
						end
						return
					end
					local id = btn:GetAttribute("ButtonId")
					local ok, msg = TycoonService.tryBuy(player, id)
					if TycoonService._toast then
						TycoonService._toast(player, msg, ok and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 140, 80))
					end
				end)
			end
			btn.Touched:Connect(function(hit)
				local model = hit:FindFirstAncestorOfClass("Model")
				local plr = model and game:GetService("Players"):GetPlayerFromCharacter(model)
				if not plr then
					return
				end
				if slot.owner and slot.owner ~= plr then
					return
				end
				-- only auto-buy if it's the active red pad
				if btn:GetAttribute("CanBuy") then
					local id = btn:GetAttribute("ButtonId")
					local ok, msg = TycoonService.tryBuy(plr, id)
					if ok and TycoonService._toast then
						TycoonService._toast(plr, msg, Color3.fromRGB(120, 255, 160))
					end
				end
			end)
		end
	end
end

return TycoonService
