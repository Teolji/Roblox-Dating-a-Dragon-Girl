--[[
	Main (server bootstrap)
	Explorer: ServerScriptService > HearthscaleServer > Main (Script)

	Starts the server: validates content, builds the placeholder world if
	needed, creates remotes, then wires DataService (saves) and GameService
	(all player actions).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Hearthscale")
local Services = script.Parent:WaitForChild("Services")

local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Net = require(Shared.Net)
local ContentValidator = require(Shared.Systems.ContentValidator)

local WorldBuilder = require(Services.WorldBuilder)
local DataService = require(Services.DataService)
local GameService = require(Services.GameService)

local ctx = { content = Content, config = Config, shared = Shared }

-- Content problems are bugs: shout about them in Studio, log them live.
local problems = ContentValidator.validate(ctx)
for _, problem in ipairs(problems) do
	warn("[Hearthscale content] " .. problem)
end
if #problems > 0 and RunService:IsStudio() then
	warn(`[Hearthscale] {#problems} content problem(s) found — see above.`)
end

WorldBuilder.build(ctx)

local remotes = Net.createServer(Shared)

DataService.init(ctx, function(player, status, message)
	if player.Parent then
		remotes.SaveStatus:FireClient(player, status, message)
	end
end)
GameService.init(ctx, DataService, remotes)

local function onPlayerAdded(player: Player)
	DataService.load(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print(`[Hearthscale] server ready ({if Config.RomanceEnabled then "romance" else "friendship"} edition)`)
