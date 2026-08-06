-- Server bootstrap (runs on the server only)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)

print(`[Server] {Hello.GameName} — Rojo bridge online`)

Players.PlayerAdded:Connect(function(player)
	print(Hello.greet(player.Name))
end)
