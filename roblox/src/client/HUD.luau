local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Util = require(game.ReplicatedStorage.Shared.Util)

-- Keep Roblox chat out of our HUD (chat defaults to top-left)
local function tuckChatAway()
	pcall(function()
		local conf = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if conf then
			conf.HorizontalAlignment = Enum.HorizontalAlignment.Left
			conf.VerticalAlignment = Enum.VerticalAlignment.Bottom
			if conf.HeightScale ~= nil then
				conf.HeightScale = 0.35
			end
			if conf.WidthScale ~= nil then
				conf.WidthScale = 0.35
			end
		end
	end)
	-- Legacy chat core (if still active)
	pcall(function()
		StarterGui:SetCore("ChatWindowPosition", UDim2.new(0, 8, 0.55, 0))
		StarterGui:SetCore("ChatWindowSize", UDim2.new(0.32, 0, 0.28, 0))
	end)
end

local HUD = {}
HUD._gui = nil
HUD._labels = {}
HUD._shop = nil
HUD._fusion = nil
HUD._toast = nil
HUD._banner = nil
HUD._onBuy = nil
HUD._onFuse = nil
HUD._onRebirth = nil
HUD._combo = nil

local player = Players.LocalPlayer

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, t)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 215, 80)
	s.Thickness = t or 1.2
	s.Transparency = 0.35
	s.Parent = parent
	return s
end

HUD._robux = nil
HUD._index = nil
HUD._onRobuxPass = nil
HUD._onRobuxProduct = nil

function HUD.mount(handlers: { buy: any, fuse: any, rebirth: any, robuxPass: any?, robuxProduct: any? })
	HUD._onBuy = handlers.buy
	HUD._onFuse = handlers.fuse
	HUD._onRebirth = handlers.rebirth
	HUD._onRobuxPass = handlers.robuxPass
	HUD._onRobuxProduct = handlers.robuxProduct

	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("CashEmpireHUD")
	if old then
		old:Destroy()
	end

	tuckChatAway()
	task.defer(tuckChatAway)
	task.delay(2, tuckChatAway)

	local gui = Instance.new("ScreenGui")
	gui.Name = "CashEmpireHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20 -- above most core UI chrome, chat still usable
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
	HUD._gui = gui

	-- TOP-RIGHT stats strip (away from chat on the left)
	local top = Instance.new("Frame")
	top.Name = "TopBar"
	top.AnchorPoint = Vector2.new(1, 0)
	top.Position = UDim2.new(1, -12, 0, 10)
	top.Size = UDim2.fromOffset(640, 52)
	top.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
	top.BackgroundTransparency = 0.2
	top.BorderSizePixel = 0
	top.Parent = gui
	corner(top, 12)
	stroke(top, Color3.fromRGB(80, 80, 110), 1)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 12, 0, 6)
	title.Size = UDim2.new(0, 150, 1, -12)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Text = "👑 " .. Config.GAME_NAME
	title.Parent = top

	local chips = Instance.new("Frame")
	chips.BackgroundTransparency = 1
	chips.Position = UDim2.new(0, 160, 0, 6)
	chips.Size = UDim2.new(1, -168, 1, -12)
	chips.Parent = top
	local chipLayout = Instance.new("UIListLayout")
	chipLayout.FillDirection = Enum.FillDirection.Horizontal
	chipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	chipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	chipLayout.Padding = UDim.new(0, 6)
	chipLayout.Parent = chips

	local function chip(name)
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromOffset(112, 36)
		f.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
		f.Parent = chips
		corner(f, 8)
		stroke(f, Color3.fromRGB(100, 100, 140), 1)
		local t = Instance.new("TextLabel")
		t.Name = "T"
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 12
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = name
		t.Parent = f
		HUD._labels[name] = t
		return f
	end
	chip("Cash")
	chip("Carry")
	chip("Multi")
	chip("Rebirth")

	-- RIGHT-SIDE action column (never under chat)
	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.AnchorPoint = Vector2.new(1, 0.5)
	actions.Position = UDim2.new(1, -14, 0.5, 0)
	actions.Size = UDim2.fromOffset(132, 200)
	actions.BackgroundTransparency = 1
	actions.Parent = gui
	local actLayout = Instance.new("UIListLayout")
	actLayout.Padding = UDim.new(0, 8)
	actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actLayout.Parent = actions

	local function actionBtn(name, text, color, onClick)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.fromOffset(128, 42)
		b.BackgroundColor3 = color
		b.Text = text
		b.Font = Enum.Font.GothamBlack
		b.TextSize = 15
		b.TextColor3 = Color3.new(1, 1, 1)
		b.AutoButtonColor = true
		b.Parent = actions
		corner(b, 10)
		stroke(b, Color3.fromRGB(255, 255, 255), 1)
		b.MouseButton1Click:Connect(onClick)
		return b
	end
	actionBtn("RobuxBtn", "💎 ROBUX", Color3.fromRGB(40, 180, 80), function()
		-- Always open; even with empty state Config catalog is used
		HUD.openRobuxShop(HUD._lastState or { monetization = Config.Monetization, passes = {} })
	end)
	actionBtn("IndexBtn", "📖 INDEX", Color3.fromRGB(200, 160, 40), function()
		HUD.openCoinIndex(HUD._lastState)
	end)

	-- Stack meter — bottom-right (above mobile jump / away from chat)
	local meter = Instance.new("Frame")
	meter.Name = "Meter"
	meter.AnchorPoint = Vector2.new(1, 1)
	meter.Position = UDim2.new(1, -14, 1, -72)
	meter.Size = UDim2.fromOffset(240, 100)
	meter.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
	meter.BackgroundTransparency = 0.12
	meter.Parent = gui
	corner(meter, 12)
	stroke(meter)

	local stackTitle = Instance.new("TextLabel")
	stackTitle.BackgroundTransparency = 1
	stackTitle.Position = UDim2.new(0, 12, 0, 8)
	stackTitle.Size = UDim2.new(1, -24, 0, 20)
	stackTitle.Font = Enum.Font.GothamBold
	stackTitle.TextSize = 13
	stackTitle.TextXAlignment = Enum.TextXAlignment.Left
	stackTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
	stackTitle.Text = "STACK HEIGHT"
	stackTitle.Parent = meter

	local stackVal = Instance.new("TextLabel")
	stackVal.Name = "StackVal"
	stackVal.BackgroundTransparency = 1
	stackVal.Position = UDim2.new(0, 12, 0, 30)
	stackVal.Size = UDim2.new(1, -24, 0, 26)
	stackVal.Font = Enum.Font.GothamBlack
	stackVal.TextSize = 18
	stackVal.TextXAlignment = Enum.TextXAlignment.Left
	stackVal.TextColor3 = Color3.fromRGB(255, 220, 100)
	stackVal.Text = "0 studs"
	stackVal.Parent = meter
	HUD._labels.Stack = stackVal

	local combo = Instance.new("TextLabel")
	combo.Name = "Combo"
	combo.BackgroundTransparency = 1
	combo.Position = UDim2.new(0, 12, 0, 60)
	combo.Size = UDim2.new(1, -24, 0, 28)
	combo.Font = Enum.Font.GothamBlack
	combo.TextSize = 16
	combo.TextXAlignment = Enum.TextXAlignment.Left
	combo.TextColor3 = Color3.fromRGB(255, 120, 200)
	combo.Text = ""
	combo.Parent = meter
	HUD._combo = combo

	-- Short hint — bottom center, above chat bottom
	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -18)
	hint.Size = UDim2.fromOffset(420, 28)
	hint.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
	hint.BackgroundTransparency = 0.35
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 12
	hint.TextColor3 = Color3.fromRGB(200, 200, 215)
	hint.Text = "🎟️ Tickets: green/gold pads at SPAWN (east side) or Red Rocks plaza · E to buy"
	hint.Parent = gui
	corner(hint, 8)

	-- Toast — upper center (below top bar, right of chat)
	local toast = Instance.new("TextLabel")
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.55, 0, 0.12, 0)
	toast.Size = UDim2.fromOffset(480, 40)
	toast.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
	toast.BackgroundTransparency = 0.08
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 15
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Visible = false
	toast.Parent = gui
	corner(toast, 12)
	stroke(toast, Color3.fromRGB(255, 255, 255), 1)
	HUD._toast = toast

	-- Event banner — top center-right
	local banner = Instance.new("TextLabel")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.55, 0, 0.06, 0)
	banner.Size = UDim2.fromOffset(480, 32)
	banner.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
	banner.Font = Enum.Font.GothamBlack
	banner.TextSize = 16
	banner.TextColor3 = Color3.fromRGB(255, 220, 100)
	banner.Visible = false
	banner.Parent = gui
	corner(banner, 10)
	HUD._banner = banner

	-- Shop panels centered
	HUD._shop = HUD._makePanel(gui, "Empire Store", UDim2.fromOffset(460, 500))
	HUD._fusion = HUD._makePanel(gui, "Fusion Lab", UDim2.fromOffset(400, 320))
	HUD._robux = HUD._makePanel(gui, "💎 Robux Shop", UDim2.fromOffset(460, 520))
	HUD._index = HUD._makePanel(gui, "📖 Coin Index", UDim2.fromOffset(480, 520))

	return gui
end

HUD._lastState = nil

function HUD._makePanel(gui, titleText, size)
	local shop = Instance.new("Frame")
	shop.Name = titleText
	shop.AnchorPoint = Vector2.new(0.5, 0.5)
	shop.Position = UDim2.fromScale(0.5, 0.52)
	shop.Size = size
	shop.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
	shop.Visible = false
	shop.Parent = gui
	corner(shop, 14)
	stroke(shop, Color3.fromRGB(255, 200, 80), 1.5)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 16, 0, 10)
	title.Size = UDim2.new(1, -70, 0, 36)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Text = titleText
	title.Parent = shop

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -48, 0, 12)
	close.BackgroundColor3 = Color3.fromRGB(70, 35, 40)
	close.Text = "✕"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.Parent = shop
	corner(close, 8)
	close.MouseButton1Click:Connect(function()
		shop.Visible = false
	end)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.new(0, 12, 0, 54)
	list.Size = UDim2.new(1, -24, 1, -66)
	list.BackgroundTransparency = 1
	list.ScrollBarThickness = 5
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = shop
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 8)
	lay.Parent = list

	return shop
end

function HUD.update(state)
	HUD._lastState = state
	if not HUD._labels.Cash then
		return
	end
	HUD._labels.Cash.Text = "💰 " .. Util.formatNumber(state.cash or 0)
	HUD._labels.Carry.Text = string.format("📦 %d/%d", state.carryCount or 0, state.capacity or 0)
	HUD._labels.Multi.Text = string.format("⚡ x%.2f", state.multi or 1)
	HUD._labels.Rebirth.Text = "♻️ " .. tostring(state.rebirths or 0)
	if HUD._labels.Stack then
		local studs = state.stackHeight or 0
		HUD._labels.Stack.Text = string.format(
			"%.0f studs · %s val · max S%d",
			studs,
			Util.formatNumber(state.carryValue or 0),
			state.maxStory or 1
		)
	end
	if HUD._combo then
		if (state.combo or 0) > 1 then
			HUD._combo.Text = "🔥 COMBO x" .. state.combo .. string.format(" (+%.0f%%)", (state.comboBonus or 0) * 100)
			HUD._combo.Visible = true
		else
			HUD._combo.Text = ""
		end
	end
end

function HUD.toast(msg, color)
	local t = HUD._toast
	if not t then
		return
	end
	t.Text = "  " .. msg
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.Visible = true
	t.TextTransparency = 0
	task.delay(2.6, function()
		if t.Text == "  " .. msg then
			t.Visible = false
		end
	end)
end

function HUD.announce(msg, color)
	local b = HUD._banner
	if not b then
		return
	end
	b.Text = msg
	b.TextColor3 = color or Color3.fromRGB(255, 220, 100)
	b.Visible = true
	task.delay(4, function()
		if b.Text == msg then
			b.Visible = false
		end
	end)
end

local function clearList(list)
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
end

local function rowButton(parent, title, subtitle, btnText, color, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 76)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 48)
	row.Parent = parent
	corner(row, 10)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 12, 0, 8)
	name.Size = UDim2.new(1, -110, 0, 22)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 15
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Text = title
	name.Parent = row

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.new(0, 12, 0, 32)
	desc.Size = UDim2.new(1, -110, 0, 36)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.TextColor3 = Color3.fromRGB(180, 180, 200)
	desc.Text = subtitle
	desc.Parent = row

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.fromOffset(84, 34)
	buy.Position = UDim2.new(1, -96, 0.5, -17)
	buy.BackgroundColor3 = color or Color3.fromRGB(70, 180, 100)
	buy.Text = btnText
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 13
	buy.TextColor3 = Color3.new(1, 1, 1)
	buy.Parent = row
	corner(buy, 8)
	buy.MouseButton1Click:Connect(onClick)
end

function HUD.openShop(catalog, state, _fusions)
	local shop = HUD._shop
	if not shop then
		return
	end
	HUD.update(state)
	local list = shop:FindFirstChild("List")
	clearList(list)

	-- rebirth button on top
	rowButton(list, "♻️ REBIRTH", "Cost " .. Util.formatNumber(state.rebirthCost or 0) .. " Cash · permanent multi · +cap", "GO", Color3.fromRGB(160, 80, 220), function()
		if HUD._onRebirth then
			HUD._onRebirth()
		end
	end)

	for _, item in catalog do
		local cost = "Cost: " .. Util.formatNumber(item.costCash or 0) .. " Cash"
		if item.costCurrency then
			for id, n in item.costCurrency do
				local def = Config.CurrencyById[id]
				cost ..= " + " .. n .. "x " .. (def and def.name or id)
			end
		end
		rowButton(list, item.name, item.description .. "\n" .. cost, "BUY", Color3.fromRGB(70, 180, 110), function()
			if HUD._onBuy then
				HUD._onBuy(item.id)
			end
		end)
	end
	shop.Visible = true
end

function HUD.openFusion(fusions, state)
	local panel = HUD._fusion
	if not panel then
		return
	end
	HUD.update(state)
	local list = panel:FindFirstChild("List")
	clearList(list)
	for _, f in fusions do
		rowButton(list, "⚗️ " .. f.name, f.description, "FUSE", Color3.fromRGB(70, 150, 230), function()
			if HUD._onFuse then
				HUD._onFuse(f.id)
			end
		end)
	end
	panel.Visible = true
end

function HUD.openRobuxShop(state)
	local panel = HUD._robux
	if not panel then
		warn("[HUD] Robux panel missing")
		return
	end
	if state then
		HUD.update(state)
	end
	state = state or HUD._lastState or {}
	local list = panel:FindFirstChild("List")
	if not list then
		warn("[HUD] Robux list missing")
		return
	end
	clearList(list)

	-- Close other panels so this is on top
	if HUD._shop then
		HUD._shop.Visible = false
	end
	if HUD._fusion then
		HUD._fusion.Visible = false
	end
	if HUD._index then
		HUD._index.Visible = false
	end

	local mon = state.monetization or Config.Monetization
	if not mon or not mon.GamePasses then
		mon = Config.Monetization
	end
	local owned = state.passes or {}
	local freeTest = Config.FREE_ROBUX_TEST == true
	local priceTag = freeTest and "FREE TEST" or nil

	rowButton(
		list,
		freeTest and "— TEST MODE: everything is FREE —" or "— ROBUX STORE —",
		freeTest and "Click CLAIM — no Robux charged while testing" or "Powerups · Gear · Fits · Cash packs",
		"OK",
		Color3.fromRGB(40, 100, 60),
		function() end
	)

	local function catHeader(title)
		rowButton(list, title, "", "…", Color3.fromRGB(55, 55, 75), function() end)
	end

	catHeader("— ⚡ POWERUPS (game passes) —")
	for _, gp in mon.GamePasses do
		if (gp.category or "powerup") == "powerup" then
			local have = owned[gp.key]
			local price = priceTag or ("~" .. tostring(gp.robuxHint) .. " R$")
			rowButton(
				list,
				(have and "✅ " or "💎 ") .. gp.name .. " · " .. price,
				gp.description,
				have and "OWNED" or (freeTest and "CLAIM" or "BUY"),
				have and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(40, 180, 90),
				function()
					if not have and HUD._onRobuxPass then
						HUD._onRobuxPass(gp.key)
					end
				end
			)
		end
	end

	catHeader("— 🛡️ GEAR —")
	for _, gp in mon.GamePasses do
		if gp.category == "gear" then
			local have = owned[gp.key]
			local price = priceTag or ("~" .. tostring(gp.robuxHint) .. " R$")
			rowButton(
				list,
				(have and "✅ " or "🛡️ ") .. gp.name .. " · " .. price,
				gp.description,
				have and "OWNED" or (freeTest and "CLAIM" or "BUY"),
				have and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(80, 140, 220),
				function()
					if not have and HUD._onRobuxPass then
						HUD._onRobuxPass(gp.key)
					end
				end
			)
		end
	end
	for _, prod in mon.Products do
		if prod.category == "gear" then
			local price = priceTag or ("~" .. tostring(prod.robuxHint) .. " R$")
			rowButton(
				list,
				"🛡️ " .. prod.name .. " · " .. price,
				prod.description,
				freeTest and "CLAIM" or "BUY",
				Color3.fromRGB(80, 160, 255),
				function()
					if HUD._onRobuxProduct then
						HUD._onRobuxProduct(prod.key)
					end
				end
			)
		end
	end

	catHeader("— 👕 CLOTHING / FITS —")
	for _, prod in mon.Products do
		if prod.category == "clothing" then
			local price = priceTag or ("~" .. tostring(prod.robuxHint) .. " R$")
			rowButton(
				list,
				"👕 " .. prod.name .. " · " .. price,
				prod.description,
				freeTest and "CLAIM" or "BUY",
				Color3.fromRGB(220, 140, 255),
				function()
					if HUD._onRobuxProduct then
						HUD._onRobuxProduct(prod.key)
					end
				end
			)
		end
	end

	catHeader("— 💰 CASH & TOKENS —")
	for _, prod in mon.Products do
		local cat = prod.category or "cash"
		if cat == "cash" or cat == "powerup" then
			local price = priceTag or ("~" .. tostring(prod.robuxHint) .. " R$")
			rowButton(
				list,
				"💰 " .. prod.name .. " · " .. price,
				prod.description,
				freeTest and "CLAIM" or "BUY",
				Color3.fromRGB(255, 180, 40),
				function()
					if HUD._onRobuxProduct then
						HUD._onRobuxProduct(prod.key)
					end
				end
			)
		end
	end

	panel.Visible = true
	panel.ZIndex = 50
	if HUD._gui then
		HUD._gui.Enabled = true
		HUD._gui.DisplayOrder = 50
	end
end

function HUD.openCoinIndex(state)
	local panel = HUD._index
	if not panel then
		return
	end
	state = state or HUD._lastState or {}
	HUD.update(state)
	local list = panel:FindFirstChild("List")
	clearList(list)
	local discovered = state.discovered or {}
	local coins = state.coinIndex or Config.Currencies
	local found = 0
	local total = 0
	for _, c in coins do
		if (c.weight or 0) > 0 or c.id == "zombie_tooth" then
			total += 1
			if discovered[c.id] then
				found += 1
			end
		end
	end
	rowButton(
		list,
		string.format("Discovered %d / %d · Your max story: S%d", found, total, state.maxStory or 1),
		"Higher building floors = rarer coins. Buy Story Gates on your tycoon plot.",
		"OK",
		Color3.fromRGB(80, 80, 100),
		function() end
	)
	-- sort by minStory then rarity
	local sorted = {}
	for _, c in coins do
		table.insert(sorted, c)
	end
	table.sort(sorted, function(a, b)
		local sa = a.minStory or 1
		local sb = b.minStory or 1
		if sa ~= sb then
			return sa < sb
		end
		return (Config.RarityOrder[a.rarity] or 0) < (Config.RarityOrder[b.rarity] or 0)
	end)
	for _, c in sorted do
		if (c.weight or 0) <= 0 and c.id ~= "zombie_tooth" then
			continue
		end
		local known = discovered[c.id]
		local title = known and (c.emoji .. " " .. c.name) or "❓ ????"
		local sub = known
				and string.format(
					"%s · $%s · Story %d+ · %s\n%s",
					c.rarity,
					tostring(c.value),
					c.minStory or 1,
					c.zone,
					c.description or ""
				)
			or string.format("??? · Appears from Story %d · Keep exploring towers!", c.minStory or 1)
		rowButton(list, title, sub, known and "✓" or "?", known and Color3.fromRGB(60, 140, 90) or Color3.fromRGB(70, 70, 80), function() end)
	end
	panel.Visible = true
end

function HUD.closeAll()
	if HUD._shop then
		HUD._shop.Visible = false
	end
	if HUD._fusion then
		HUD._fusion.Visible = false
	end
	if HUD._robux then
		HUD._robux.Visible = false
	end
	if HUD._index then
		HUD._index.Visible = false
	end
end

return HUD
