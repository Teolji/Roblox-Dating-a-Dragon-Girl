--[[
	Quests
	Explorer: ReplicatedStorage > Hearthscale > Content > Quests (ModuleScript)

	steps run in order. A step completes when all objectives are done:
	  { id, text, event = "talk:x", count = n }  — counts quest events
	  { id, text, condition = <condition> }      — checks state
	Events come from effects (`event = "..."`), collectibles ("collect:<group>"),
	activities ("activity:<id>") and locations ("reach:<id>").
	hint: what Saffron says when asked "Where should I go next?".
	order: journal sort order (lower = earlier).
]]

return {
	q_arrival = {
		title = "A Rough Landing",
		chapter = 1,
		order = 10,
		summary = "Your balloon came down hard — straight through somebody's roof.",
		steps = {
			{
				id = "meet",
				text = "Find whoever owns the roof you crashed through.",
				hint = "Talk to the tall woman with the horns. She's right here.",
				objectives = {
					{ id = "talk", text = "Talk to the woman at the Keeping House", event = "talk:saffron_meet" },
				},
			},
		},
		rewards = { startQuest = "q_item_4112" },
	},

	q_item_4112 = {
		title = "Item #4112",
		chapter = 1,
		order = 20,
		summary = "Miss Ignavarre has logged you as lost property. Work off the roof to be 'un-filed'.",
		steps = {
			{
				id = "catalogue",
				text = "Help Miss Ignavarre catalogue the hoard.",
				hint = "The sorting table is right beside my counter. Talk to me, or use the table.",
				objectives = {
					{ id = "sort", text = "Sort lost items at the sorting table", event = "activity:act_catalogue" },
				},
			},
			{
				id = "strays",
				text = "Return three lost items to their owners.",
				hint = "Mabel's bakery is north of the square, the Mayor's Hall is east, and Wren's workshop is south-east.",
				onStart = { { give = "rolling_pin" }, { give = "spectacles" }, { give = "lamp_hook" } },
				objectives = {
					{ id = "pin", text = "Return the rolling pin to Mabel (bakery)", event = "return:rolling_pin" },
					{ id = "specs", text = "Return the spectacles to Mayor Pim (Hall)", event = "return:spectacles" },
					{ id = "hook", text = "Return the hook to Wren (workshop)", event = "return:lamp_hook" },
				},
			},
			{
				id = "report",
				text = "Report back to Miss Ignavarre.",
				hint = "Come back to the Keeping House and tell me how it went.",
				objectives = {
					{ id = "talk", text = "Talk to Miss Ignavarre", event = "talk:saffron_report_4112" },
				},
			},
		},
	},

	q_lanternfall = {
		title = "Lanternfall Preparations",
		chapter = 2,
		order = 30,
		summary = "The Hearthflame on Hearthpeak is guttering, and the Lanternfall Festival is days away.",
		steps = {
			{
				id = "notice",
				text = "Mayor Pim is waving frantically at you from the square.",
				hint = "The Mayor is flapping about in the square. You'd better see what he wants.",
				objectives = { { id = "talk", text = "Talk to Mayor Pim in the square", event = "talk:pim_flame" } },
			},
			{
				id = "ask",
				text = "Ask Saffron about the Hearthflame.",
				hint = "You have a question for me. I can tell. You have a question face.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_ask_flame" } },
			},
			{
				id = "glowcaps",
				text = "Gather glowcaps in Glowcap Woods, east of the village.",
				hint = "Glowcap Woods is east of the village. Look for the softly glowing mushrooms.",
				objectives = {
					{ id = "caps", text = "Gather glowcaps", event = "collect:glowcap", count = 5 },
				},
			},
			{
				id = "deliver",
				text = "Bring the glowcaps to Wren at the Lamplighter's Workshop.",
				hint = "Wren's workshop is south-east of the square. Follow the smell of lamp oil.",
				objectives = {
					{ id = "talk", text = "Give Wren the glowcaps", event = "talk:wren_glowcaps" },
				},
			},
		},
	},

	q_pond = {
		title = "An Afternoon Off",
		chapter = 2,
		order = 35,
		summary = "Saffron asked you to meet her at Mirror Pond. She fishes there. For lost things, mostly.",
		steps = {
			{
				id = "fish",
				text = "Fish for lost things with Saffron at Mirror Pond.",
				hint = "Mirror Pond is south of the square. I'll be at the dock.",
				objectives = {
					{ id = "fish", text = "Fish with Saffron", event = "activity:act_fishing" },
				},
			},
			{
				id = "talk",
				text = "Sit with Saffron by the water.",
				hint = "Come sit with me. The tea's cold, but the company isn't.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_pond_talk" } },
			},
		},
	},

	q_old_bridge = {
		title = "The Old Bridge",
		chapter = 2,
		order = 40,
		summary = "Wren told you the Old Bridge burned on the night of Saffron's Warden trial.",
		steps = {
			{
				id = "ask",
				text = "Ask Saffron about the Old Bridge.",
				hint = "You've got your 'Wren told me something' face on. Out with it.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_bridge_invite" } },
			},
			{
				id = "go",
				text = "Meet Saffron at the Old Bridge ruins, north-east beyond the woods.",
				hint = "The ruins are north-east, past Glowcap Woods, where the gorge is.",
				objectives = { { id = "reach", text = "Reach the Old Bridge ruins", event = "reach:old_bridge" } },
			},
			{
				id = "talk",
				text = "Talk to Saffron at the ruins.",
				hint = "I'm here. I'm just... looking at it.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_bridge_story" } },
			},
		},
	},

	q_letter = {
		title = "A Letter Sealed in Wax",
		chapter = 3,
		order = 50,
		summary = "A very large bird, politely on fire, delivered a letter to the Mayor's Hall.",
		steps = {
			{
				id = "pickup",
				text = "Collect a letter for Saffron from Mayor Pim.",
				hint = "Pim's been pacing outside the Hall all morning. Something about a bird.",
				objectives = { { id = "talk", text = "Talk to Mayor Pim", event = "talk:pim_letter" } },
			},
			{
				id = "deliver",
				text = "Deliver the sealed letter to Saffron.",
				hint = "A letter? For me? Nobody writes to me. Bring it here.",
				objectives = { { id = "talk", text = "Give Saffron the letter", event = "talk:saffron_letter" } },
			},
		},
		rewards = { startQuest = "q_lantern_hoard" },
	},

	q_lantern_hoard = {
		title = "The Lantern in the Hoard",
		chapter = 3,
		order = 55,
		summary = "Somewhere in the Keeping House, Saffron buried her mother's Warden lantern. On purpose.",
		steps = {
			{
				id = "search",
				text = "Search the hoard for Saffron's hidden notes.",
				hint = "Back shelves of the Keeping House. My notes are on yellow tags.",
				objectives = {
					{ id = "clues", text = "Find Saffron's notes", event = "collect:hoard_clue", count = 3 },
				},
			},
			{
				id = "find",
				text = "Follow the notes to the Warden's lantern.",
				hint = "If the notes say 'not here', it's not there. Try where the socks live.",
				objectives = {
					{ id = "lantern", text = "Find the lantern", event = "collect:warden_lantern_spot" },
				},
			},
			{
				id = "decide",
				text = "Bring the lantern to Saffron.",
				hint = "You found it? Bring it to me. Slowly. Like it might bite.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_lantern" } },
			},
		},
		rewards = { startQuest = "q_stargazing" },
	},

	q_stargazing = {
		title = "Fireflies on Stargazer Hill",
		chapter = 3,
		order = 60,
		summary = "There's a meteor shower tonight, and Saffron asked you to come stargazing.",
		steps = {
			{
				id = "catch",
				text = "Catch fireflies with Saffron on Stargazer Hill, west of the village.",
				hint = "Stargazer Hill is west of the village. I'll be at the top.",
				objectives = {
					{ id = "fireflies", text = "Catch fireflies", event = "activity:act_fireflies" },
				},
			},
			{
				id = "talk",
				text = "Watch the meteor shower with Saffron.",
				hint = "Come lie in the grass. The meteors are starting.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_stars" } },
			},
		},
	},

	q_cinderra = {
		title = "The Matriarch",
		chapter = 4,
		order = 70,
		summary = "A dragon has landed in the village square.",
		steps = {
			{
				id = "meet",
				text = "Meet the dragon in the village square.",
				hint = "...There's a dragon in the square. Not me. A different dragon. Please go and look.",
				objectives = { { id = "talk", text = "Talk to the visitor", event = "talk:cinderra_meet" } },
			},
			{
				id = "saffron",
				text = "Find Saffron. She's hiding in the Keeping House.",
				hint = "I'm not here. I'm a coat.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_after_mother" } },
			},
		},
		rewards = { startQuest = "q_lanterns" },
	},

	q_lanterns = {
		title = "Lanterns for Lanternfall",
		chapter = 4,
		order = 80,
		summary = "The festival is tomorrow. The lanterns are not painted.",
		steps = {
			{
				id = "craft",
				text = "Paint lantern runes with Saffron in the square.",
				hint = "Lantern tables are in the square. Bring a steady hand.",
				objectives = {
					{ id = "paint", text = "Paint the festival lanterns", event = "activity:act_lanterns" },
				},
			},
			{
				id = "eve",
				text = "Talk with Saffron beneath the lanterns.",
				hint = "Sit with me a minute. There's something I want to ask.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_eve" } },
			},
		},
	},

	q_summit = {
		title = "The Hearthflame",
		chapter = 5,
		order = 90,
		summary = "Lanternfall night. The Hearthflame is down to a single ember.",
		steps = {
			{
				id = "climb",
				text = "Climb the Hearthpeak trail to the summit.",
				hint = "The trail starts north of the square. Up. Keep going up.",
				objectives = { { id = "reach", text = "Reach the summit", event = "reach:summit" } },
			},
			{
				id = "choose",
				text = "Stand with Saffron at the Hearthflame.",
				hint = "I'm here. Please come stand next to me.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_summit" } },
			},
			{
				id = "rekindle",
				text = "Help Saffron rekindle the Hearthflame.",
				hint = "Breathe with me. In, and out.",
				objectives = {
					{
						id = "flame",
						text = "Breathe with Saffron",
						condition = { any = { { activity = "act_rekindle" }, { flag = "finale_no_rekindle" } } },
					},
				},
			},
			{
				id = "after",
				text = "Watch the Hearthflame with Saffron.",
				hint = "Look. Look at it.",
				objectives = { { id = "talk", text = "Talk to Saffron", event = "talk:saffron_finale_after" } },
			},
		},
	},
}
