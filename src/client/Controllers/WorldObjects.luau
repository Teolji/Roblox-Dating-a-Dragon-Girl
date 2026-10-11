--[[
	WorldObjects
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > WorldObjects (ModuleScript)

	Local, per-player pickups and activity spots. Each collectible exists only
	in this player's world while their story makes it available; picking it up
	asks the server (which checks distance and conditions). Activity spots
	show a "Begin" prompt when that outing is available.

	Visuals are PLACEHOLDER glowing shapes; swap in models later by name.
]]

local TweenService = game:GetService("TweenService")

local Session = require(script.Parent.Session)

local World = require(Session.Shared.Systems.World)
local Activities = require(Session.Shared.Systems.Activities)
local WorldAnchors = require(Session.Shared.WorldAnchors)

local WorldObjects = {}

local folder: Folder
local pickups = {} -- [collectibleId] = part
local spots = {} -- [activityId] = part
local hooks = {
	toast = function(_text: string) end,
	startActivity = function(_payload) end,
}

local function hexColor(hex: string?): Color3
	local ok, color = pcall(Color3.fromHex, hex or "#FFD27A")
	return ok and color or Color3.fromRGB(255, 210, 122)
end

local function makePickup(id: string, def)
	local position = WorldAnchors.position(def.anchor)
	if position == nil then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = "Pickup_" .. id
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.4, 1.4, 1.4)
	part.Material = Enum.Material.Neon
	part.Color = hexColor(def.color)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Position = position
	local light = Instance.new("PointLight")
	light.Range = 8
	light.Brightness = 1
	light.Color = part.Color
	light.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = def.name or "Something"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function()
		if not Session.isFree() then
			return
		end
		prompt.Enabled = false
		local result = Session.request("collect", { id = id })
		if result.ok then
			if result.text then
				hooks.toast(result.text)
			end
			part:Destroy()
			pickups[id] = nil
		else
			prompt.Enabled = true
			if result.reason == "tooFar" then
				hooks.toast("A little closer…")
			end
		end
	end)
	-- Gentle bob so pickups read as interactive.
	if not Session.settings().reduceMotion then
		TweenService:Create(
			part,
			TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = position + Vector3.new(0, 0.6, 0) }
		):Play()
	end
	part.Parent = folder
	return part
end

local function makeSpot(actId: string, def)
	local position = WorldAnchors.position(def.anchor)
	if position == nil then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = "Activity_" .. actId
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Position = position + Vector3.new(0, 2.5, 0)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Begin"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function()
		if not Session.isFree() then
			return
		end
		local result = Session.request("startActivity", { activity = actId })
		if result.ok then
			hooks.startActivity(result.activity)
		elseif result.reason == "tooFar" then
			hooks.toast("A little closer…")
		end
	end)
	part.Parent = folder
	return part
end

function WorldObjects.refresh()
	local state = Session.state
	if state == nil then
		return
	end
	for id, def in pairs(Session.Content.Collectibles) do
		local available = World.collectibleAvailable(state, id, Session.ctx)
		if available and pickups[id] == nil then
			pickups[id] = makePickup(id, def)
		elseif not available and pickups[id] then
			pickups[id]:Destroy()
			pickups[id] = nil
		end
	end
	for actId, def in pairs(Session.Content.Activities) do
		local available = def.anchor ~= nil and (Activities.canStart(state, actId, Session.ctx))
		if available and spots[actId] == nil then
			spots[actId] = makeSpot(actId, def)
		elseif not available and spots[actId] then
			spots[actId]:Destroy()
			spots[actId] = nil
		end
	end
	WorldObjects.updatePrompts()
end

function WorldObjects.updatePrompts()
	local free = Session.isFree()
	for _, part in pairs(pickups) do
		local prompt = part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = free
		end
	end
	for _, part in pairs(spots) do
		local prompt = part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = free
		end
	end
end

function WorldObjects.init(hookTable)
	hooks = hookTable
	folder = Instance.new("Folder")
	folder.Name = "HearthscaleLocalObjects"
	folder.Parent = workspace
	Session.StateChanged:Connect(WorldObjects.refresh)
	Session.ModeChanged:Connect(WorldObjects.updatePrompts)
	WorldObjects.refresh()
end

return WorldObjects
