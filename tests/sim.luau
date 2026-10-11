--[[
	Simulated player for story playthrough tests.

	Plays the real game rules (Dialogue, Rules, Activities, Gifts, World) the
	way a player would — only talking to NPCs that are actually present at
	their current station, doing activities when an objective needs them,
	collecting what's available, gifting, chatting — and picks dialogue
	choices according to a strategy. Fails loudly if the story ever gets
	stuck. Optionally JSON round-trips the save after every action to prove
	that leaving and rejoining at any point preserves progress.
]]

local serde = require("@lune/serde")

local Sim = {}
Sim.__index = Sim

local NPC_ORDER = { "saffron", "mabel", "pim", "wren", "cinderra" }

function Sim.new(root, gameRequire, strategy, configOverrides)
	local self = setmetatable({}, Sim)
	local Config = gameRequire(root.Config)
	local cfg = table.clone(Config)
	for k, v in pairs(configOverrides or {}) do
		cfg[k] = v
	end
	self.Content = gameRequire(root.Content)
	self.Rules = gameRequire(root.Systems.Rules)
	self.Dialogue = gameRequire(root.Systems.Dialogue)
	self.Gifts = gameRequire(root.Systems.Gifts)
	self.Activities = gameRequire(root.Systems.Activities)
	self.World = gameRequire(root.Systems.World)
	self.SaveSchema = gameRequire(root.Systems.SaveSchema)
	self.Conditions = gameRequire(root.Systems.Conditions)
	local Prng = gameRequire(root.Util.Prng)

	self.ctx = { content = self.Content, config = cfg }
	self.strategy = strategy
	self.rng = Prng.new(strategy.seed or 7)
	self.state = self.SaveSchema.default(self.ctx)
	self.Rules.ensureStarted(self.state, self.ctx, {})
	self.tried = {}
	self.steps = 0
	self.milestones = {}
	self.chapterStats = {}
	self.sawRomanceChoice = false
	self.choicesTaken = {}
	self.giftsGiven = 0

	self.prefRank = {}
	for i, tag in ipairs(strategy.prefs or {}) do
		self.prefRank[tag] = i
	end
	self.avoid = {}
	for _, tag in ipairs(strategy.avoid or {}) do
		self.avoid[tag] = true
	end
	return self
end

function Sim:signature(): string
	return serde.encode("json", self.state)
end

function Sim:roundtrip()
	local blob = serde.decode("json", serde.encode("json", self.state))
	self.state = self.SaveSchema.reconcile(blob, self.ctx)
end

function Sim:record(events)
	for _, e in ipairs(events) do
		if e.kind == "milestone" then
			table.insert(self.milestones, e.milestone)
		elseif e.kind == "chapter" then
			local rel = self.state.rel.saffron
			self.chapterStats[e.chapter] = {
				trust = rel.trust,
				affinity = rel.affinity,
				romance = rel.romance,
				resolve = rel.resolve,
			}
		end
	end
end

-- Choice scoring -----------------------------------------------------------
function Sim:tagScore(tag)
	if tag == nil then
		return 0
	end
	if self.avoid[tag] then
		return -1000
	end
	local rank = self.prefRank[tag]
	if rank then
		return 1000 - rank * 10
	end
	return -1
end

local function hasActionEffect(choice)
	local e = choice.effects
	return e ~= nil and (e.startActivity ~= nil or e.action ~= nil)
end

function Sim:topicsLeft(conv, state)
	local topics = conv.nodes.topics
	if topics == nil then
		return false
	end
	for _, c in ipairs(topics.choices) do
		if
			c.once
			and not state.flags["once:" .. c.once]
			and (not c.romance or self.ctx.config.RomanceEnabled)
			and self.Conditions.check(c.when, state, self.ctx)
			and self:tagScore(c.tag) > -1000
		then
			return true
		end
	end
	return false
end

function Sim:choose(session, view)
	local conv = self.Content.Conversations[session.conv]
	local node = conv.nodes[session.node]
	local hub = conv.repeatable and (conv.priority or 0) == 0
	local best, bestScore = nil, -math.huge
	local unlocked = {}
	for index, entry in ipairs(session.choices) do
		local choice = node.choices[entry.def]
		if view.choices[index].romance then
			self.sawRomanceChoice = true
		end
		if not entry.locked then
			table.insert(unlocked, index)
			local score
			if hub then
				if hasActionEffect(choice) or choice.next == "outings" then
					score = -500
				elseif choice.once then
					score = 500 + self:tagScore(choice.tag) / 10
					if self:tagScore(choice.tag) <= -1000 then
						score = -900
					end
				elseif choice.next == "topics" then
					score = self:topicsLeft(conv, session.state) and 300 or -50
				elseif choice.next == "menu" then
					score = 20
				elseif choice.next == nil then
					score = 10
				else
					score = -50
				end
			else
				score = self:tagScore(choice.tag)
				if hasActionEffect(choice) then
					score += 50 -- start the activity the scene is offering
				elseif choice.next == nil and choice.tag == nil and #node.choices > 1 then
					score -= 5 -- don't wander off mid-scene
				end
			end
			if score > bestScore then
				best, bestScore = index, score
			end
		end
	end
	if self.strategy.random and not hub then
		return unlocked[self.rng:range(1, #unlocked)]
	end
	return best
end

-- Actions -------------------------------------------------------------------
function Sim:perf(): number
	local p = self.strategy.perf or 1
	if p == "random" then
		return self.rng:nextNumber()
	end
	return p
end

function Sim:playActivity(actId)
	local ok = self.Activities.canStart(self.state, actId, self.ctx)
	if not ok then
		return false
	end
	local def = self.Content.Activities[actId]
	local session = self.Activities.start(self.state, actId, self.ctx, self.rng:nextInt())
	local p = self:perf()
	local submission = {}
	if def.kind == "sort" then
		for i, answer in ipairs(session.secret.answers) do
			submission[i] = if i <= math.floor(#session.secret.answers * p + 0.5) then answer else (answer % 4) + 1
		end
	elseif def.kind == "sequence" then
		for i, seq in ipairs(session.secret.rounds) do
			submission[i] = if i <= math.floor(#session.secret.rounds * p + 0.5) then table.clone(seq) else { 1 }
		end
	elseif def.kind == "timing" then
		for i, round in ipairs(session.secret.rounds) do
			submission[i] = if i <= math.floor(#session.secret.rounds * p + 0.5)
				then round.center
				else math.clamp(round.center + 0.45, 0, 1)
		end
	elseif def.kind == "collect" then
		local n = math.floor(#session.secret.points * p + 0.5)
		for i = 1, n do
			self.Activities.collect(session, i)
		end
	end
	local events = {}
	local finished, result = self.Activities.finish(self.state, session, submission, (def.minDuration or 0) + 1, self.ctx, events)
	assert(finished, `activity {actId} refused: {tostring(result)}`)
	self:record(events)
	self:handleActions(events)
	return true
end

function Sim:handleActions(events)
	for _, e in ipairs(events) do
		if e.kind == "action" and e.action == "startActivity" then
			self:playActivity(e.activity)
		end
	end
end

function Sim:talk(npcId, convId)
	local events = {}
	local session = self.Dialogue.begin(self.state, convId, self.ctx, events)
	for _ = 1, 400 do
		if session.ended then
			break
		end
		local view = self.Dialogue.view(session, self.ctx, "Tester")
		if session.choices then
			local index = self:choose(session, view)
			assert(index, `no selectable choice in {convId}.{session.node}`)
			local node = self.Content.Conversations[convId].nodes[session.node]
			local choice = node.choices[session.choices[index].def]
			table.insert(self.choicesTaken, `{convId}.{session.node}:{choice.tag or "-"}`)
			local ok, why = self.Dialogue.choose(session, index, self.ctx, events)
			assert(ok, `choose failed in {convId}: {tostring(why)}`)
		else
			local ok, why = self.Dialogue.advance(session, self.ctx, events)
			assert(ok, `advance failed in {convId}: {tostring(why)}`)
		end
	end
	assert(session.ended, `conversation {convId} never ended`)
	self.state = session.state -- commit
	self:record(events)
	self:handleActions(events)
end

function Sim:tryConversations(hubOnly: boolean): boolean
	for _, npcId in ipairs(NPC_ORDER) do
		if self.World.station(self.state, npcId, self.ctx) ~= nil then
			local convId = self.Dialogue.pick(self.state, npcId, self.ctx)
			if convId then
				local conv = self.Content.Conversations[convId]
				local isHub = conv.repeatable == true and (conv.priority or 0) == 0
				if isHub == hubOnly then
					local before = self:signature()
					local key = before .. "|" .. convId
					if not self.tried[key] then
						self.tried[key] = true
						self:talk(npcId, convId)
						if self:signature() ~= before then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

function Sim:tryActivities(): boolean
	for actId in pairs(self.Content.Activities) do
		if self.Rules.wantsEvent(self.state, "activity:" .. actId, self.ctx) then
			if self:playActivity(actId) then
				return true
			end
		end
	end
	return false
end

function Sim:tryCollect(): boolean
	local ids = {}
	for id in pairs(self.Content.Collectibles) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		if self.World.collectibleAvailable(self.state, id, self.ctx) then
			local events = {}
			assert(self.World.collect(self.state, id, self.ctx, events))
			self:record(events)
			return true
		end
	end
	return false
end

function Sim:tryReach(): boolean
	for _, locId in ipairs(self.World.pendingReaches(self.state, self.ctx)) do
		local events = {}
		if self.World.reach(self.state, locId, self.ctx, events) then
			self:record(events)
			return true
		end
	end
	return false
end

local TIER_ORDER = {
	best = { "loved", "liked", "neutral" },
	worst = { "hated", "disliked" },
}

function Sim:tryGift(): boolean
	local mode = self.strategy.gifts or "none"
	if mode == "none" or not self.Gifts.canGive(self.state, "saffron", self.ctx) then
		return false
	end
	local pick
	if mode == "random" then
		local owned = {}
		for itemId in pairs(self.state.inv) do
			if self.Content.Items[itemId].giftable then
				table.insert(owned, itemId)
			end
		end
		table.sort(owned)
		if #owned > 0 then
			pick = owned[self.rng:range(1, #owned)]
		end
	else
		for _, tier in ipairs(TIER_ORDER[mode]) do
			local ids = {}
			for itemId in pairs(self.state.inv) do
				if self.Content.Items[itemId].giftable and self.Gifts.tierOf(self.ctx, "saffron", itemId) == tier then
					table.insert(ids, itemId)
				end
			end
			table.sort(ids)
			-- prefer items never given before
			for _, id in ipairs(ids) do
				if (self.state.rel.saffron.gifts[id] or 0) == 0 then
					pick = id
					break
				end
			end
			pick = pick or ids[1]
			if pick then
				break
			end
		end
	end
	if pick == nil then
		return false
	end
	local events = {}
	local ok = self.Gifts.give(self.state, "saffron", pick, self.ctx, events)
	assert(ok, "gift refused after canGive")
	self.giftsGiven += 1
	self:record(events)
	return true
end

function Sim:run(maxSteps: number?)
	maxSteps = maxSteps or 3000
	while self.state.ending == nil do
		self.steps += 1
		if self.steps > maxSteps then
			error("simulation exceeded step limit; " .. self:describe())
		end
		if self.strategy.roundtrip then
			self:roundtrip()
		end
		-- Like a real player: chat and give gifts whenever possible, then
		-- pursue the story.
		local progressed = self:tryGift()
			or (self.strategy.chat ~= false and self:tryConversations(true))
			or self:tryConversations(false)
			or self:tryActivities()
			or self:tryReach()
			or self:tryCollect()
		if not progressed then
			error("story got stuck; " .. self:describe())
		end
	end
	-- Epilogue conversations must also run cleanly for everyone present.
	for _, npcId in ipairs(NPC_ORDER) do
		if self.World.station(self.state, npcId, self.ctx) ~= nil then
			local convId = self.Dialogue.pick(self.state, npcId, self.ctx)
			assert(convId, `no epilogue conversation for {npcId}`)
			self:talk(npcId, convId)
		end
	end
	return self.state.ending
end

function Sim:describe(): string
	local active = {}
	for questId, q in pairs(self.state.quests) do
		if q.s == "active" then
			table.insert(active, `{questId}#{self.Content.Quests[questId].steps[q.step].id}`)
		end
	end
	local rel = self.state.rel.saffron
	return string.format(
		"chapter=%d active={%s} milestone=%s trust=%d affinity=%d romance=%d resolve=%d path=%s",
		self.state.chapter,
		table.concat(active, ","),
		rel.milestone,
		rel.trust,
		rel.affinity,
		rel.romance,
		rel.resolve,
		self.state.path
	)
end

return Sim
