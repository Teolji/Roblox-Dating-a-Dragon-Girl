--[[
	Story
	Explorer: ReplicatedStorage > Hearthscale > Content > Story (ModuleScript)

	Chapters, new-game setup, story-director rules (one-shot reactions to
	state that move the plot forward), UI labels and journal notes.
]]

return {
	Chapters = {
		{
			id = 1,
			title = "Item #4112",
			summary = "You crash-landed through the roof of the Keeping House and were logged as lost property by its keeper, Saffron Ignavarre.",
			timeOfDay = 14,
		},
		{
			id = 2,
			title = "The Guttering Flame",
			summary = "The Hearthflame that keeps the Long Frost away is failing, and the only fire dragon in Kettlewick insists she isn't one.",
			timeOfDay = 15.5,
		},
		{
			id = 3,
			title = "What the Hoard Remembers",
			summary = "A letter from the Roost, a lantern buried on purpose, and a night of falling stars.",
			timeOfDay = 17,
		},
		{
			id = 4,
			title = "Lanternfall Eve",
			summary = "Saffron's mother has come to rekindle the flame and take her daughter home.",
			timeOfDay = 18.2,
		},
		{
			id = 5,
			title = "The Hearthflame",
			summary = "Lanternfall night. One ember left.",
			timeOfDay = 19.5,
		},
		{
			id = 6,
			title = "Epilogue",
			summary = "After Lanternfall.",
			timeOfDay = 9,
		},
	},

	FestivalCountdown = {
		[1] = "six days",
		[2] = "five days",
		[3] = "three days",
		[4] = "one night",
		[5] = "tonight",
		[6] = "over",
	},

	NewGame = { startQuest = "q_arrival" },

	StoryRules = {
		{
			id = "chapter2",
			when = { quest = { "q_item_4112", "complete" } },
			effects = { chapter = 2, startQuest = "q_lanternfall" },
		},
		{
			id = "old_bridge",
			when = { { quest = { "q_lanternfall", "complete" } }, { quest = { "q_pond", "complete" } } },
			effects = { startQuest = "q_old_bridge" },
		},
		{
			id = "chapter3",
			when = { quest = { "q_old_bridge", "complete" } },
			effects = { chapter = 3, startQuest = "q_letter" },
		},
		{
			id = "chapter4",
			when = { quest = { "q_stargazing", "complete" } },
			effects = { chapter = 4, startQuest = "q_cinderra" },
		},
		{
			id = "chapter5",
			when = { quest = { "q_lanterns", "complete" } },
			effects = { chapter = 5, startQuest = "q_summit" },
		},
	},

	StatLabels = {
		trust = "Trust",
		affinity = "Affinity",
		romance = "Romance",
		resolve = "Her Resolve",
	},

	StatDescriptions = {
		trust = "Does she feel safe and respected with you? Grows when you listen, keep promises and respect her boundaries.",
		affinity = "How much she enjoys your company. Grows through jokes, outings, conversations and thoughtful gifts.",
		romance = "Mutual romantic interest. Only grows once she's open to it — and she decides, too.",
		resolve = "Saffron's courage to face her fire again. Built by how you support her. Makes the finale easier.",
	},

	FlagHints = {
		pond_heart_to_heart = "Share a quiet moment at Mirror Pond",
		heard_full_story = "Hear the story of the Old Bridge",
	},

	-- Journal "What you know about Saffron" entries, unlocked by flags.
	Notes = {
		{
			flag = "met_saffron",
			text = "Runs the Keeping House, Kettlewick's Lost & Found. Very particular about the ledger.",
		},
		{
			flag = "learned_age",
			text = "She's two hundred and nine — twenty-six in dragon years. Doing the maths out loud is rude.",
		},
		{ flag = "learned_shy", text = "Avoids going out. People ask about her horns, and about the Hearthflame." },
		{ flag = "learned_tea", text = "Loves smoked ember tea. Mabel blends it." },
		{
			flag = "learned_lost_things",
			text = "Lights up at lost things. Anything unclaimed is, in her words, 'just waiting'.",
		},
		{ flag = "learned_tail", text = "Her tail and horns are hers. Don't touch without being invited." },
		{ flag = "learned_stars", text = "Loves stargazing — especially the Dragon's Tail constellation." },
		{
			flag = "pond_heart_to_heart",
			text = "Hasn't breathed real fire in eight years. Every time she reaches for it, there's 'a wall'.",
		},
		{
			flag = "heard_full_story",
			text = "Eight years ago her fire burned the Old Bridge during her Warden trial. Nobody was hurt. She never forgave herself.",
		},
		{
			flag = "read_letter",
			text = "Her mother, Cinderra — the Eighth Flame — is coming on Lanternfall Eve to take her home.",
		},
		{
			flag = "found_lantern",
			text = "She kept her mother's Warden lantern for eight years, and polished it every anniversary.",
		},
	},
}
