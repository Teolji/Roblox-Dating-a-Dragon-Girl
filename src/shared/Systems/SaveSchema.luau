--[[
	SaveSchema
	Explorer: ReplicatedStorage > Hearthscale > Systems > SaveSchema (ModuleScript)

	Defines the per-player save format, sanitises anything loaded from the
	DataStore (unknown ids dropped, numbers clamped, wrong types replaced) and
	migrates older versions. Never trust a loaded blob: a corrupted or
	hand-edited save must not crash the server or unlock content.
]]

local Tables = require(script.Parent.Parent.Util.Tables)

local SaveSchema = {}

SaveSchema.Paths = { none = true, friendship = true, romance = true }

SaveSchema.DefaultSettings = {
	textSpeed = "normal", -- slow | normal | fast | instant
	music = 0.6,
	sfx = 0.8,
	showNumbers = false, -- show exact relationship deltas in toasts
	reduceMotion = false, -- no camera moves, no shake, instant text
	cinematicCamera = true,
	showWaypoint = true, -- floating marker toward the current objective
	uiScale = 1,
}

local TEXT_SPEEDS = { slow = true, normal = true, fast = true, instant = true }

function SaveSchema.newRelationship()
	return {
		trust = 0,
		affinity = 0,
		romance = 0,
		resolve = 0,
		milestone = "stranger",
		giftReady = false,
		gifts = {}, -- [itemId] = times given
	}
end

function SaveSchema.default(ctx)
	local rel = {}
	for id, char in pairs(ctx.content.Characters) do
		if char.relationship then
			rel[id] = SaveSchema.newRelationship()
		end
	end
	return {
		v = ctx.config.SaveVersion,
		flags = {},
		chapter = 1,
		path = "none",
		ending = nil,
		endingsSeen = {},
		rulesFired = {},
		quests = {},
		inv = {},
		collected = {},
		seen = {},
		acts = {},
		rel = rel,
		settings = Tables.deepCopy(SaveSchema.DefaultSettings),
		meta = { stories = 1, playSeconds = 0 },
	}
end

local function num(value, default, min, max, integer)
	if type(value) ~= "number" or value ~= value then -- NaN check
		return default
	end
	if integer then
		value = math.floor(value)
	end
	return math.clamp(value, min, max)
end

local function boolSet(value, isValid)
	local out = {}
	if type(value) ~= "table" then
		return out
	end
	for k, v in pairs(value) do
		if type(k) == "string" and v == true and (isValid == nil or isValid(k)) then
			out[k] = true
		end
	end
	return out
end

function SaveSchema.validateSettings(input: any, base: any?)
	local s = Tables.deepCopy(base or SaveSchema.DefaultSettings)
	if type(input) ~= "table" then
		return s
	end
	if type(input.textSpeed) == "string" and TEXT_SPEEDS[input.textSpeed] then
		s.textSpeed = input.textSpeed
	end
	s.music = num(input.music, s.music, 0, 1, false)
	s.sfx = num(input.sfx, s.sfx, 0, 1, false)
	s.uiScale = num(input.uiScale, s.uiScale, 0.8, 1.3, false)
	for _, key in ipairs({ "showNumbers", "reduceMotion", "cinematicCamera", "showWaypoint" }) do
		if type(input[key]) == "boolean" then
			s[key] = input[key]
		end
	end
	return s
end

-- Version upgrades. Each step takes the raw table at version n and returns n+1.
local Migrations: { [number]: (any) -> any } = {
	-- [1] = function(data) ... data.v = 2 return data end,
}

function SaveSchema.migrate(data: any, targetVersion: number)
	local v = type(data.v) == "number" and data.v or 1
	while v < targetVersion do
		local step = Migrations[v]
		if step == nil then
			break
		end
		data = step(data)
		v += 1
	end
	data.v = targetVersion
	return data
end

function SaveSchema.reconcile(data: any, ctx)
	local content, config = ctx.content, ctx.config
	local state = SaveSchema.default(ctx)
	if type(data) ~= "table" then
		return state
	end
	data = SaveSchema.migrate(data, config.SaveVersion)

	state.flags = boolSet(data.flags)
	state.chapter = num(data.chapter, 1, 1, #content.Chapters, true)
	if type(data.path) == "string" and SaveSchema.Paths[data.path] then
		state.path = data.path
	end
	if state.path == "romance" and not config.RomanceEnabled then
		state.path = "friendship"
	end

	local endingIds = {}
	for _, e in ipairs(content.Endings) do
		endingIds[e.id] = e
	end
	if type(data.ending) == "string" and endingIds[data.ending] then
		state.ending = data.ending
	end
	state.endingsSeen = boolSet(data.endingsSeen, function(k)
		return endingIds[k] ~= nil
	end)

	local ruleIds = {}
	for _, r in ipairs(content.StoryRules) do
		ruleIds[r.id] = true
	end
	state.rulesFired = boolSet(data.rulesFired, function(k)
		return ruleIds[k] == true
	end)

	if type(data.quests) == "table" then
		for questId, q in pairs(data.quests) do
			local def = content.Quests[questId]
			if def and type(q) == "table" and (q.s == "active" or q.s == "complete") then
				local entry = { s = q.s, step = num(q.step, 1, 1, #def.steps, true), p = {} }
				if q.s == "active" and type(q.p) == "table" then
					local step = def.steps[entry.step]
					for _, obj in ipairs(step.objectives or {}) do
						if q.p[obj.id] ~= nil then
							entry.p[obj.id] = num(q.p[obj.id], 0, 0, obj.count or 1, true)
						end
					end
				end
				state.quests[questId] = entry
			end
		end
	end

	if type(data.inv) == "table" then
		for itemId, count in pairs(data.inv) do
			if content.Items[itemId] then
				local n = num(count, 0, 0, 99, true)
				if n > 0 then
					state.inv[itemId] = n
				end
			end
		end
	end

	state.collected = boolSet(data.collected, function(k)
		return content.Collectibles[k] ~= nil
	end)
	state.seen = boolSet(data.seen, function(k)
		return content.Conversations[k] ~= nil
	end)

	if type(data.acts) == "table" then
		for actId, a in pairs(data.acts) do
			if content.Activities[actId] and type(a) == "table" then
				state.acts[actId] = {
					plays = num(a.plays, 0, 0, 1e6, true),
					best = num(a.best, 0, 0, 1e6, true),
					repeats = num(a.repeats, 0, 0, 1e6, true),
				}
			end
		end
	end

	if type(data.rel) == "table" then
		for npcId, r in pairs(state.rel) do
			local saved = data.rel[npcId]
			if type(saved) == "table" then
				r.trust = num(saved.trust, 0, 0, config.StatMax, false)
				r.affinity = num(saved.affinity, 0, 0, config.StatMax, false)
				r.romance = config.RomanceEnabled and num(saved.romance, 0, 0, config.StatMax, false) or 0
				r.resolve = num(saved.resolve, 0, 0, config.ResolveMax, false)
				local m = content.MilestoneById[saved.milestone]
				if m and (not m.romance or config.RomanceEnabled) then
					r.milestone = saved.milestone
				elseif m and m.romance then
					r.milestone = m.fallback or "confidant"
				end
				r.giftReady = saved.giftReady == true
				if type(saved.gifts) == "table" then
					for itemId, n in pairs(saved.gifts) do
						if content.Items[itemId] then
							r.gifts[itemId] = num(n, 0, 0, 1e6, true)
						end
					end
				end
			end
		end
	end

	state.settings = SaveSchema.validateSettings(data.settings)
	if type(data.meta) == "table" then
		state.meta.stories = num(data.meta.stories, 1, 1, 1e6, true)
		state.meta.playSeconds = num(data.meta.playSeconds, 0, 0, 1e12, true)
	end
	return state
end

-- Fresh story that keeps the endings gallery, settings and lifetime stats.
function SaveSchema.newStory(old: any, ctx)
	local state = SaveSchema.default(ctx)
	state.endingsSeen = Tables.deepCopy(old.endingsSeen or {})
	state.settings = Tables.deepCopy(old.settings or SaveSchema.DefaultSettings)
	state.meta = Tables.deepCopy(old.meta or state.meta)
	state.meta.stories = (state.meta.stories or 1) + 1
	return state
end

return SaveSchema
