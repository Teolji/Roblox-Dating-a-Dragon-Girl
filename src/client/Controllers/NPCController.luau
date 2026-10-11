--[[
	NPCController
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > NPCController (ModuleScript)

	Spawns every NPC LOCALLY for this player, at the station their own story
	puts them (shared/Systems/World.station). Two players on one server can
	be in different chapters: each sees Saffron where their own story needs
	her, and nobody sees anyone else's conversations or relationship.

	Models: ReplicatedStorage.HearthscaleAssets.NPCs.<npcId> if present,
	otherwise a PlaceholderRig. Talking uses a local ProximityPrompt, which
	asks the server (which re-checks distance and story state).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Session = require(script.Parent.Session)
local PlaceholderRig = require(script.Parent.PlaceholderRig)
local Expressions = require(script.Parent.Expressions)

local World = require(Session.Shared.Systems.World)
local Dialogue = require(Session.Shared.Systems.Dialogue)
local WorldAnchors = require(Session.Shared.WorldAnchors)

local NPCController = {}

local npcs = {} -- [npcId] = { model, anchor, prompt, hip, baseCFrame, lookAt }
local folder: Folder
local onTalk: (string) -> () = function(_npcId: string) end

local function templateFor(npcId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("HearthscaleAssets")
	local npcFolder = assets and assets:FindFirstChild("NPCs")
	local template = npcFolder and npcFolder:FindFirstChild(npcId)
	if template and template:IsA("Model") then
		return template
	end
	return nil
end

-- Finds the ground under an anchor so models stand on any custom map.
local function groundCFrame(anchorCFrame: CFrame): CFrame
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { folder }
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local origin = anchorCFrame.Position + Vector3.new(0, 6, 0)
	local hit = workspace:Raycast(origin, Vector3.new(0, -14, 0), params)
	local y = hit and hit.Position.Y or anchorCFrame.Position.Y
	local _, yaw = anchorCFrame:ToOrientation()
	return CFrame.new(anchorCFrame.Position.X, y, anchorCFrame.Position.Z) * CFrame.Angles(0, yaw, 0)
end

local function makePrompt(npcId: string, model: Model)
	local char = Session.Content.Characters[npcId]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = char.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function()
		if Session.isFree() then
			onTalk(npcId)
		end
	end)
	return prompt
end

local function spawnNpc(npcId: string, anchorName: string)
	local char = Session.Content.Characters[npcId]
	local anchorCFrame = WorldAnchors.get(anchorName)
	if anchorCFrame == nil then
		warn("[Hearthscale] missing anchor", anchorName)
		return
	end
	local template = templateFor(npcId)
	local model: Model
	local hip: number
	if template then
		model = template:Clone()
		if model.PrimaryPart == nil then
			model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
				or model:FindFirstChildWhichIsA("BasePart", true)
		end
		local humanoid = model:FindFirstChildWhichIsA("Humanoid")
		hip = humanoid and (humanoid.HipHeight + model.PrimaryPart.Size.Y / 2) or model.PrimaryPart.Size.Y / 2
		model.PrimaryPart.Anchored = true
	else
		model = PlaceholderRig.build(npcId, char)
		hip = PlaceholderRig.hipHeight(char)
	end
	local base = groundCFrame(anchorCFrame) * CFrame.new(0, hip, 0)
	model:PivotTo(base)
	model.Parent = folder
	Expressions.attach(model, npcId, template == nil)
	npcs[npcId] = {
		model = model,
		anchor = anchorName,
		prompt = makePrompt(npcId, model),
		baseCFrame = base,
		lookAt = nil,
	}
end

local function despawn(npcId: string)
	local entry = npcs[npcId]
	if entry then
		Expressions.detach(entry.model)
		entry.model:Destroy()
		npcs[npcId] = nil
	end
end

-- Pending story conversation => "!" over the head.
local function updateMarker(npcId: string, entry)
	local head = entry.model:FindFirstChild("Head", true)
	local marker = head and head:FindFirstChild("QuestMarker")
	if marker == nil then
		return
	end
	local convId = Dialogue.pick(Session.state, npcId, Session.ctx)
	local conv = convId and Session.Content.Conversations[convId]
	marker.Enabled = conv ~= nil and (conv.priority or 0) >= 800
end

function NPCController.refresh()
	local state = Session.state
	if state == nil then
		return
	end
	-- Don't move anyone mid-scene; ModeChanged triggers a refresh afterwards.
	if Session.mode("dialogue") or Session.mode("minigame") then
		NPCController.updatePrompts()
		return
	end
	for npcId in pairs(Session.Content.Characters) do
		local anchor = World.station(state, npcId, Session.ctx)
		local entry = npcs[npcId]
		if entry and entry.anchor ~= anchor then
			despawn(npcId)
			entry = nil
		end
		if anchor and entry == nil then
			spawnNpc(npcId, anchor)
			entry = npcs[npcId]
		end
		if entry then
			updateMarker(npcId, entry)
		end
	end
	NPCController.updatePrompts()
end

function NPCController.updatePrompts()
	local free = Session.isFree()
	for _, entry in pairs(npcs) do
		entry.prompt.Enabled = free
	end
end

function NPCController.setExpression(npcId: string, emote: string)
	local entry = npcs[npcId]
	if entry then
		Expressions.set(entry.model, emote)
	end
end

-- Turn toward a world position (or back to the station facing with nil).
function NPCController.lookAt(npcId: string, position: Vector3?)
	local entry = npcs[npcId]
	if entry then
		entry.lookAt = position
	end
end

function NPCController.model(npcId: string): Model?
	local entry = npcs[npcId]
	return entry and entry.model
end

function NPCController.init(talkCallback: (string) -> ())
	onTalk = talkCallback
	folder = Instance.new("Folder")
	folder.Name = "HearthscaleLocalNPCs"
	folder.Parent = workspace
	Session.StateChanged:Connect(NPCController.refresh)
	Session.ModeChanged:Connect(NPCController.refresh)
	NPCController.refresh()

	-- Smoothly face the player during conversations.
	RunService.Heartbeat:Connect(function(dt)
		for _, entry in pairs(npcs) do
			local root = entry.model.PrimaryPart
			if root then
				local target = entry.baseCFrame
				if entry.lookAt then
					local flat = Vector3.new(entry.lookAt.X, entry.baseCFrame.Position.Y, entry.lookAt.Z)
					if (flat - entry.baseCFrame.Position).Magnitude > 0.5 then
						target = CFrame.lookAt(entry.baseCFrame.Position, flat)
					end
				end
				local current = entry.model:GetPivot()
				entry.model:PivotTo(current:Lerp(target, math.clamp(dt * 6, 0, 1)))
			end
		end
	end)
end

return NPCController
