--[[
	Minigames
	Explorer: ReplicatedStorage > Hearthscale > Systems > Minigames (ModuleScript)

	Server-side generation and scoring for the four reusable minigame kinds.
	`generate` returns { public = <sent to the client>, secret = <kept on the
	server> }. `score` never trusts the client's own idea of its score: it
	recomputes from the secret answers.

	Kinds
	  sort      Put lost items on the right shelf. Answers are secret.
	  sequence  Repeat rune patterns. The pattern must be shown, so it is
	            public, but inputs are still checked server-side.
	  timing    Stop a sweeping marker inside a target zone. Zones are public
	            (they must be drawn); the server re-checks each stop position.
	  collect   Walk to glowing points in the world. The server validates each
	            pickup against the player's real position (see ActivityService).
]]

local Minigames = {}

local Generators = {}
local Scorers = {}

-- sort ---------------------------------------------------------------------
Generators.sort = function(params, rng)
	local pool = table.clone(params.pool)
	rng:shuffle(pool)
	local items, answers = {}, {}
	for i = 1, math.min(params.count, #pool) do
		local entry = pool[i]
		table.insert(items, { name = entry.name, flavor = entry.flavor })
		table.insert(answers, entry.shelf)
	end
	return {
		public = { items = items, shelves = params.shelves, timeLimit = params.timeLimit },
		secret = { answers = answers },
	}
end

Scorers.sort = function(session, submission)
	local answers = session.secret.answers
	if type(submission) ~= "table" then
		return 0, #answers
	end
	local score = 0
	for i, correct in ipairs(answers) do
		if submission[i] == correct then
			score += 1
		end
	end
	return score, #answers
end

-- sequence -----------------------------------------------------------------
Generators.sequence = function(params, rng)
	local rounds = {}
	for r = 1, params.rounds do
		local length = params.startLength + (r - 1) * (params.growth or 1)
		local seq = {}
		for i = 1, length do
			seq[i] = rng:range(1, #params.symbols)
		end
		rounds[r] = seq
	end
	return {
		public = { symbols = params.symbols, rounds = rounds, timeLimit = params.timeLimit },
		secret = { rounds = rounds },
	}
end

Scorers.sequence = function(session, submission)
	local rounds = session.secret.rounds
	if type(submission) ~= "table" then
		return 0, #rounds
	end
	local score = 0
	for r, seq in ipairs(rounds) do
		local answer = submission[r]
		if type(answer) == "table" and #answer == #seq then
			local correct = true
			for i, symbol in ipairs(seq) do
				if answer[i] ~= symbol then
					correct = false
					break
				end
			end
			if correct then
				score += 1
			end
		end
	end
	return score, #rounds
end

-- timing -------------------------------------------------------------------
-- modifiers.widthBonus widens every zone (used by the finale: Saffron's
-- resolve, built from earlier choices, makes the last scene easier).
Generators.timing = function(params, rng, modifiers)
	local bonus = (modifiers and modifiers.widthBonus) or 0
	local rounds = {}
	for r = 1, params.rounds do
		local width = math.clamp(params.zoneWidth + bonus, params.minWidth or 0.05, params.maxWidth or 0.5)
		local margin = width / 2 + 0.05
		local center = margin + rng:nextNumber() * (1 - 2 * margin)
		local speed = params.speedMin + rng:nextNumber() * (params.speedMax - params.speedMin)
		rounds[r] = {
			center = math.floor(center * 1000) / 1000,
			width = math.floor(width * 1000) / 1000,
			speed = math.floor(speed * 100) / 100,
		}
	end
	return {
		public = { rounds = rounds, prompt = params.prompt, timeLimit = params.timeLimit },
		secret = { rounds = rounds },
	}
end

Scorers.timing = function(session, submission)
	local rounds = session.secret.rounds
	if type(submission) ~= "table" then
		return 0, #rounds
	end
	local score = 0
	for r, round in ipairs(rounds) do
		local pos = submission[r]
		if type(pos) == "number" and pos == pos and math.abs(pos - round.center) <= round.width / 2 + 0.005 then
			score += 1
		end
	end
	return score, #rounds
end

-- collect ------------------------------------------------------------------
Generators.collect = function(params, rng)
	local points = table.clone(params.points)
	rng:shuffle(points)
	local chosen = {}
	for i = 1, math.min(params.count, #points) do
		chosen[i] = points[i]
	end
	return {
		public = { points = chosen, label = params.label, timeLimit = params.timeLimit },
		secret = { points = chosen },
	}
end

Scorers.collect = function(session)
	local got = 0
	for _ in pairs(session.collected) do
		got += 1
	end
	return got, #session.secret.points
end

Minigames.Kinds = { sort = true, sequence = true, timing = true, collect = true }

function Minigames.generate(kind: string, params, rng, modifiers)
	local gen = Generators[kind]
	assert(gen, `Unknown minigame kind {kind}`)
	return gen(params, rng, modifiers)
end

function Minigames.score(kind: string, session, submission): (number, number)
	return Scorers[kind](session, submission)
end

return Minigames
