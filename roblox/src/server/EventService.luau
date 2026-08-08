local Config = require(game.ReplicatedStorage.Shared.Config)
local Util = require(game.ReplicatedStorage.Shared.Util)
local CollectibleService = require(script.Parent.CollectibleService)

local EventService = {}
EventService._active = nil :: any
EventService._onAnnounce = nil :: ((string, Color3) -> ())?

function EventService.get()
	return EventService._active
end

function EventService.setAnnounce(fn)
	EventService._onAnnounce = fn
end

function EventService.start()
	task.spawn(function()
		while true do
			task.wait(90 + math.random(0, 60))
			local ev = Util.weightedChoice(Config.Events, "weight")
			EventService._active = {
				id = ev.id,
				name = ev.name,
				multi = ev.multi or 1,
				zoneBoost = ev.zoneBoost,
				mythicBoost = ev.mythicBoost,
				color = ev.color,
				endsAt = os.clock() + ev.duration,
			}
			CollectibleService.setEvent(EventService._active)
			if EventService._onAnnounce then
				EventService._onAnnounce("⚡ EVENT: " .. ev.name .. " (" .. ev.duration .. "s)", ev.color)
			end
			task.wait(ev.duration)
			EventService._active = nil
			CollectibleService.setEvent(nil)
			if EventService._onAnnounce then
				EventService._onAnnounce("Event ended.", Color3.fromRGB(180, 180, 200))
			end
		end
	end)
end

return EventService
