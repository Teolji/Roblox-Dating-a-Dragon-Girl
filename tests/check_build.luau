--[[
	Build sanity check:  lune run tests/check_build.luau
	1. Compiles every .luau file under src/ (catches syntax errors in server
	   and client code that the Lune specs can't execute).
	2. Loads the Rojo-built place file and checks script classes and the
	   expected Explorer layout.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local failures = 0
local compiled = 0

local function walk(dir: string)
	for _, entry in ipairs(fs.readDir(dir)) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			walk(path)
		elseif string.sub(entry, -5) == ".luau" then
			local ok, err = pcall(luau.compile, fs.readFile(path))
			compiled += 1
			if not ok then
				failures += 1
				print("SYNTAX  " .. path .. "\n        " .. tostring(err))
			end
		end
	end
end
walk("src")
print(`compiled {compiled} files`)

local placePath = process.args[1] or "build/Hearthscale.rbxlx"
if fs.isFile(placePath) then
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local function find(path: { string })
		local node = game
		for _, name in ipairs(path) do
			node = node:FindFirstChild(name)
			if node == nil then
				return nil
			end
		end
		return node
	end
	local expected = {
		{ { "ReplicatedStorage", "Hearthscale" }, "Folder" },
		{ { "ReplicatedStorage", "Hearthscale", "Config" }, "ModuleScript" },
		{ { "ReplicatedStorage", "Hearthscale", "Content" }, "ModuleScript" },
		{ { "ReplicatedStorage", "Hearthscale", "Content", "Dialogue" }, "ModuleScript" },
		{ { "ReplicatedStorage", "Hearthscale", "Systems", "Rules" }, "ModuleScript" },
		{ { "ServerScriptService", "HearthscaleServer", "Main" }, "Script" },
		{ { "ServerScriptService", "HearthscaleServer", "Services", "GameService" }, "ModuleScript" },
		{ { "StarterPlayer", "StarterPlayerScripts", "HearthscaleClient", "Main" }, "LocalScript" },
		{
			{ "StarterPlayer", "StarterPlayerScripts", "HearthscaleClient", "UI", "Minigames", "MinigameHost" },
			"ModuleScript",
		},
	}
	for _, e in ipairs(expected) do
		local node = find(e[1])
		local label = table.concat(e[1], ".")
		if node == nil then
			failures += 1
			print("MISSING " .. label)
		elseif node.ClassName ~= e[2] then
			failures += 1
			print(`CLASS   {label} is {node.ClassName}, expected {e[2]}`)
		end
	end
	local scripts = 0
	for _, d in ipairs(game:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		end
	end
	print(`place file has {scripts} scripts`)
else
	print("no place file at " .. placePath .. " (run: rojo build -o " .. placePath .. ")")
end

if failures > 0 then
	print(`{failures} problem(s)`)
	process.exit(1)
end
print("build check ok")
