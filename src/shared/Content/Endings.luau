--[[
	Endings
	Explorer: ReplicatedStorage > Hearthscale > Content > Endings (ModuleScript)

	Checked in order when the finale resolves; the last entry must be an
	unconditional fallback. paragraphs: plain strings always show; tables
	show when their `when` passes (lets earlier decisions colour the epilogue).
]]

return {
	{
		id = "strangers_lantern",
		title = "A Stranger's Lantern",
		tone = "bittersweet",
		requires = { flag = "finale_low_trust" },
		onReach = { chapter = 6 },
		paragraphs = {
			"The Hearthflame burns gold above Kettlewick — Cinderra's fire, steady and ancient. The Long Frost will not come this year.",
			"Saffron thanks you for your help with the festival. She means it. She is polite, and kind, and very careful, the way people are with guests.",
			{
				when = { flag = "d1_dismissive" },
				text = "You think about the Old Bridge, and what you said there, and how quickly her tail curled around her ankles afterwards.",
			},
			"Wren's balloon carries you over the mountains at dawn. Behind you, the Keeping House shrinks to a dot, its ledger still open to Item #4112.",
			"Some lanterns take more than one evening to light. (Saffron opens up to people who listen, respect her boundaries, and stay.)",
		},
	},
	{
		id = "long_way_home",
		title = "The Long Way Home",
		tone = "bittersweet",
		requires = { flag = "finale_mother" },
		onReach = { chapter = 6 },
		paragraphs = {
			"Cinderra lights the Hearthflame, and in the morning Saffron flies north with her mother — a real dragon, wings and all, for the first time in eight years.",
			{
				when = { flag = "reconciled" },
				text = "They fly wingtip to wingtip. Mabel swears she saw them bump horns over the ridge, the way dragons do when they've forgiven each other.",
			},
			"She leaves you the keys to the Keeping House, and a note in the ledger: 'Item #4112 — reclassified. Keeper (Acting). Please don't let anyone shelve the umbrellas near the goat.'",
			{
				romance = true,
				when = { path = "romance" },
				text = "Every week, a very large bird, politely on fire, brings you a letter. Each one ends the same way: 'Keep my place. I'm learning the fire properly, and then I'm coming home to you.'",
			},
			{
				when = { path = "friendship" },
				text = "Every week, a very large bird, politely on fire, brings you a letter full of terrible drawings of the Roost. Each one is signed 'Your best friend, the Ninth Flame (in training)'.",
			},
			{
				when = { path = "none" },
				text = "Now and then, a letter arrives, warm to the touch. She is learning. She is well. She hopes the spoons are behaving.",
			},
			"Some fires have to be learned from the beginning. Next Lanternfall, she says, she'll light it herself.",
		},
	},
	{
		id = "two_flames",
		title = "Two Flames",
		tone = "romance",
		romance = true,
		requires = { path = "romance" },
		onReach = { chapter = 6 },
		paragraphs = {
			"The Hearthflame blazes over Kettlewick, and when Saffron finally turns away from it, she's laughing — the kettle-boiling-over laugh Mabel told you about on your very first day.",
			{
				when = { flag = "finale_together" },
				text = "She never lets go of your hand the whole way down the mountain. When you point this out, she says dragons have excellent grip and it would be rude to stop now.",
			},
			{
				when = { flag = "finale_believe" },
				text = "She lit it herself — every spark her own — and then turned and found you in the crowd as if you were the only lantern on the mountain.",
			},
			{
				when = { flag = "reconciled" },
				text = "Cinderra stays for the festival. She tells you, very solemnly, that you are 'adequate', and Saffron explains later that this is dragon for 'welcome to the family'.",
			},
			{
				when = { flag = "d1_honesty" },
				text = "At the festival, Saffron stands on the fountain and tells the whole village about the Old Bridge, and says sorry. Pim cries. Mabel cries. The goat-shaped candle, somehow, also appears to cry.",
			},
			"The ledger gets a new column. It just says your name, with a small, slightly singed heart beside it.",
			"Wren's balloon is finished. It sits in the square with a little bell on it. You both agree it makes an excellent planter.",
		},
	},
	{
		id = "kindred_sparks",
		title = "Kindred Sparks",
		tone = "friendship",
		requires = {},
		onReach = { chapter = 6 },
		paragraphs = {
			"The Hearthflame roars back to life above Kettlewick, and Saffron whoops so loudly that three villages over, a goat looks up.",
			{
				when = { flag = "finale_family" },
				text = "She and Cinderra lit it together: two flames, one gold and one ember-red, braided into a single fire.",
			},
			{
				when = { flag = "rekindle_assisted" },
				text = "Her fire was ragged, and her mother's hand was steady on her shoulder, and it was enough. It was more than enough.",
			},
			{
				when = { flag = "d1_honesty" },
				text = "At the festival she tells the village the truth about the Old Bridge, and apologises. Nobody, it turns out, ever blamed her. Mabel says 'I told you so' eleven times.",
			},
			"At the festival, she presents you with a new mug. It says WORLD'S BEST FRIEND (AND ASSISTANT KEEPER). She found it. She is lying. She had it made.",
			{
				when = { flag = "leaving" },
				text = "When Wren's balloon finally lifts you over the mountains, Saffron runs alongside it until the meadow ends, waving the ledger. Your entry reads: 'Item #4112 — CLAIMED. By a friend.'",
			},
			{
				when = { notFlag = "leaving" },
				text = "You stay. Of course you stay. There are two hundred and six spoons, and somebody has to help her give them back.",
			},
		},
	},
}
