--[[
	Dialogue
	Explorer: ReplicatedStorage > Hearthscale > Systems > Dialogue (ModuleScript)

	Runs branching conversations defined in Content/Dialogue. The server owns
	the session; clients only ever see the current node's text and the list
	of choices they are allowed to pick, by index.

	Conversations are transactional: a session works on a private copy of the
	player's state (`session.state`). The caller commits it when the
	conversation ends. If the player disconnects or walks away mid-scene the
	copy is discarded, so effects can't be farmed by quitting early and quest
	progress can't be half-applied.

	Conversation definition:
	  {
	    npc = "saffron", priority = 100, when = <condition>,
	    repeatable = false,          -- default: plays once
	    romance = false,             -- whole conversation is romance-only
	    start = "n1",
	    onEnd = <effects>,
	    nodes = {
	      n1 = { speaker = "saffron", emote = "smug", text = "...", effects = <effects>, next = "n2" },
	      n2 = { text = "...", choices = {
	        { text = "...", tag = "kind", when = <cond>, effects = <effects>, next = "n3",
	          once = "topic_key", romance = true, lockedText = "(shown greyed when `when` fails)" },
	      } },
	      n3 = { branch = { { when = <cond>, next = "a" }, { next = "b" } } },
	    },
	  }
	Text tokens: {player} {saffron} {festival}
]]

local Conditions = require(script.Parent.Conditions)
local Rules = require(script.Parent.Rules)
local Tables = require(script.Parent.Parent.Util.Tables)

local Dialogue = {}

local MAX_JUMPS = 128

local function allowed(def, ctx): boolean
	return not def.romance or ctx.config.RomanceEnabled == true
end

function Dialogue.isAvailable(state, convId: string, ctx): boolean
	local conv = ctx.content.Conversations[convId]
	if conv == nil or not allowed(conv, ctx) then
		return false
	end
	if not conv.repeatable and state.seen[convId] then
		return false
	end
	return Conditions.check(conv.when, state, ctx)
end

-- Highest-priority conversation currently available for an NPC.
function Dialogue.pick(state, npcId: string, ctx): string?
	local best, bestPriority = nil, -math.huge
	for _, convId in ipairs(ctx.content.ConversationsByNpc[npcId] or {}) do
		if Dialogue.isAvailable(state, convId, ctx) then
			local p = ctx.content.Conversations[convId].priority or 0
			if p > bestPriority then
				best, bestPriority = convId, p
			end
		end
	end
	return best
end

-- The current objective's hint for the earliest active quest in journal order.
function Dialogue.hint(state, ctx): string
	for _, questId in ipairs(ctx.content.QuestOrder) do
		local q = state.quests[questId]
		if q and q.s == "active" then
			local step = ctx.content.Quests[questId].steps[q.step]
			return step.hint or step.text
		end
	end
	return "Nothing urgent. Wander. Chat. Bring me something interesting."
end

function Dialogue.format(text: string?, state, ctx, playerName: string?): string
	if text == nil then
		return ""
	end
	local rel = state.rel.saffron
	local milestone = rel and ctx.content.MilestoneById[rel.milestone]
	local tokens = {
		player = playerName or "traveler",
		saffron = milestone and milestone.callHer or "Saffron",
		festival = (ctx.content.FestivalCountdown or {})[state.chapter] or "soon",
	}
	return (
		string.gsub(text, "{(%w+)}", function(key)
			if key == "hint" then
				return Dialogue.hint(state, ctx)
			end
			return tokens[key]
		end)
	)
end

local function visibleChoices(state, node, ctx)
	local list = {}
	for i, choice in ipairs(node.choices) do
		local hiddenByOnce = choice.once ~= nil and state.flags["once:" .. choice.once] == true
		if allowed(choice, ctx) and not hiddenByOnce then
			if Conditions.check(choice.when, state, ctx) then
				table.insert(list, { def = i, locked = false })
			elseif choice.lockedText then
				table.insert(list, { def = i, locked = true })
			end
		end
	end
	return list
end

local function finish(session, ctx, events)
	if session.ended then
		return
	end
	session.ended = true
	session.choices = nil
	local state = session.state
	local conv = ctx.content.Conversations[session.conv]
	if not conv.repeatable then
		state.seen[session.conv] = true
	end
	Rules.apply(state, conv.onEnd, ctx, events)
end

local function enter(session, nodeId: string?, ctx, events)
	local state = session.state
	local conv = ctx.content.Conversations[session.conv]
	for _ = 1, MAX_JUMPS do
		if nodeId == nil then
			finish(session, ctx, events)
			return
		end
		local node = conv.nodes[nodeId]
		assert(node, `Conversation {session.conv} has no node {nodeId}`)
		session.node = nodeId
		session.choices = nil
		if node.effects then
			Rules.apply(state, node.effects, ctx, events)
		end
		if node.branch then
			local target = nil
			for _, option in ipairs(node.branch) do
				if allowed(option, ctx) and Conditions.check(option.when, state, ctx) then
					target = option.next
					break
				end
			end
			nodeId = target
		elseif node.text == nil and node.choices == nil then
			nodeId = node.next
		else
			if node.choices then
				session.choices = visibleChoices(state, node, ctx)
				if #session.choices == 0 then
					-- Defensive: never strand the player on a node with nothing to pick.
					session.choices = nil
				end
			end
			return
		end
	end
	error(`Conversation {session.conv} jumped too many times (loop without text?)`)
end

-- Starts a conversation on a private copy of `state`.
function Dialogue.begin(state, convId: string, ctx, events)
	local session = {
		conv = convId,
		node = nil,
		choices = nil,
		ended = false,
		state = Tables.deepCopy(state),
	}
	enter(session, ctx.content.Conversations[convId].start, ctx, events)
	return session
end

function Dialogue.view(session, ctx, playerName: string?)
	if session.ended then
		return { ended = true }
	end
	local state = session.state
	local conv = ctx.content.Conversations[session.conv]
	local node = conv.nodes[session.node]
	local speaker = node.speaker or conv.npc
	local char = ctx.content.Characters[speaker]
	local view = {
		conv = session.conv,
		npc = conv.npc,
		speaker = speaker,
		speakerName = if speaker == "player"
			then (playerName or "You")
			elseif speaker == "narrator" then ""
			else (char and char.name or speaker),
		emote = node.emote or "neutral",
		text = Dialogue.format(node.text, state, ctx, playerName),
		canContinue = session.choices == nil,
		isLast = session.choices == nil and node.next == nil,
	}
	if session.choices then
		view.choices = {}
		for index, entry in ipairs(session.choices) do
			local choice = node.choices[entry.def]
			table.insert(view.choices, {
				index = index,
				text = Dialogue.format(entry.locked and choice.lockedText or choice.text, state, ctx, playerName),
				locked = entry.locked,
				romance = choice.romance == true,
			})
		end
	end
	return view
end

-- Continue from a node that has no choices.
function Dialogue.advance(session, ctx, events): (boolean, string?)
	if session.ended then
		return false, "ended"
	end
	if session.choices ~= nil then
		return false, "mustChoose"
	end
	local node = ctx.content.Conversations[session.conv].nodes[session.node]
	enter(session, node.next, ctx, events)
	return true, nil
end

function Dialogue.choose(session, index: number, ctx, events): (boolean, string?)
	if session.ended or session.choices == nil then
		return false, "noChoices"
	end
	if type(index) ~= "number" or index % 1 ~= 0 then
		return false, "badIndex"
	end
	local entry = session.choices[index]
	if entry == nil or entry.locked then
		return false, "invalidChoice"
	end
	local state = session.state
	local node = ctx.content.Conversations[session.conv].nodes[session.node]
	local choice = node.choices[entry.def]
	if not allowed(choice, ctx) or not Conditions.check(choice.when, state, ctx) then
		return false, "unavailable"
	end
	if choice.once then
		state.flags["once:" .. choice.once] = true
	end
	session.choices = nil
	if choice.effects then
		Rules.apply(state, choice.effects, ctx, events)
	end
	session.lastTag = choice.tag
	enter(session, choice.next, ctx, events)
	return true, nil
end

return Dialogue
