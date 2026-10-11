--[[
	Objectives
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Objectives (ModuleScript)

	Read-only helpers that turn quest state into UI text and a waypoint
	target ("Saffron · 42 m"). Works out which NPC/spot satisfies each
	objective by scanning the content data, so new quests need no UI code.
]]

local Session = require(script.Parent.Session)

local Content = Session.Content
local ctx = Session.ctx
local Rules = require(Session.Shared.Systems.Rules)
local World = require(Session.Shared.Systems.World)
local WorldAnchors = require(Session.Shared.WorldAnchors)

local Objectives = {}

-- event name -> npc id whose conversation emits it
local eventNpc = {}
do
	local function scan(effects, npc)
		if type(effects) ~= "table" then
			return
		end
		if effects[1] ~= nil then
			for _, e in ipairs(effects) do
				scan(e, npc)
			end
			return
		end
		local ev = effects.event
		if type(ev) == "string" then
			eventNpc[ev] = npc
		elseif type(ev) == "table" then
			for _, name in ipairs(ev) do
				eventNpc[name] = npc
			end
		end
	end
	for _, conv in pairs(Content.Conversations) do
		scan(conv.onEnd, conv.npc)
		for _, node in pairs(conv.nodes) do
			scan(node.effects, conv.npc)
			for _, choice in ipairs(node.choices or {}) do
				scan(choice.effects, conv.npc)
			end
		end
	end
end

function Objectives.activeQuests(state)
	local out = {}
	for _, questId in ipairs(Content.QuestOrder) do
		local q = state.quests[questId]
		if q and q.s == "active" then
			table.insert(out, questId)
		end
	end
	return out
end

function Objectives.describe(state, questId: string)
	local def = Content.Quests[questId]
	local q = state.quests[questId]
	local step = def.steps[q.step]
	local objectives = {}
	for _, obj in ipairs(step.objectives or {}) do
		local done = Rules.objectiveDone(state, q, obj, ctx)
		table.insert(objectives, {
			text = obj.text,
			progress = obj.event and (q.p[obj.id] or 0) or (done and 1 or 0),
			count = obj.event and (obj.count or 1) or 1,
			done = done,
			event = obj.event,
		})
	end
	return {
		questId = questId,
		title = def.title,
		summary = def.summary,
		stepText = step.text,
		hint = step.hint,
		objectives = objectives,
	}
end

function Objectives.current(state)
	local first = Objectives.activeQuests(state)[1]
	return first and Objectives.describe(state, first) or nil
end

local function npcTarget(state, npc: string)
	local anchor = World.station(state, npc, ctx)
	local position = WorldAnchors.position(anchor)
	if position then
		return position + Vector3.new(0, 6, 0), Content.Characters[npc].name
	end
	return nil
end

local function nearestCollectible(state, group: string, from: Vector3?)
	local best, bestDistance, name = nil, math.huge, nil
	for id, def in pairs(Content.Collectibles) do
		if (def.group or id) == group and World.collectibleAvailable(state, id, ctx) then
			local position = WorldAnchors.position(def.anchor)
			if position then
				local d = from and (position - from).Magnitude or 0
				if d < bestDistance then
					best, bestDistance, name = position, d, def.name
				end
			end
		end
	end
	return best, name
end

-- Where should the waypoint point? Returns position, label (or nil).
function Objectives.target(state, from: Vector3?)
	for _, questId in ipairs(Objectives.activeQuests(state)) do
		local info = Objectives.describe(state, questId)
		for _, obj in ipairs(info.objectives) do
			if not obj.done and obj.event then
				local kind, id = string.match(obj.event, "^(%w+):(.+)$")
				if kind == "collect" then
					local position, name = nearestCollectible(state, id, from)
					if position then
						return position + Vector3.new(0, 3, 0), name
					end
				elseif kind == "reach" then
					local loc = Content.Locations[id]
					local position = loc and WorldAnchors.position(loc.anchor)
					if position then
						return position + Vector3.new(0, 4, 0), loc.name
					end
				elseif kind == "activity" then
					local act = Content.Activities[id]
					if act and act.partner then
						local position, name = npcTarget(state, act.partner)
						if position then
							return position, name
						end
					end
					if act and act.anchor then
						return (WorldAnchors.position(act.anchor) :: Vector3) + Vector3.new(0, 4, 0), act.name
					end
				else
					local npc = eventNpc[obj.event]
					if npc then
						local position, name = npcTarget(state, npc)
						if position then
							return position, name
						end
					end
				end
			end
		end
	end
	return nil, nil
end

return Objectives
