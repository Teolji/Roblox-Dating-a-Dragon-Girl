--[[
	Supporting cast: Mabel (baker), Mayor Pim, Wren (lamplighter), Cinderra
	Explorer: ReplicatedStorage > Hearthscale > Content > Dialogue > Villagers
]]

local function bun(chapter: number)
	return {
		text = "Could I have a honey bun?",
		once = "bun_ch" .. chapter,
		when = { chapter = chapter },
		effects = { give = "honey_bun" },
		next = "bun",
	}
end

return {
	-- MABEL ---------------------------------------------------------------------
	mabel_return_pin = {
		npc = "mabel",
		priority = 900,
		when = { questStep = { "q_item_4112", "strays" }, item = "rolling_pin" },
		start = "a1",
		nodes = {
			a1 = {
				emote = "surprised",
				text = "My rolling pin! I'd know that dent anywhere — that's from the Great Scone Dispute.",
				effects = { take = "rolling_pin" },
				next = "a2",
			},
			a2 = {
				emote = "thoughtful",
				text = "Saffron sent you? She usually returns things with a note under the door. Little drawings. Very formal.",
				next = "a3",
			},
			a3 = {
				emote = "sad",
				text = "She hasn't laughed properly in years, you know. Not since... well. Not my story to tell. But she used to laugh like a kettle boiling over.",
				choices = {
					{ text = "I'll see what I can do.", tag = "kind", next = "b1" },
					{ text = "Like a kettle? That's adorable.", tag = "joke", next = "b1" },
				},
			},
			b1 = {
				emote = "happy",
				text = "Here — a honey bun for your trouble. Saffron likes them, though she'll claim it's 'professional interest'.",
				effects = { give = "honey_bun" },
			},
		},
		onEnd = { event = "return:rolling_pin" },
	},

	mabel_hub = {
		npc = "mabel",
		priority = 0,
		repeatable = true,
		start = "a0",
		nodes = {
			a0 = { branch = { { when = { anyEnding = true }, next = "epi" }, { next = "menu" } } },
			menu = {
				emote = "happy",
				text = "Welcome to Crumb's! Everything's fresh except the gossip, which is vintage.",
				choices = {
					bun(1),
					bun(2),
					bun(3),
					bun(4),
					bun(5),
					{
						text = "What does Saffron like? I'd like to bring her something.",
						once = "mabel_likes",
						tag = "kind",
						when = { milestone = "acquaintance" },
						next = "likes",
					},
					{ text = "How long have you known Saffron?", once = "mabel_known", tag = "curious", next = "known" },
					{ text = "Any gossip?", next = "gossip" },
					{ text = "Goodbye." },
				},
			},
			bun = { emote = "happy", text = "Fresh from the oven! Mind the honey, it's ambitious today.", next = "menu" },
			likes = {
				emote = "smug",
				text = "Smoked ember tea, my special blend. She'd sell her own horns for it. Here — take a tin. Tell her it's from you. I won't tell her it's from me.",
				effects = { give = "smoked_ember_tea", flag = "learned_tea" },
				next = "likes2",
			},
			likes2 = {
				emote = "thoughtful",
				text = "And she goes misty over lost things. Odd socks. Single mittens. Anything waiting to be found. Don't bring her anything cold, mind. She'll sulk for a week.",
				next = "menu",
			},
			known = {
				emote = "thoughtful",
				text = "Eight years. She walked into my bakery the morning after the Old Bridge burned, arms full of things people had dropped, and asked if I'd seen who they belonged to. Didn't say a word about the fire. Just wanted to give things back.",
				next = "menu",
			},
			gossip = {
				branch = {
					{ when = { chapter = 1 }, next = "g1" },
					{ when = { chapter = 2 }, next = "g2" },
					{ when = { chapter = 3 }, next = "g3" },
					{ when = { chapter = 4 }, next = "g4" },
					{ next = "g5" },
				},
			},
			g1 = {
				emote = "smug",
				text = "The Mayor's been practising his festival speech on the ducks. The ducks have notes.",
				next = "menu",
			},
			g2 = {
				emote = "smug",
				text = "Wren's been up all night fixing your balloon. Don't tell them I told you — it's meant to be a surprise. It is not going to be a surprise. It's enormous.",
				next = "menu",
			},
			g3 = {
				emote = "surprised",
				text = "A bird landed on the Hall roof this morning. On fire! Politely on fire. Pim screamed for eleven minutes. I timed it.",
				next = "menu",
			},
			g4 = {
				emote = "surprised",
				text = "There's a DRAGON in the square. A proper one. She bought four loaves and said 'thank you' like a thunderclap. I think I'm in love. With the bread order.",
				next = "menu",
			},
			g5 = {
				emote = "determined",
				text = "Gossip? Tonight? Go on, get up that mountain. I'll have honey buns waiting when you come down.",
				next = "menu",
			},
			epi = {
				branch = {
					{ when = { ending = "two_flames" }, next = "e_tf" },
					{ when = { ending = "kindred_sparks" }, next = "e_ks" },
					{ when = { ending = "long_way_home" }, next = "e_lw" },
					{ next = "e_sl" },
				},
			},
			e_tf = {
				emote = "laugh",
				text = "She LAUGHED. In my shop. Like a kettle boiling over. I had to sit down. I'm still sitting down, inside, emotionally. Look after her.",
			},
			e_ks = {
				emote = "happy",
				text = "Best friends, is it? About time somebody got past the umbrellas. Honey bun? On the house. Forever.",
			},
			e_lw = {
				emote = "sad",
				text = "Shop's quiet without her. But you're keeping it lovely, Acting Keeper. She'll be back. They always come back for the honey buns.",
			},
			e_sl = {
				emote = "neutral",
				text = "Off already? Safe travels, love. Here's a bun for the road.",
			},
		},
	},

	-- PIM -----------------------------------------------------------------------
	pim_return_specs = {
		npc = "pim",
		priority = 900,
		when = { questStep = { "q_item_4112", "strays" }, item = "spectacles" },
		start = "a1",
		nodes = {
			a1 = {
				emote = "surprised",
				text = "Who's there? Is that the roof person? I can make out a roof-person-shaped blur.",
				next = "a2",
			},
			a2 = {
				emote = "happy",
				text = "My spectacles! Ah. Clarity. Glorious clarity. You look exactly as alarming as I imagined.",
				effects = { take = "spectacles" },
				next = "a3",
			},
			a3 = {
				emote = "thoughtful",
				text = "Miss Ignavarre sent you? Bless her. Wonderful at returning things. Less wonderful at returning herself to society, but who among us.",
				next = "a4",
			},
			a4 = {
				emote = "sad",
				text = "Between us — keep an eye on the peak, would you? The Hearthflame's looking a bit peaky. Peaky! Ha. Festival humour. I'm very stressed.",
			},
		},
		onEnd = { event = "return:spectacles" },
	},

	pim_flame = {
		npc = "pim",
		priority = 900,
		when = { questStep = { "q_lanternfall", "notice" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "surprised",
				text = "You! Roof person! Assistant-Keeper-whatever! Come here, come here — LOOK at the peak!",
				next = "a2",
			},
			a2 = {
				speaker = "narrator",
				emote = "sad",
				text = "Far above the village, the Hearthflame flickers on the summit of Hearthpeak — small and orange, like a candle somebody forgot.",
				next = "a3",
			},
			a3 = {
				emote = "sad",
				text = "The Hearthflame keeps the Long Frost off Kettlewick. Every autumn a Warden rekindles it on Lanternfall night. Lanternfall is in {festival}. We do not have a Warden.",
				next = "a4",
			},
			a4 = {
				emote = "thoughtful",
				text = "What we DO have is a very tall woman with horns, a tail and a lifelong passion for hats, who runs the Lost & Found and is absolutely, definitely not a dragon.",
				choices = {
					{ text = "Everybody knows she's a dragon, don't they?", tag = "joke", next = "b1" },
					{ text = "Why don't you ask her yourself?", tag = "curious", next = "b2" },
				},
			},
			b1 = {
				emote = "smug",
				text = "Everybody knows. She doesn't know that we know. It's a delicate civic ecosystem.",
				next = "b2",
			},
			b2 = {
				emote = "sad",
				text = "I tried, years ago. She went very quiet and the smoke alarm in the Hall went off. I think she'd listen to you. You fell out of the sky — you're practically an omen.",
				next = "b3",
			},
			b3 = {
				emote = "determined",
				text = "Please. Just ask her about the flame. Gently. I'll put you in charge of festival lanterns! Very prestigious position. Nobody else wanted it.",
			},
		},
		onEnd = { event = "talk:pim_flame" },
	},

	pim_letter = {
		npc = "pim",
		priority = 900,
		when = { questStep = { "q_letter", "pickup" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "surprised",
				text = "Oh good, it's you. This arrived for Miss Ignavarre by — and I want to be very clear — an extremely large bird. The bird was on fire. Politely.",
				next = "a2",
			},
			a2 = {
				emote = "thoughtful",
				text = "I have not opened it. I held it up to a window. It appears to be written in a language consisting entirely of the word 'disappointed'.",
				choices = {
					{ text = "I'll take it to her.", tag = "kind", next = "b1" },
					{ text = "Pim! Don't read her post.", tag = "respect", next = "b2" },
				},
			},
			b1 = { emote = "happy", text = "Splendid. Do mind the seal. It's warm. Why is it warm?", effects = { give = "sealed_letter" } },
			b2 = {
				emote = "flustered",
				text = "I didn't READ it! I squinted at it supportively. Here — take it before I squint again.",
				effects = { give = "sealed_letter" },
			},
		},
		onEnd = { event = "talk:pim_letter" },
	},

	pim_hub = {
		npc = "pim",
		priority = 0,
		repeatable = true,
		start = "a0",
		nodes = {
			a0 = {
				branch = {
					{ when = { anyEnding = true }, next = "epi" },
					{ when = { chapter = 1 }, next = "c1" },
					{ when = { chapter = 2 }, next = "c2" },
					{ when = { chapter = 3 }, next = "c3" },
					{ when = { chapter = 4 }, next = "c4" },
					{ next = "c5" },
				},
			},
			c1 = {
				emote = "happy",
				text = "Welcome to Kettlewick! Population: two hundred and twelve, plus one roof-related incident.",
				choices = { { text = "Goodbye." } },
			},
			c2 = {
				emote = "thoughtful",
				text = "Glowcaps, lanterns, bunting, Hearthflame. My list has a list. How are the preparations?",
				choices = {
					{ text = "Anything I can carry for Saffron?", once = "pim_firestarter", tag = "kind", next = "fs1" },
					{ text = "Goodbye." },
				},
			},
			fs1 = {
				emote = "happy",
				text = "Funny you should ask! I bought her a fire starter kit. Flint, steel, tinder — for her, ahem, little problem. Very thoughtful, I think. Very civic.",
				choices = {
					{
						text = "Pim... I don't think she'd see it that way.",
						tag = "respect",
						effects = { give = "fire_starter" },
						next = "fs2",
					},
					{ text = "I'll pass it along.", effects = { give = "fire_starter" }, next = "fs3" },
				},
			},
			fs2 = {
				emote = "sad",
				text = "No? Oh. Oh dear. Well — take it anyway, I've no use for it. Perhaps for a campfire. A normal campfire. Not a metaphorical one.",
			},
			fs3 = { emote = "happy", text = "Wonderful! Civic gift-giving. Nothing could possibly go wrong." },
			c3 = {
				emote = "thoughtful",
				text = "I've drafted a contingency plan for the Long Frost. It's mostly scarves. Twelve pages of scarves.",
				choices = { { text = "Goodbye." } },
			},
			c4 = {
				emote = "flustered",
				text = "There is a DRAGON in my square. She asked for a 'perch'. I gave her a bench. We are both coping.",
				choices = { { text = "Goodbye." } },
			},
			c5 = {
				emote = "determined",
				text = "The whole village will be watching the peak tonight. No pressure. Enormous pressure, actually. Good luck!",
				choices = { { text = "Goodbye." } },
			},
			epi = {
				branch = {
					{ when = { ending = "strangers_lantern" }, next = "e_sl" },
					{ next = "e_ok" },
				},
			},
			e_ok = {
				emote = "happy",
				text = "Best Lanternfall in eight years! I've decided to give a speech about it. Annually. The ducks are thrilled.",
			},
			e_sl = {
				emote = "happy",
				text = "The flame's lit, the frost's away, and nobody set the bunting on fire. A triumph! Safe travels, roof person.",
			},
		},
	},

	-- WREN ----------------------------------------------------------------------
	wren_return_hook = {
		npc = "wren",
		priority = 900,
		when = { questStep = { "q_item_4112", "strays" }, item = "lamp_hook" },
		start = "a1",
		nodes = {
			a1 = {
				emote = "happy",
				text = "My hook! I've been lighting the high lanterns with a broom. You don't want to know what the broom thinks of me now.",
				effects = { take = "lamp_hook" },
				next = "a2",
			},
			a2 = {
				emote = "surprised",
				text = "Wait — you're the balloon person! I saw you come down. WHOOSH, crunch. Ten out of ten. Do you want it fixed? I've never fixed a balloon. I've fixed a LOT of things that weren't balloons.",
				choices = {
					{ text = "Yes, please! That'd be amazing.", tag = "kind", effects = { flag = "balloon_repair" }, next = "a3" },
					{ text = "No rush. I'm not going anywhere just yet.", tag = "friend", effects = { flag = "balloon_repair" }, next = "a3" },
				},
			},
			a3 = {
				emote = "thoughtful",
				text = "Also — is it true Miss Ignavarre's a dragon? Can she breathe fire? Does her tail get cold?",
				choices = {
					{ text = "That's her business to share.", tag = "respect", effects = { flag = "wren_respect" }, next = "b1" },
					{ text = "Ask her yourself!", tag = "joke", next = "b2" },
				},
			},
			b1 = { emote = "thoughtful", text = "Fair. Very fair. I'll stop asking. ...I won't stop wondering." },
			b2 = { emote = "laugh", text = "I did! In July! She said 'never' and walked into a cupboard." },
		},
		onEnd = { event = "return:lamp_hook" },
	},

	wren_glowcaps = {
		npc = "wren",
		priority = 900,
		when = { questStep = { "q_lanternfall", "deliver" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "happy",
				text = "Glowcaps! Perfect — these'll keep the festival lanterns glowing all night.",
				effects = { take = { "glowcap", 5 } },
				next = "a2",
			},
			a2 = {
				emote = "thoughtful",
				text = "Hey... did Miss Ignavarre say anything? About lighting the Hearthflame?",
				choices = {
					{ text = "She said she can't.", tag = "honest", next = "b1" },
					{ text = "That's between her and me.", tag = "respect", next = "b1" },
				},
			},
			b1 = {
				emote = "sad",
				text = "I was little when the Old Bridge burned — up past the woods, north-east, over the gorge. It was the night of her Warden trial. Everyone saw the fire. Nobody really talks about it.",
				effects = { flag = "heard_bridge" },
				next = "b2",
			},
			b2 = {
				emote = "tender",
				text = "My mum says Miss Ignavarre came down the mountain the next morning with her arms full of things people dropped. Gave every single one back. With a note.",
				choices = { { text = "That sounds like her.", tag = "kind" } },
			},
		},
		onEnd = { event = "talk:wren_glowcaps" },
	},

	wren_hub = {
		npc = "wren",
		priority = 0,
		repeatable = true,
		start = "a0",
		nodes = {
			a0 = {
				branch = {
					{ when = { anyEnding = true }, next = "epi" },
					{ when = { chapter = 1 }, next = "c1" },
					{ when = { chapter = 2 }, next = "c2" },
					{ when = { chapter = 3 }, next = "c3" },
					{ next = "c4" },
				},
			},
			c1 = {
				emote = "happy",
				text = "Measuring your balloon! It's very holey. Not in a religious way. In a hole way.",
				next = "menu",
			},
			c2 = {
				emote = "happy",
				text = "Patched the envelope! The basket is... a work in progress. Currently it's a sculpture.",
				next = "menu",
			},
			c3 = {
				emote = "happy",
				text = "Balloon's nearly ready. I put a little bell on it. Was that okay? It's okay. It goes 'ting'.",
				next = "menu",
			},
			c4 = {
				emote = "thoughtful",
				text = "Balloon's done! Whenever you want to go. ...Do you want to go?",
				next = "menu",
			},
			menu = {
				emote = "neutral",
				text = "Anything else?",
				choices = {
					{
						text = "Do you have anything about stars? Saffron loves them.",
						once = "wren_star_chart",
						tag = "kind",
						when = { flag = "learned_stars" },
						effects = { give = "star_chart" },
						next = "sc",
					},
					{ text = "What's a lamplighter actually do?", once = "wren_job", tag = "curious", next = "job" },
					{ text = "Goodbye." },
				},
			},
			sc = {
				emote = "happy",
				text = "I inked this star chart last winter — the Dragon's Tail is circled. Take it! It'd make me very happy to know where it went.",
				next = "menu",
			},
			job = {
				emote = "happy",
				text = "Lights lanterns, fixes lanterns, argues with lanterns. Someday I want to tend the Hearthflame itself. Well — help the Warden tend it. Whoever that turns out to be.",
				next = "menu",
			},
			epi = {
				branch = {
					{ when = { ending = "long_way_home" }, next = "e_lw" },
					{ when = { ending = "strangers_lantern" }, next = "e_sl" },
					{ next = "e_ok" },
				},
			},
			e_ok = {
				emote = "laugh",
				text = "She lit it! I SAW it! Fire! Real dragon fire! I'm going to be insufferable about this for years.",
			},
			e_lw = {
				emote = "tender",
				text = "I'm keeping the Keeping House lanterns lit until she's back. Every single night. That's a lamplighter promise.",
			},
			e_sl = {
				emote = "happy",
				text = "Your balloon's ready! The bell goes 'ting'. Safe skies, balloon person.",
			},
		},
	},

	-- CINDERRA ------------------------------------------------------------------
	cinderra_meet = {
		npc = "cinderra",
		priority = 900,
		when = { questStep = { "q_cinderra", "meet" } },
		start = "a0",
		nodes = {
			a0 = {
				speaker = "narrator",
				emote = "neutral",
				text = "A dragon has landed in the village square — wings, scales like banked coals, the lot. Then she folds herself smaller and smaller, into a tall, grey-haired woman with enormous horns and a travelling cloak.",
				next = "a1",
			},
			a1 = {
				emote = "neutral",
				text = "You smell of my daughter's shop. Smoke, paper and far too many spoons. You must be the one who fell through her roof.",
				next = "a2",
			},
			a2 = {
				emote = "determined",
				text = "I am Cinderra Ignavarre, the Eighth Flame. Where is Saffron?",
				choices = {
					{
						text = "At the Keeping House. She's... not ready to see you yet.",
						tag = "honest",
						effects = { flag = "told_cinderra_truth" },
						next = "b1",
					},
					{
						text = "She's busy. And she's not going anywhere she doesn't want to go.",
						tag = "respect",
						effects = { flag = "defended_saffron", stat = { "trust", 2 } },
						next = "b2",
					},
					{
						text = "Before I answer — why did you wait eight years to write?",
						tag = "honest",
						effects = { flag = "questioned_cinderra" },
						next = "b3",
					},
				},
			},
			b1 = { emote = "thoughtful", text = "Not ready. She was not ready eight years ago either. It seems some things keep.", next = "c1" },
			b2 = {
				emote = "smug",
				text = "Protective. Good. She needs someone who will stand in a doorway for her. It was never going to be me.",
				next = "c1",
			},
			b3 = {
				emote = "sad",
				text = "...Because I told her she was not ready, and then I waited for her to prove me wrong. Dragons are very patient. It is not always a virtue.",
				next = "c1",
			},
			c1 = {
				emote = "determined",
				text = "Tomorrow is Lanternfall. I will rekindle the Hearthflame, as is my duty. Then she will come home. Tell her I am here. Tell her... I brought her blanket. She will know which one.",
			},
		},
		onEnd = { event = "talk:cinderra_meet" },
	},

	cinderra_hub = {
		npc = "cinderra",
		priority = 0,
		repeatable = true,
		start = "a0",
		nodes = {
			a0 = { branch = { { when = { anyEnding = true }, next = "epi" }, { next = "menu" } } },
			menu = {
				emote = "neutral",
				text = "Speak. Briefly. I am conserving my fire.",
				choices = {
					{
						text = "What was Saffron like as a hatchling?",
						once = "cin_hatchling",
						tag = "curious",
						next = "h1",
					},
					{ text = "Why do you want her to come home?", once = "cin_why", tag = "honest", next = "w1" },
					{ text = "Goodbye." },
				},
			},
			h1 = {
				emote = "tender",
				text = "Loud. She set fire to her own birthday cake out of sheer excitement. Every year. For forty years. I stopped baking cakes. I started baking bricks. She set fire to those too.",
				next = "menu",
			},
			w1 = {
				emote = "sad",
				text = "Because I do not know how to tell her I miss her, and 'come home' is shorter. Do not repeat that.",
				next = "menu",
			},
			epi = {
				branch = {
					{ when = { flag = "reconciled", notFlag = "finale_no_rekindle" }, next = "e_rec" },
					{ next = "e_def" },
				},
			},
			e_rec = {
				emote = "tender",
				text = "My daughter lit the Hearthflame. I have told every dragon in the Roost. Twice. You are... adequate. That is a compliment.",
			},
			e_def = {
				emote = "neutral",
				text = "The flame burns. The frost will keep away another year. That is what matters. ...Mostly.",
			},
		},
	},
}
