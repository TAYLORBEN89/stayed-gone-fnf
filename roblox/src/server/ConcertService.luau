--[[
	Red Rocks Amphitheatre — ticket check, entry, show atmosphere.
]]

local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local ConcertService = {}
ConcertService._toast = nil :: ((Player, string, Color3?) -> ())?
ConcertService._push = nil :: ((Player) -> ())?
ConcertService._title = nil :: ((Player) -> ())?
ConcertService._venue = nil :: any
ConcertService._showActive = false

function ConcertService.setCallbacks(toast, push, titleFn)
	ConcertService._toast = toast
	ConcertService._push = push
	ConcertService._title = titleFn
end

local function toast(player, msg, color)
	if ConcertService._toast then
		ConcertService._toast(player, msg, color)
	end
end

function ConcertService.bindVenue(venue)
	ConcertService._venue = venue
end

function ConcertService.hasTicket(player: Player): boolean
	local t = PlayerData.get(player).concertTicket
	return t == "ga" or t == "vip"
end

function ConcertService.isVip(player: Player): boolean
	return PlayerData.get(player).concertTicket == "vip"
end

function ConcertService.buyTicket(player: Player, tier: string): (boolean, string)
	tier = string.lower(tier or "ga")
	local profile = PlayerData.get(player)
	local rr = Config.RedRocks or {}
	local cost = tier == "vip" and (rr.vipTicketCost or 2500) or (rr.ticketCost or 500)
	local name = tier == "vip" and (rr.vipTicketName or "VIP Ticket") or (rr.ticketName or "GA Ticket")

	if profile.concertTicket == "vip" then
		return false, "You already have VIP access!"
	end
	if profile.concertTicket == tier then
		return false, "You already have this ticket"
	end
	if profile.cash < cost then
		return false, "Need $" .. cost .. " Cash for " .. name
	end
	profile.cash -= cost
	profile.concertTicket = tier
	if tier == "vip" then
		profile.title = "ROCKS VIP"
		if ConcertService._title then
			ConcertService._title(player)
		end
	end
	PlayerData.updateLeaderstats(player)
	if ConcertService._push then
		ConcertService._push(player)
	end
	return true, "🎟️ " .. name .. " purchased! Enter through the gate."
end

function ConcertService.tryEnter(player: Player): (boolean, string)
	if not ConcertService.hasTicket(player) then
		return false, "🎟️ No ticket — buy GA ($" .. ((Config.RedRocks and Config.RedRocks.ticketCost) or 500) .. ") or VIP at the box office"
	end
	local venue = ConcertService._venue
	if not venue or not venue.insideCF then
		return false, "Venue not ready"
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, "No character"
	end
	local dest = venue.insideCF
	if ConcertService.isVip(player) and venue.vipCF then
		dest = venue.vipCF
	end
	root.CFrame = dest
	return true, ConcertService.isVip(player) and "🌟 VIP entry — front rows!" or "🎸 Welcome to Red Rocks — enjoy the show!"
end

function ConcertService.tryExit(player: Player)
	local venue = ConcertService._venue
	if not venue or not venue.exitCF then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = venue.exitCF
		toast(player, "👋 Left Red Rocks Amphitheatre", Color3.fromRGB(200, 180, 160))
	end
end

function ConcertService.startShowLoop()
	task.spawn(function()
		while true do
			ConcertService._showActive = true
			if ConcertService._venue and ConcertService._venue.setShowActive then
				ConcertService._venue.setShowActive(true)
			end
			-- announce
			for _, plr in Players:GetPlayers() do
				toast(plr, "🎸 LIVE at RED ROCKS — the set is starting!", Color3.fromRGB(255, 120, 80))
			end
			task.wait((Config.RedRocks and Config.RedRocks.showLength) or 90)
			ConcertService._showActive = false
			if ConcertService._venue and ConcertService._venue.setShowActive then
				ConcertService._venue.setShowActive(false)
			end
			task.wait(45) -- intermission
		end
	end)
end

local function wireBuy(prompt, tier: string)
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(plr)
		local ok, msg = ConcertService.buyTicket(plr, tier)
		toast(plr, msg, ok and Color3.fromRGB(100, 255, 140) or Color3.fromRGB(255, 160, 80))
	end)
end

function ConcertService.wire(venue)
	ConcertService.bindVenue(venue)
	-- Venue box office
	wireBuy(venue.ticketGAPrompt, "ga")
	wireBuy(venue.ticketVIPPrompt, "vip")
	-- Spawn hub booths
	wireBuy(venue.hubGAPrompt, "ga")
	wireBuy(venue.hubVIPPrompt, "vip")

	if venue.gatePrompt then
		venue.gatePrompt.Triggered:Connect(function(plr)
			local ok, msg = ConcertService.tryEnter(plr)
			toast(plr, msg, ok and Color3.fromRGB(255, 140, 90) or Color3.fromRGB(255, 160, 80))
		end)
	end
	if venue.gatePart then
		local gateCd: { [Player]: number } = {}
		venue.gatePart.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			local plr = model and Players:GetPlayerFromCharacter(model)
			if not plr then
				return
			end
			local now = os.clock()
			if (gateCd[plr] or 0) > now then
				return
			end
			gateCd[plr] = now + 2
			local ok, msg = ConcertService.tryEnter(plr)
			toast(plr, msg, ok and Color3.fromRGB(255, 140, 90) or Color3.fromRGB(255, 160, 80))
		end)
	end
	if venue.exitPrompt then
		venue.exitPrompt.Triggered:Connect(function(plr)
			ConcertService.tryExit(plr)
		end)
	end
	if venue.goToVenuePrompt then
		venue.goToVenuePrompt.Triggered:Connect(function(plr)
			local char = plr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and venue.boxOfficeCF then
				root.CFrame = venue.boxOfficeCF
				toast(plr, "🎸 Red Rocks box office — buy a ticket, then enter the gate!", Color3.fromRGB(255, 160, 90))
			elseif root and venue.exitCF then
				root.CFrame = venue.exitCF
				toast(plr, "🎸 Red Rocks — buy tickets on the glowing pads!", Color3.fromRGB(255, 160, 90))
			end
		end)
	end
	ConcertService.startShowLoop()
end

return ConcertService
