--[[
	Mesh IDs from your Studio import (wired automatically).
	Only Cash Empire pickup/prop meshes — ViewSelector / random free models ignored.
]]

local MeshAssets = {}

local function id(n: number | string): string
	return "rbxassetid://" .. tostring(n)
end

-- currencyId → mesh
MeshAssets.Pickups = {
	penny = { meshId = id("95977318204625"), size = Vector3.new(2.2, 0.45, 2.2) },
	dollar = { meshId = id("91953316138313"), size = Vector3.new(2.4, 1.2, 1.4) },
	fiver = { meshId = id("85433662966391"), size = Vector3.new(2.5, 1.3, 1.5) },
	twenty = { meshId = id("73425768077358"), size = Vector3.new(2.6, 1.6, 1.5) },
	coin_jar = { meshId = id("76606888831903"), size = Vector3.new(2.2, 3.0, 2.2) },
	zombie_tooth = { meshId = id("128397630589252"), size = Vector3.new(1.4, 2.2, 1.4) },
	chuck_e = { meshId = id("86237000120722"), size = Vector3.new(2.3, 0.5, 2.3) },
	monopoly = { meshId = id("72438755151836"), size = Vector3.new(2.4, 1.0, 1.8) },
	ticket = { meshId = id("77297505995037"), size = Vector3.new(2.6, 0.3, 1.4) },
	doubloon = { meshId = id("83944393110023"), size = Vector3.new(2.5, 0.5, 2.5) },
	pearl = { meshId = id("74969040384665"), size = Vector3.new(2.0, 2.0, 2.0) },
	denarius = { meshId = id("137849948383035"), size = Vector3.new(2.3, 0.45, 2.3) },
	laurel = { meshId = id("81053877705915"), size = Vector3.new(2.8, 2.0, 2.8) },
	platinum_coin = { meshId = id("80669104910161"), size = Vector3.new(2.4, 0.5, 2.4) },
	platinum_bar = { meshId = id("79769603420387"), size = Vector3.new(2.8, 1.0, 1.4) },
	vault_key = { meshId = id("102388231505801"), size = Vector3.new(2.6, 0.25, 1.7) },
	bitcoin = { meshId = id("101838955226290"), size = Vector3.new(2.5, 0.5, 2.5) },
	ethereum = { meshId = id("77778109804710"), size = Vector3.new(2.0, 2.8, 2.0) },
	nft_duck = { meshId = id("134246342223051"), size = Vector3.new(2.8, 2.4, 2.4) },
	star_fragment = { meshId = id("111052748566644"), size = Vector3.new(2.0, 2.8, 2.0) },
	nebula_shard = { meshId = id("120094329376014"), size = Vector3.new(2.4, 2.4, 2.4) },
	dragon_egg = { meshId = id("78990278111732"), size = Vector3.new(2.4, 3.2, 2.4) },
	infinity_cent = { meshId = id("111949698311609"), size = Vector3.new(2.6, 2.2, 2.6) },
}

-- Optional nature meshes (for later WorldBuilder use)
MeshAssets.Nature = {
	grass_clump = { meshId = id("109107698241456"), size = Vector3.new(3, 2, 3) },
	oak_tree = { meshId = id("117619729813068"), size = Vector3.new(8, 12, 8) },
}

MeshAssets.FbxToCurrency = {
	Penny = "penny",
	DollarBill = "dollar",
	FiveSpot = "fiver",
	TwentyStack = "twenty",
	CoinJar = "coin_jar",
	ZombieTooth = "zombie_tooth",
	ChuckEToken = "chuck_e",
	MonopolyPiece = "monopoly",
	PrizeTicket = "ticket",
	GoldDoubloon = "doubloon",
	BlackPearl = "pearl",
	RomanDenarius = "denarius",
	GoldenLaurel = "laurel",
	PlatinumCoin = "platinum_coin",
	PlatinumBar = "platinum_bar",
	VaultKeycard = "vault_key",
	Bitcoin = "bitcoin",
	Ethereum = "ethereum",
	JPEGDuck = "nft_duck",
	StarFragment = "star_fragment",
	NebulaShard = "nebula_shard",
	DragonEgg = "dragon_egg",
	InfinityCent = "infinity_cent",
}

function MeshAssets.getPickup(currencyId: string)
	return MeshAssets.Pickups[currencyId]
end

function MeshAssets.hasCustomMesh(currencyId: string): boolean
	local a = MeshAssets.Pickups[currencyId]
	return a ~= nil and type(a.meshId) == "string" and string.find(a.meshId, "rbxassetid://") ~= nil
end

return MeshAssets
