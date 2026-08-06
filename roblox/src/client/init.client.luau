-- Client bootstrap (runs for each player)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)
local player = Players.LocalPlayer

print(`[Client] {Hello.greet(player.Name)}`)
print(`[Client] {Hello.Tagline} — edit files in /roblox/src and they sync via Rojo`)
