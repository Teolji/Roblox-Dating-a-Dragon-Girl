--[[
	Characters
	Explorer: ReplicatedStorage > Hearthscale > Content > Characters (ModuleScript)

	stations: first entry whose `when` passes decides where the NPC stands for
	that player (anchor name), or `hidden = true` to remove them.
	rig: colours/proportions for the procedural PLACEHOLDER figure used until
	a real model exists at ReplicatedStorage.HearthscaleAssets.NPCs.<id>.
	gifts: preferences (only characters with `gifts` accept presents).
]]

return {
	saffron = {
		name = "Saffron",
		fullName = "Saffron Ignavarre",
		title = "Keeper of Lost Things",
		relationship = true,
		color = "#E07A3A",
		bio = "A fire dragon of two hundred and nine (twenty-six, in dragon years) who runs Kettlewick's Lost & Found in humanoid form. Proud, dramatic, secretly anxious. Hoards lost things so nothing else gets lost. Hasn't breathed real fire in eight years.",
		rig = {
			kind = "dragon",
			height = 1.12,
			skin = "#F1C7A1",
			scales = "#C9512F",
			hair = "#7B2D1E",
			horns = "#EBC57D",
			outfit = "#3F5E78",
			accent = "#E9B44C",
			eyes = "#F2A51A",
			tail = 4,
			hornStyle = "curl",
			spectacles = true,
		},
		stations = {
			{ when = { ending = "long_way_home" }, hidden = true },
			{ when = { anyEnding = true }, anchor = "Saffron_Shop" },
			{ when = { quest = { "q_summit", "active" } }, anchor = "Saffron_Summit" },
			{ when = { quest = { "q_lanterns", "active" } }, anchor = "Saffron_Square" },
			{ when = { quest = { "q_stargazing", "active" } }, anchor = "Saffron_Hill" },
			{
				when = {
					any = {
						{ questStep = { "q_old_bridge", "go" } },
						{ questStep = { "q_old_bridge", "talk" } },
					},
				},
				anchor = "Saffron_Bridge",
			},
			{ when = { quest = { "q_pond", "active" } }, anchor = "Saffron_Pond" },
			{ anchor = "Saffron_Shop" },
		},
		gifts = {
			minMilestone = "acquaintance",
			tiers = {
				smoked_ember_tea = "loved",
				lost_mitten = "loved",
				star_chart = "loved",
				honey_bun = "liked",
				glowcap = "liked",
				river_pebble = "liked",
				wildflowers = "neutral",
				frostbloom = "disliked",
				fire_starter = "hated",
			},
			values = {
				loved = { affinity = 6, trust = 2 },
				liked = { affinity = 3 },
				neutral = { affinity = 1 },
				disliked = { affinity = -2 },
				hated = { affinity = -3, trust = -4 },
			},
			reactions = {
				smoked_ember_tea = {
					first = {
						emote = "happy",
						text = "Smoked ember tea. Do you have any idea— no, you clearly DO have an idea, that's the problem. Thank you. I'm brewing this immediately. Cold. Don't comment.",
					},
					again = { emote = "happy", text = "More ember tea! You're enabling me, and I'm allowing it." },
				},
				lost_mitten = {
					first = {
						emote = "happy",
						text = "A LOST ITEM. Unpaired, weathered, deeply loved by somebody. Item four thousand one hundred and thirteen. Oh, I'm so happy. Look at my tail. Don't look at my tail.",
					},
					again = { emote = "happy", text = "Another lost thing! You're a natural Keeper." },
				},
				star_chart = {
					first = {
						emote = "tender",
						text = "The Dragon's Tail. My mother used to trace it on the ceiling of the roost with one claw. ...Thank you. Really.",
					},
					effects = { stat = { "resolve", 1 }, flag = "gift_star_chart" },
				},
				honey_bun = {
					first = {
						emote = "happy",
						text = "A honey bun. Mabel's? Of course it's Mabel's. Nobody else bakes with that much confidence.",
					},
				},
				glowcap = {
					first = {
						emote = "happy",
						text = "A glowcap! A nightlight AND a snack. Very practical gift. I respect it.",
					},
				},
				river_pebble = {
					first = {
						emote = "smug",
						text = "Smooth. Cool. Perfectly unremarkable. I'm keeping it forever, obviously.",
					},
				},
				wildflowers = {
					first = {
						emote = "smug",
						text = "Flowers. Lovely. They'll be ash by Tuesday — I run warm. But it's the thought, and the thought is nice.",
					},
				},
				frostbloom = {
					first = {
						emote = "annoyed",
						text = "Why is it COLD. Why would you hand a fire dragon something COLD. It's like handing a fish a hairdryer.",
					},
					again = { emote = "annoyed", text = "Another one?! Are you trying to start a winter in my hands?" },
				},
				fire_starter = {
					first = {
						emote = "sad",
						text = "Is this... a joke? About my flame? ...I'm going to put it somewhere I don't have to look at it.",
					},
					again = { emote = "sad", text = "Again. Okay. Message received, I suppose." },
				},
			},
			defaults = {
				loved = { emote = "happy", text = "Oh! This is perfect. How did you know?" },
				liked = { emote = "happy", text = "For me? That's very kind. Thank you." },
				likedAgain = { emote = "smug", text = "Another one! I'm sensing a theme. I approve of the theme." },
				neutral = { emote = "neutral", text = "Ah. Thank you. I'll find it a shelf." },
				disliked = { emote = "annoyed", text = "...I'll pretend you didn't mean that." },
				hated = { emote = "sad", text = "I'd rather you hadn't." },
				tooMany = {
					emote = "smug",
					text = "Another one? I'm starting a collection. Which, admittedly, is my entire personality. Maybe surprise me next time?",
				},
			},
			refusals = {
				tooSoon = {
					emote = "smug",
					text = "You're inventory. Inventory doesn't give gifts. Ask me again once you've been un-filed.",
				},
				notReady = {
					emote = "smug",
					text = "You just gave me something! Let's go have an adventure first — gifts are nicer when there's a story behind them.",
				},
			},
		},
	},

	mabel = {
		name = "Mabel",
		fullName = "Mabel Crumb",
		title = "Baker",
		color = "#D9A35B",
		bio = "Runs Crumb's Bakery. Saffron's oldest friend in Kettlewick and the village's most reliable source of gossip and honey buns.",
		rig = {
			kind = "human",
			height = 0.92,
			skin = "#8D5A3B",
			hair = "#2B1A12",
			outfit = "#C96F5A",
			accent = "#F4EBDD",
			eyes = "#3B2414",
			apron = true,
		},
		stations = { { anchor = "Mabel_Bakery" } },
	},

	pim = {
		name = "Mayor Pim",
		fullName = "Pimsworth Thistlewhite",
		title = "Mayor of Kettlewick",
		color = "#7E9C5B",
		bio = "Kettlewick's anxious, well-meaning mayor. Organiser of the Lanternfall Festival. Owner of a very tall hat.",
		rig = {
			kind = "human",
			height = 0.85,
			skin = "#F0C8A8",
			hair = "#C9C3B8",
			outfit = "#4E6B3A",
			accent = "#D4AF37",
			eyes = "#4A6FA5",
			topHat = true,
		},
		stations = {
			{ when = { chapter = 2 }, anchor = "Pim_Square" },
			{ anchor = "Pim_Hall" },
		},
	},

	wren = {
		name = "Wren",
		fullName = "Wren Hollis",
		title = "Apprentice Lamplighter",
		color = "#5B8FB9",
		bio = "Kettlewick's young-adult apprentice lamplighter and self-taught tinkerer. Fixes things. Has never fixed a balloon. Is fixing your balloon.",
		rig = {
			kind = "human",
			height = 1.0,
			skin = "#D6A27A",
			hair = "#3A6EA5",
			outfit = "#6B4F3A",
			accent = "#B8C4CC",
			eyes = "#2E4A3D",
			goggles = true,
		},
		stations = { { anchor = "Wren_Workshop" } },
	},

	cinderra = {
		name = "Cinderra",
		fullName = "Cinderra Ignavarre",
		title = "The Eighth Flame",
		color = "#9E3B2A",
		bio = "Saffron's mother and the previous Warden of the Hearthflame. Stern, ancient and far kinder than she knows how to show.",
		rig = {
			kind = "dragon",
			height = 1.22,
			skin = "#E3B994",
			scales = "#5E2A22",
			hair = "#B9B4AE",
			horns = "#2E2522",
			outfit = "#2F2A3A",
			accent = "#C47A2C",
			eyes = "#F2A51A",
			tail = 5,
			hornStyle = "sweep",
			cloak = true,
		},
		stations = {
			{ when = { chapterMax = 3 }, hidden = true },
			{ when = { ending = "long_way_home" }, hidden = true },
			{ when = { quest = { "q_summit", "active" } }, anchor = "Cinderra_Summit" },
			{ anchor = "Cinderra_Square" },
		},
	},
}
