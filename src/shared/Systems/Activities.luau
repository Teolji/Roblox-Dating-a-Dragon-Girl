--[[
	Activities
	Explorer: ReplicatedStorage > Hearthscale > Systems > Activities (ModuleScript)

	Shared activities / outings built on the Minigames kinds. Handles
	availability, session creation, duration sanity checks, tiered results and
	rewards. Rewards:
	  • first clear  → rewards.first + the reached tier's effects
	  • replays      → rewards.again (soft-capped), at most
	                   Config.ActivityRepeatRewardLimit times per activity
	Every completion emits the quest event "activity:<id>".
]]

local Conditions = require(script.Parent.Conditions)
local Rules = require(script.Parent.Rules)
local Minigames = require(script.Parent.Minigames)
local Prng = require(script.Parent.Parent.Util.Prng)

local Activities = {}

local LATE_GRACE = 20 -- seconds allowed past the time limit for network lag

function Activities.canStart(state, actId: string, ctx): (boolean, string?)
	local def = ctx.content.Activities[actId]
	if def == nil then
		return false, "unknown"
	end
	if def.romance and not ctx.config.RomanceEnabled then
		return false, "unavailable"
	end
	if not Conditions.check(def.when, state, ctx) then
		return false, "locked"
	end
	return true, nil
end

function Activities.modifiers(state, def)
	local mods = {}
	if def.resolveWidthBonus then
		local rel = state.rel.saffron
		mods.widthBonus = (rel and rel.resolve or 0) * def.resolveWidthBonus
	end
	return mods
end

function Activities.start(state, actId: string, ctx, seed: number)
	local def = ctx.content.Activities[actId]
	local generated = Minigames.generate(def.kind, def.params, Prng.new(seed), Activities.modifiers(state, def))
	return {
		activity = actId,
		kind = def.kind,
		public = generated.public,
		secret = generated.secret,
		collected = {},
		finished = false,
	}
end

-- Marks a collect point as gathered. Distance is validated by the caller.
function Activities.collect(session, pointIndex: number): boolean
	if session.kind ~= "collect" or session.finished then
		return false
	end
	if type(pointIndex) ~= "number" or session.secret.points[pointIndex] == nil then
		return false
	end
	if session.collected[pointIndex] then
		return false
	end
	session.collected[pointIndex] = true
	return true
end

function Activities.tierFor(def, score: number)
	local index, tier = 1, def.tiers[1]
	for i, t in ipairs(def.tiers) do
		if score >= t.min then
			index, tier = i, t
		end
	end
	return index, tier
end

-- Returns ok, result | reason
function Activities.finish(state, session, submission, elapsed: number, ctx, events)
	if session.finished then
		return false, "alreadyFinished"
	end
	local def = ctx.content.Activities[session.activity]
	if elapsed < (def.minDuration or 0) then
		return false, "tooFast"
	end
	session.finished = true

	local score, maxScore = Minigames.score(def.kind, session, submission)
	local timeLimit = def.params.timeLimit
	if timeLimit and elapsed > timeLimit + LATE_GRACE and def.kind ~= "collect" then
		-- Way past the limit: count it as a gentle "ran out of time".
		score = math.min(score, def.tiers[1].min)
	end
	local tierIndex, tier = Activities.tierFor(def, score)

	local record = state.acts[session.activity]
	if record == nil then
		record = { plays = 0, best = 0, repeats = 0 }
		state.acts[session.activity] = record
	end
	local first = record.plays == 0
	record.plays += 1
	record.best = math.max(record.best, score)

	if first then
		Rules.applyEffects(state, def.rewards and def.rewards.first, ctx, events)
		Rules.applyEffects(state, tier.effects, ctx, events)
		Rules.markProgressBeat(state, ctx)
	elseif record.repeats < ctx.config.ActivityRepeatRewardLimit and def.rewards and def.rewards.again then
		record.repeats += 1
		Rules.applyEffects(state, def.rewards.again, ctx, events)
	end

	Rules.emit(state, "activity:" .. session.activity, ctx, events)
	Rules.settle(state, ctx, events)

	return true,
		{
			activity = session.activity,
			score = score,
			maxScore = maxScore,
			tier = tierIndex,
			tierLabel = tier.label,
			first = first,
			line = tier.line,
		}
end

return Activities
