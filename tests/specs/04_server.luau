-- Integration tests for the real server modules (GameService, DataService)
-- with mocked Roblox services. Covers request validation, the Chapter 1
-- vertical slice through actual requests, saving, session locks, save
-- failures and leave/rejoin persistence.
return function(T)
	local Harness = T.Harness

	local function byText(fragment)
		return function(node)
			for _, choice in ipairs(node.choices) do
				if not choice.locked and string.find(choice.text, fragment, 1, true) then
					return choice.index
				end
			end
			return nil
		end
	end

	local function lastStatus(h, player)
		local list = h.statuses[player] or {}
		return list[#list] and list[#list].status
	end

	-- Plays the Chapter 1 vertical slice through server requests.
	local function playChapterOne(h, player)
		h:moveTo(player, "Saffron_Shop")
		local r = h:converse(player, "saffron", byText("sorry about your roof"))
		T.ok(r.ok, "meet conversation")
		T.eq(h:state(player).quests.q_item_4112.s, "active", "Item #4112 started")

		r = h:converse(player, "saffron", byText("Let's sort"))
		T.ok(r.activity ~= nil, "dialogue started the sorting activity")
		T.eq(r.activity.public.items[1].shelf, nil, "answers not sent to client")
		local early =
			h:request(player, "submitActivity", { id = r.activity.id, submission = { 1, 1, 1, 1, 1, 1, 1, 1 } })
		T.eq(early.reason, "tooFast", "instant submit rejected")
		h.advance(5)
		local done =
			h:request(player, "submitActivity", { id = r.activity.id, submission = { 1, 2, 3, 4, 1, 2, 3, 4 } })
		T.ok(done.ok, "activity accepted")
		T.ok(h:state(player).inv.rolling_pin == 1, "strays handed over")

		for _, stop in ipairs({ { "mabel", "Mabel_Bakery" }, { "pim", "Pim_Hall" }, { "wren", "Wren_Workshop" } }) do
			h:moveTo(player, stop[2])
			T.ok(h:converse(player, stop[1]).ok, "returned item to " .. stop[1])
		end
		h:moveTo(player, "Saffron_Shop")
		r = h:converse(player, "saffron", byText("Mostly decorative"))
		T.ok(r.ok, "report conversation")
		local state = h:state(player)
		T.eq(state.rel.saffron.milestone, "acquaintance", "milestone unlocked")
		T.eq(state.chapter, 2, "chapter 2 begins")
	end

	T.test("server: new player gets a fresh story and takes the session lock", function()
		local h = Harness.new()
		local player = h:join(101)
		local state = h:state(player)
		T.eq(state.quests.q_arrival.s, "active", "first quest")
		T.eq(h.store.data.player_101.lock.job, "server-A", "lock")
		T.eq(lastStatus(h, player), "ok", "status")
	end)

	T.test("server: talking requires being near an NPC who is present", function()
		local h = Harness.new()
		local player = h:join(102)
		h:moveTo(player, "Mabel_Bakery")
		T.eq(h:request(player, "talk", { npc = "saffron" }).reason, "tooFar", "far away")
		T.eq(h:request(player, "talk", { npc = "cinderra" }).reason, "absent", "not in chapter 1")
		T.eq(h:request(player, "talk", { npc = "nobody" }).reason, "badNpc", "unknown npc")
		h:moveTo(player, "Saffron_Shop")
		local r = h:request(player, "talk", { npc = "saffron" })
		T.ok(r.ok and r.node.text ~= nil, "close enough")
	end)

	T.test("server: Chapter 1 vertical slice works end to end through requests", function()
		local h = Harness.new()
		local player = h:join(103)
		playChapterOne(h, player)
		T.eq(#h.warnings, 0, "no server warnings: " .. table.concat(h.warnings, " | "))
	end)

	T.test("server: leaving mid-conversation discards it; finishing commits it", function()
		local h = Harness.new()
		local player = h:join(104)
		h:moveTo(player, "Saffron_Shop")
		local r = h:request(player, "talk", { npc = "saffron" })
		while r.node.choices == nil do
			r = h:request(player, "advance")
		end
		h:request(player, "choose", { index = 1 }) -- +trust in the draft
		T.ok(h:request(player, "leaveDialogue").discarded, "discarded")
		T.eq(h:state(player).rel.saffron.trust, 0, "trust unchanged")
		T.eq(h:state(player).quests.q_arrival.s, "active", "still can replay")
	end)

	T.test("server: other actions are refused while a conversation is open", function()
		local h = Harness.new()
		local player = h:join(105)
		h:moveTo(player, "Saffron_Shop")
		h:request(player, "talk", { npc = "saffron" })
		T.eq(h:request(player, "collect", { id = "wildflowers_hill" }).reason, "busy", "collect blocked")
		T.eq(h:request(player, "gift", { npc = "saffron", item = "honey_bun" }).reason, "busy", "gift blocked")
	end)

	T.test("server: malformed and hostile requests fail safely", function()
		local h = Harness.new()
		local player = h:join(106)
		for _, case in ipairs({
			{ 42, {} },
			{ "fly", {} },
			{ "talk", "not a table" },
			{ "talk", { npc = string.rep("x", 1000) } },
			{ "choose", { index = 1 } },
			{ "advance", nil },
			{ "gift", { npc = "saffron", item = "star_chart" } },
			{ "collect", { id = "glowcap_1" } },
			{ "collect", { id = "lost_mitten" } },
			{ "submitActivity", { id = "nope", submission = { 1 } } },
			{ "activityCollect", { id = "nope", index = 1 } },
			{ "startActivity", { activity = "act_rekindle" } },
			{ "setFlag", { flag = "finale_together" } },
			{ "settings", { settings = { music = 1e9, textSpeed = "warp", uiScale = -5 } } },
			{ "newStory", { confirm = "yes" } },
			{ "endingText", { id = "two_flames" } },
		}) do
			local ok, result = pcall(function()
				return h:request(player, case[1], case[2])
			end)
			T.ok(ok, "request threw: " .. tostring(case[1]))
			if case[1] ~= "settings" then
				T.eq(result.ok, false, "should be refused: " .. tostring(case[1]))
			end
		end
		local settings = h:state(player).settings
		T.ok(settings.music <= 1 and settings.uiScale >= 0.8, "settings clamped")
		T.eq(h:state(player).flags.finale_together, nil, "story flag not settable by client")
		for _, w in ipairs(h.warnings) do
			T.ok(not string.find(w, "failed for", 1, true), "handler crashed: " .. w)
		end
	end)

	T.test("server: request spam is rate limited", function()
		local h = Harness.new()
		local player = h:join(107)
		local limited = 0
		for _ = 1, 60 do
			if h:request(player, "ready").reason == "rateLimited" then
				limited += 1
			end
		end
		T.ok(limited > 0, "some requests limited")
		h.advance(5)
		T.ok(h:request(player, "ready").ok, "recovers after a pause")
	end)

	T.test("server: leave and rejoin (even on another server) keeps all progress", function()
		local store = Harness.newStore()
		local a = Harness.new({ store = store, jobId = "server-A" })
		local player = a:join(108)
		playChapterOne(a, player)
		local before = a:state(player)
		a:leave(player)
		T.eq(store.data.player_108.lock, nil, "lock released on leave")
		T.eq(store.data.player_108.state.chapter, 2, "saved chapter")

		local b = Harness.new({ store = store, jobId = "server-B" })
		local again = b:join(108)
		local after = b:state(again)
		T.eq(after.chapter, before.chapter, "chapter")
		T.eq(after.rel.saffron.milestone, "acquaintance", "milestone")
		T.eq(after.rel.saffron.trust, before.rel.saffron.trust, "trust")
		T.eq(after.quests.q_lanternfall.s, "active", "next quest")
		T.eq(store.data.player_108.lock.job, "server-B", "new server holds the lock")
	end)

	T.test("server: a fresh lock from another server is waited on, then taken over", function()
		local store = Harness.newStore()
		store.data.player_109 = { state = { chapter = 3 }, lock = { job = "server-OLD", t = 1000 } }
		local h = Harness.new({ store = store, jobId = "server-NEW" })
		local player = h:join(109)
		T.eq(h:state(player).chapter, 3, "loaded the old server's data")
		T.eq(store.data.player_109.lock.job, "server-NEW", "lock taken over")
		T.ok(h.DataService.get(player).saveEnabled, "saving enabled")
	end)

	T.test("server: a server that lost its lock stops saving instead of overwriting", function()
		local store = Harness.newStore()
		local h = Harness.new({ store = store })
		local player = h:join(110)
		local profile = h.DataService.get(player)
		-- Another server took over and wrote newer progress.
		store.data.player_110.lock = { job = "server-Z", t = h.now }
		store.data.player_110.state = { chapter = 4 }
		h.DataService.markDirty(profile)
		h.run(h.DataService.save, profile, false)
		T.eq(store.data.player_110.state.chapter, 4, "newer progress not overwritten")
		T.eq(profile.saveEnabled, false, "this server stopped saving")
		T.eq(lastStatus(h, player), "disabled", "player told why")
	end)

	T.test("server: if the save can't load, play continues but nothing is overwritten", function()
		local store = Harness.newStore()
		store.data.player_111 = { state = { chapter = 5, flags = { met_saffron = true } } }
		store.failAll = true
		local h = Harness.new({ store = store })
		local player = h:join(111)
		T.ok(h:state(player) ~= nil, "player can still play")
		T.eq(h.DataService.get(player).saveEnabled, false, "saving disabled")
		T.eq(lastStatus(h, player), "disabled", "warning shown")
		store.failAll = false
		h:leave(player)
		T.eq(store.data.player_111.state.chapter, 5, "real save untouched")
	end)

	T.test("server: transient save errors are retried", function()
		local store = Harness.newStore()
		local h = Harness.new({ store = store })
		local player = h:join(112)
		local profile = h.DataService.get(player)
		profile.state.flags.test_marker = true
		h.DataService.markDirty(profile)
		store.failUpdates = 2
		local ok = h.run(h.DataService.save, profile, false)
		T.ok(ok, "saved after retries")
		T.eq(store.data.player_112.state.flags.test_marker, true, "data written")
		T.eq(profile.dirty, false, "clean after save")
	end)

	T.test("server: autosave writes changed profiles in the background", function()
		local h = Harness.new()
		local player = h:join(113)
		local profile = h.DataService.get(player)
		profile.state.flags.autosave_marker = true
		h.DataService.markDirty(profile)
		h.advance(h.ctx.config.AutosaveInterval + 15)
		T.eq(h.store.data.player_113.state.flags.autosave_marker, true, "autosaved")
	end)

	T.test("server: shutdown flush saves everyone and releases locks", function()
		local h = Harness.new()
		local p1, p2 = h:join(114), h:join(115)
		h:state(p1).flags.flush_marker = true
		h:state(p2).flags.flush_marker = true
		h.run(h.game.closeHandlers[1])
		T.eq(h.store.data.player_114.state.flags.flush_marker, true, "p1 saved")
		T.eq(h.store.data.player_115.lock, nil, "p2 lock released")
	end)

	T.test("server: location objectives fire only when the player is actually there", function()
		local h = Harness.new()
		local player = h:join(116)
		local state = h:state(player)
		state.quests.q_old_bridge = { s = "active", step = 2, p = {} }
		h:moveTo(player, "Saffron_Shop")
		h.advance(3)
		T.eq(h:state(player).quests.q_old_bridge.step, 2, "not yet")
		h:moveTo(player, "Bridge_Site")
		h.advance(3)
		T.eq(h:state(player).quests.q_old_bridge.step, 3, "reached the ruins")
	end)

	T.test("server: two players on one server keep fully separate stories", function()
		local h = Harness.new()
		local alice, bob = h:join(201), h:join(202)
		playChapterOne(h, alice)
		T.eq(h:state(bob).chapter, 1, "bob untouched")
		T.eq(h:state(bob).rel.saffron.milestone, "stranger", "bob's relationship untouched")
		local bobSyncs = 0
		for _, record in ipairs(h.fired) do
			if record.name == "StateSync" and record.player == bob then
				bobSyncs += 1
				T.eq(record.args[1].chapter, 1, "bob only ever receives his own chapter-1 state")
			end
		end
		T.eq(bobSyncs, 1, "bob only got the sync from his own load")
	end)
end
