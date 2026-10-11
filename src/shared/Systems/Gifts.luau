--[[
	Gifts
	Explorer: ReplicatedStorage > Hearthscale > Systems > Gifts (ModuleScript)

	Character-specific gift reactions without gift grinding:
	  • A character accepts one gift per "progress beat" (a finished quest
	    step or first-time shared activity), never on a timer.
	  • Repeating the same item gives half value the second time, nothing
	    after that, and a unique "you again?" line.
	  • Positive affinity from gifts is soft-capped per milestone, so gifts
	    can smooth the way but never replace story progress.
	  • Disliked items always cost something; insulting items cost trust.
]]

local Conditions = require(script.Parent.Conditions)
local Rules = require(script.Parent.Rules)

local Gifts = {}

function Gifts.canGive(state, npcId: string, ctx): (boolean, string?)
	local char = ctx.content.Characters[npcId]
	if char == nil or char.gifts == nil then
		return false, "noGifts"
	end
	local rel = state.rel[npcId]
	if rel == nil then
		return false, "noGifts"
	end
	if Conditions.milestoneRank(ctx, rel.milestone) < Conditions.milestoneRank(ctx, char.gifts.minMilestone) then
		return false, "tooSoon"
	end
	if not rel.giftReady then
		return false, "notReady"
	end
	return true, nil
end

function Gifts.tierOf(ctx, npcId: string, itemId: string): string
	local char = ctx.content.Characters[npcId]
	return char.gifts.tiers[itemId] or "neutral"
end

-- Returns ok, result. On success result = { tier, text, emote, times }.
-- On refusal result = { reason, text, emote } (text is an in-character line).
function Gifts.give(state, npcId: string, itemId: string, ctx, events)
	local char = ctx.content.Characters[npcId]
	local ok, reason = Gifts.canGive(state, npcId, ctx)
	if not ok then
		local line = char and char.gifts and char.gifts.refusals[reason]
		return false, { reason = reason, text = line and line.text, emote = line and line.emote }
	end
	local item = ctx.content.Items[itemId]
	if item == nil or not item.giftable then
		return false, { reason = "notGiftable" }
	end
	if (state.inv[itemId] or 0) < 1 then
		return false, { reason = "notOwned" }
	end

	local prefs = char.gifts
	local rel = state.rel[npcId]
	local tier = Gifts.tierOf(ctx, npcId, itemId)
	local times = rel.gifts[itemId] or 0

	Rules.takeItem(state, itemId, 1, events)
	rel.gifts[itemId] = times + 1
	rel.giftReady = false

	local value = prefs.values[tier]
	local affinity = value.affinity or 0
	if affinity > 0 then
		local multiplier = if times == 0 then 1 elseif times == 1 then 0.5 else 0
		affinity = math.floor(affinity * multiplier + 0.5)
	end
	if affinity ~= 0 then
		Rules.addStat(state, ctx, npcId, "affinity", affinity, events, true)
	end
	local trust = value.trust or 0
	if trust < 0 or (trust > 0 and times == 0) then
		Rules.addStat(state, ctx, npcId, "trust", trust, events)
	end

	local reaction = prefs.reactions[itemId]
	local line
	if times >= 2 and tier ~= "disliked" and tier ~= "hated" then
		line = (reaction and reaction.tooMany) or prefs.defaults.tooMany
	elseif times >= 1 then
		line = (reaction and reaction.again) or prefs.defaults[tier .. "Again"] or prefs.defaults[tier]
	else
		line = (reaction and reaction.first) or prefs.defaults[tier]
	end

	if times == 0 and reaction and reaction.effects then
		Rules.applyEffects(state, reaction.effects, ctx, events)
	end
	table.insert(events, { kind = "gift", npc = npcId, item = itemId, tier = tier })
	Rules.settle(state, ctx, events)

	return true, {
		tier = tier,
		text = line.text,
		emote = line.emote or "neutral",
		times = times + 1,
	}
end

return Gifts
