--[[
	Prng
	Explorer: ReplicatedStorage > Hearthscale > Util > Prng (ModuleScript)

	Small deterministic Park–Miller generator. Used instead of Roblox's Random
	so shared systems run identically in Studio and in the Lune test suite.
]]

local Prng = {}
Prng.__index = Prng

local MODULUS = 2147483647
local MULTIPLIER = 16807

function Prng.new(seed: number?)
	local s = math.floor(math.abs(seed or 1)) % MODULUS
	if s == 0 then
		s = 1
	end
	return setmetatable({ _state = s }, Prng)
end

function Prng:nextInt(): number
	self._state = (self._state * MULTIPLIER) % MODULUS
	return self._state
end

-- Float in [0, 1)
function Prng:nextNumber(): number
	return (self:nextInt() - 1) / (MODULUS - 1)
end

-- Integer in [min, max]
function Prng:range(min: number, max: number): number
	return min + (self:nextInt() % (max - min + 1))
end

function Prng:shuffle(list: { any }): { any }
	for i = #list, 2, -1 do
		local j = self:range(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function Prng:pick(list: { any }): any
	return list[self:range(1, #list)]
end

return Prng
