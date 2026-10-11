-- Full-story simulations: every ending must be reachable by a matching play
-- style, no play style may soft-lock, and saves survive a JSON round trip
-- (the same encoding DataStores use) after every single action.
return function(T, root, gameRequire)
	local Sim = T.Sim

	local KIND = { "kind", "respect", "comfort", "honest", "insight", "joke", "curious" }
	local function concat(...)
		local out = {}
		for _, list in ipairs({ ... }) do
			for _, v in ipairs(list) do
				table.insert(out, v)
			end
		end
		return out
	end

	local function show(sim)
		local lines = {}
		for chapter = 2, 6 do
			local s = sim.chapterStats[chapter]
			if s then
				table.insert(
					lines,
					string.format("ch%d: trust %d, affinity %d, romance %d, resolve %d", chapter, s.trust, s.affinity, s.romance, s.resolve)
				)
			end
		end
		return table.concat(lines, " | ")
	end

	local function play(strategy, overrides)
		strategy.roundtrip = true
		local sim = Sim.new(root, gameRequire, strategy, overrides)
		local ending = sim:run()
		print(`        [{strategy.name}] ending={ending} milestones={table.concat(sim.milestones, ">")} gifts={sim.giftsGiven} steps={sim.steps}`)
		print(`        [{strategy.name}] {show(sim)}`)
		return sim, ending
	end

	T.test("playthrough: attentive romance path reaches 'Two Flames'", function()
		local sim, ending = play({
			name = "romance",
			prefs = concat({ "romance", "together" }, KIND, { "believe", "friend" }),
			avoid = { "rude", "push", "dismissive", "leave", "mother" },
			gifts = "best",
		})
		T.eq(ending, "two_flames", "ending")
		T.eq(sim.state.rel.saffron.milestone, "sweetheart", "milestone")
		T.eq(sim.state.path, "romance", "path")
	end)

	T.test("playthrough: attentive friendship path reaches 'Kindred Sparks'", function()
		local sim, ending = play({
			name = "friendship",
			prefs = concat({ "friend" }, KIND, { "believe", "family" }),
			avoid = { "romance", "together", "rude", "push", "dismissive", "leave", "mother" },
			gifts = "best",
		})
		T.eq(ending, "kindred_sparks", "ending")
		T.eq(sim.state.rel.saffron.milestone, "kindred", "milestone")
		T.eq(sim.state.rel.saffron.romance, 0, "no romance points")
	end)

	T.test("playthrough: choosing to send her home reaches 'The Long Way Home'", function()
		local _, ending = play({
			name = "home",
			prefs = concat({ "mother", "friend" }, KIND),
			avoid = { "romance", "together", "believe", "family", "rude", "push", "dismissive", "leave" },
			gifts = "best",
		})
		T.eq(ending, "long_way_home", "ending")
	end)

	T.test("playthrough: pushy, dismissive player reaches 'A Stranger's Lantern'", function()
		local sim, ending = play({
			name = "rude",
			prefs = { "rude", "push", "dismissive", "leave", "joke" },
			avoid = { "kind", "respect", "comfort", "honest", "insight", "romance", "friend", "mother" },
			gifts = "worst",
		})
		T.eq(ending, "strangers_lantern", "ending")
		T.ok(sim.state.rel.saffron.milestone ~= "friend", "rude player never becomes a friend")
	end)

	T.test("playthrough: romance can't be ground out — she declines without enough trust", function()
		-- Romance-seeking but careless: pushes boundaries, so trust stays low.
		local sim, ending = play({
			name = "pushy-romantic",
			prefs = { "romance", "together", "push", "joke", "curious", "believe" },
			avoid = { "respect", "comfort", "mother" },
			gifts = "best",
		})
		T.ok(sim.state.path ~= "romance", "Saffron does not accept a confession from someone she doesn't trust")
		T.ok(ending ~= "two_flames", "no romance ending")
	end)

	T.test("playthrough: friendship edition (RomanceEnabled=false) hides all romance and still completes", function()
		local sim, ending = play({
			name = "all-ages",
			prefs = concat({ "romance", "together" }, KIND, { "believe", "friend" }),
			avoid = { "rude", "push", "dismissive", "leave", "mother" },
			gifts = "best",
		}, { RomanceEnabled = false })
		T.eq(sim.sawRomanceChoice, false, "romance choice shown")
		T.eq(sim.state.rel.saffron.romance, 0, "romance stat")
		T.ok(sim.state.rel.saffron.milestone ~= "sweetheart", "no sweetheart milestone")
		T.eq(ending, "kindred_sparks", "ending")
	end)

	T.test("playthrough: always-first-choice player with no gifts or chat still finishes", function()
		local _, ending = play({ name = "first", prefs = {}, avoid = {}, gifts = "none", chat = false, perf = 0 })
		T.ok(ending ~= nil, "reached an ending")
	end)

	T.test("playthrough: 60 random players never soft-lock", function()
		local counts = {}
		for seed = 1, 60 do
			local sim = Sim.new(root, gameRequire, {
				name = "random",
				random = true,
				seed = seed * 7919,
				gifts = "random",
				perf = "random",
				roundtrip = seed % 3 == 0,
			})
			local ending = sim:run()
			counts[ending] = (counts[ending] or 0) + 1
		end
		local parts = {}
		for id, n in pairs(counts) do
			table.insert(parts, `{id}={n}`)
		end
		table.sort(parts)
		print("        [random x60] " .. table.concat(parts, " "))
	end)
end
