--[[
	Cash Empire v4 world
	- Spawn hub far SW corner: shop, fusion, rebirth, claim, portals, chests
	- Gate out into the open world
	- 8 mega-bases on map edges (different biomes)
	- Hills, rivers, mountains, desert via Terrain + parts
]]

local CollectionService = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function label(parent: BasePart, text: string, color: Color3?, yOff: number?, maxDist: number?, alwaysOnTop: boolean?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PadLabel"
	gui.Size = UDim2.fromOffset(220, 52)
	gui.StudsOffset = Vector3.new(0, yOff or (parent.Size.Y / 2 + 2.2), 0)
	gui.AlwaysOnTop = alwaysOnTop == true
	gui.MaxDistance = maxDist or Config.LABEL_DISTANCE_PAD or 50
	gui.LightInfluence = 0.35
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.35
	t.Text = text
	t.Parent = gui
	return t
end

local function markWalkover(p: BasePart, baseTransparency: number?)
	local t = baseTransparency or 0
	p:SetAttribute("Walkover", true)
	p:SetAttribute("BaseTransparency", t)
	p.Transparency = t
	CollectionService:AddTag(p, "WalkoverPad")
end

--[[
	Building with sign on the FRONT face, oriented to face `faceToward` (e.g. main bank).
	`groundPos` = center of footprint on the ground. Returns body + front direction (flat unit).
]]
local function signBuilding(
	parent: Instance,
	groundPos: Vector3,
	size: Vector3,
	color: Color3,
	signText: string,
	faceToward: Vector3?,
	signColor: Color3?
): (Part, Vector3)
	local target = faceToward or (groundPos + Vector3.new(0, 0, 1))
	local flat = Vector3.new(target.X - groundPos.X, 0, target.Z - groundPos.Z)
	local front = if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(0, 0, 1)

	-- CFrame.lookAt: LookVector (-Z) points at target → front of building faces bank
	local bodyCenter = groundPos + Vector3.new(0, size.Y / 2, 0)
	local bodyCF = CFrame.lookAt(bodyCenter, bodyCenter + front)

	local body = part({
		Name = "Bld",
		Size = size,
		Color = color,
		Material = Enum.Material.Brick,
		Parent = parent,
	})
	body.CFrame = bodyCF

	local roof = part({
		Name = "Roof",
		Size = Vector3.new(size.X + 2, 1.5, size.Z + 2),
		Color = Color3.fromRGB(50, 40, 35),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	roof.CFrame = bodyCF * CFrame.new(0, size.Y / 2 + 0.8, 0)

	-- Sign on front face (local -Z = toward bank)
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(math.min(size.X * 0.9, 22), 6, 0.6),
		Color = Color3.fromRGB(30, 30, 40),
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})
	sign.CFrame = bodyCF * CFrame.new(0, size.Y * 0.15, -(size.Z / 2 + 0.35))
	label(sign, signText, signColor or Color3.fromRGB(255, 220, 100), 0.2, 70, false)
	return body, front
end

--[[
	Custom mega-estate: open side faces map center, closed back toward map edge.
	Rooms left/right + courtyard, bridge walkways, dojo hut, elevators with story gates.
]]
local function customMegaBase(
	parent: Instance,
	origin: Vector3,
	stories: number,
	footprint: Vector3,
	wallColor: Color3,
	name: string,
	layout: string?
): { { story: number, pos: Vector3 } }
	local spawns = {}
	local H = Config.STORY_HEIGHT
	local w, d = footprint.X, footprint.Z
	layout = layout or "default"

	-- Open side faces map center (0,0,0); back wall faces outward
	local towardCenter = Vector3.new(-origin.X, 0, -origin.Z)
	if towardCenter.Magnitude < 0.1 then
		towardCenter = Vector3.new(0, 0, -1)
	else
		towardCenter = towardCenter.Unit
	end
	local right = Vector3.new(-towardCenter.Z, 0, towardCenter.X)
	-- CF: local -Z = toward center (open face)
	local baseCF = CFrame.lookAt(origin, origin + towardCenter)

	local function localToWorld(lx: number, ly: number, lz: number): Vector3
		return (baseCF * CFrame.new(lx, ly, lz)).Position
	end
	local function place(props, lx, ly, lz, lookYaw: number?)
		local p = part(props)
		local cf = baseCF * CFrame.new(lx, ly, lz)
		if lookYaw then
			cf = cf * CFrame.Angles(0, lookYaw, 0)
		end
		p.CFrame = cf
		return p
	end

	-- Layout offsets (local space: X = right, Z = toward center is -Z)
	local roomW = w * 0.32
	local roomD = d * 0.38
	local roomX = w * 0.28 -- left/right rooms
	local roomZ = d * 0.08 -- slightly toward center
	local courtW = w * 0.36
	local courtD = d * 0.42
	local backZ = d * 0.32 -- closed back (positive local Z = away from center)

	local matFloor = Enum.Material.Concrete
	local matWall = Enum.Material.Brick
	local matBridge = Enum.Material.Wood
	local hutColor = Color3.fromRGB(160, 120, 70)
	if layout == "sand" then
		matFloor = Enum.Material.Sandstone
		matWall = Enum.Material.Sandstone
		hutColor = Color3.fromRGB(230, 200, 140)
	elseif layout == "frost" then
		matFloor = Enum.Material.Ice
		matWall = Enum.Material.Glacier
		hutColor = Color3.fromRGB(200, 230, 255)
	elseif layout == "pine" then
		matFloor = Enum.Material.WoodPlanks
		matWall = Enum.Material.Wood
		hutColor = Color3.fromRGB(90, 140, 70)
	elseif layout == "river" then
		matFloor = Enum.Material.Concrete
		matBridge = Enum.Material.WoodPlanks
		hutColor = Color3.fromRGB(80, 130, 160)
	elseif layout == "obsidian" then
		matFloor = Enum.Material.Basalt
		matWall = Enum.Material.Slate
		hutColor = Color3.fromRGB(40, 30, 50)
	elseif layout == "storm" then
		matFloor = Enum.Material.Slate
		matWall = Enum.Material.Rock
		hutColor = Color3.fromRGB(90, 100, 140)
	elseif layout == "crystal" then
		matFloor = Enum.Material.Foil
		matWall = Enum.Material.Glass
		hutColor = Color3.fromRGB(180, 120, 255)
	elseif layout == "gold" then
		matFloor = Enum.Material.Ground
		matWall = Enum.Material.Brick
		hutColor = Color3.fromRGB(200, 170, 60)
	end

	for story = 1, stories do
		local yBase = (story - 1) * H
		local wallH = H - 2
		local floorCol = story == 1 and Color3.fromRGB(95, 95, 105)
			or Color3.fromRGB(70 + story * 14, 70 + story * 4, 90)

		-- Courtyard floor (center)
		local court = place({
			Name = name .. "_Court_S" .. story,
			Size = Vector3.new(courtW, 1.2, courtD),
			Color = floorCol,
			Material = matFloor,
			Parent = parent,
		}, 0, yBase + 0.6, -d * 0.05)
		court:SetAttribute("Story", story)
		label(court, Config.StoryLabels[story] or ("Story " .. story), Color3.fromRGB(255, 240, 150), 2, 55)

		-- Left room
		local left = place({
			Name = name .. "_RoomL_S" .. story,
			Size = Vector3.new(roomW, 1.2, roomD),
			Color = floorCol,
			Material = matFloor,
			Parent = parent,
		}, -roomX, yBase + 0.6, -roomZ)
		left:SetAttribute("Story", story)

		-- Right room
		local rightRoom = place({
			Name = name .. "_RoomR_S" .. story,
			Size = Vector3.new(roomW, 1.2, roomD),
			Color = floorCol,
			Material = matFloor,
			Parent = parent,
		}, roomX, yBase + 0.6, -roomZ)
		rightRoom:SetAttribute("Story", story)

		-- Back closed wall (map edge side)
		place({
			Name = "BackWall",
			Size = Vector3.new(w * 0.92, wallH, 1.4),
			Color = wallColor,
			Material = matWall,
			Parent = parent,
		}, 0, yBase + wallH / 2 + 1.2, backZ)

		-- Side walls (partial — leave open toward center)
		place({
			Name = "SideL",
			Size = Vector3.new(1.4, wallH, d * 0.55),
			Color = wallColor,
			Material = matWall,
			Parent = parent,
		}, -w / 2 + 1, yBase + wallH / 2 + 1.2, backZ * 0.35)
		place({
			Name = "SideR",
			Size = Vector3.new(1.4, wallH, d * 0.55),
			Color = wallColor,
			Material = matWall,
			Parent = parent,
		}, w / 2 - 1, yBase + wallH / 2 + 1.2, backZ * 0.35)

		-- Room dividers with door gaps (short walls)
		place({
			Name = "DivL",
			Size = Vector3.new(1.2, wallH * 0.85, roomD * 0.55),
			Color = wallColor:Lerp(Color3.new(0, 0, 0), 0.15),
			Material = matWall,
			Parent = parent,
		}, -roomX + roomW * 0.35, yBase + wallH * 0.45 + 1.2, -roomZ + roomD * 0.15)
		place({
			Name = "DivR",
			Size = Vector3.new(1.2, wallH * 0.85, roomD * 0.55),
			Color = wallColor:Lerp(Color3.new(0, 0, 0), 0.15),
			Material = matWall,
			Parent = parent,
		}, roomX - roomW * 0.35, yBase + wallH * 0.45 + 1.2, -roomZ + roomD * 0.15)

		-- Bridge walkway left ↔ right across courtyard
		local bridge = place({
			Name = "Bridge_S" .. story,
			Size = Vector3.new(roomX * 2 - roomW * 0.3, 1.0, 10),
			Color = Color3.fromRGB(140, 105, 70),
			Material = matBridge,
			Parent = parent,
		}, 0, yBase + 1.5, -roomZ - 2)
		bridge:SetAttribute("Story", story)
		label(bridge, "🌉 Bridge S" .. story, Color3.fromRGB(255, 220, 160), 1.5, 40)

		-- Bridge railings
		place({
			Name = "Rail",
			Size = Vector3.new(bridge.Size.X, 2.5, 0.5),
			Color = Color3.fromRGB(90, 70, 50),
			Material = matBridge,
			Parent = parent,
		}, 0, yBase + 3.2, -roomZ - 2 - 5)
		place({
			Name = "Rail",
			Size = Vector3.new(bridge.Size.X, 2.5, 0.5),
			Color = Color3.fromRGB(90, 70, 50),
			Material = matBridge,
			Parent = parent,
		}, 0, yBase + 3.2, -roomZ - 2 + 5)

		-- Second walkway toward open side (gallery)
		place({
			Name = "Gallery_S" .. story,
			Size = Vector3.new(w * 0.55, 1.0, 8),
			Color = Color3.fromRGB(120, 100, 75),
			Material = matBridge,
			Parent = parent,
		}, 0, yBase + 1.5, -d * 0.28)

		-- Dojo hut (front open side, every floor gets a small hut / pavilion)
		local hutSize = Vector3.new(18 + story, 10 + story * 0.5, 16)
		local hutZ = -d * 0.38
		place({
			Name = "DojoHut_S" .. story,
			Size = hutSize,
			Color = hutColor,
			Material = Enum.Material.Wood,
			Parent = parent,
		}, (story % 2 == 0 and -1 or 1) * (w * 0.12), yBase + hutSize.Y / 2 + 1.2, hutZ)
		-- hut roof
		place({
			Name = "DojoRoof",
			Size = Vector3.new(hutSize.X + 3, 1.2, hutSize.Z + 3),
			Color = Color3.fromRGB(80, 50, 40),
			Material = Enum.Material.Slate,
			Parent = parent,
		}, (story % 2 == 0 and -1 or 1) * (w * 0.12), yBase + hutSize.Y + 1.8, hutZ)
		label(
			place({
				Name = "DojoPad",
				Size = Vector3.new(10, 0.8, 10),
				Color = Color3.fromRGB(200, 160, 90),
				Material = Enum.Material.Fabric,
				Parent = parent,
			}, (story % 2 == 0 and -1 or 1) * (w * 0.12), yBase + 1.6, hutZ),
			"🏯 Dojo S" .. story,
			Color3.fromRGB(255, 230, 180),
			2,
			45
		)

		-- Open front: low railing only (faces map center) so building is accessible
		place({
			Name = "OpenRail",
			Size = Vector3.new(w * 0.7, 2.2, 0.8),
			Color = wallColor,
			Material = matWall,
			Transparency = 0.25,
			Parent = parent,
		}, 0, yBase + 2.2, -d / 2 + 2)

		-- Elevators in courtyard (easy to find) — TargetY is WORLD height
		local elevLX, elevLZ = -18, -d * 0.05
		local floorStandY = function(storyNum: number): number
			-- stand height on that story's floor surface
			return (baseCF * CFrame.new(0, (storyNum - 1) * H + 5, 0)).Position.Y
		end
		if story < stories then
			local up = place({
				Name = "ElevatorUp",
				Size = Vector3.new(14, 1.8, 14),
				Color = Color3.fromRGB(80, 180, 255),
				Material = Enum.Material.Neon,
				Parent = parent,
				CanTouch = true,
				CanCollide = true,
			}, elevLX, yBase + 1.6, elevLZ)
			up:SetAttribute("Elevator", true)
			up:SetAttribute("ElevatorDir", "up")
			up:SetAttribute("FromStory", story)
			up:SetAttribute("ToStory", story + 1)
			up:SetAttribute("TargetY", floorStandY(story + 1))
			up:SetAttribute("RequiredStory", 1) -- travel free; loot still gated by maxStory
			label(up, "⬆ ELEVATOR\nFloor " .. (story + 1), Color3.fromRGB(200, 240, 255), 2.5, 60, true)
			local upPrompt = Instance.new("ProximityPrompt")
			upPrompt.Name = "ElevatorPrompt"
			upPrompt.ActionText = "Go up"
			upPrompt.ObjectText = "Floor " .. (story + 1)
			upPrompt.HoldDuration = 0
			upPrompt.MaxActivationDistance = 16
			upPrompt.RequiresLineOfSight = false
			upPrompt.Parent = up
		end
		if story > 1 then
			local down = place({
				Name = "ElevatorDown",
				Size = Vector3.new(14, 1.8, 14),
				Color = Color3.fromRGB(255, 160, 80),
				Material = Enum.Material.Neon,
				Parent = parent,
				CanTouch = true,
				CanCollide = true,
			}, elevLX + 16, yBase + 1.6, elevLZ)
			down:SetAttribute("Elevator", true)
			down:SetAttribute("ElevatorDir", "down")
			down:SetAttribute("FromStory", story)
			down:SetAttribute("ToStory", story - 1)
			down:SetAttribute("TargetY", floorStandY(story - 1))
			down:SetAttribute("RequiredStory", 1)
			label(down, "⬇ ELEVATOR\nFloor " .. (story - 1), Color3.fromRGB(255, 220, 180), 2.5, 60, true)
			local downPrompt = Instance.new("ProximityPrompt")
			downPrompt.Name = "ElevatorPrompt"
			downPrompt.ActionText = "Go down"
			downPrompt.ObjectText = "Floor " .. (story - 1)
			downPrompt.HoldDuration = 0
			downPrompt.MaxActivationDistance = 16
			downPrompt.RequiresLineOfSight = false
			downPrompt.Parent = down
		end

		-- Spiral ramp on right side (accessible path)
		if story < stories then
			local rampLen = math.clamp(H * 2.2, 28, 48)
			local ramp = part({
				Name = "Ramp",
				Size = Vector3.new(12, 1.3, rampLen),
				Material = matBridge,
				Color = Color3.fromRGB(130, 100, 65),
				Parent = parent,
			})
			local angle = math.atan2(H, rampLen * 0.9)
			local rampOrigin = localToWorld(w * 0.38, yBase + 0.7, -d * 0.15)
			ramp.CFrame = CFrame.lookAt(rampOrigin, rampOrigin + towardCenter)
				* CFrame.Angles(-angle, 0, 0)
				* CFrame.new(0, 0, -rampLen / 2)
			ramp:SetAttribute("RequiredStory", story + 1)
		end

		-- Loot spawns: more denser and higher value on upper floors
		local nSpawns = math.clamp(6 + story * 4, 8, 28)
		local spots = {
			{ 0, -d * 0.05 },
			{ -roomX, -roomZ },
			{ roomX, -roomZ },
			{ 0, -roomZ - 2 },
			{ -w * 0.12, -d * 0.38 },
			{ w * 0.12, -d * 0.28 },
			{ 0, -d * 0.22 },
			{ -roomX * 0.5, -roomZ * 0.5 },
			{ roomX * 0.5, -roomZ * 0.5 },
		}
		for i = 1, nSpawns do
			local spot = spots[((i - 1) % #spots) + 1]
			local jx = (math.random() - 0.5) * 10
			local jz = (math.random() - 0.5) * 8
			table.insert(spawns, {
				story = story,
				pos = localToWorld(spot[1] + jx, yBase + 3.2, spot[2] + jz),
			})
		end
	end

	-- Roof deck
	place({
		Name = name .. "_Roof",
		Size = Vector3.new(w * 0.7, 1.5, d * 0.55),
		Color = Color3.fromRGB(70, 40, 40),
		Material = Enum.Material.Slate,
		Parent = parent,
	}, 0, stories * H + 1, -d * 0.05)

	return spawns
end

--[[ Wedge ramp: smooth drive surface, no bottom lip (hypotenuse is the road). ]]
local function wedgePart(props: { [string]: any }): WedgePart
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.CastShadow = true
	for k, v in props do
		(w :: any)[k] = v
	end
	return w
end

--[[
	Dirtbike jump: flush approach → wedge takeoff → thin boost (no collide) → gap → wedge landing.
	No bottom lips: wedges start at ground level.
]]
local function buildDirtJump(
	parent: Instance,
	origin: Vector3,
	yaw: number,
	opts: { width: number?, rampLen: number?, height: number?, gap: number?, boost: number?, name: string? }?
): { BasePart }
	opts = opts or {}
	local width = opts.width or 24
	local rampLen = opts.rampLen or 48
	local height = opts.height or 14
	local gap = opts.gap or 34
	local boostPower = opts.boost or 160
	local name = opts.name or "DirtJump"
	local boostParts = {}

	-- cf: origin at ground; -Z is jump direction
	local cf = CFrame.new(origin) * CFrame.Angles(0, yaw, 0)
	local groundY = 0.15 -- slight above terrain

	-- Long flush approach (thin, half-buried feel — top is driveable)
	local approachLen = 36
	local approach = part({
		Name = name .. "_Approach",
		Size = Vector3.new(width, 1.0, approachLen),
		Color = Color3.fromRGB(90, 75, 55),
		Material = Enum.Material.Ground,
		Parent = parent,
	})
	-- Top surface ~ groundY + 0.5
	approach.CFrame = cf * CFrame.new(0, groundY + 0.5, approachLen / 2)

	-- Takeoff = WedgePart: Size Y = height, Size Z = length; slope faces -Z after rotation
	-- Wedge default: slope goes from high +Z to low -Z on top when oriented correctly
	local takeoff = wedgePart({
		Name = name .. "_Takeoff",
		Size = Vector3.new(width, height, rampLen),
		Color = Color3.fromRGB(115, 95, 65),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	-- Place so low edge sits on approach (no step). Center of wedge at mid height/length.
	-- Rotate 180° yaw so slope rises toward -Z (launch)
	takeoff.CFrame = cf
		* CFrame.new(0, groundY + height / 2, -rampLen / 2)
		* CFrame.Angles(0, math.pi, 0)

	-- Thin flush transition plate between approach and wedge low edge
	local blend = part({
		Name = name .. "_Blend",
		Size = Vector3.new(width, 0.6, 6),
		Color = Color3.fromRGB(100, 85, 55),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	blend.CFrame = cf * CFrame.new(0, groundY + 0.35, 1)

	-- Side rails (visual only, thin, outside track — won't snag centerline)
	for _, side in { -1, 1 } do
		local rail = part({
			Name = "Rail",
			Size = Vector3.new(0.8, height * 0.55, rampLen * 0.9),
			Color = Color3.fromRGB(70, 55, 40),
			Material = Enum.Material.Wood,
			Parent = parent,
			CanCollide = false,
		})
		rail.CFrame = cf * CFrame.new(side * (width / 2 + 0.6), groundY + height * 0.4, -rampLen / 2)
	end

	-- BOOST at lip: NO collide so it never obstructs the bike; CanTouch for boost
	local lip = part({
		Name = name .. "_BoostLip",
		Size = Vector3.new(width * 0.9, 4, 12),
		Color = Color3.fromRGB(255, 90, 30),
		Material = Enum.Material.Neon,
		Parent = parent,
		CanCollide = false,
		CanTouch = true,
		Transparency = 0.25,
	})
	-- Hover just above the high end of the wedge
	lip.CFrame = cf * CFrame.new(0, groundY + height + 1.5, -rampLen + 4)
	lip:SetAttribute("JumpBoost", true)
	lip:SetAttribute("BoostPower", boostPower)
	lip:SetAttribute("BoostUp", boostPower * 0.45)
	CollectionService:AddTag(lip, "JumpBoost")
	label(lip, "🚀 BOOST\nFull speed!", Color3.fromRGB(255, 240, 120), 2, 90, true)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Brightness = 3
	light.Range = 28
	light.Parent = lip
	table.insert(boostParts, lip)

	-- Landing wedge (mirror): slope down into ground, flush outrun
	local landLen = rampLen * 0.9
	local landH = height * 0.75
	local land = wedgePart({
		Name = name .. "_Landing",
		Size = Vector3.new(width + 2, landH, landLen),
		Color = Color3.fromRGB(100, 85, 55),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	-- High edge toward gap, low edge toward outrun (+Z relative to jump dir is back...)
	-- Jump dir is -Z. Landing sits past gap at more negative Z.
	-- Want slope facing so you land from +Z side of landing wedge (from gap) going to -Z.
	land.CFrame = cf
		* CFrame.new(0, groundY + landH / 2, -rampLen - gap - landLen / 2)
		* CFrame.Angles(0, 0, 0) -- default wedge: high at +Z, low at -Z → good for landing from gap (from +Z)

	local flat = part({
		Name = name .. "_Outrun",
		Size = Vector3.new(width + 4, 1.0, 32),
		Color = Color3.fromRGB(85, 70, 50),
		Material = Enum.Material.Ground,
		Parent = parent,
	})
	flat.CFrame = cf * CFrame.new(0, groundY + 0.5, -rampLen - gap - landLen - 16)

	local flag = part({
		Name = "JumpFlag",
		Size = Vector3.new(1.0, 16, 1.0),
		Color = Color3.fromRGB(220, 50, 40),
		Material = Enum.Material.Metal,
		Parent = parent,
		CanCollide = false,
	})
	flag.CFrame = cf * CFrame.new(width / 2 + 5, 8, -rampLen / 2)
	label(flag, "🏍️ " .. name, Color3.fromRGB(255, 200, 80), 9, 120, true)

	return boostParts
end

--[[ Soft driveable mound — ball centers below ground so base slopes gently. ]]
local function softHill(terrain: Terrain, x: number, z: number, radius: number, material: Enum.Material)
	-- Large base ball buried → gentle skirt; smaller top for height
	terrain:FillBall(Vector3.new(x, -radius * 0.55, z), radius * 1.25, material)
	terrain:FillBall(Vector3.new(x, -radius * 0.25, z), radius * 0.85, material)
	terrain:FillBall(Vector3.new(x, radius * 0.05, z), radius * 0.45, material)
end

--[[
	RED ROCKS AMPHITHEATRE (Morrison, CO inspired)
	- Creation Rock (N) + Ship Rock (S) flank the bowl
	- Stage carved into Stage Rock (east / downhill end)
	- Sandstone tier seating rising west, packed with crowd NPCs
	- Box office + ticket gate outside
]]
local function buildRedRocks(parent: Instance): any
	local rr = Config.RedRocks or {}
	local center = rr.center or Vector3.new(280, 0, -280)
	local folder = Instance.new("Folder")
	folder.Name = "RedRocksAmphitheatre"
	folder.Parent = parent

	local red = Color3.fromRGB(168, 72, 48)
	local redDark = Color3.fromRGB(120, 48, 32)
	local redLite = Color3.fromRGB(190, 95, 60)
	local sand = Color3.fromRGB(175, 120, 85)
	local stageGrey = Color3.fromRGB(50, 50, 58)

	-- Clear / red rock terrain under venue
	local terrain = workspace.Terrain
	terrain:FillBlock(CFrame.new(center.X, -3, center.Z), Vector3.new(420, 12, 480), Enum.Material.Sandstone)
	terrain:FillBlock(CFrame.new(center.X, -2, center.Z), Vector3.new(300, 10, 360), Enum.Material.Rock)

	-- Bowl faces +Z toward stage rock (stage at +Z end of amphitheater)
	-- Seating rises toward -Z (uphill / "west" in our layout)
	local stagePos = center + Vector3.new(0, 4, 95)

	-- ── Creation Rock (north monolith) ──
	local function monolith(name: string, offset: Vector3, size: Vector3, tilt: number)
		local rock = part({
			Name = name,
			Size = size,
			Color = red,
			Material = Enum.Material.Sandstone,
			Parent = folder,
		})
		rock.CFrame = CFrame.new(center + offset + Vector3.new(0, size.Y / 2 - 4, 0))
			* CFrame.Angles(0, 0, math.rad(tilt))
		-- jagged extra slabs
		for i = 1, 4 do
			local slab = part({
				Name = name .. "_Slab",
				Size = Vector3.new(size.X * (0.4 + math.random() * 0.4), size.Y * (0.3 + math.random() * 0.4), size.Z * 0.35),
				Color = (i % 2 == 0) and redDark or redLite,
				Material = Enum.Material.Sandstone,
				Parent = folder,
			})
			slab.CFrame = rock.CFrame
				* CFrame.new((math.random() - 0.5) * size.X * 0.4, (math.random() - 0.3) * size.Y * 0.3, (math.random() - 0.5) * 8)
				* CFrame.Angles(math.rad(math.random(-12, 12)), math.rad(math.random(-20, 20)), math.rad(math.random(-10, 10)))
		end
		return rock
	end

	-- Creation Rock ~ north (taller)
	monolith("CreationRock", Vector3.new(-95, 0, 20), Vector3.new(55, 140, 70), -8)
	-- Ship Rock ~ south
	monolith("ShipRock", Vector3.new(95, 0, 25), Vector3.new(50, 110, 65), 10)
	-- Stage Rock ~ behind stage (carved canyon face)
	monolith("StageRock", Vector3.new(0, 0, 130), Vector3.new(140, 95, 50), 0)
	-- Extra canyon walls
	monolith("CanyonN", Vector3.new(-70, 0, 90), Vector3.new(40, 80, 55), -15)
	monolith("CanyonS", Vector3.new(70, 0, 90), Vector3.new(40, 75, 55), 12)

	-- Stage floor carved into Stage Rock
	local stage = part({
		Name = "Stage",
		Size = Vector3.new(90, 2.5, 40),
		Position = stagePos,
		Color = stageGrey,
		Material = Enum.Material.Concrete,
		Parent = folder,
	})
	label(stage, "🎸 STAGE\nCarved into Stage Rock", Color3.fromRGB(255, 200, 120), 6, 120, true)

	-- Stage roof canopy (modern Red Rocks-style open canopy)
	local canopy = part({
		Name = "StageCanopy",
		Size = Vector3.new(100, 2, 48),
		Color = Color3.fromRGB(35, 35, 42),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	canopy.CFrame = CFrame.new(stagePos + Vector3.new(0, 22, -2)) * CFrame.Angles(math.rad(-6), 0, 0)
	for _, sx in { -40, 40 } do
		part({
			Name = "CanopyColumn",
			Size = Vector3.new(3, 22, 3),
			Position = stagePos + Vector3.new(sx, 11, 12),
			Color = Color3.fromRGB(40, 40, 48),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end

	-- Stage lights + speaker stacks
	local showLights = {}
	for i = -3, 3 do
		local lightBar = part({
			Name = "LightBar",
			Size = Vector3.new(8, 1.5, 2),
			Position = stagePos + Vector3.new(i * 12, 18, -8),
			Color = Color3.fromRGB(255, 80, 40),
			Material = Enum.Material.Neon,
			Parent = folder,
			CanCollide = false,
		})
		local pl = Instance.new("PointLight")
		pl.Brightness = 2
		pl.Range = 40
		pl.Color = Color3.fromRGB(255, 100, 60)
		pl.Parent = lightBar
		table.insert(showLights, lightBar)
	end
	for _, side in { -38, 38 } do
		part({
			Name = "SpeakerStack",
			Size = Vector3.new(8, 16, 6),
			Position = stagePos + Vector3.new(side, 9, 5),
			Color = Color3.fromRGB(25, 25, 30),
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
		})
	end

	-- Simple band on stage
	for i, off in {
		Vector3.new(0, 4, 0),
		Vector3.new(-12, 4, 4),
		Vector3.new(12, 4, 4),
		Vector3.new(-22, 4, -4),
		Vector3.new(22, 4, -4),
	} do
		local body = part({
			Name = "Performer",
			Size = Vector3.new(2.2, 4.5, 1.4),
			Position = stagePos + off,
			Color = Color3.fromRGB(30 + i * 20, 30, 40),
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
			CanCollide = false,
		})
		part({
			Name = "Head",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 1.6, 1.6),
			Position = body.Position + Vector3.new(0, 3.2, 0),
			Color = Color3.fromRGB(230, 190, 150),
			Parent = folder,
			CanCollide = false,
		})
	end

	-- Sandstone seating bowl: many tiers rising away from stage (-Z)
	local crowdFolder = Instance.new("Folder")
	crowdFolder.Name = "Crowd"
	crowdFolder.Parent = folder

	local function makePerson(pos: Vector3, hue: number)
		local torso = part({
			Name = "Fan",
			Size = Vector3.new(1.4, 2.2, 1.0),
			Position = pos + Vector3.new(0, 1.4, 0),
			Color = Color3.fromHSV(hue, 0.55, 0.55 + math.random() * 0.35),
			Material = Enum.Material.SmoothPlastic,
			Parent = crowdFolder,
			CanCollide = false,
			CastShadow = false,
		})
		part({
			Name = "Head",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.15, 1.15, 1.15),
			Position = pos + Vector3.new(0, 3.0, 0),
			Color = Color3.fromRGB(210 + math.random(0, 30), 170 + math.random(0, 25), 140),
			Parent = crowdFolder,
			CanCollide = false,
			CastShadow = false,
		})
		return torso
	end

	-- Packed sandstone bowl (~2k+ figures — "thousands" look, still playable)
	local rows = 55
	local seatsPerRow = 38
	for row = 1, rows do
		-- rise + pull back from stage (bowl slopes up away from Stage Rock)
		local z = stagePos.Z - 35 - row * 3.15
		local y = 2 + row * 1.2
		local rowWidth = 72 + row * 1.4
		local bench = part({
			Name = "Bench_R" .. row,
			Size = Vector3.new(rowWidth, 1.2, 2.4),
			Position = Vector3.new(center.X, y, z),
			Color = sand,
			Material = Enum.Material.Sandstone,
			Parent = folder,
		})
		for seat = 1, seatsPerRow do
			local u = (seat - 0.5) / seatsPerRow - 0.5
			if math.abs(u) < 0.045 then
				continue -- center aisle
			end
			if math.abs(math.abs(u) - 0.3) < 0.028 then
				continue -- side aisles
			end
			local x = center.X + u * rowWidth * 0.92
			if row > 35 and math.random() < 0.15 then
				continue
			end
			makePerson(Vector3.new(x, y + 0.6, z), (row * 0.01 + seat * 0.017) % 1)
		end
		if row % 10 == 0 then
			label(bench, "Row " .. row, Color3.fromRGB(255, 220, 180), 3, 40)
		end
	end

	-- VIP front rows platform
	local vipPad = part({
		Name = "VIPRow",
		Size = Vector3.new(50, 1.5, 12),
		Position = Vector3.new(center.X, 6, stagePos.Z - 28),
		Color = Color3.fromRGB(255, 200, 60),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	label(vipPad, "🌟 VIP ROWS", Color3.fromRGB(255, 240, 150), 3, 70)

	-- Perimeter fence / walls for ticketed area (open at gate -Z side)
	for _, wall in {
		{ Vector3.new(center.X - 160, 18, center.Z + 20), Vector3.new(6, 36, 280) },
		{ Vector3.new(center.X + 160, 18, center.Z + 20), Vector3.new(6, 36, 280) },
		{ Vector3.new(center.X, 18, center.Z + 160), Vector3.new(320, 36, 6) },
	} do
		part({
			Name = "VenueWall",
			Size = wall[2],
			Position = wall[1],
			Color = redDark,
			Material = Enum.Material.Sandstone,
			Parent = folder,
		})
	end

	-- Box office plaza OUTSIDE the bowl (approach from -Z) — raised so never buried
	local boxPos = center + Vector3.new(0, 0, -155)
	terrain:FillBlock(CFrame.new(boxPos.X, -2, boxPos.Z), Vector3.new(120, 10, 100), Enum.Material.Asphalt)
	terrain:FillBlock(CFrame.new(boxPos.X, 4, boxPos.Z), Vector3.new(100, 12, 80), Enum.Material.Air)

	local plazaY = 6
	local plaza = part({
		Name = "BoxOfficePlaza",
		Size = Vector3.new(90, 2.5, 70),
		Position = Vector3.new(boxPos.X, plazaY, boxPos.Z),
		Color = Color3.fromRGB(55, 45, 40),
		Material = Enum.Material.Concrete,
		Parent = folder,
	})
	local deckTop = plazaY + 1.25

	part({
		Name = "BoxOffice",
		Size = Vector3.new(32, 18, 20),
		Position = Vector3.new(boxPos.X, deckTop + 9, boxPos.Z - 12),
		Color = redDark,
		Material = Enum.Material.Sandstone,
		Parent = folder,
	})
	part({
		Name = "BoxRoof",
		Size = Vector3.new(36, 2.5, 24),
		Position = Vector3.new(boxPos.X, deckTop + 19, boxPos.Z - 12),
		Color = Color3.fromRGB(60, 40, 30),
		Material = Enum.Material.Slate,
		Parent = folder,
	})
	local boxSign = part({
		Name = "BoxSign",
		Size = Vector3.new(30, 8, 1.2),
		Position = Vector3.new(boxPos.X, deckTop + 16, boxPos.Z + 2),
		Color = Color3.fromRGB(20, 12, 10),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	label(boxSign, "🎟️ RED ROCKS BOX OFFICE\nBUY TICKETS HERE", Color3.fromRGB(255, 200, 100), 1, 200, true)

	-- Giant glowing ticket towers (impossible to miss)
	local function ticketTower(name: string, offset: Vector3, color: Color3, title: string, cost: number)
		local base = part({
			Name = name,
			Size = Vector3.new(16, 3, 16),
			Position = Vector3.new(boxPos.X + offset.X, deckTop + 1.6, boxPos.Z + offset.Z),
			Color = color,
			Material = Enum.Material.Neon,
			Parent = folder,
			CanTouch = true,
		})
		-- tall beacon pillar
		local pillar = part({
			Name = name .. "Beacon",
			Size = Vector3.new(6, 28, 6),
			Position = Vector3.new(boxPos.X + offset.X, deckTop + 16, boxPos.Z + offset.Z),
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.15,
			Parent = folder,
			CanCollide = false,
		})
		local pl = Instance.new("PointLight")
		pl.Brightness = 5
		pl.Range = 50
		pl.Color = color
		pl.Parent = pillar
		label(pillar, title .. "\n$" .. tostring(cost) .. " · PRESS E", Color3.fromRGB(255, 255, 255), 2, 250, true)
		label(base, title .. "\nSTAND HERE · E", color:Lerp(Color3.new(1, 1, 1), 0.4), 3, 120, true)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyTicket"
		prompt.ActionText = "Buy " .. title
		prompt.ObjectText = "Red Rocks"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 22
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = base
		return base, prompt
	end

	local gaCost = rr.ticketCost or 500
	local vipCost = rr.vipTicketCost or 2500
	local gaBooth, gaPrompt = ticketTower("TicketGA", Vector3.new(-22, 0, 18), Color3.fromRGB(40, 255, 100), "🎟️ GA TICKET", gaCost)
	local vipBooth, vipPrompt = ticketTower("TicketVIP", Vector3.new(22, 0, 18), Color3.fromRGB(255, 210, 40), "🌟 VIP TICKET", vipCost)

	-- Entry gate on plaza (raised)
	local gatePos = Vector3.new(boxPos.X, 0, boxPos.Z + 38)
	local gate = part({
		Name = "TicketGate",
		Size = Vector3.new(32, 18, 4),
		Position = Vector3.new(gatePos.X, deckTop + 9, gatePos.Z),
		Color = Color3.fromRGB(255, 90, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		Parent = folder,
		CanTouch = true,
	})
	label(gate, "🚪 ENTER WITH TICKET\nPRESS E", Color3.fromRGB(255, 230, 180), 2, 180, true)
	local gatePrompt = Instance.new("ProximityPrompt")
	gatePrompt.Name = "EnterGate"
	gatePrompt.ActionText = "Enter with ticket"
	gatePrompt.ObjectText = "Red Rocks Gate"
	gatePrompt.HoldDuration = 0
	gatePrompt.MaxActivationDistance = 22
	gatePrompt.RequiresLineOfSight = false
	gatePrompt.KeyboardKeyCode = Enum.KeyCode.E
	gatePrompt.Parent = gate

	-- Neon arrows on plaza floor pointing to pads
	for i, txt in { "→ GA", "VIP ←", "GATE ↑" } do
		local arrow = part({
			Name = "Arrow",
			Size = Vector3.new(10, 0.6, 10),
			Position = Vector3.new(boxPos.X + (i - 2) * 18, deckTop + 0.4, boxPos.Z + 5),
			Color = Color3.fromRGB(255, 255, 80),
			Material = Enum.Material.Neon,
			Parent = folder,
			CanCollide = false,
		})
		label(arrow, txt, Color3.fromRGB(20, 20, 20), 1.5, 80, true)
	end

	-- Exit pad inside (raised above seating)
	local exitPad = part({
		Name = "ExitPad",
		Size = Vector3.new(18, 2, 18),
		Position = Vector3.new(center.X, 10, center.Z - 85),
		Color = Color3.fromRGB(80, 160, 255),
		Material = Enum.Material.Neon,
		Parent = folder,
		CanTouch = true,
	})
	label(exitPad, "↩ EXIT VENUE", Color3.fromRGB(200, 230, 255), 3, 80, true)
	local exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.Name = "ExitPrompt"
	exitPrompt.ActionText = "Leave concert"
	exitPrompt.ObjectText = "Exit"
	exitPrompt.HoldDuration = 0
	exitPrompt.MaxActivationDistance = 16
	exitPrompt.Parent = exitPad

	-- Landmark (far visible) + path beacons from map toward box office
	local landmark = part({
		Name = "RedRocksLandmark",
		Size = Vector3.new(12, 80, 12),
		Position = Vector3.new(boxPos.X, 40, boxPos.Z - 30),
		Color = Color3.fromRGB(255, 100, 50),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
		Parent = folder,
		CanCollide = false,
	})
	label(landmark, "🎸 RED ROCKS\nTICKETS ON PLAZA", Color3.fromRGB(255, 220, 120), 8, 1200, true)
	local lmLight = Instance.new("PointLight")
	lmLight.Brightness = 6
	lmLight.Range = 80
	lmLight.Color = Color3.fromRGB(255, 120, 50)
	lmLight.Parent = landmark

	-- Atmosphere particles on stage
	local attach = Instance.new("Attachment")
	attach.Parent = stage
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 8
	smoke.Lifetime = NumberRange.new(2, 4)
	smoke.Speed = NumberRange.new(2, 6)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(Color3.fromRGB(255, 120, 60))
	smoke.Parent = attach

	local function setShowActive(active: boolean)
		for _, l in showLights do
			l.Color = active and Color3.fromRGB(255, math.random(40, 120), math.random(40, 100))
				or Color3.fromRGB(120, 50, 30)
			local pl = l:FindFirstChildOfClass("PointLight")
			if pl then
				pl.Brightness = active and 4 or 1.2
				pl.Color = l.Color
			end
		end
		smoke.Rate = active and 25 or 6
	end

	return {
		folder = folder,
		center = center,
		stage = stage,
		ticketGAPrompt = gaPrompt,
		ticketVIPPrompt = vipPrompt,
		gatePrompt = gatePrompt,
		gatePart = gate,
		exitPrompt = exitPrompt,
		insideCF = CFrame.new(center.X, 12, center.Z - 40),
		vipCF = CFrame.new(vipPad.Position + Vector3.new(0, 4, 0)),
		exitCF = CFrame.new(boxPos.X, deckTop + 5, boxPos.Z + 10),
		setShowActive = setShowActive,
	}
end

-- Carve terrain air out of a base so hills/sand never block interiors
local function clearTerrainUnderBase(center: Vector3, sizeX: number, sizeZ: number, height: number)
	local terrain = workspace.Terrain
	-- Flatten pad under plot + air volume for multi-story
	terrain:FillBlock(
		CFrame.new(center.X, height / 2, center.Z),
		Vector3.new(sizeX + 30, height + 8, sizeZ + 30),
		Enum.Material.Air
	)
	-- Solid walkable ground slab under the plot
	terrain:FillBlock(
		CFrame.new(center.X, -2, center.Z),
		Vector3.new(sizeX + 36, 8, sizeZ + 36),
		Enum.Material.Ground
	)
end

local function buildTerrain()
	local terrain = workspace.Terrain
	terrain:Clear()

	local half = Config.MAP_HALF
	local edge = half - 40
	-- Base grass fill for whole map
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(half * 2 + 80, 14, half * 2 + 80), Enum.Material.Grass)

	-- Biome plates on the same large ring as mega-bases
	local biomeMats = {
		Enum.Material.Snow,
		Enum.Material.LeafyGrass,
		Enum.Material.Ground,
		Enum.Material.Sand,
		Enum.Material.Mud,
		Enum.Material.Rock,
		Enum.Material.Slate,
		Enum.Material.Ice,
	}
	for i = 1, 8 do
		local ang = (i - 1) * (math.pi * 2 / 8) + math.rad(22.5)
		local c = Vector3.new(math.cos(ang) * edge, 0, math.sin(ang) * edge)
		terrain:FillBlock(CFrame.new(c.X, -4, c.Z), Vector3.new(360, 14, 360), biomeMats[i])
	end
	terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(280, 10, 280), Enum.Material.LeafyGrass)

	-- Flat plaza under spawn hub
	local hub = Config.SPAWN_HUB
	terrain:FillBlock(CFrame.new(hub.X, -3, hub.Z), Vector3.new(180, 10, 180), Enum.Material.Asphalt)

	-- Rolling hills — soft skirts so bikes can drive up (no cliff bases)
	for _ = 1, 48 do
		local x = (math.random() - 0.5) * half * 1.75
		local z = (math.random() - 0.5) * half * 1.75
		local nearHub = (Vector3.new(x, 0, z) - Vector3.new(hub.X, 0, hub.Z)).Magnitude < 140
		if not nearHub then
			local r = 28 + math.random() * 50 -- wider = gentler
			softHill(terrain, x, z, r, Enum.Material.Grass)
			if math.random() < 0.3 then
				-- small rocky cap (still gentle)
				terrain:FillBall(Vector3.new(x, r * 0.15, z), r * 0.35, Enum.Material.Rock)
			end
		end
	end

	-- Mountain range near frost — stepped soft mounds, not sheer walls
	local frostAng = 0 * (math.pi * 2 / 8) + math.rad(22.5)
	for i = 1, 10 do
		local a = frostAng + (i - 5) * 0.08
		local rr = edge - 60 + math.random(-40, 30)
		local x = math.cos(a) * rr
		local z = math.sin(a) * rr
		softHill(terrain, x, z, 40 + math.random() * 18, Enum.Material.Rock)
		terrain:FillBall(Vector3.new(x, 18, z), 22, Enum.Material.Snow)
	end

	-- Desert dunes — wide soft sand mounds
	local sandAng = 3 * (math.pi * 2 / 8) + math.rad(22.5)
	local sandscar = Vector3.new(math.cos(sandAng) * edge, 0, math.sin(sandAng) * edge)
	for _ = 1, 16 do
		local a = sandAng + (math.random() - 0.5) * 0.6
		local r = edge * (0.55 + math.random() * 0.35)
		local x = math.cos(a) * r
		local z = math.sin(a) * r
		local p = Vector3.new(x, 0, z)
		if (p - sandscar).Magnitude > 130 then
			softHill(terrain, x, z, 30 + math.random() * 28, Enum.Material.Sand)
		end
	end

	-- Main river (west→east, meanders; feeds Rivermouth south)
	for t = 0, 48 do
		local u = t / 48
		local x = -half + u * half * 2
		local z = -60 + math.sin(u * math.pi * 3.2) * 100
		terrain:FillBlock(CFrame.new(x, -2, z), Vector3.new(30, 10, 38), Enum.Material.Water)
		terrain:FillBlock(CFrame.new(x, -8, z), Vector3.new(42, 8, 52), Enum.Material.Mud)
	end

	-- River branch south toward Rivermouth
	for t = 0, 20 do
		local u = t / 20
		local x = 60 + math.sin(u * math.pi) * 40
		local z = -100 - u * (edge - 80)
		terrain:FillBlock(CFrame.new(x, -2, z), Vector3.new(22, 9, 30), Enum.Material.Water)
	end

	-- Northern stream (Pinewood / Crystalvale)
	for t = 0, 28 do
		local u = t / 28
		local x = -220 + u * 440
		local z = 220 + math.cos(u * math.pi * 2.2) * 50
		terrain:FillBlock(CFrame.new(x, -2, z), Vector3.new(20, 8, 28), Enum.Material.Water)
	end
end

function WorldBuilder.build()
	local folder = workspace:FindFirstChild("CashStackWorld")
	if folder then
		folder:Destroy()
	end
	-- Hide Studio-only beacons once the real world builds
	local editorPreview = workspace:FindFirstChild("EditorOnly_MapPreview")
	if editorPreview then
		editorPreview:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "CashStackWorld"
	folder.Parent = workspace

	local props = Instance.new("Folder")
	props.Name = "Buildings"
	props.Parent = folder

	local floorSpawns = {}
	local walkovers = {}
	local elevators = {}

	-- Terrain biomes
	pcall(buildTerrain)

	local hub = Config.SPAWN_HUB
	local hubY = 2

	-- ═══════════════════════════════════════════
	-- SPAWN HUB (far SW corner)
	-- ═══════════════════════════════════════════
	local spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "SpawnHub"
	spawnFolder.Parent = folder

	-- Platform
	local plaza = part({
		Name = "SpawnPlaza",
		Size = Vector3.new(140, 2, 140),
		Position = hub + Vector3.new(0, hubY, 0),
		Color = Color3.fromRGB(45, 48, 70),
		Material = Enum.Material.Basalt,
		Parent = spawnFolder,
	})
	label(plaza, "👑 " .. Config.GAME_NAME .. "\nSPAWN HUB", Color3.fromRGB(255, 215, 90), 8, 80)

	-- Spawn pad (player starts here)
	local spawnPad = part({
		Name = "PlayerSpawn",
		Size = Vector3.new(16, 1.2, 16),
		Position = hub + Vector3.new(0, hubY + 1.5, -40),
		Color = Color3.fromRGB(90, 150, 255),
		Material = Enum.Material.Neon,
		Parent = spawnFolder,
	})
	label(spawnPad, "★ YOU SPAWN HERE ★", Color3.fromRGB(200, 230, 255), 2.5, 60)
	local spawnCF = CFrame.new(spawnPad.Position + Vector3.new(0, 4, 0))

	-- Official Roblox spawn so default join lands in the hub (not map center)
	for _, old in workspace:GetDescendants() do
		if old:IsA("SpawnLocation") then
			old:Destroy()
		end
	end
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = false
	spawnLoc.Transparency = 1
	spawnLoc.Duration = 0
	spawnLoc.Neutral = true
	spawnLoc.Size = Vector3.new(14, 1, 14)
	spawnLoc.CFrame = spawnCF
	spawnLoc.Parent = spawnFolder

	-- Main bank first (center) so all shops face it
	local bankGround = hub + Vector3.new(0, hubY, 0)
	local mainBank = part({
		Name = "MainBank",
		Size = Vector3.new(20, 1.8, 20),
		Position = bankGround + Vector3.new(0, 1.6, 0),
		Color = Color3.fromRGB(40, 255, 140),
		Material = Enum.Material.Neon,
		Parent = spawnFolder,
		CanTouch = true,
	})
	mainBank:SetAttribute("IsDeposit", true)
	markWalkover(mainBank, 0)
	label(mainBank, "★ MAIN BANK ★", Color3.fromRGB(200, 255, 210), 2.5, 55)
	local mainPrompt = Instance.new("ProximityPrompt")
	mainPrompt.Name = "DepositPrompt"
	mainPrompt.ActionText = "Deposit"
	mainPrompt.ObjectText = "Bank"
	mainPrompt.HoldDuration = 0
	mainPrompt.MaxActivationDistance = 18
	mainPrompt.KeyboardKeyCode = Enum.KeyCode.E
	mainPrompt.Parent = mainBank
	table.insert(walkovers, mainBank)

	-- Hub buildings ring around plaza — each faces + pad toward main bank
	local hubServices = {
		{
			key = "shop",
			offset = Vector3.new(42, 0, -22),
			size = Vector3.new(28, 16, 22),
			color = Color3.fromRGB(180, 100, 30),
			sign = "🛒 EMPIRE STORE",
			padColor = Color3.fromRGB(255, 170, 40),
			attr = "IsShop",
		},
		{
			key = "fusion",
			offset = Vector3.new(-42, 0, -22),
			size = Vector3.new(26, 14, 20),
			color = Color3.fromRGB(30, 90, 160),
			sign = "⚗️ FUSION LAB",
			padColor = Color3.fromRGB(80, 180, 255),
			attr = "IsFusion",
		},
		{
			key = "rebirth",
			offset = Vector3.new(42, 0, 28),
			size = Vector3.new(26, 15, 20),
			color = Color3.fromRGB(90, 40, 140),
			sign = "♻️ REBIRTH HALL",
			padColor = Color3.fromRGB(180, 70, 255),
			attr = "IsRebirth",
		},
		{
			key = "claim",
			offset = Vector3.new(-42, 0, 28),
			size = Vector3.new(28, 15, 22),
			color = Color3.fromRGB(40, 70, 140),
			sign = "🏠 BASE CLAIM\nPick a free plot outside",
			padColor = Color3.fromRGB(70, 140, 255),
			attr = "IsClaimInfo",
		},
		{
			key = "mybase",
			offset = Vector3.new(0, 0, 52),
			size = Vector3.new(24, 14, 18),
			color = Color3.fromRGB(40, 100, 140),
			sign = "↩ MY BASE PORTAL",
			padColor = Color3.fromRGB(80, 200, 255),
			attr = "IsReturnBase",
		},
		{
			key = "robux",
			offset = Vector3.new(0, 0, -52),
			size = Vector3.new(30, 16, 22),
			color = Color3.fromRGB(30, 140, 70),
			sign = "💎 ROBUX STORE\nPowerups · Gear · Fits",
			padColor = Color3.fromRGB(40, 220, 100),
			attr = "IsRobuxStore",
		},
	}

	local shopPad, fusionPad, rebirthPad, claimInfoPad, returnPad, robuxPad
	local rebirthPrompt

	for _, svc in hubServices do
		local slot = hub + svc.offset + Vector3.new(0, hubY, 0)
		local toBank = Vector3.new(bankGround.X - slot.X, 0, bankGround.Z - slot.Z)
		local towardBank = if toBank.Magnitude > 0.05 then toBank.Unit else Vector3.new(0, 0, -1)

		-- Building sits slightly away from bank; pad sits in front (between building and bank)
		local buildingGround = slot - towardBank * 8
		signBuilding(spawnFolder, buildingGround, svc.size, svc.color, svc.sign, bankGround)

		local pad = part({
			Name = svc.key .. "Pad",
			Size = Vector3.new(16, 1.5, 16),
			Position = slot + towardBank * 6 + Vector3.new(0, 1.6, 0),
			Color = svc.padColor,
			Material = Enum.Material.Neon,
			Parent = spawnFolder,
			CanTouch = true,
		})
		pad:SetAttribute(svc.attr, true)
		markWalkover(pad, 0)
		local shortSign = string.split(svc.sign, "\n")[1] or svc.sign
		label(pad, shortSign, Color3.fromRGB(255, 255, 230), 2.5, 55)
		table.insert(walkovers, pad)

		if svc.key == "shop" then
			shopPad = pad
		elseif svc.key == "fusion" then
			fusionPad = pad
		elseif svc.key == "rebirth" then
			rebirthPad = pad
			rebirthPrompt = Instance.new("ProximityPrompt")
			rebirthPrompt.Name = "RebirthPrompt"
			rebirthPrompt.ActionText = "Rebirth"
			rebirthPrompt.ObjectText = "Prestige"
			rebirthPrompt.HoldDuration = 0.35
			rebirthPrompt.MaxActivationDistance = 16
			rebirthPrompt.RequiresLineOfSight = false
			rebirthPrompt.Parent = pad
		elseif svc.key == "claim" then
			claimInfoPad = pad
		elseif svc.key == "mybase" then
			returnPad = pad
		elseif svc.key == "robux" then
			robuxPad = pad
		end
	end

	-- Daily chest (edges of plaza, still readable from bank)
	local dailyChest = part({
		Name = "DailyChest",
		Size = Vector3.new(8, 6, 8),
		Position = hub + Vector3.new(22, hubY + 4, -48),
		Color = Color3.fromRGB(255, 190, 40),
		Material = Enum.Material.Neon,
		Parent = spawnFolder,
		CanTouch = true,
	})
	dailyChest:SetAttribute("IsDailyChest", true)
	label(dailyChest, "🎁 DAILY CHEST\nOnce per day", Color3.fromRGB(255, 240, 180), 3, 50)
	local dailyPrompt = Instance.new("ProximityPrompt")
	dailyPrompt.Name = "DailyPrompt"
	dailyPrompt.ActionText = "Claim daily"
	dailyPrompt.ObjectText = "Daily Chest"
	dailyPrompt.HoldDuration = 0.2
	dailyPrompt.MaxActivationDistance = 14
	dailyPrompt.Parent = dailyChest

	-- Playtime chest
	local playChest = part({
		Name = "PlaytimeChest",
		Size = Vector3.new(8, 6, 8),
		Position = hub + Vector3.new(-22, hubY + 4, -48),
		Color = Color3.fromRGB(100, 220, 255),
		Material = Enum.Material.Neon,
		Parent = spawnFolder,
		CanTouch = true,
	})
	playChest:SetAttribute("IsPlaytimeChest", true)
	label(playChest, "⏱ PLAYTIME CHEST\nEarn while online", Color3.fromRGB(200, 240, 255), 3, 50)
	local playPrompt = Instance.new("ProximityPrompt")
	playPrompt.Name = "PlaytimePrompt"
	playPrompt.ActionText = "Claim playtime"
	playPrompt.ObjectText = "Playtime Chest"
	playPrompt.HoldDuration = 0.2
	playPrompt.MaxActivationDistance = 14
	playPrompt.Parent = playChest

	-- GATE out of spawn (toward map center)
	local gateFrame = part({
		Name = "GateFrame",
		Size = Vector3.new(36, 18, 4),
		Position = hub + Vector3.new(55, hubY + 9, 55),
		Color = Color3.fromRGB(60, 60, 80),
		Material = Enum.Material.Metal,
		Parent = spawnFolder,
	})
	-- rotated toward NE (map)
	gateFrame.CFrame = CFrame.new(hub + Vector3.new(55, hubY + 9, 55)) * CFrame.Angles(0, math.rad(45), 0)
	local gate = part({
		Name = "WorldGate",
		Size = Vector3.new(20, 14, 2),
		Color = Color3.fromRGB(100, 255, 140),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		Parent = spawnFolder,
		CanTouch = true,
	})
	gate.CFrame = gateFrame.CFrame * CFrame.new(0, 0, 0)
	gate:SetAttribute("IsWorldGate", true)
	label(gate, "🚪 GATE TO THE WORLD\nClaim a FREE base beyond!", Color3.fromRGB(200, 255, 200), 2, 90, true)

	-- Force-field walls around spawn (leave gate gap)
	-- Simplified: 3 walls, open toward NE gate
	for _, wcfg in {
		{ Vector3.new(0, 10, -72), Vector3.new(150, 20, 3) },
		{ Vector3.new(-72, 10, 0), Vector3.new(3, 20, 150) },
		{ Vector3.new(72, 10, -20), Vector3.new(3, 20, 100) },
	} do
		part({
			Name = "SpawnWall",
			Size = wcfg[2],
			Position = hub + Vector3.new(wcfg[1].X, hubY + wcfg[1].Y, wcfg[1].Z),
			Color = Color3.fromRGB(40, 80, 140),
			Material = Enum.Material.ForceField,
			Transparency = 0.55,
			Parent = spawnFolder,
		})
	end

	-- ═══════════════════════════════════════════
	-- EDGE MEGA-BASES (8) with biomes
	-- ═══════════════════════════════════════════
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = folder

	-- Mega-bases evenly around a large ring — far apart, open side faces map center
	local edge = Config.MAP_HALF - 80
	local maxStories = Config.MAX_STORIES or 6
	local ring = {
		{ name = "Frostpeak", color = Color3.fromRGB(200, 220, 240), biome = "Snow Mountains", layout = "frost", size = Vector3.new(140, 0, 140) },
		{ name = "Pinewood", color = Color3.fromRGB(60, 120, 50), biome = "Forest Hills", layout = "pine", size = Vector3.new(130, 0, 130) },
		{ name = "Goldfield", color = Color3.fromRGB(160, 140, 60), biome = "Meadow", layout = "gold", size = Vector3.new(135, 0, 135) },
		{ name = "Sandscar", color = Color3.fromRGB(210, 180, 100), biome = "Desert", layout = "sand", size = Vector3.new(128, 0, 128) },
		{ name = "Rivermouth", color = Color3.fromRGB(70, 110, 140), biome = "River Valley", layout = "river", size = Vector3.new(130, 0, 130) },
		{ name = "Obsidian", color = Color3.fromRGB(50, 45, 55), biome = "Volcanic Rock", layout = "obsidian", size = Vector3.new(128, 0, 128) },
		{ name = "Stormcliff", color = Color3.fromRGB(70, 80, 120), biome = "Storm Cliffs", layout = "storm", size = Vector3.new(125, 0, 125) },
		{ name = "Crystalvale", color = Color3.fromRGB(140, 100, 200), biome = "Crystal Plains", layout = "crystal", size = Vector3.new(132, 0, 132) },
	}
	-- Place on ring; rotate so none sits on the spawn hub (SW)
	local hubFlat = Vector3.new(Config.SPAWN_HUB.X, 0, Config.SPAWN_HUB.Z)
	local baseDefs = {}
	for i, def in ring do
		-- 8 slots, start ~NE of SW hub gap: offset so SW sector is empty-ish
		local ang = (i - 1) * (math.pi * 2 / 8) + math.rad(22.5)
		local pos = Vector3.new(math.cos(ang) * edge, 0, math.sin(ang) * edge)
		-- If too close to hub, push further out along ring normal
		if (pos - hubFlat).Magnitude < 280 then
			pos = pos.Unit * (edge + 120)
		end
		table.insert(baseDefs, {
			name = def.name,
			pos = pos,
			color = def.color,
			biome = def.biome,
			stories = maxStories,
			size = def.size,
			layout = def.layout,
		})
	end

	local baseSlots = {}
	local allDeposit = { mainBank }

	for i, def in baseDefs do
		local pos = def.pos
		local outward = pos.Unit
		if outward.Magnitude < 0.1 then
			outward = Vector3.new(0, 0, 1)
		end
		local right = Vector3.new(-outward.Z, 0, outward.X)
		local towardCenter = -outward

		-- Remove sand hills / rock from inside the estate before building
		clearTerrainUnderBase(pos, def.size.X + 50, def.size.Z + 50, (def.stories + 1) * Config.STORY_HEIGHT)

		-- Plot platform around building
		local plot = part({
			Name = "BasePlot_" .. i,
			Size = Vector3.new(def.size.X + 48, 2.5, def.size.Z + 48),
			Position = pos + Vector3.new(0, 1.2, 0),
			Color = Color3.fromRGB(55, 55, 70),
			Material = Enum.Material.Concrete,
			Parent = basesFolder,
		})
		plot:SetAttribute("BaseIndex", i)

		-- Custom multi-room estate (open toward map center)
		local sp = customMegaBase(
			props,
			pos + Vector3.new(0, 2.5, 0),
			def.stories,
			def.size,
			def.color,
			def.name,
			def.layout
		)
		for _, s in sp do
			table.insert(floorSpawns, s)
		end

		-- Owner sign on open side (toward center) so names face the map
		local namePillar = part({
			Name = "OwnerSign",
			Size = Vector3.new(4, 28, 4),
			Position = pos + towardCenter * (def.size.Z / 2 + 22) + Vector3.new(0, 16, 0),
			Color = Color3.fromRGB(40, 40, 55),
			Material = Enum.Material.Metal,
			Parent = basesFolder,
		})
		local ownerText = label(
			namePillar,
			"🏠 " .. def.name:upper() .. "\n" .. def.biome .. "\n✦ AVAILABLE",
			Color3.fromRGB(120, 255, 150),
			10,
			Config.LABEL_DISTANCE_OPEN_BASE,
			true
		)
		ownerText.Name = "OwnerText"

		-- Claim pad on open approach (from map center)
		local claimPad = part({
			Name = "ClaimPad_" .. i,
			Size = Vector3.new(16, 1.8, 16),
			Position = pos + towardCenter * (def.size.Z / 2 + 14) + Vector3.new(0, 2.8, 0),
			Color = Color3.fromRGB(100, 255, 130),
			Material = Enum.Material.Neon,
			Parent = basesFolder,
			CanTouch = true,
		})
		claimPad:SetAttribute("IsBaseClaim", true)
		claimPad:SetAttribute("BaseIndex", i)
		markWalkover(claimPad, 0)
		label(claimPad, "CLAIM " .. def.name:upper() .. "\nPermanent base", Color3.fromRGB(230, 255, 230), 2.5, 70)
		local claimPrompt = Instance.new("ProximityPrompt")
		claimPrompt.Name = "ClaimPrompt"
		claimPrompt.ActionText = "Claim this base forever"
		claimPrompt.ObjectText = def.name
		claimPrompt.HoldDuration = 0.4
		claimPrompt.MaxActivationDistance = 18
		claimPrompt.Parent = claimPad
		table.insert(walkovers, claimPad)

		-- Deposit in courtyard center
		local deposit = part({
			Name = "Deposit_" .. i,
			Size = Vector3.new(16, 1.8, 16),
			Position = pos + Vector3.new(0, 4, 0),
			Color = Color3.fromRGB(50, 255, 140),
			Material = Enum.Material.Neon,
			Parent = basesFolder,
			CanTouch = true,
		})
		deposit:SetAttribute("IsDeposit", true)
		deposit:SetAttribute("BaseIndex", i)
		markWalkover(deposit, 0)
		label(deposit, "★ DEPOSIT ★", Color3.fromRGB(210, 255, 220), 2.5, 50)
		local depositPrompt = Instance.new("ProximityPrompt")
		depositPrompt.Name = "DepositPrompt"
		depositPrompt.ActionText = "Deposit"
		depositPrompt.ObjectText = "Vault"
		depositPrompt.HoldDuration = 0
		depositPrompt.MaxActivationDistance = 18
		depositPrompt.KeyboardKeyCode = Enum.KeyCode.E
		depositPrompt.Parent = deposit
		table.insert(walkovers, deposit)
		table.insert(allDeposit, deposit)

		-- Tycoon buttons ON the plot deck (front edge) so hills never bury them
		local tyFolder = Instance.new("Folder")
		tyFolder.Name = "Tycoon_" .. i
		tyFolder.Parent = basesFolder
		local buttons = {}
		local nBtn = #Config.TycoonButtons
		local plotTopY = plot.Position.Y + plot.Size.Y / 2
		-- Front of plot (open side toward map center), still on concrete
		local stripCenter = pos + towardCenter * (def.size.Z / 2 - 10)
		local stripW = math.max(nBtn * 5.4 + 14, 48)
		local tyDeck = part({
			Name = "TycoonDeck_" .. i,
			Size = Vector3.new(stripW, 2, 18),
			Position = Vector3.new(stripCenter.X, plotTopY + 1.0, stripCenter.Z),
			Color = Color3.fromRGB(50, 50, 68),
			Material = Enum.Material.Concrete,
			Parent = tyFolder,
		})
		local deckTopY = tyDeck.Position.Y + tyDeck.Size.Y / 2
		local btnY = deckTopY + 0.95

		for bi, btn in Config.TycoonButtons do
			local lateral = (bi - (nBtn + 1) / 2) * 5.2
			local bpos = stripCenter + right * lateral
			local b = part({
				Name = btn.id,
				Size = Vector3.new(4.2, 1.5, 4.2),
				Position = Vector3.new(bpos.X, btnY, bpos.Z),
				Color = Color3.fromRGB(255, 80, 80),
				Material = Enum.Material.Neon,
				Parent = tyFolder,
				CanTouch = true,
			})
			b:SetAttribute("TycoonButton", true)
			b:SetAttribute("ButtonId", btn.id)
			b:SetAttribute("BaseIndex", i)
			b:SetAttribute("Cost", btn.cost)
			b:SetAttribute("Order", bi)
			markWalkover(b, 0)
			label(b, "BUY\n" .. btn.name .. "\n$" .. btn.cost, Color3.fromRGB(255, 230, 230), 2.2, 55)
			local pp = Instance.new("ProximityPrompt")
			pp.Name = "BuyPrompt"
			pp.ActionText = "Buy $" .. btn.cost
			pp.ObjectText = btn.name
			pp.HoldDuration = 0
			pp.MaxActivationDistance = 14
			pp.Parent = b
			table.insert(buttons, b)
			table.insert(walkovers, b)
		end

		-- Claim pad sits on plot top (not under terrain)
		claimPad.Position = Vector3.new(claimPad.Position.X, plotTopY + 1.3, claimPad.Position.Z)
		namePillar.Position = Vector3.new(namePillar.Position.X, plotTopY + 16, namePillar.Position.Z)

		table.insert(baseSlots, {
			index = i,
			name = def.name,
			biome = def.biome,
			layout = def.layout,
			plot = plot,
			deposit = deposit,
			prompt = depositPrompt,
			claimPad = claimPad,
			claimPrompt = claimPrompt,
			namePillar = namePillar,
			ownerText = ownerText,
			spawn = Vector3.new(
				(pos + towardCenter * (def.size.Z / 2 - 4)).X,
				plotTopY + 5,
				(pos + towardCenter * (def.size.Z / 2 - 4)).Z
			),
			owner = nil :: Player?,
			tycoon = { folder = tyFolder, buttons = buttons },
		})
	end

	-- Smaller public loot estates (inner ring — not crowding mega-bases)
	local inner = edge * 0.38
	for i, tpos in {
		Vector3.new(inner * 0.7, 0, inner * 0.7),
		Vector3.new(-inner * 0.7, 0, inner * 0.7),
		Vector3.new(inner * 0.7, 0, -inner * 0.55),
		Vector3.new(-inner * 0.5, 0, -inner * 0.5),
	} do
		clearTerrainUnderBase(tpos, 90, 90, 4 * Config.STORY_HEIGHT)
		local sp = customMegaBase(
			props,
			tpos + Vector3.new(0, 2, 0),
			4,
			Vector3.new(72, 0, 72),
			Color3.fromRGB(100, 90, 110),
			"LootEstate" .. i,
			"gold"
		)
		for _, s in sp do
			table.insert(floorSpawns, s)
		end
	end

	local loot = Instance.new("Folder")
	loot.Name = "Collectibles"
	loot.Parent = folder

	local zombiesFolder = Instance.new("Folder")
	zombiesFolder.Name = "Zombies"
	zombiesFolder.Parent = folder

	-- ═══════════════════════════════════════════
	-- RED ROCKS AMPHITHEATRE (ticketed concert)
	-- ═══════════════════════════════════════════
	local redRocks = buildRedRocks(folder)

	-- Extra ticket booths AT SPAWN HUB so players always see them
	do
		local hubTicketY = hub.Y + hubY + 3
		local hubTicketCenter = hub + Vector3.new(55, 0, 0)
		local deck = part({
			Name = "HubTicketDeck",
			Size = Vector3.new(48, 2, 28),
			Position = Vector3.new(hubTicketCenter.X, hubTicketY, hubTicketCenter.Z),
			Color = Color3.fromRGB(60, 40, 35),
			Material = Enum.Material.Concrete,
			Parent = spawnFolder,
		})
		local top = hubTicketY + 1
		label(deck, "🎟️ RED ROCKS TICKETS\nBuy here or at the venue", Color3.fromRGB(255, 180, 100), 4, 120, true)

		local function hubTower(name, ox, color, title, cost)
			local b = part({
				Name = name,
				Size = Vector3.new(14, 2.5, 14),
				Position = Vector3.new(hubTicketCenter.X + ox, top + 1.4, hubTicketCenter.Z + 4),
				Color = color,
				Material = Enum.Material.Neon,
				Parent = spawnFolder,
				CanTouch = true,
			})
			local beacon = part({
				Name = name .. "Beacon",
				Size = Vector3.new(5, 22, 5),
				Position = Vector3.new(hubTicketCenter.X + ox, top + 14, hubTicketCenter.Z + 4),
				Color = color,
				Material = Enum.Material.Neon,
				Transparency = 0.2,
				Parent = spawnFolder,
				CanCollide = false,
			})
			local pl = Instance.new("PointLight")
			pl.Brightness = 4
			pl.Range = 40
			pl.Color = color
			pl.Parent = beacon
			label(beacon, title .. "\n$" .. cost .. " · E", Color3.fromRGB(255, 255, 255), 2, 150, true)
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText = "Buy " .. title
			pr.ObjectText = "Red Rocks"
			pr.HoldDuration = 0
			pr.MaxActivationDistance = 20
			pr.RequiresLineOfSight = false
			pr.KeyboardKeyCode = Enum.KeyCode.E
			pr.Parent = b
			return b, pr
		end
		local rrCfg = Config.RedRocks or {}
		local _, hubGA = hubTower("HubTicketGA", -14, Color3.fromRGB(40, 255, 100), "GA TICKET", rrCfg.ticketCost or 500)
		local _, hubVIP = hubTower("HubTicketVIP", 14, Color3.fromRGB(255, 210, 40), "VIP TICKET", rrCfg.vipTicketCost or 2500)
		-- Wire hub prompts into venue table so ConcertService picks them up
		if redRocks then
			redRocks.hubGAPrompt = hubGA
			redRocks.hubVIPPrompt = hubVIP
			-- Teleport pad to venue box office
			local goPad = part({
				Name = "GoToRedRocks",
				Size = Vector3.new(16, 2, 16),
				Position = Vector3.new(hubTicketCenter.X, top + 1.2, hubTicketCenter.Z - 10),
				Color = Color3.fromRGB(255, 100, 50),
				Material = Enum.Material.Neon,
				Parent = spawnFolder,
				CanTouch = true,
			})
			label(goPad, "🎸 GO TO RED ROCKS\nTeleport to box office", Color3.fromRGB(255, 220, 160), 3, 100, true)
			local goPrompt = Instance.new("ProximityPrompt")
			goPrompt.ActionText = "Teleport to Red Rocks"
			goPrompt.ObjectText = "Venue"
			goPrompt.HoldDuration = 0
			goPrompt.MaxActivationDistance = 18
			goPrompt.Parent = goPad
			redRocks.goToVenuePrompt = goPrompt
			redRocks.boxOfficeCF = redRocks.exitCF -- outside gate
		end
	end

	-- ═══════════════════════════════════════════
	-- DIRTBIKE JUMPS + LIP BOOSTERS (YZ65 playground)
	-- ═══════════════════════════════════════════
	local jumpsFolder = Instance.new("Folder")
	jumpsFolder.Name = "DirtJumps"
	jumpsFolder.Parent = folder
	local boostPads: { BasePart } = {}

	local function addJump(origin: Vector3, yaw: number, opts)
		local pads = buildDirtJump(jumpsFolder, origin, yaw, opts)
		for _, p in pads do
			table.insert(boostPads, p)
		end
	end

	-- Hub exit line (toward map center) — first jumps after the gate
	local toCenter = Vector3.new(-hub.X, 0, -hub.Z)
	if toCenter.Magnitude < 0.1 then
		toCenter = Vector3.new(1, 0, 1)
	end
	toCenter = toCenter.Unit
	local hubYaw = math.atan2(-toCenter.X, -toCenter.Z)

	addJump(hub + toCenter * 130 + Vector3.new(0, 2, 0), hubYaw, {
		name = "Gate Launch",
		height = 14,
		rampLen = 38,
		gap = 32,
		boost = 150,
	})
	addJump(hub + toCenter * 260 + Vector3.new(28, 2, 0), hubYaw + math.rad(8), {
		name = "Hub Double",
		height = 18,
		rampLen = 44,
		gap = 40,
		boost = 160,
	})
	addJump(hub + toCenter * 400 + Vector3.new(-35, 2, 0), hubYaw - math.rad(6), {
		name = "Trail Step-Up",
		height = 20,
		rampLen = 48,
		gap = 44,
		boost = 170,
	})

	-- Center freestyle pad jumps (cardinal)
	for i, ang in { 0, math.rad(90), math.rad(180), math.rad(270) } do
		local o = Vector3.new(math.cos(ang) * 160, 2, math.sin(ang) * 160)
		addJump(o, ang + math.pi / 2, {
			name = "Center " .. i,
			height = 16 + i,
			rampLen = 40,
			gap = 34 + i * 2,
			boost = 155,
			width = 24,
		})
	end

	-- Big ring jumps between mega-bases (one per sector)
	for i = 1, 8 do
		local ang = (i - 1) * (math.pi * 2 / 8) + math.rad(22.5) + math.rad(22.5)
		local r = edge * 0.55
		local o = Vector3.new(math.cos(ang) * r, 2, math.sin(ang) * r)
		-- face tangent so you ride the ring
		local yaw = ang + math.pi / 2
		addJump(o, yaw, {
			name = "Ring Jump " .. i,
			height = 18 + (i % 3) * 3,
			rampLen = 46,
			gap = 38 + (i % 2) * 8,
			boost = 165,
			width = 26,
		})
	end

	-- Dense ground loot anchors: hub ring, gate path, center, base approaches
	local groundSpawns: { Vector3 } = {}
	local function addGround(pos: Vector3)
		table.insert(groundSpawns, Vector3.new(pos.X, 4.5, pos.Z))
	end
	-- Around spawn hub (outside plaza so players leaving the gate see cash)
	for i = 1, 48 do
		local ang = (i / 48) * math.pi * 2
		local r = 55 + (i % 5) * 18
		addGround(hub + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r))
	end
	-- Path hub → map center
	for i = 0, 40 do
		local t = i / 40
		local p = hub:Lerp(Vector3.new(0, hub.Y, 0), t)
		addGround(p + Vector3.new((math.random() - 0.5) * 40, 0, (math.random() - 0.5) * 40))
	end
	-- Map center scatter
	for i = 1, 60 do
		local ang = math.random() * math.pi * 2
		local r = 30 + math.random() * 320
		addGround(Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r))
	end
	-- Approaches to each mega-base (open side)
	for _, slot in baseSlots do
		local toward = Vector3.new(-slot.plot.Position.X, 0, -slot.plot.Position.Z)
		if toward.Magnitude > 0.1 then
			toward = toward.Unit
		else
			toward = Vector3.new(0, 0, -1)
		end
		local basePos = Vector3.new(slot.plot.Position.X, 0, slot.plot.Position.Z)
		for j = 1, 14 do
			addGround(basePos + toward * (40 + j * 12) + Vector3.new((math.random() - 0.5) * 30, 0, (math.random() - 0.5) * 30))
		end
		-- courtyard ground level near claim
		if slot.claimPad then
			addGround(slot.claimPad.Position + Vector3.new(0, 2, 0))
			for k = 1, 8 do
				local a = (k / 8) * math.pi * 2
				addGround(slot.claimPad.Position + Vector3.new(math.cos(a) * 18, 2, math.sin(a) * 18))
			end
		end
	end
	-- Inner loot estate rings
	for i = 1, 40 do
		local ang = math.random() * math.pi * 2
		local r = edge * 0.25 + math.random() * edge * 0.2
		addGround(Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r))
	end

	-- Collect elevator parts for wiring
	for _, inst in folder:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute("Elevator") then
			table.insert(elevators, inst)
		end
	end

	print(
		("[CashEmpire] World built · floorSpawns=%d groundSpawns=%d bases=%d jumps=%d"):format(
			#floorSpawns,
			#groundSpawns,
			#baseSlots,
			#boostPads
		)
	)

	return {
		folder = folder,
		bases = baseSlots,
		lootFolder = loot,
		zombiesFolder = zombiesFolder,
		shopPad = shopPad,
		mainBank = mainBank,
		rebirthPad = rebirthPad,
		fusionPad = fusionPad,
		robuxPad = robuxPad,
		indexPad = claimInfoPad, -- claim info doubles as index tip area; index via HUD
		claimOffice = claimInfoPad,
		returnPad = returnPad,
		rebirthPrompt = rebirthPrompt,
		allDepositParts = allDeposit,
		floorSpawns = floorSpawns,
		groundSpawns = groundSpawns,
		boostPads = boostPads,
		walkovers = walkovers,
		spawnCF = spawnCF,
		worldGate = gate,
		dailyChest = dailyChest,
		dailyPrompt = dailyPrompt,
		playChest = playChest,
		playPrompt = playPrompt,
		elevators = elevators,
		redRocks = redRocks,
	}
end

return WorldBuilder
