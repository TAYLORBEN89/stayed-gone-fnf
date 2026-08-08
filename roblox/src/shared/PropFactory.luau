--[[
	Build pickup visuals: custom MeshPart if MeshId set, else nice multi-Part props.
]]

local MeshAssets = require(script.Parent.MeshAssets)

local PropFactory = {}

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = false -- welded to anchored root so bobbing moves children
	p.Massless = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	for k, v in props do
		if k ~= "Rel" then
			(p :: any)[k] = v
		end
	end
	return p
end

function PropFactory.createPickup(currencyId: string, color: Color3, scale: number?): BasePart
	local s = scale or 1
	-- NOTE: Custom MeshIds / CreateMeshPartAsync can hang or fail in Studio.
	-- Built-in neon/metal shapes always work and keep the map full of loot.
	local _asset = MeshAssets.getPickup(currencyId)
	local _ = _asset -- keep require path used; mesh path disabled for reliability

	-- Built-in prop shapes (no import needed)
	local root = Instance.new("Part")
	root.Name = currencyId
	root.Anchored = true
	root.CanCollide = false
	root.CastShadow = false
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Size = Vector3.new(2, 2, 2) * s
	root.Material = Enum.Material.SmoothPlastic
	root.Color = color

	local function child(props)
		local c = part(props)
		c.CFrame = root.CFrame * (props.Rel or CFrame.new())
		c.Parent = root
		weld(root, c)
		return c
	end

	if currencyId == "penny" or currencyId == "doubloon" or currencyId == "denarius" or currencyId == "platinum_coin" or currencyId == "chuck_e" or currencyId == "bitcoin" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(0.45 * s, 2.1 * s, 2.1 * s)
		root.Material = Enum.Material.Metal
		root.CFrame = CFrame.Angles(0, 0, math.rad(90))
		child({
			Name = "Center",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2 * s, 1.0 * s, 1.0 * s),
			Material = Enum.Material.Metal,
			Color = color:Lerp(Color3.new(1, 1, 1), 0.25),
			Rel = CFrame.new(),
		})
	elseif currencyId == "dollar" or currencyId == "fiver" or currencyId == "twenty" then
		root.Size = Vector3.new(2.4 * s, 0.15 * s, 1.3 * s)
		root.Material = Enum.Material.SmoothPlastic
		for i = 1, 4 do
			child({
				Name = "Bill" .. i,
				Size = Vector3.new(2.3 * s, 0.12 * s, 1.2 * s),
				Material = Enum.Material.SmoothPlastic,
				Color = color,
				Rel = CFrame.new(0, 0.12 * i * s, 0) * CFrame.Angles(0, math.rad(i * 3), 0),
			})
		end
		child({
			Name = "Band",
			Size = Vector3.new(2.5 * s, 0.35 * s, 0.25 * s),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(40, 40, 45),
			Rel = CFrame.new(0, 0.35 * s, 0),
		})
	elseif currencyId == "platinum_bar" then
		root.Size = Vector3.new(2.6 * s, 0.9 * s, 1.3 * s)
		root.Material = Enum.Material.Metal
	elseif currencyId == "coin_jar" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(2.4 * s, 1.6 * s, 1.6 * s)
		root.Material = Enum.Material.Glass
		root.Transparency = 0.35
		root.Color = Color3.fromRGB(180, 220, 230)
		child({
			Name = "Lid",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.35 * s, 1.3 * s, 1.3 * s),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(255, 200, 60),
			Rel = CFrame.new(0, 1.4 * s, 0),
		})
	elseif currencyId == "pearl" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(2 * s, 2 * s, 2 * s)
		root.Material = Enum.Material.SmoothPlastic
		root.Color = Color3.fromRGB(25, 25, 35)
	elseif currencyId == "dragon_egg" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(2.2 * s, 2.9 * s, 2.2 * s)
		root.Material = Enum.Material.SmoothPlastic
		root.Color = Color3.fromRGB(220, 40, 60)
		for i = 1, 3 do
			child({
				Name = "Ring" .. i,
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.15 * s, (1.6 + i * 0.15) * s, (1.6 + i * 0.15) * s),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 120, 40),
				Rel = CFrame.new(0, (-0.4 + i * 0.4) * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
			})
		end
	elseif currencyId == "star_fragment" or currencyId == "ethereum" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(1.4 * s, 2.6 * s, 1.4 * s)
		root.Material = Enum.Material.Neon
		root.Color = color
	elseif currencyId == "nebula_shard" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(2.2 * s, 2.2 * s, 2.2 * s)
		root.Material = Enum.Material.Neon
		root.Color = Color3.fromRGB(180, 80, 255)
		child({
			Name = "Core",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2 * s, 1.2 * s, 1.2 * s),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 100, 200),
			Rel = CFrame.new(),
		})
	elseif currencyId == "nft_duck" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(2.2 * s, 1.8 * s, 2.0 * s)
		root.Material = Enum.Material.SmoothPlastic
		root.Color = Color3.fromRGB(255, 210, 50)
		child({
			Name = "Head",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2 * s, 1.2 * s, 1.2 * s),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 210, 50),
			Rel = CFrame.new(1.0 * s, 0.6 * s, 0),
		})
		child({
			Name = "Beak",
			Size = Vector3.new(0.7 * s, 0.35 * s, 0.35 * s),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 120, 30),
			Rel = CFrame.new(1.7 * s, 0.5 * s, 0),
		})
	elseif currencyId == "vault_key" or currencyId == "ticket" or currencyId == "monopoly" then
		root.Size = Vector3.new(2.5 * s, 0.25 * s, 1.6 * s)
		root.Material = Enum.Material.SmoothPlastic
		root.Color = color
	elseif currencyId == "zombie_tooth" then
		root.Size = Vector3.new(0.7 * s, 1.8 * s, 0.7 * s)
		root.Material = Enum.Material.SmoothPlastic
		root.Color = Color3.fromRGB(200, 220, 180)
		child({
			Name = "Gunk",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.6 * s, 0.6 * s, 0.6 * s),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(100, 220, 80),
			Rel = CFrame.new(0, 0.9 * s, 0),
		})
	elseif currencyId == "infinity_cent" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(0.4 * s, 2.2 * s, 2.2 * s)
		root.Material = Enum.Material.Neon
		root.Color = Color3.new(1, 1, 1)
		root.CFrame = CFrame.Angles(0, 0, math.rad(90))
	elseif currencyId == "laurel" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(0.3 * s, 1.5 * s, 1.5 * s)
		root.Material = Enum.Material.Metal
		root.Color = Color3.fromRGB(255, 200, 50)
		root.CFrame = CFrame.Angles(0, 0, math.rad(90))
	else
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(2 * s, 2 * s, 2 * s)
		root.Material = Enum.Material.Neon
		root.Color = color
	end

	return root
end

return PropFactory
