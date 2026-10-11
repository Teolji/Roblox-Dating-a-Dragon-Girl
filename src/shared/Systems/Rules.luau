--[[
	Rules
	Explorer: ReplicatedStorage > Hearthscale > Systems > Rules (ModuleScript)

	The story engine. Applies data-driven effects, advances quests, fires
	story-director rules, promotes relationship milestones and resolves
	endings. Pure Luau (no Roblox services) so the same code runs in the
	server and in the Lune test suite.

	Every mutating call appends notification records to `events`, e.g.
	  { kind = "stat", npc = "saffron", stat = "trust", delta = 3 }
	  { kind = "item", item = "glowcap", delta = 1 }
	  { kind = "questStarted" | "questStep" | "questComplete", quest = id }
	  { kind = "milestone", npc = id, milestone = id }
	  { kind = "chapter", chapter = n }
	  { kind = "ending", ending = id }
	  { kind = "toast", text = string }
	  { kind = "action", action = "startActivity" | "openGift" | ..., ... }

	Effect keys (one table may combine several; lists are applied in order):
	  flag = "x" | {...}           unflag = "x" | {...}
	  stat = { "trust", 3 [, npc] } | { {..}, {..} }
	  softStat = same as stat, but positive affinity respects Config.SoftAffinityCap
	  give = "id" | { "id", n }    take = "id" | { "id", n }
	  startQuest = "q_id"          path = "friendship" | "romance" | "none"
	  chapter = n                  giftReady = true | false
	  event = "name" | {...}       toast = "text"
	  startActivity = "act_id"     action = { action = "openGift", npc = "saffron" }
	  resolveEnding = true
]]

local Conditions = require(script.Parent.Conditions)
local SaveSchema = require(script.Parent.SaveSchema)
local Tables = require(script.Parent.Parent.Util.Tables)

local Rules = {}

local DEFAULT_NPC = "saffron"
local SETTLE_LIMIT = 64

local function push(events, record)
	if events then
		table.insert(events, record)
	end
end

local function asList(value)
	if type(value) == "table" then
		return value
	end
	return { value }
end

local function relOf(state, npc)
	npc = npc or DEFAULT_NPC
	local rel = state.rel[npc]
	if rel == nil then
		rel = SaveSchema.newRelationship()
		state.rel[npc] = rel
	end
	return rel
end

-- Stats --------------------------------------------------------------------

function Rules.addStat(state, ctx, npc: string?, stat: string, delta: number, events, soft: boolean?): number
	local config = ctx.config
	if stat == "romance" and not config.RomanceEnabled then
		return 0
	end
	local rel = relOf(state, npc)
	local max = (stat == "resolve") and config.ResolveMax or config.StatMax
	local before = rel[stat] or 0
	local after = math.clamp(before + delta, 0, max)
	if soft and delta > 0 and stat == "affinity" then
		local cap = config.SoftAffinityCap[rel.milestone] or max
		after = math.min(after, math.max(before, cap))
	end
	rel[stat] = after
	local applied = after - before
	if applied ~= 0 then
		push(events, { kind = "stat", npc = npc or DEFAULT_NPC, stat = stat, delta = applied })
	end
	return applied
end

-- A "progress beat" (finished quest step, first-time activity) is what lets
-- Saffron accept another gift. This replaces timers and blocks gift grinding.
function Rules.markProgressBeat(state, ctx)
	for npcId, char in pairs(ctx.content.Characters) do
		if char.gifts and state.rel[npcId] then
			state.rel[npcId].giftReady = true
		end
	end
end

-- Effects ------------------------------------------------------------------

local EffectHandlers = {}
local EffectOrder = {
	"flag",
	"unflag",
	"stat",
	"softStat",
	"give",
	"take",
	"path",
	"chapter",
	"giftReady",
	"startQuest",
	"event",
	"toast",
	"startActivity",
	"action",
	"resolveEnding",
}

EffectHandlers.flag = function(state, value)
	for _, f in ipairs(asList(value)) do
		state.flags[f] = true
	end
end

EffectHandlers.unflag = function(state, value)
	for _, f in ipairs(asList(value)) do
		state.flags[f] = nil
	end
end

local function applyStats(state, value, ctx, events, soft)
	local list = type(value[1]) == "table" and value or { value }
	for _, s in ipairs(list) do
		Rules.addStat(state, ctx, s[3], s[1], s[2], events, soft)
	end
end

EffectHandlers.stat = function(state, value, ctx, events)
	applyStats(state, value, ctx, events, false)
end

EffectHandlers.softStat = function(state, value, ctx, events)
	applyStats(state, value, ctx, events, true)
end

local function itemArgs(value)
	if type(value) == "table" then
		return value[1], value[2] or 1
	end
	return value, 1
end

function Rules.giveItem(state, itemId: string, count: number, events)
	local before = state.inv[itemId] or 0
	local after = math.min(before + count, 99)
	state.inv[itemId] = after
	if after ~= before then
		push(events, { kind = "item", item = itemId, delta = after - before })
	end
end

function Rules.takeItem(state, itemId: string, count: number, events)
	local before = state.inv[itemId] or 0
	local after = math.max(before - count, 0)
	state.inv[itemId] = if after > 0 then after else nil
	if after ~= before then
		push(events, { kind = "item", item = itemId, delta = after - before })
	end
end

EffectHandlers.give = function(state, value, ctx, events)
	local id, n = itemArgs(value)
	assert(ctx.content.Items[id], `give: unknown item {id}`)
	Rules.giveItem(state, id, n, events)
end

EffectHandlers.take = function(state, value, ctx, events)
	local id, n = itemArgs(value)
	assert(ctx.content.Items[id], `take: unknown item {id}`)
	Rules.takeItem(state, id, n, events)
end

EffectHandlers.path = function(state, value, ctx, events)
	if value == "romance" and not ctx.config.RomanceEnabled then
		value = "friendship"
	end
	if state.path ~= value then
		state.path = value
		push(events, { kind = "path", path = value })
	end
end

EffectHandlers.chapter = function(state, value, _ctx, events)
	if value > state.chapter then
		state.chapter = value
		push(events, { kind = "chapter", chapter = value })
	end
end

EffectHandlers.giftReady = function(state, value)
	relOf(state).giftReady = value == true
end

EffectHandlers.startQuest = function(state, value, ctx, events)
	for _, q in ipairs(asList(value)) do
		Rules.startQuest(state, q, ctx, events)
	end
end

EffectHandlers.event = function(state, value, ctx, events)
	for _, name in ipairs(asList(value)) do
		Rules.emit(state, name, ctx, events)
	end
end

EffectHandlers.toast = function(_state, value, _ctx, events)
	push(events, { kind = "toast", text = value })
end

EffectHandlers.startActivity = function(_state, value, _ctx, events)
	push(events, { kind = "action", action = "startActivity", activity = value })
end

EffectHandlers.action = function(_state, value, _ctx, events)
	local record = Tables.deepCopy(value)
	record.kind = "action"
	push(events, record)
end

EffectHandlers.resolveEnding = function(state, _value, ctx, events)
	Rules.resolveEnding(state, ctx, events)
end

Rules.EffectKeys = {}
for _, key in ipairs(EffectOrder) do
	assert(EffectHandlers[key], key)
	Rules.EffectKeys[key] = true
end

function Rules.applyEffects(state, effects, ctx, events)
	if effects == nil then
		return
	end
	if effects[1] ~= nil then
		for _, e in ipairs(effects) do
			Rules.applyEffects(state, e, ctx, events)
		end
		return
	end
	for key in pairs(effects) do
		if EffectHandlers[key] == nil then
			error(`Unknown effect key '{tostring(key)}'`)
		end
	end
	for _, key in ipairs(EffectOrder) do
		local value = effects[key]
		if value ~= nil then
			EffectHandlers[key](state, value, ctx, events)
		end
	end
end

-- Quests -------------------------------------------------------------------

function Rules.startQuest(state, questId: string, ctx, events): boolean
	local def = ctx.content.Quests[questId]
	assert(def, `startQuest: unknown quest {questId}`)
	if state.quests[questId] ~= nil then
		return false
	end
	state.quests[questId] = { s = "active", step = 1, p = {} }
	push(events, { kind = "questStarted", quest = questId })
	Rules.applyEffects(state, def.onStart, ctx, events)
	local first = def.steps[1]
	if first then
		Rules.applyEffects(state, first.onStart, ctx, events)
	end
	return true
end

function Rules.currentStep(state, questId: string, ctx)
	local q = state.quests[questId]
	if q == nil or q.s ~= "active" then
		return nil
	end
	return ctx.content.Quests[questId].steps[q.step]
end

function Rules.objectiveDone(state, q, obj, ctx): boolean
	if obj.event then
		return (q.p[obj.id] or 0) >= (obj.count or 1)
	end
	if obj.condition then
		return Conditions.check(obj.condition, state, ctx)
	end
	return true
end

-- Does any active quest objective currently listen for this event?
function Rules.wantsEvent(state, eventName: string, ctx): boolean
	for questId, q in pairs(state.quests) do
		if q.s == "active" then
			local step = ctx.content.Quests[questId].steps[q.step]
			for _, obj in ipairs(step and step.objectives or {}) do
				if obj.event == eventName and (q.p[obj.id] or 0) < (obj.count or 1) then
					return true
				end
			end
		end
	end
	return false
end

function Rules.emit(state, eventName: string, ctx, events)
	for _, questId in ipairs(Tables.keys(state.quests)) do
		local q = state.quests[questId]
		if q.s == "active" then
			local step = ctx.content.Quests[questId].steps[q.step]
			for _, obj in ipairs(step and step.objectives or {}) do
				if obj.event == eventName then
					local count = obj.count or 1
					local current = q.p[obj.id] or 0
					if current < count then
						q.p[obj.id] = current + 1
						push(events, {
							kind = "objective",
							quest = questId,
							objective = obj.id,
							progress = current + 1,
							count = count,
						})
					end
				end
			end
		end
	end
end

local function settleQuests(state, ctx, events): boolean
	local changed = false
	for _, questId in ipairs(Tables.keys(state.quests)) do
		local q = state.quests[questId]
		local def = ctx.content.Quests[questId]
		while q.s == "active" do
			local step = def.steps[q.step]
			local done = true
			for _, obj in ipairs(step.objectives or {}) do
				if not Rules.objectiveDone(state, q, obj, ctx) then
					done = false
					break
				end
			end
			if not done then
				break
			end
			changed = true
			Rules.applyEffects(state, step.onComplete, ctx, events)
			Rules.markProgressBeat(state, ctx)
			if q.step >= #def.steps then
				q.s = "complete"
				q.p = {}
				push(events, { kind = "questComplete", quest = questId })
				Rules.applyEffects(state, def.rewards, ctx, events)
			else
				push(events, { kind = "questStep", quest = questId, step = step.id })
				q.step += 1
				q.p = {}
				Rules.applyEffects(state, def.steps[q.step].onStart, ctx, events)
			end
		end
	end
	return changed
end

-- Story director: one-shot rules that react to state (e.g. start the next
-- chapter once its prerequisite quests are complete).
local function settleDirector(state, ctx, events): boolean
	local changed = false
	for _, rule in ipairs(ctx.content.StoryRules) do
		if
			not state.rulesFired[rule.id]
			and (not rule.romance or ctx.config.RomanceEnabled)
			and Conditions.check(rule.when, state, ctx)
		then
			state.rulesFired[rule.id] = true
			Rules.applyEffects(state, rule.effects, ctx, events)
			changed = true
		end
	end
	return changed
end

-- Milestones never regress. Each step requires the previous rank, so the
-- relationship cannot skip a stage even if stats jump.
local function settleMilestones(state, ctx, events): boolean
	local changed = false
	local rel = state.rel[DEFAULT_NPC]
	if rel == nil then
		return false
	end
	local progressed = true
	while progressed do
		progressed = false
		local rank = Conditions.milestoneRank(ctx, rel.milestone)
		for _, m in ipairs(ctx.content.Milestones) do
			if
				m.rank == rank + 1
				and (not m.romance or ctx.config.RomanceEnabled)
				and Conditions.check(m.requires, state, ctx)
			then
				rel.milestone = m.id
				push(events, { kind = "milestone", npc = DEFAULT_NPC, milestone = m.id })
				Rules.applyEffects(state, m.onReach, ctx, events)
				progressed = true
				changed = true
				break
			end
		end
	end
	return changed
end

function Rules.settle(state, ctx, events)
	for _ = 1, SETTLE_LIMIT do
		local changed = false
		changed = settleQuests(state, ctx, events) or changed
		changed = settleDirector(state, ctx, events) or changed
		changed = settleMilestones(state, ctx, events) or changed
		if not changed then
			return
		end
	end
	error("Rules.settle did not converge; check for cyclic story rules")
end

-- Apply effects, then settle. Returns the events list.
function Rules.apply(state, effects, ctx, events)
	events = events or {}
	Rules.applyEffects(state, effects, ctx, events)
	Rules.settle(state, ctx, events)
	return events
end

-- Emit a quest event, then settle.
function Rules.fire(state, eventName: string, ctx, events)
	events = events or {}
	Rules.emit(state, eventName, ctx, events)
	Rules.settle(state, ctx, events)
	return events
end

-- Runs the content's new-game effects exactly once per story.
function Rules.ensureStarted(state, ctx, events)
	events = events or {}
	if not state.flags.__started then
		state.flags.__started = true
		Rules.applyEffects(state, ctx.content.NewGame, ctx, events)
	end
	Rules.settle(state, ctx, events)
	return events
end

-- Endings ------------------------------------------------------------------

function Rules.resolveEnding(state, ctx, events): string
	if state.ending then
		return state.ending
	end
	for _, ending in ipairs(ctx.content.Endings) do
		if (not ending.romance or ctx.config.RomanceEnabled) and Conditions.check(ending.requires, state, ctx) then
			state.ending = ending.id
			state.endingsSeen[ending.id] = true
			push(events, { kind = "ending", ending = ending.id })
			Rules.applyEffects(state, ending.onReach, ctx, events)
			return ending.id
		end
	end
	error("No ending matched. Content must end with an unconditional fallback ending.")
end

function Rules.endingById(ctx, endingId: string)
	for _, ending in ipairs(ctx.content.Endings) do
		if ending.id == endingId then
			return ending
		end
	end
	return nil
end

-- Paragraphs of the epilogue whose conditions pass for this playthrough.
function Rules.endingText(state, ctx, endingId: string): { string }
	local ending = Rules.endingById(ctx, endingId)
	local out = {}
	if ending == nil then
		return out
	end
	for _, p in ipairs(ending.paragraphs) do
		if type(p) == "string" then
			table.insert(out, p)
		elseif (not p.romance or ctx.config.RomanceEnabled) and Conditions.check(p.when, state, ctx) then
			table.insert(out, p.text)
		end
	end
	return out
end

return Rules
