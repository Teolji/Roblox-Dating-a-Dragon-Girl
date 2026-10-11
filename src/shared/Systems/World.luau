--[[
	World
	Explorer: ReplicatedStorage > Hearthscale > Systems > World (ModuleScript)

	Per-player world rules: where each NPC currently stands (stations),
	which collectibles exist for this player, and which locations count as
	"reached". Server and client evaluate the same rules on the same state,
	so every player's village reflects only their own story.
]]

local Conditions = require(script.Parent.Conditions)
local Rules = require(script.Parent.Rules)

local World = {}

-- Anchor name for an NPC, or nil when the NPC is absent for this player.
function World.station(state, npcId: string, ctx): string?
	local char = ctx.content.Characters[npcId]
	if char == nil then
		return nil
	end
	for _, s in ipairs(char.stations or {}) do
		if Conditions.check(s.when, state, ctx) then
			if s.hidden then
				return nil
			end
			return s.anchor
		end
	end
	return nil
end

function World.collectibleAvailable(state, colId: string, ctx): boolean
	local def = ctx.content.Collectibles[colId]
	if def == nil or state.collected[colId] then
		return false
	end
	return Conditions.check(def.when, state, ctx)
end

function World.collect(state, colId: string, ctx, events): boolean
	if not World.collectibleAvailable(state, colId, ctx) then
		return false
	end
	local def = ctx.content.Collectibles[colId]
	state.collected[colId] = true
	Rules.applyEffects(state, def.effects, ctx, events)
	Rules.emit(state, "collect:" .. (def.group or colId), ctx, events)
	Rules.settle(state, ctx, events)
	return true
end

-- Locations whose "reach:<id>" event an active objective is waiting for.
function World.pendingReaches(state, ctx): { string }
	local out = {}
	for locId in pairs(ctx.content.Locations) do
		if Rules.wantsEvent(state, "reach:" .. locId, ctx) then
			table.insert(out, locId)
		end
	end
	table.sort(out)
	return out
end

function World.reach(state, locId: string, ctx, events): boolean
	if not Rules.wantsEvent(state, "reach:" .. locId, ctx) then
		return false
	end
	Rules.emit(state, "reach:" .. locId, ctx, events)
	Rules.settle(state, ctx, events)
	return true
end

-- Every anchor name the content refers to (used by WorldBuilder + tests).
function World.referencedAnchors(ctx): { [string]: boolean }
	local out = {}
	for _, char in pairs(ctx.content.Characters) do
		for _, s in ipairs(char.stations or {}) do
			if s.anchor then
				out[s.anchor] = true
			end
		end
	end
	for _, col in pairs(ctx.content.Collectibles) do
		out[col.anchor] = true
	end
	for _, loc in pairs(ctx.content.Locations) do
		out[loc.anchor] = true
	end
	for _, act in pairs(ctx.content.Activities) do
		if act.anchor then
			out[act.anchor] = true
		end
		if act.kind == "collect" then
			for _, p in ipairs(act.params.points) do
				out[p] = true
			end
		end
	end
	return out
end

return World
