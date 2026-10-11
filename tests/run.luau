--[[
	Test runner:  lune run tests/run.luau  [filter]

	Runs every spec in tests/specs against the real shared game code
	(src/shared). Exits with code 1 if any test fails.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local luau = require("@lune/luau")

local Loader = require("./loader")
local Sim = require("./sim")

local root, gameRequire = Loader.mount("src/shared", "Hearthscale")

local T = { results = {}, Sim = Sim }

function T.test(name: string, fn: () -> ())
	table.insert(T.results, { name = name, fn = fn })
end

local function fmt(v)
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

function T.eq(actual, expected, label: string?)
	if actual ~= expected then
		error(`{label or "value"}: expected {fmt(expected)}, got {fmt(actual)}`, 2)
	end
end

function T.ok(value, label: string?)
	if not value then
		error(`{label or "assertion"} failed`, 2)
	end
end

function T.near(actual: number, expected: number, tolerance: number, label: string?)
	if math.abs(actual - expected) > tolerance then
		error(`{label or "value"}: expected ~{expected}, got {actual}`, 2)
	end
end

local filter = process.args[1]
local specFiles = {}
for _, entry in ipairs(fs.readDir("tests/specs")) do
	if string.sub(entry, -5) == ".luau" then
		table.insert(specFiles, entry)
	end
end
table.sort(specFiles)

for _, file in ipairs(specFiles) do
	local path = "tests/specs/" .. file
	local chunk = luau.load(fs.readFile(path), { debugName = path })
	local spec = chunk()
	spec(T, root, gameRequire, string.sub(file, 1, -6))
end

local passed, failed = 0, 0
local started = os.clock()
for _, case in ipairs(T.results) do
	if filter == nil or string.find(case.name, filter, 1, true) then
		local ok, message = pcall(case.fn)
		if ok then
			passed += 1
			print(`  ok    {case.name}`)
		else
			failed += 1
			print(`  FAIL  {case.name}\n        {tostring(message)}`)
		end
	end
end

print(string.format("\n%d passed, %d failed (%.2fs)", passed, failed, os.clock() - started))
if failed > 0 then
	process.exit(1)
end
