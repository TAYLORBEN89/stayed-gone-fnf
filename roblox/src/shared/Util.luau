local Util = {}

function Util.formatNumber(n: number): string
	n = math.floor(tonumber(n) or 0)
	local neg = n < 0
	n = math.abs(n)
	local s
	if n >= 1e12 then
		s = string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then
		s = string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		s = string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		s = string.format("%.1fK", n / 1e3)
	else
		s = tostring(n)
	end
	return neg and ("-" .. s) or s
end

function Util.weightedChoice(items: { any }, weightKey: string, weightScale: ((any) -> number)?)
	local total = 0
	local weights = {}
	for i, item in items do
		local w = item[weightKey] or 1
		if weightScale then
			w = w * weightScale(item)
		end
		weights[i] = w
		total += w
	end
	if total <= 0 then
		return items[1]
	end
	local r = math.random() * total
	local acc = 0
	for i, item in items do
		acc += weights[i]
		if r <= acc then
			return item
		end
	end
	return items[#items]
end

function Util.randomInRing(center: Vector3, minR: number, maxR: number): Vector3
	local angle = math.random() * math.pi * 2
	local r = minR + math.random() * math.max(0, maxR - minR)
	return Vector3.new(center.X + math.cos(angle) * r, 0, center.Z + math.sin(angle) * r)
end

function Util.deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local n = {}
	for k, v in t do
		n[k] = Util.deepCopy(v)
	end
	return n
end

return Util
