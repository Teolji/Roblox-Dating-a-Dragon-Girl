--[[
	Conditions
	Explorer: ReplicatedStorage > Hearthscale > Systems > Conditions (ModuleScript)

	Evaluates data-driven requirement tables against a player's story state.
	Used by dialogue, quests, milestones, stations, activities and endings,
	on both server (authoritative) and client (display only).

	A condition is either:
	  • a list   { c1, c2, ... }        → all must pass
	  • a table  { key = value, ... }   → every clause must pass

	Clauses (relationship stats default to npc "saffron"):
	  flag = "x"                    notFlag = "x"
	  stat = { "trust", 20 [, npc] }          (stat >= value)
	  statBelow = { "trust", 40 [, npc] }     (stat < value)
	  quest = { "q_id", "notStarted" | "active" | "complete" | "started" }
	  questStep = { "q_id", "stepId" }        (quest active and on that step)
	  item = "id"  |  { "id", count }
	  chapter = n    chapterMin = n    chapterMax = n
	  milestone = "friend"          (rank at least that milestone's rank)
	  milestoneIs = "sweetheart"    (exact milestone)
	  canReachMilestone = "friend"  (that milestone's requirements pass now)
	  path = "none" | "friendship" | "romance"
	  romance = true                (Config.RomanceEnabled must be true)
	  activity = "act_id"           (completed at least once)
	  ending = "id"   noEnding = true   anyEnding = true
	  giftReady = true | false  [, npc implied saffron]
	  all = {...}   any = {...}   ["not"] = {...}
]]

local Conditions = {}

local DEFAULT_NPC = "saffron"

local function relOf(state, npc)
	return state.rel and state.rel[npc or DEFAULT_NPC]
end

function Conditions.milestoneRank(ctx, milestoneId: string?): number
	if milestoneId == nil then
		return -1
	end
	local m = ctx.content.MilestoneById[milestoneId]
	return m and m.rank or -1
end

function Conditions.questStatus(state, questId: string): string
	local q = state.quests[questId]
	if q == nil then
		return "notStarted"
	end
	return q.s
end

local Handlers: { [string]: (any, any, any) -> boolean } = {}

Handlers.flag = function(value, state)
	return state.flags[value] == true
end

Handlers.notFlag = function(value, state)
	return state.flags[value] ~= true
end

Handlers.stat = function(value, state)
	local rel = relOf(state, value[3])
	return rel ~= nil and (rel[value[1]] or 0) >= value[2]
end

Handlers.statBelow = function(value, state)
	local rel = relOf(state, value[3])
	return rel == nil or (rel[value[1]] or 0) < value[2]
end

Handlers.quest = function(value, state)
	local status = Conditions.questStatus(state, value[1])
	if value[2] == "started" then
		return status ~= "notStarted"
	end
	return status == value[2]
end

Handlers.questStep = function(value, state, ctx)
	local q = state.quests[value[1]]
	if q == nil or q.s ~= "active" then
		return false
	end
	local def = ctx.content.Quests[value[1]]
	local step = def and def.steps[q.step]
	return step ~= nil and step.id == value[2]
end

Handlers.item = function(value, state)
	local id, count
	if type(value) == "table" then
		id, count = value[1], value[2] or 1
	else
		id, count = value, 1
	end
	return (state.inv[id] or 0) >= count
end

Handlers.chapter = function(value, state)
	return state.chapter == value
end

Handlers.chapterMin = function(value, state)
	return state.chapter >= value
end

Handlers.chapterMax = function(value, state)
	return state.chapter <= value
end

Handlers.milestone = function(value, state, ctx)
	local rel = relOf(state)
	if rel == nil then
		return false
	end
	return Conditions.milestoneRank(ctx, rel.milestone) >= Conditions.milestoneRank(ctx, value)
end

Handlers.milestoneIs = function(value, state)
	local rel = relOf(state)
	return rel ~= nil and rel.milestone == value
end

Handlers.canReachMilestone = function(value, state, ctx)
	local m = ctx.content.MilestoneById[value]
	if m == nil then
		return false
	end
	if m.romance and not ctx.config.RomanceEnabled then
		return false
	end
	return Conditions.check(m.requires, state, ctx)
end

Handlers.path = function(value, state)
	return (state.path or "none") == value
end

Handlers.romance = function(value, _state, ctx)
	return (ctx.config.RomanceEnabled == true) == value
end

Handlers.activity = function(value, state)
	local a = state.acts[value]
	return a ~= nil and (a.plays or 0) > 0
end

Handlers.ending = function(value, state)
	return state.ending == value
end

Handlers.noEnding = function(value, state)
	return (state.ending == nil) == value
end

Handlers.anyEnding = function(value, state)
	return (state.ending ~= nil) == value
end

Handlers.giftReady = function(value, state)
	local rel = relOf(state)
	return rel ~= nil and (rel.giftReady == true) == value
end

Handlers.all = function(value, state, ctx)
	for _, c in ipairs(value) do
		if not Conditions.check(c, state, ctx) then
			return false
		end
	end
	return true
end

Handlers.any = function(value, state, ctx)
	for _, c in ipairs(value) do
		if Conditions.check(c, state, ctx) then
			return true
		end
	end
	return false
end

Handlers["not"] = function(value, state, ctx)
	return not Conditions.check(value, state, ctx)
end

Conditions.Keys = {}
for key in pairs(Handlers) do
	Conditions.Keys[key] = true
end

function Conditions.check(cond: any, state: any, ctx: any): boolean
	if cond == nil then
		return true
	end
	if cond[1] ~= nil then
		for _, c in ipairs(cond) do
			if not Conditions.check(c, state, ctx) then
				return false
			end
		end
		return true
	end
	for key, value in pairs(cond) do
		local handler = Handlers[key]
		if handler == nil then
			error(`Unknown condition key '{tostring(key)}'`)
		end
		if not handler(value, state, ctx) then
			return false
		end
	end
	return true
end

--[[
	Produces a readable checklist for UI ("Trust 20+", "Complete: The Old Bridge").
	Returns { { text = string, met = boolean } }. Only covers the clause types
	used in milestone requirements; others are summarised generically.
]]
function Conditions.describe(cond: any, state: any, ctx: any): { { text: string, met: boolean } }
	local out = {}
	local function add(text, c)
		table.insert(out, { text = text, met = Conditions.check(c, state, ctx) })
	end
	local function visit(c)
		if c == nil then
			return
		end
		if c[1] ~= nil then
			for _, sub in ipairs(c) do
				visit(sub)
			end
			return
		end
		for key, value in pairs(c) do
			local clause = { [key] = value }
			if key == "stat" then
				local label = (ctx.content.StatLabels or {})[value[1]] or value[1]
				add(`{label} {value[2]}+`, clause)
			elseif key == "quest" then
				local q = ctx.content.Quests[value[1]]
				local title = q and q.title or value[1]
				if value[2] == "complete" then
					add(`Complete "{title}"`, clause)
				else
					add(`Quest "{title}" ({value[2]})`, clause)
				end
			elseif key == "path" then
				add(value == "romance" and "You both chose romance" or "You chose to stay close friends", clause)
			elseif key == "flag" then
				local hint = (ctx.content.FlagHints or {})[value]
				add(hint or "Story event", clause)
			elseif key == "activity" then
				local a = ctx.content.Activities[value]
				add(`Share "{a and a.name or value}"`, clause)
			elseif key == "milestone" then
				local m = ctx.content.MilestoneById[value]
				add(`Reach "{m and m.title or value}"`, clause)
			else
				add("Story progress", clause)
			end
		end
	end
	visit(cond)
	return out
end

return Conditions
