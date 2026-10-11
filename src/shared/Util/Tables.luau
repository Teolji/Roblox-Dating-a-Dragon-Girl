--[[
	Tables
	Explorer: ReplicatedStorage > Hearthscale > Util > Tables (ModuleScript)
]]

local Tables = {}

function Tables.deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value :: any) do
		out[Tables.deepCopy(k)] = Tables.deepCopy(v)
	end
	return out :: any
end

function Tables.count(t: { [any]: any }): number
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

function Tables.keys(t: { [any]: any }): { any }
	local out = {}
	for k in pairs(t) do
		table.insert(out, k)
	end
	table.sort(out, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return out
end

function Tables.contains(list: { any }, value: any): boolean
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

-- A table is treated as a list when it has a [1] entry.
function Tables.isList(t: any): boolean
	return type(t) == "table" and t[1] ~= nil
end

return Tables
