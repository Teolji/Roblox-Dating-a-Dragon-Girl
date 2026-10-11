--[[
	ContentValidator
	Explorer: ReplicatedStorage > Hearthscale > Systems > ContentValidator (ModuleScript)

	Static checks over all data-driven content. Run by the Lune test suite and
	at server start (problems are printed as warnings in Studio's Output), so
	a typo in a quest id or a dead-end dialogue node is caught before playing.

	validate(ctx) -> { string }  (empty list = content is consistent)
]]

local Conditions = require(script.Parent.Conditions)
local Rules = require(script.Parent.Rules)
local Minigames = require(script.Parent.Minigames)
local World = require(script.Parent.World)

local ContentValidator = {}

local SPEAKERS_EXTRA = { narrator = true, player = true }
local PATHS = { none = true, friendship = true, romance = true }
local QUEST_STATUSES = { notStarted = true, active = true, complete = true, started = true }

function ContentValidator.validate(ctx): { string }
	local content = ctx.content
	local errors = {}
	local function err(where, msg)
		table.insert(errors, `{where}: {msg}`)
	end

	local flagsSet = { __started = true }
	local flagsChecked = {}
	local eventsEmitted = {}
	local questsStarted = {}

	local endingIds = {}
	for _, e in ipairs(content.Endings) do
		endingIds[e.id] = true
	end

	-- Conditions -------------------------------------------------------------
	local function checkCondition(cond, where)
		if cond == nil then
			return
		end
		if type(cond) ~= "table" then
			err(where, "condition must be a table")
			return
		end
		if cond[1] ~= nil then
			for i, c in ipairs(cond) do
				checkCondition(c, `{where}[{i}]`)
			end
			return
		end
		for key, value in pairs(cond) do
			if not Conditions.Keys[key] then
				err(where, `unknown condition key '{tostring(key)}'`)
			elseif key == "flag" or key == "notFlag" then
				flagsChecked[value] = flagsChecked[value] or where
			elseif key == "quest" then
				if content.Quests[value[1]] == nil then
					err(where, `unknown quest '{tostring(value[1])}'`)
				end
				if not QUEST_STATUSES[value[2]] then
					err(where, `bad quest status '{tostring(value[2])}'`)
				end
			elseif key == "questStep" then
				local q = content.Quests[value[1]]
				if q == nil then
					err(where, `unknown quest '{tostring(value[1])}'`)
				else
					local found = false
					for _, s in ipairs(q.steps) do
						found = found or s.id == value[2]
					end
					if not found then
						err(where, `quest '{value[1]}' has no step '{tostring(value[2])}'`)
					end
				end
			elseif key == "item" then
				local id = type(value) == "table" and value[1] or value
				if content.Items[id] == nil then
					err(where, `unknown item '{tostring(id)}'`)
				end
			elseif key == "milestone" or key == "milestoneIs" or key == "canReachMilestone" then
				if content.MilestoneById[value] == nil then
					err(where, `unknown milestone '{tostring(value)}'`)
				end
			elseif key == "activity" then
				if content.Activities[value] == nil then
					err(where, `unknown activity '{tostring(value)}'`)
				end
			elseif key == "ending" then
				if not endingIds[value] then
					err(where, `unknown ending '{tostring(value)}'`)
				end
			elseif key == "path" then
				if not PATHS[value] then
					err(where, `bad path '{tostring(value)}'`)
				end
			elseif key == "stat" or key == "statBelow" then
				if type(value) ~= "table" or type(value[1]) ~= "string" or type(value[2]) ~= "number" then
					err(where, "stat condition must be { name, number }")
				end
			elseif key == "all" or key == "any" then
				for i, c in ipairs(value) do
					checkCondition(c, `{where}.{key}[{i}]`)
				end
			elseif key == "not" then
				checkCondition(value, `{where}.not`)
			end
		end
	end

	-- Effects ----------------------------------------------------------------
	local function asList(v)
		return type(v) == "table" and v or { v }
	end

	local function checkEffects(effects, where)
		if effects == nil then
			return
		end
		if type(effects) ~= "table" then
			err(where, "effects must be a table")
			return
		end
		if effects[1] ~= nil then
			for i, e in ipairs(effects) do
				checkEffects(e, `{where}[{i}]`)
			end
			return
		end
		for key, value in pairs(effects) do
			if not Rules.EffectKeys[key] then
				err(where, `unknown effect key '{tostring(key)}'`)
			elseif key == "flag" then
				for _, f in ipairs(asList(value)) do
					flagsSet[f] = true
				end
			elseif key == "give" or key == "take" then
				local id = type(value) == "table" and value[1] or value
				if content.Items[id] == nil then
					err(where, `unknown item '{tostring(id)}'`)
				end
			elseif key == "startQuest" then
				for _, q in ipairs(asList(value)) do
					if content.Quests[q] == nil then
						err(where, `unknown quest '{tostring(q)}'`)
					end
					questsStarted[q] = true
				end
			elseif key == "event" then
				for _, e in ipairs(asList(value)) do
					eventsEmitted[e] = true
				end
			elseif key == "startActivity" then
				if content.Activities[value] == nil then
					err(where, `unknown activity '{tostring(value)}'`)
				end
			elseif key == "path" then
				if not PATHS[value] then
					err(where, `bad path '{tostring(value)}'`)
				end
			elseif key == "chapter" then
				if type(value) ~= "number" or content.Chapters[value] == nil then
					err(where, `bad chapter '{tostring(value)}'`)
				end
			elseif key == "stat" or key == "softStat" then
				local list = type(value[1]) == "table" and value or { value }
				for _, s in ipairs(list) do
					if type(s[1]) ~= "string" or type(s[2]) ~= "number" then
						err(where, "stat effect must be { name, number }")
					end
				end
			elseif key == "action" then
				if type(value) ~= "table" or type(value.action) ~= "string" then
					err(where, "action effect needs an `action` string")
				end
			end
		end
	end

	-- Characters ---------------------------------------------------------------
	for npcId, char in pairs(content.Characters) do
		local where = `Characters.{npcId}`
		for i, s in ipairs(char.stations or {}) do
			checkCondition(s.when, `{where}.stations[{i}]`)
			if not s.hidden and (s.anchor == nil or content.Anchors[s.anchor] == nil) then
				err(`{where}.stations[{i}]`, `unknown anchor '{tostring(s.anchor)}'`)
			end
		end
		if char.gifts then
			for itemId, tier in pairs(char.gifts.tiers) do
				if content.Items[itemId] == nil then
					err(`{where}.gifts`, `unknown item '{itemId}'`)
				end
				if char.gifts.values[tier] == nil then
					err(`{where}.gifts`, `no value for tier '{tier}'`)
				end
			end
			for itemId, reaction in pairs(char.gifts.reactions) do
				if content.Items[itemId] == nil then
					err(`{where}.gifts.reactions`, `unknown item '{itemId}'`)
				end
				checkEffects(reaction.effects, `{where}.gifts.reactions.{itemId}`)
			end
			if content.MilestoneById[char.gifts.minMilestone] == nil then
				err(`{where}.gifts`, "unknown minMilestone")
			end
		end
	end

	-- Conversations --------------------------------------------------------------
	for convId, conv in pairs(content.Conversations) do
		local where = `Conversation {convId}`
		if content.Characters[conv.npc] == nil then
			err(where, `unknown npc '{tostring(conv.npc)}'`)
		end
		checkCondition(conv.when, `{where}.when`)
		checkEffects(conv.onEnd, `{where}.onEnd`)
		if conv.nodes[conv.start] == nil then
			err(where, `missing start node '{tostring(conv.start)}'`)
		end
		local reachable = {}
		local function visit(nodeId)
			if nodeId == nil or reachable[nodeId] then
				return
			end
			reachable[nodeId] = true
			local node = conv.nodes[nodeId]
			if node == nil then
				return
			end
			if node.next then
				visit(node.next)
			end
			for _, c in ipairs(node.choices or {}) do
				visit(c.next)
			end
			for _, b in ipairs(node.branch or {}) do
				visit(b.next)
			end
		end
		visit(conv.start)
		for nodeId, node in pairs(conv.nodes) do
			local w = `{where}.{nodeId}`
			if not reachable[nodeId] then
				err(w, "node is unreachable")
			end
			if node.speaker and not SPEAKERS_EXTRA[node.speaker] and content.Characters[node.speaker] == nil then
				err(w, `unknown speaker '{node.speaker}'`)
			end
			if node.next and conv.nodes[node.next] == nil then
				err(w, `next -> missing node '{node.next}'`)
			end
			checkEffects(node.effects, `{w}.effects`)
			if node.branch then
				if node.text or node.choices then
					err(w, "branch nodes must not have text or choices")
				end
				local last = node.branch[#node.branch]
				if last == nil or last.when ~= nil or last.romance then
					err(w, "branch must end with an unconditional option")
				end
				for i, b in ipairs(node.branch) do
					checkCondition(b.when, `{w}.branch[{i}]`)
					if b.next and conv.nodes[b.next] == nil then
						err(w, `branch -> missing node '{b.next}'`)
					end
				end
			end
			if node.choices then
				if node.text == nil then
					err(w, "choice nodes need text")
				end
				local hasFallback = false
				for i, c in ipairs(node.choices) do
					local cw = `{w}.choices[{i}]`
					if type(c.text) ~= "string" then
						err(cw, "choice needs text")
					end
					if c.next and conv.nodes[c.next] == nil then
						err(cw, `next -> missing node '{c.next}'`)
					end
					checkCondition(c.when, cw)
					checkEffects(c.effects, cw)
					if c.once then
						flagsSet["once:" .. c.once] = true
					end
					if c.when == nil and not c.romance and c.once == nil then
						hasFallback = true
					end
				end
				if not hasFallback then
					err(w, "needs at least one choice that is always available (no when/once/romance)")
				end
			end
		end
	end

	-- Quests ---------------------------------------------------------------------
	for questId, quest in pairs(content.Quests) do
		local where = `Quest {questId}`
		if #quest.steps == 0 then
			err(where, "has no steps")
		end
		checkEffects(quest.onStart, `{where}.onStart`)
		checkEffects(quest.rewards, `{where}.rewards`)
		local stepIds = {}
		for i, step in ipairs(quest.steps) do
			local w = `{where}.steps[{i}]`
			if stepIds[step.id] then
				err(w, `duplicate step id '{step.id}'`)
			end
			stepIds[step.id] = true
			checkEffects(step.onStart, `{w}.onStart`)
			checkEffects(step.onComplete, `{w}.onComplete`)
			for j, obj in ipairs(step.objectives or {}) do
				if obj.id == nil or obj.text == nil then
					err(`{w}.objectives[{j}]`, "objective needs id and text")
				end
				if obj.event == nil and obj.condition == nil then
					err(`{w}.objectives[{j}]`, "objective needs event or condition")
				end
				checkCondition(obj.condition, `{w}.objectives[{j}]`)
			end
		end
	end

	-- Activities -----------------------------------------------------------------
	for actId, act in pairs(content.Activities) do
		local where = `Activity {actId}`
		eventsEmitted["activity:" .. actId] = true
		if not Minigames.Kinds[act.kind] then
			err(where, `unknown kind '{tostring(act.kind)}'`)
		end
		checkCondition(act.when, `{where}.when`)
		if act.anchor and content.Anchors[act.anchor] == nil then
			err(where, `unknown anchor '{act.anchor}'`)
		end
		local previous = -math.huge
		for i, tier in ipairs(act.tiers) do
			if tier.min <= previous then
				err(where, "tiers must have ascending min scores")
			end
			previous = tier.min
			checkEffects(tier.effects, `{where}.tiers[{i}]`)
		end
		if act.tiers[1] == nil or act.tiers[1].min ~= 0 then
			err(where, "first tier must start at 0")
		end
		if act.rewards then
			checkEffects(act.rewards.first, `{where}.rewards.first`)
			checkEffects(act.rewards.again, `{where}.rewards.again`)
		end
	end

	-- Collectibles / locations -------------------------------------------------
	for colId, col in pairs(content.Collectibles) do
		eventsEmitted["collect:" .. (col.group or colId)] = true
		checkCondition(col.when, `Collectible {colId}`)
		checkEffects(col.effects, `Collectible {colId}`)
	end
	for locId in pairs(content.Locations) do
		eventsEmitted["reach:" .. locId] = true
	end
	for anchor in pairs(World.referencedAnchors(ctx)) do
		if content.Anchors[anchor] == nil then
			err("World", `referenced anchor '{anchor}' is not defined in Content.World.Anchors`)
		end
	end

	-- Milestones -----------------------------------------------------------------
	for i, m in ipairs(content.Milestones) do
		checkCondition(m.requires, `Milestone {m.id}`)
		checkEffects(m.onReach, `Milestone {m.id}`)
		if i == 1 and m.rank ~= 0 then
			err(`Milestone {m.id}`, "first milestone must be rank 0")
		end
		if m.romance and content.MilestoneById[m.fallback or "confidant"] == nil then
			err(`Milestone {m.id}`, "romance milestone needs a valid fallback")
		end
	end

	-- Story rules / endings -------------------------------------------------------
	checkEffects(content.NewGame, "NewGame")
	for _, rule in ipairs(content.StoryRules) do
		checkCondition(rule.when, `StoryRule {rule.id}`)
		checkEffects(rule.effects, `StoryRule {rule.id}`)
	end
	for i, ending in ipairs(content.Endings) do
		checkCondition(ending.requires, `Ending {ending.id}`)
		checkEffects(ending.onReach, `Ending {ending.id}`)
		for j, p in ipairs(ending.paragraphs) do
			if type(p) == "table" then
				checkCondition(p.when, `Ending {ending.id}.paragraphs[{j}]`)
			end
		end
		if i == #content.Endings then
			if ending.romance or next(ending.requires or {}) ~= nil then
				err(`Ending {ending.id}`, "last ending must be an unconditional, non-romance fallback")
			end
		end
	end

	-- Cross references ---------------------------------------------------------
	for questId, quest in pairs(content.Quests) do
		for i, step in ipairs(quest.steps) do
			for _, obj in ipairs(step.objectives or {}) do
				if obj.event and not eventsEmitted[obj.event] then
					err(`Quest {questId}.steps[{i}]`, `nothing ever emits event '{obj.event}'`)
				end
			end
		end
		if not questsStarted[questId] then
			err(`Quest {questId}`, "is never started")
		end
	end
	for flag, where in pairs(flagsChecked) do
		if not flagsSet[flag] then
			err(where, `flag '{flag}' is checked but never set`)
		end
	end
	for _, note in ipairs(content.Notes or {}) do
		if not flagsSet[note.flag] then
			err("Notes", `note flag '{note.flag}' is never set`)
		end
	end

	table.sort(errors)
	return errors
end

return ContentValidator
