--[[
	Loads the game's shared ModuleScripts outside Roblox, using Lune.

	Mirrors Rojo's file mapping for one directory:
	  dir/            -> Folder (or ModuleScript if it has init.luau)
	  name.luau       -> ModuleScript "name"
	and provides a tiny fake Instance (Name, Parent, GetChildren,
	FindFirstChild, WaitForChild, IsA, child access by name) plus a
	`require` that accepts those fake instances. Only Roblox-free modules
	(ReplicatedStorage > Hearthscale) are loaded this way.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Loader = {}

local Instance = {}

local function newInstance(name, className, parent, source, path)
	local self = {
		_name = name,
		_className = className,
		_parent = parent,
		_children = {},
		_source = source,
		_path = path,
	}
	return setmetatable(self, Instance)
end

Instance.__index = function(self, key)
	if key == "Name" then
		return rawget(self, "_name")
	elseif key == "Parent" then
		return rawget(self, "_parent")
	elseif key == "ClassName" then
		return rawget(self, "_className")
	elseif Instance[key] then
		return Instance[key]
	end
	local child = rawget(self, "_children")[key]
	if child then
		return child
	end
	error(`{tostring(key)} is not a valid member of {rawget(self, "_className")} "{rawget(self, "_name")}"`, 2)
end

Instance.__tostring = function(self)
	return rawget(self, "_name")
end

function Instance.GetChildren(self)
	local out = {}
	for _, child in pairs(rawget(self, "_children")) do
		table.insert(out, child)
	end
	table.sort(out, function(a, b)
		return a.Name < b.Name
	end)
	return out
end

function Instance.FindFirstChild(self, name)
	return rawget(self, "_children")[name]
end

function Instance.WaitForChild(self, name)
	local child = rawget(self, "_children")[name]
	assert(child, `WaitForChild would yield forever: {name}`)
	return child
end

function Instance.IsA(self, className)
	return rawget(self, "_className") == className
end

local function build(path, name, parent)
	local init = path .. "/init.luau"
	local node
	if fs.isFile(init) then
		node = newInstance(name, "ModuleScript", parent, fs.readFile(init), init)
	else
		node = newInstance(name, "Folder", parent, nil, path)
	end
	for _, entry in ipairs(fs.readDir(path)) do
		local full = path .. "/" .. entry
		if fs.isDir(full) then
			rawget(node, "_children")[entry] = build(full, entry, node)
		elseif entry ~= "init.luau" and string.sub(entry, -5) == ".luau" then
			local base = string.sub(entry, 1, -6)
			if not string.find(base, "%.server$") and not string.find(base, "%.client$") then
				rawget(node, "_children")[base] = newInstance(base, "ModuleScript", node, fs.readFile(full), full)
			end
		end
	end
	return node
end

function Loader.mount(path: string, name: string)
	local root = build(path, name, nil)
	local cache = {}

	local function requireModule(module)
		if type(module) ~= "table" or getmetatable(module) ~= Instance then
			error("require expects a fake ModuleScript instance", 2)
		end
		if cache[module] ~= nil then
			return cache[module]
		end
		assert(rawget(module, "_className") == "ModuleScript", `{module.Name} is not a ModuleScript`)
		local chunk = luau.load(rawget(module, "_source"), {
			debugName = rawget(module, "_path"),
			environment = { script = module, require = requireModule },
		})
		local result = chunk()
		cache[module] = result
		return result
	end

	return root, requireModule
end

return Loader
