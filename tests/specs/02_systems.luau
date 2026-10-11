-- Unit tests for the shared systems: conditions, rules, dialogue, gifts,
-- minigames/activities, save sanitising and per-player world rules.
return function(T, root, gameRequire)
	local serde = require("@lune/serde")

	local Config = gameRequire(root.Config)
	local Content = gameRequire(root.Content)
	local Conditions = gameRequire(root.Systems.Conditions)
	local Rules = gameRequire(root.Systems.Rules)
	local Dialogue = gameRequire(root.Systems.Dialogue)
	local Gifts = gameRequire(root.Systems.Gifts)
	local Minigames = gameRequire(root.Systems.Minigames)
	local Activities = gameRequire(root.Systems.Activities)
	local World = gameRequire(root.Systems.World)
	local SaveSchema = gameRequire(root.Systems.SaveSchema)
	local Prng = gameRequire(root.Util.Prng)

	local function ctxWith(overrides)
		local cfg = table.clone(Config)
		for k, v in pairs(overrides or {}) do
			cfg[k] = v
		end
		return { content = Content, config = cfg }
	end
	local ctx = ctxWith()

	local function fresh(c)
		c = c or ctx
		local state = SaveSchema.default(c)
		Rules.ensureStarted(state, c, {})
		return state
	end

	-- Puts a state at "Assistant Keeper" with gifts unlocked.
	local function acquaintance()
		local state = fresh()
		state.quests.q_item_4112 = { s = "complete", step = 3, p = {} }
		Rules.settle(state, ctx, {})
		state.rel.saffron.giftReady = true
		return state
	end

	-- Conditions ---------------------------------------------------------------
	T.test("conditions: lists, any/all/not and stats", function()
		local state = fresh()
		state.flags.a = true
		state.rel.saffron.trust = 30
		T.ok(Conditions.check({ { flag = "a" }, { stat = { "trust", 30 } } }, state, ctx), "list = all")
		T.ok(not Conditions.check({ flag = "a", stat = { "trust", 31 } }, state, ctx), "table = all clauses")
		T.ok(Conditions.check({ any = { { flag = "zzz" }, { flag = "a" } } }, state, ctx), "any")
		T.ok(Conditions.check({ ["not"] = { flag = "zzz" } }, state, ctx), "not")
		T.ok(Conditions.check({ statBelow = { "trust", 31 } }, state, ctx), "statBelow")
		T.ok(Conditions.check({ quest = { "q_arrival", "active" } }, state, ctx), "quest active")
		T.ok(Conditions.check({ questStep = { "q_arrival", "meet" } }, state, ctx), "quest step")
		T.ok(Conditions.check({ romance = true }, state, ctxWith({ RomanceEnabled = true })), "romance gate on")
		T.ok(not Conditions.check({ romance = true }, state, ctxWith({ RomanceEnabled = false })), "romance gate off")
	end)

	T.test("conditions: unknown keys are errors, not silent passes", function()
		local ok = pcall(Conditions.check, { notARealKey = 1 }, fresh(), ctx)
		T.eq(ok, false, "unknown key accepted")
	end)

	-- Rules --------------------------------------------------------------------
	T.test("rules: milestones advance in order and never regress", function()
		local state = acquaintance()
		T.eq(state.rel.saffron.milestone, "acquaintance", "after Ch1 quest")
		state.rel.saffron.trust, state.rel.saffron.affinity = 99, 99
		Rules.settle(state, ctx, {})
		T.eq(state.rel.saffron.milestone, "acquaintance", "stats alone can't skip the pond scene")
		state.flags.pond_heart_to_heart = true
		state.flags.heard_full_story = true
		Rules.settle(state, ctx, {})
		T.eq(state.rel.saffron.milestone, "confidant", "climbs one rank at a time to confidant")
		state.rel.saffron.trust, state.rel.saffron.affinity = 0, 0
		Rules.settle(state, ctx, {})
		T.eq(state.rel.saffron.milestone, "confidant", "losing stats never demotes")
	end)

	T.test("rules: stats clamp and soft cap only limits gift/replay affinity", function()
		local state = acquaintance()
		local cap = Config.SoftAffinityCap.acquaintance
		state.rel.saffron.affinity = cap - 1
		Rules.apply(state, { softStat = { "affinity", 10 } }, ctx)
		T.eq(state.rel.saffron.affinity, cap, "soft cap")
		Rules.apply(state, { stat = { "affinity", 500 } }, ctx)
		T.eq(state.rel.saffron.affinity, Config.StatMax, "hard clamp")
		Rules.apply(state, { stat = { "trust", -500 } }, ctx)
		T.eq(state.rel.saffron.trust, 0, "floor")
	end)

	T.test("rules: romance stat and path are inert in the friendship edition", function()
		local c = ctxWith({ RomanceEnabled = false })
		local state = fresh(c)
		Rules.apply(state, { stat = { "romance", 20 }, path = "romance" }, c)
		T.eq(state.rel.saffron.romance, 0, "romance")
		T.eq(state.path, "friendship", "path converted")
	end)

	T.test("rules: quest events only count for the current step and cap at count", function()
		local state = fresh()
		Rules.fire(state, "collect:glowcap", ctx)
		T.eq(state.quests.q_lanternfall, nil, "future quest untouched")
		state.quests.q_lanternfall = { s = "active", step = 3, p = {} }
		for _ = 1, 9 do
			Rules.emit(state, "collect:glowcap", ctx, {})
		end
		T.eq(state.quests.q_lanternfall.p.caps, 5, "capped at objective count")
		Rules.settle(state, ctx, {})
		T.eq(state.quests.q_lanternfall.step, 4, "advanced to deliver")
	end)

	-- Dialogue -----------------------------------------------------------------
	T.test("dialogue: conversations are transactional (abandoning discards effects)", function()
		local state = fresh()
		local before = serde.encode("json", state)
		local session = Dialogue.begin(state, "saffron_meet", ctx, {})
		while session.choices == nil do
			Dialogue.advance(session, ctx, {})
		end
		Dialogue.choose(session, 1, ctx, {}) -- the kind answer: +trust
		T.ok(session.state.rel.saffron.trust > 0, "draft changed")
		T.eq(serde.encode("json", state), before, "real state untouched until commit")
	end)

	T.test("dialogue: invalid, locked and out-of-range choices are rejected", function()
		local state = acquaintance()
		state.quests.q_stargazing = { s = "active", step = 2, p = {} }
		local session = Dialogue.begin(state, "saffron_stars", ctx, {})
		while session.choices == nil do
			Dialogue.advance(session, ctx, {})
		end
		local view = Dialogue.view(session, ctx, "P")
		T.ok(view.choices[1].locked, "romance confession locked for a non-confidant")
		T.eq((Dialogue.choose(session, 1, ctx, {})), false, "locked choice")
		T.eq((Dialogue.choose(session, 99, ctx, {})), false, "out of range")
		T.eq((Dialogue.choose(session, 1.5, ctx, {})), false, "non-integer")
		T.eq((Dialogue.choose(session, "1" :: any, ctx, {})), false, "string index")
	end)

	T.test("dialogue: romance choices vanish entirely in the friendship edition", function()
		local c = ctxWith({ RomanceEnabled = false })
		local state = fresh(c)
		state.quests.q_stargazing = { s = "active", step = 2, p = {} }
		local session = Dialogue.begin(state, "saffron_stars", c, {})
		while session.choices == nil do
			Dialogue.advance(session, c, {})
		end
		for _, choice in ipairs(Dialogue.view(session, c, "P").choices) do
			T.eq(choice.romance, false, "romance choice visible: " .. choice.text)
		end
	end)

	T.test("dialogue: chat topics can only be used once", function()
		local state = acquaintance()
		local function topicCount(s)
			local session = Dialogue.begin(s, "saffron_hub", ctx, {})
			Dialogue.choose(session, 1, ctx, {}) -- "Can we chat?"
			return #session.choices, session
		end
		local n1, session = topicCount(state)
		Dialogue.choose(session, 1, ctx, {}) -- first topic (age)
		while not session.ended do
			if session.choices then
				Dialogue.choose(session, #session.choices, ctx, {}) -- Never mind / Goodbye
			else
				Dialogue.advance(session, ctx, {})
			end
		end
		local n2 = topicCount(session.state)
		T.eq(n2, n1 - 1, "topic removed after use")
	end)

	T.test("dialogue: text tokens fill in name, title and hint", function()
		local state = fresh()
		T.eq(
			Dialogue.format("Hi {player}, {saffron}.", state, ctx, "Ash"),
			"Hi Ash, Miss Ignavarre.",
			"stranger tokens"
		)
		T.ok(#Dialogue.format("{hint}", state, ctx, "Ash") > 10, "hint text")
	end)

	-- Gifts --------------------------------------------------------------------
	T.test("gifts: refused before Assistant Keeper and between adventures", function()
		local state = fresh()
		state.inv.honey_bun = 3
		local ok, result = Gifts.give(state, "saffron", "honey_bun", ctx, {})
		T.eq(ok, false, "stranger")
		T.eq(result.reason, "tooSoon", "reason")
		state = acquaintance()
		state.inv.honey_bun = 3
		T.ok((Gifts.give(state, "saffron", "honey_bun", ctx, {})), "first gift")
		ok, result = Gifts.give(state, "saffron", "honey_bun", ctx, {})
		T.eq(ok, false, "second gift without an adventure")
		T.eq(result.reason, "notReady", "reason")
		T.ok(result.text ~= nil, "in-character refusal line")
		T.eq(state.inv.honey_bun, 2, "refused gift not consumed")
	end)

	T.test("gifts: repeats give diminishing returns, then nothing", function()
		local state = acquaintance()
		state.inv.smoked_ember_tea = 3
		local gains = {}
		for i = 1, 3 do
			state.rel.saffron.giftReady = true
			local before = state.rel.saffron.affinity
			Gifts.give(state, "saffron", "smoked_ember_tea", ctx, {})
			gains[i] = state.rel.saffron.affinity - before
		end
		T.eq(gains[1], 6, "first")
		T.eq(gains[2], 3, "second")
		T.eq(gains[3], 0, "third")
	end)

	T.test("gifts: insulting gift costs trust every time; items must be owned and giftable", function()
		local state = acquaintance()
		state.rel.saffron.trust = 20
		state.inv.fire_starter = 2
		Gifts.give(state, "saffron", "fire_starter", ctx, {})
		state.rel.saffron.giftReady = true
		Gifts.give(state, "saffron", "fire_starter", ctx, {})
		T.eq(state.rel.saffron.trust, 12, "trust lost twice")
		state.rel.saffron.giftReady = true
		T.eq((Gifts.give(state, "saffron", "star_chart", ctx, {})), false, "not owned")
		state.inv.sealed_letter = 1
		T.eq((Gifts.give(state, "saffron", "sealed_letter", ctx, {})), false, "quest item")
	end)

	T.test("gifts: finishing a quest step re-opens gifting", function()
		local state = acquaintance()
		state.rel.saffron.giftReady = false
		state.quests.q_pond = { s = "active", step = 1, p = {} }
		Rules.fire(state, "activity:act_fishing", ctx)
		T.eq(state.rel.saffron.giftReady, true, "progress beat")
	end)

	-- Minigames / activities -----------------------------------------------------
	T.test("minigames: scoring uses server-side answers and survives garbage input", function()
		local rng = Prng.new(42)
		local sort = Minigames.generate("sort", Content.Activities.act_catalogue.params, rng)
		local session = { secret = sort.secret, collected = {} }
		T.eq((Minigames.score("sort", session, sort.secret.answers)), 8, "perfect sort")
		T.eq((Minigames.score("sort", session, "lol")), 0, "string submission")
		T.eq((Minigames.score("sort", session, { { 1 }, 0 / 0 })), 0, "nested/NaN submission")
		T.eq(sort.public.items[1].shelf, nil, "answers not sent to client")

		local timing = Minigames.generate("timing", Content.Activities.act_fishing.params, rng)
		local tsession = { secret = timing.secret }
		local centers, misses = {}, {}
		for i, r in ipairs(timing.secret.rounds) do
			centers[i] = r.center
			misses[i] = r.center + r.width
		end
		T.eq((Minigames.score("timing", tsession, centers)), 5, "all hits")
		T.eq((Minigames.score("timing", tsession, misses)), 0, "all misses")
		T.eq((Minigames.score("timing", tsession, { 0 / 0, math.huge })), 0, "NaN/inf")

		local seq = Minigames.generate("sequence", Content.Activities.act_lanterns.params, rng)
		T.eq((Minigames.score("sequence", { secret = seq.secret }, seq.secret.rounds)), 4, "sequence perfect")
	end)

	T.test("activities: too-fast submissions rejected; replay rewards are limited", function()
		local state = acquaintance()
		state.quests.q_pond = { s = "active", step = 1, p = {} }
		local session = Activities.start(state, "act_fishing", ctx, 1)
		local ok, why = Activities.finish(state, session, {}, 0.5, ctx, {})
		T.eq(ok, false, "instant finish")
		T.eq(why, "tooFast", "reason")
		local rewarded = 0
		state.rel.saffron.affinity = 0
		for _ = 1, 8 do
			local s = Activities.start(state, "act_fishing", ctx, 2)
			local before = state.rel.saffron.affinity
			Activities.finish(state, s, {}, 10, ctx, {})
			if state.rel.saffron.affinity > before then
				rewarded += 1
			end
		end
		T.eq(rewarded, 1 + Config.ActivityRepeatRewardLimit, "first clear + limited replays")
		local s = Activities.start(state, "act_fishing", ctx, 3)
		Activities.finish(state, s, {}, 10, ctx, {})
		T.eq((Activities.finish(state, s, {}, 10, ctx, {})), false, "double submit")
	end)

	T.test("activities: finale gets easier with Saffron's resolve", function()
		local state = acquaintance()
		state.quests.q_summit = { s = "active", step = 3, p = {} }
		state.rel.saffron.resolve = 0
		local low = Activities.start(state, "act_rekindle", ctx, 5)
		state.rel.saffron.resolve = 10
		local high = Activities.start(state, "act_rekindle", ctx, 5)
		T.ok(high.public.rounds[1].width > low.public.rounds[1].width, "wider target with more resolve")
	end)

	T.test("activities: collect points are validated and counted once", function()
		local state = acquaintance()
		state.quests.q_stargazing = { s = "active", step = 1, p = {} }
		local session = Activities.start(state, "act_fireflies", ctx, 9)
		T.ok(Activities.collect(session, 1), "first pickup")
		T.eq(Activities.collect(session, 1), false, "duplicate")
		T.eq(Activities.collect(session, 999), false, "bogus index")
		local ok, result = Activities.finish(state, session, nil, 30, ctx, {})
		T.ok(ok, "finish")
		T.eq(result.score, 1, "score")
	end)

	-- Saves ----------------------------------------------------------------------
	T.test("save: garbage and hostile blobs sanitise to a valid state", function()
		local blobs = {
			"string",
			42,
			{ flags = "x", quests = { q_fake = { s = "active" }, q_item_4112 = { s = "complete", step = 999 } } },
			{
				inv = { glowcap = 1e9, not_real = 5, honey_bun = -3 },
				rel = { saffron = { trust = 1e9, affinity = 0 / 0, milestone = "emperor", giftReady = "yes" } },
				settings = { music = 99, textSpeed = "ludicrous", uiScale = -1 },
				chapter = 999,
				ending = "made_up",
			},
		}
		local checked = 0
		for i = 0, #blobs do
			local blob = blobs[i] -- index 0 is nil: a missing save
			checked += 1
			local state = SaveSchema.reconcile(blob, ctx)
			T.ok(state.chapter >= 1 and state.chapter <= #Content.Chapters, "chapter in range")
			T.eq(state.quests.q_fake, nil, "unknown quest dropped")
			if state.quests.q_item_4112 then
				T.eq(state.quests.q_item_4112.step, 3, "step clamped")
			end
			T.ok((state.inv.glowcap or 0) <= 99, "item count clamped")
			T.eq(state.inv.not_real, nil, "unknown item dropped")
			T.eq(state.inv.honey_bun, nil, "negative count dropped")
			T.ok(state.rel.saffron.trust <= Config.StatMax, "trust clamped")
			T.eq(state.rel.saffron.affinity, 0, "NaN replaced")
			T.eq(state.rel.saffron.milestone, "stranger", "bad milestone reset")
			T.eq(state.rel.saffron.giftReady, false, "bool coerced")
			T.ok(state.settings.music <= 1, "volume clamped")
			T.eq(state.settings.textSpeed, "normal", "bad text speed")
			T.eq(state.ending, nil, "fake ending dropped")
		end
		T.eq(checked, 5, "blobs checked")
	end)

	T.test("save: round trip through JSON preserves a mid-story state exactly", function()
		local state = acquaintance()
		state.flags.learned_tea = true
		state.inv.glowcap = 4
		state.collected.glowcap_2 = true
		state.acts.act_catalogue = { plays = 2, best = 7, repeats = 1 }
		state.rel.saffron.gifts.honey_bun = 1
		local restored = SaveSchema.reconcile(serde.decode("json", serde.encode("json", state)), ctx)
		T.eq(serde.encode("json", restored), serde.encode("json", state), "identical after reload")
	end)

	T.test("save: romance save loaded into the friendship edition downgrades safely", function()
		local state = acquaintance()
		state.path = "romance"
		state.rel.saffron.milestone = "sweetheart"
		state.rel.saffron.romance = 40
		local c = ctxWith({ RomanceEnabled = false })
		local restored = SaveSchema.reconcile(serde.decode("json", serde.encode("json", state)), c)
		T.eq(restored.path, "friendship", "path")
		T.eq(restored.rel.saffron.milestone, "confidant", "milestone fallback")
		T.eq(restored.rel.saffron.romance, 0, "romance")
	end)

	T.test("save: new story keeps endings gallery and settings", function()
		local state = acquaintance()
		state.endingsSeen.kindred_sparks = true
		state.settings.music = 0.1
		local reset = SaveSchema.newStory(state, ctx)
		T.eq(reset.endingsSeen.kindred_sparks, true, "gallery kept")
		T.eq(reset.settings.music, 0.1, "settings kept")
		T.eq(reset.meta.stories, 2, "story counter")
		T.eq(next(reset.quests), nil, "quests reset")
	end)

	-- World ----------------------------------------------------------------------
	T.test("world: each player's NPC placement follows only their own story", function()
		local a, b = acquaintance(), acquaintance()
		a.quests.q_pond = { s = "active", step = 1, p = {} }
		T.eq(World.station(a, "saffron", ctx), "Saffron_Pond", "player A sees her at the pond")
		T.eq(World.station(b, "saffron", ctx), "Saffron_Shop", "player B still sees her at the shop")
		T.eq(World.station(b, "cinderra", ctx), nil, "Cinderra absent before chapter 4")
	end)

	T.test("world: collectibles respect conditions and can't be collected twice", function()
		local state = fresh()
		T.eq(World.collectibleAvailable(state, "glowcap_1", ctx), false, "before the quest step")
		state.quests.q_lanternfall = { s = "active", step = 3, p = {} }
		T.ok(World.collect(state, "glowcap_1", ctx, {}), "collect")
		T.eq(World.collect(state, "glowcap_1", ctx, {}), false, "twice")
		T.eq(state.inv.glowcap, 1, "one glowcap")
	end)
end
