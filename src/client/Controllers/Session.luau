--[[
	Session
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Session (ModuleScript)

	Client-side mirror of the player's own story state plus the request
	channel to the server. The client reads state to draw UI and decide what
	to show (stations, collectibles, quest markers) but every change is made
	by the server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Hearthscale")
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)

local Session = {}

Session.Shared = Shared
Session.Config = Config
Session.Content = Content
Session.ctx = { content = Content, config = Config }
Session.state = nil :: any
Session.saveMode = "datastore"
Session.saveEnabled = true

Session.StateChanged = Signal.new()
Session.Notified = Signal.new()
Session.SaveStatus = Signal.new()
Session.EndingShown = Signal.new()
Session.ModeChanged = Signal.new()

-- UI "modes" that block world interaction (prompts hide while any is on).
local modes = { dialogue = false, minigame = false, menu = false, cinematic = false }

local remotes

function Session.request(action: string, args: { [string]: any }?): any
	if remotes == nil then
		return { ok = false, reason = "notReady" }
	end
	local ok, result = pcall(function()
		return remotes.Request:InvokeServer(action, args or {})
	end)
	if not ok then
		warn("[Hearthscale] request failed:", action, result)
		return { ok = false, reason = "network" }
	end
	return result or { ok = false, reason = "empty" }
end

function Session.setMode(name: string, on: boolean)
	if modes[name] ~= on then
		modes[name] = on
		Session.ModeChanged:Fire(name, on)
	end
end

function Session.mode(name: string): boolean
	return modes[name] == true
end

function Session.isFree(): boolean
	return not (modes.dialogue or modes.minigame or modes.menu or modes.cinematic)
end

function Session.settings()
	return Session.state and Session.state.settings or {}
end

function Session.init()
	remotes = Net.waitClient(Shared)
	remotes.StateSync.OnClientEvent:Connect(function(state)
		Session.state = state
		Session.StateChanged:Fire(state)
	end)
	remotes.Notify.OnClientEvent:Connect(function(events)
		Session.Notified:Fire(events)
	end)
	remotes.SaveStatus.OnClientEvent:Connect(function(status, message)
		Session.SaveStatus:Fire(status, message)
	end)
	remotes.EndingShown.OnClientEvent:Connect(function(ending)
		Session.EndingShown:Fire(ending)
	end)

	-- The server may still be loading the save; keep asking politely.
	while true do
		local result = Session.request("ready")
		if result.ok then
			Session.state = result.state
			Session.saveMode = result.saveMode
			Session.saveEnabled = result.saveEnabled
			Session.StateChanged:Fire(result.state)
			return result
		end
		task.wait(0.75)
	end
end

return Session
