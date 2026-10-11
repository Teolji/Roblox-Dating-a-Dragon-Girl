--[[
	Activities (shared activities / outings)
	Explorer: ReplicatedStorage > Hearthscale > Content > Activities (ModuleScript)

	kind: sort | sequence | timing | collect (see Systems/Minigames)
	anchor: world spot with a "Begin" prompt (optional; dialogue can also start it)
	when: availability condition
	tiers: ascending score thresholds; `effects` apply on first clear only;
	       `line` is the partner's reaction shown after the game.
	rewards.first: first clear; rewards.again: limited replays (soft-capped).
]]

return {
	act_catalogue = {
		name = "Cataloguing the Hoard",
		description = "Read each lost item's tag and shelve it with Saffron.",
		kind = "sort",
		partner = "saffron",
		anchor = "Sort_Table",
		minDuration = 3,
		when = { any = { { questStep = { "q_item_4112", "catalogue" } }, { activity = "act_catalogue" } } },
		params = {
			count = 8,
			timeLimit = 90,
			shelves = { "Wearables", "Kitchenware", "Curiosities", "Paperwork" },
			pool = {
				{ name = "Left boot (no right boot)", flavor = "Size enormous. Smells of adventure.", shelf = 1 },
				{ name = "Knitted scarf, 3 m long", flavor = "Possibly still being knitted.", shelf = 1 },
				{ name = "Wizard hat, slightly singed", flavor = "Tag: 'NOT MINE. — S.'", shelf = 1 },
				{ name = "Single red mitten", flavor = "The other one is out there. Somewhere.", shelf = 1 },
				{ name = "Copper teapot", flavor = "Whistles when nervous.", shelf = 2 },
				{ name = "Spoon #207", flavor = "Two hundred and seven. Oh no.", shelf = 2 },
				{ name = "Pie tin with a dent", flavor = "Dent is shaped like a goat.", shelf = 2 },
				{ name = "Wooden ladle", flavor = "Has clearly seen things.", shelf = 2 },
				{ name = "Music box that hums off-key", flavor = "Plays one song. Badly. Forever.", shelf = 3 },
				{ name = "Glass eye (marble?)", flavor = "Let's say marble.", shelf = 3 },
				{ name = "Tiny brass dragon", flavor = "Saffron says she has 'no comment'.", shelf = 3 },
				{ name = "Goat-shaped candle", flavor = "Unlit. Judging you.", shelf = 3 },
				{ name = "Overdue library book", flavor = "Due back nine years ago.", shelf = 4 },
				{ name = "Love letter, unsent", flavor = "Sealed. We do NOT read these.", shelf = 4 },
				{ name = "Map of somewhere else", flavor = "Labelled 'HERE BE ME'.", shelf = 4 },
				{ name = "Bakery receipt", flavor = "Forty-one honey buns. One day.", shelf = 4 },
			},
		},
		tiers = {
			{
				min = 0,
				label = "Creative Filing",
				line = { emote = "smug", text = "We'll call that 'creative filing'. The umbrellas are scandalised." },
			},
			{
				min = 5,
				label = "Respectably Tidy",
				line = {
					emote = "happy",
					text = "Respectable! Nothing on fire, nothing in the wrong century. Well done.",
				},
			},
			{
				min = 8,
				label = "Immaculate",
				line = {
					emote = "laugh",
					text = "Immaculate. Every single one. I could hug you. I won't. But I could.",
				},
				effects = { flag = "catalogue_perfect", stat = { "affinity", 2 } },
			},
		},
		rewards = {
			first = { stat = { { "affinity", 3 }, { "trust", 2 } } },
			again = { softStat = { "affinity", 1 } },
		},
	},

	act_fishing = {
		name = "Fishing at Mirror Pond",
		description = "Reel in when the bobber glows. Mostly socks. Sometimes treasure.",
		kind = "timing",
		partner = "saffron",
		anchor = "Pond_Dock",
		minDuration = 2.5,
		when = { any = { { questStep = { "q_pond", "fish" } }, { activity = "act_fishing" } } },
		params = {
			rounds = 5,
			zoneWidth = 0.2,
			minWidth = 0.08,
			maxWidth = 0.4,
			speedMin = 0.45,
			speedMax = 0.85,
			timeLimit = 90,
			prompt = "Tap REEL when the marker is in the glowing zone!",
		},
		tiers = {
			{
				min = 0,
				label = "Soggy Boots",
				line = { emote = "laugh", text = "Two boots and a lily pad! A classic Mirror Pond haul." },
				effects = { give = "river_pebble" },
			},
			{
				min = 3,
				label = "A Fine Haul",
				line = { emote = "happy", text = "A teapot, a pebble and somebody's spectacles. Excellent work." },
				effects = { give = "river_pebble" },
			},
			{
				min = 5,
				label = "Legendary Catch",
				line = {
					emote = "surprised",
					text = "Is that — you caught the GOAT-SHAPED KETTLE. It's been down there for a century. You're a legend.",
				},
				effects = { give = "river_pebble", flag = "caught_goat_kettle", stat = { "affinity", 2 } },
			},
		},
		rewards = {
			first = { stat = { { "affinity", 4 }, { "trust", 2 } } },
			again = { softStat = { "affinity", 1 } },
		},
	},

	act_fireflies = {
		name = "Firefly Catching",
		description = "Catch drifting fireflies on Stargazer Hill before the meteor shower starts.",
		kind = "collect",
		partner = "saffron",
		anchor = "Hill_Meadow",
		minDuration = 4,
		when = { any = { { questStep = { "q_stargazing", "catch" } }, { activity = "act_fireflies" } } },
		params = {
			count = 8,
			timeLimit = 90,
			label = "Fireflies",
			points = {
				"Firefly_1",
				"Firefly_2",
				"Firefly_3",
				"Firefly_4",
				"Firefly_5",
				"Firefly_6",
				"Firefly_7",
				"Firefly_8",
				"Firefly_9",
				"Firefly_10",
				"Firefly_11",
				"Firefly_12",
			},
		},
		tiers = {
			{
				min = 0,
				label = "A Few Sparks",
				line = { emote = "happy", text = "A few! That's plenty. They're employees, not prisoners." },
			},
			{
				min = 5,
				label = "A Jar of Stars",
				line = { emote = "happy", text = "Look at them all. It's like holding a little sky." },
			},
			{
				min = 8,
				label = "Firefly Whisperer",
				line = { emote = "tender", text = "Every one of them. They like you. ...I can see why." },
				effects = { flag = "fireflies_perfect", stat = { "affinity", 2 } },
			},
		},
		rewards = {
			first = { stat = { { "affinity", 4 }, { "trust", 1 } } },
			again = { softStat = { "affinity", 1 } },
		},
	},

	act_lanterns = {
		name = "Painting Festival Lanterns",
		description = "Saffron paints a rune pattern; copy it before the paint dries.",
		kind = "sequence",
		partner = "saffron",
		anchor = "Lantern_Table",
		minDuration = 8,
		when = { any = { { questStep = { "q_lanterns", "craft" } }, { activity = "act_lanterns" } } },
		params = {
			symbols = { "Ember", "Leaf", "Star", "Wave" },
			rounds = 4,
			startLength = 3,
			growth = 1,
			timeLimit = 150,
		},
		tiers = {
			{
				min = 0,
				label = "Abstract Art",
				line = { emote = "laugh", text = "That lantern now says 'soup' in Old Draconic. I love it. It stays." },
			},
			{
				min = 2,
				label = "Festival Ready",
				line = { emote = "happy", text = "Lovely work. Those will glow beautifully tomorrow." },
			},
			{
				min = 4,
				label = "Master Lanternwright",
				line = {
					emote = "happy",
					text = "Perfect runes! My mother would — well. She'd say 'adequate', which is dragon for 'perfect'.",
				},
				effects = { flag = "lanterns_perfect", stat = { "affinity", 2 } },
			},
		},
		rewards = {
			first = { stat = { { "affinity", 3 }, { "trust", 2 } } },
			again = { softStat = { "affinity", 1 } },
		},
	},

	act_rekindle = {
		name = "Rekindling the Hearthflame",
		description = "Breathe with Saffron. Push when the ember glows.",
		kind = "timing",
		partner = "saffron",
		minDuration = 2.5,
		-- Each point of Saffron's resolve (earned through earlier choices) widens the zone.
		resolveWidthBonus = 0.02,
		when = { questStep = { "q_summit", "rekindle" } },
		params = {
			rounds = 5,
			zoneWidth = 0.12,
			minWidth = 0.08,
			maxWidth = 0.4,
			speedMin = 0.5,
			speedMax = 0.9,
			timeLimit = 120,
			prompt = "Tap BREATHE when the ember glows — together with Saffron.",
		},
		tiers = {
			{ min = 0, label = "Embers", effects = { flag = "rekindle_low" } },
			{ min = 3, label = "Steady Flame", effects = { flag = "rekindle_mid" } },
			{ min = 5, label = "Blazing Hearth", effects = { flag = "rekindle_high" } },
		},
		rewards = { first = { stat = { "resolve", 1 } } },
	},
}
