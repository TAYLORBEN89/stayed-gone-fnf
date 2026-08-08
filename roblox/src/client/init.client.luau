--[[ Cash Empire — client ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local HUD = require(script.HUD)
local CarryVisual = require(script.CarryVisual)
local FX = require(script.FX)
local YZ65Drive = require(script.YZ65Drive)

local player = Players.LocalPlayer
YZ65Drive.start()
local boundFolder: Instance? = nil
local connections: { RBXScriptConnection } = {}

local function disconnectAll()
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
end

local function bindRemotes(remotes: Folder)
	if boundFolder == remotes then
		return
	end
	boundFolder = remotes
	disconnectAll()

	local RE_State = remotes:WaitForChild("State", 10) :: RemoteEvent
	local RE_Toast = remotes:WaitForChild("Toast", 10) :: RemoteEvent
	local RE_OpenShop = remotes:WaitForChild("OpenShop", 10) :: RemoteEvent
	local RE_Announce = remotes:FindFirstChild("Announce") :: RemoteEvent?
	local RE_FX = remotes:FindFirstChild("FX") :: RemoteEvent?
	local RE_OpenFusion = remotes:FindFirstChild("OpenFusion") :: RemoteEvent?
	local RE_OpenIndex = remotes:FindFirstChild("OpenIndex") :: RemoteEvent?
	local RE_OpenRobux = remotes:FindFirstChild("OpenRobux") :: RemoteEvent?
	local RE_Attack = remotes:FindFirstChild("Attack") :: RemoteEvent?
	local RF_Buy = remotes:WaitForChild("Buy", 10) :: RemoteFunction
	local RF_Deposit = remotes:WaitForChild("Deposit", 10) :: RemoteFunction
	local RF_GetState = remotes:WaitForChild("GetState", 10) :: RemoteFunction
	local RF_Rebirth = remotes:FindFirstChild("Rebirth") :: RemoteFunction?
	local RF_Fuse = remotes:FindFirstChild("Fuse") :: RemoteFunction?
	-- Must be RemoteFunctions (not Events) — unique names on server
	local RF_PromptPass = remotes:WaitForChild("PromptPass", 10)
	local RF_PromptProduct = remotes:WaitForChild("PromptProduct", 10)
	if not RF_PromptPass or not RF_PromptPass:IsA("RemoteFunction") then
		warn("[CashEmpire] PromptPass RemoteFunction missing — Robux shop buys will fail")
		RF_PromptPass = nil
	end
	if not RF_PromptProduct or not RF_PromptProduct:IsA("RemoteFunction") then
		warn("[CashEmpire] PromptProduct RemoteFunction missing")
		RF_PromptProduct = nil
	end

	local function applyState(state)
		if state then
			HUD.update(state)
			CarryVisual.setState(state)
		end
	end

	local function refreshState()
		local ok, state = pcall(function()
			return RF_GetState:InvokeServer()
		end)
		if ok then
			applyState(state)
		end
		return ok and state or nil
	end

	HUD.mount({
		buy = function(id)
			local ok, msg, state = RF_Buy:InvokeServer(id)
			applyState(state)
			if msg then
				HUD.toast(tostring(msg), ok and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 120, 120))
			end
		end,
		fuse = function(id)
			if not RF_Fuse then
				return
			end
			local ok, msg, state = RF_Fuse:InvokeServer(id)
			applyState(state)
			if msg then
				HUD.toast(tostring(msg), ok and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(255, 140, 100))
			end
		end,
		rebirth = function()
			if not RF_Rebirth then
				return
			end
			local ok, msg, state = RF_Rebirth:InvokeServer()
			applyState(state)
			if msg then
				HUD.toast(tostring(msg), ok and Color3.fromRGB(200, 140, 255) or Color3.fromRGB(255, 140, 100))
			end
		end,
		robuxPass = function(key)
			if not RF_PromptPass then
				HUD.toast("Robux shop offline — reconnect Rojo / replay", Color3.fromRGB(255, 120, 80))
				return
			end
			local okInvoke, ok, msg, state = pcall(function()
				return RF_PromptPass:InvokeServer(key)
			end)
			if not okInvoke then
				HUD.toast("Buy failed: " .. tostring(ok), Color3.fromRGB(255, 120, 80))
				return
			end
			-- Invoke returns ok, msg, state
			local granted, message, newState = ok, msg, state
			if newState then
				applyState(newState)
			else
				refreshState()
			end
			if message then
				HUD.toast(tostring(message), granted and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 180, 80))
			end
			-- Refresh shop list (OWNED state)
			HUD.openRobuxShop(HUD._lastState)
		end,
		robuxProduct = function(key)
			if not RF_PromptProduct then
				HUD.toast("Robux shop offline — reconnect Rojo / replay", Color3.fromRGB(255, 120, 80))
				return
			end
			local okInvoke, ok, msg, state = pcall(function()
				return RF_PromptProduct:InvokeServer(key)
			end)
			if not okInvoke then
				HUD.toast("Buy failed: " .. tostring(ok), Color3.fromRGB(255, 120, 80))
				return
			end
			local granted, message, newState = ok, msg, state
			if newState then
				applyState(newState)
			else
				refreshState()
			end
			if message then
				HUD.toast(tostring(message), granted and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 180, 80))
			end
			HUD.openRobuxShop(HUD._lastState)
		end,
	})
	CarryVisual.start()

	table.insert(connections, RE_State.OnClientEvent:Connect(applyState))
	table.insert(connections, RE_Toast.OnClientEvent:Connect(function(msg, color)
		HUD.toast(msg, color)
	end))
	table.insert(connections, RE_OpenShop.OnClientEvent:Connect(function(catalog, state, fusions)
		HUD.openShop(catalog, state, fusions)
	end))
	if RE_OpenFusion then
		table.insert(connections, RE_OpenFusion.OnClientEvent:Connect(function(fusions, state)
			HUD.openFusion(fusions, state)
		end))
	end
	if RE_OpenIndex then
		table.insert(connections, RE_OpenIndex.OnClientEvent:Connect(function(state)
			HUD.openCoinIndex(state)
		end))
	end
	if RE_OpenRobux then
		table.insert(connections, RE_OpenRobux.OnClientEvent:Connect(function(state)
			if state then
				applyState(state)
			end
			HUD.openRobuxShop(state or HUD._lastState)
		end))
	end
	if RE_Announce then
		table.insert(connections, RE_Announce.OnClientEvent:Connect(function(msg, color)
			HUD.announce(msg, color)
		end))
	end
	if RE_FX then
		table.insert(connections, RE_FX.OnClientEvent:Connect(function(kind, color)
			if kind == "open_robux" then
				HUD.openRobuxShop(HUD._lastState)
				return
			end
			FX.play(kind, color)
		end))
	end

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			local ok, msg, state = RF_Deposit:InvokeServer()
			applyState(state)
			if msg then
				HUD.toast(tostring(msg), ok and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 160, 80))
			end
		elseif input.KeyCode == Enum.KeyCode.X then
			HUD.closeAll()
		elseif input.KeyCode == Enum.KeyCode.B then
			-- Quick open Robux shop
			local st = refreshState()
			HUD.openRobuxShop(st or HUD._lastState)
		elseif input.KeyCode == Enum.KeyCode.R then
			if RF_Rebirth then
				local ok, msg, state = RF_Rebirth:InvokeServer()
				applyState(state)
				if msg then
					HUD.toast(tostring(msg), ok and Color3.fromRGB(200, 140, 255) or Color3.fromRGB(255, 140, 100))
				end
			end
		elseif input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if RE_Attack then
				RE_Attack:FireServer()
			end
		end
	end))

	task.spawn(function()
		local state = refreshState()
		HUD.toast("👑 " .. Config.GAME_NAME .. " — " .. Config.TAGLINE, Color3.fromRGB(255, 220, 100))
		if Config.FREE_ROBUX_TEST then
			task.delay(1.5, function()
				HUD.toast("💎 Press B or ROBUX button — shop is FREE in test", Color3.fromRGB(100, 255, 140))
			end)
		end
		local _ = state
	end)

	print("[CashEmpire] Client bound remotes · PromptPass=" .. tostring(RF_PromptPass ~= nil))
end

local remotes = ReplicatedStorage:FindFirstChild("CashStackRemotes")
if remotes and remotes:IsA("Folder") then
	bindRemotes(remotes)
else
	task.spawn(function()
		local r = ReplicatedStorage:WaitForChild("CashStackRemotes", 90)
		if r and r:IsA("Folder") then
			bindRemotes(r)
		end
	end)
end

ReplicatedStorage.ChildAdded:Connect(function(child)
	if child.Name == "CashStackRemotes" and child:IsA("Folder") then
		task.wait(0.15)
		boundFolder = nil -- force rebind to new folder
		bindRemotes(child)
	end
end)

print("[CashEmpire] Client " .. Config.VERSION)
