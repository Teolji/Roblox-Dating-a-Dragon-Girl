--[[
	Saffron — main story conversations (Chapters 1–5)
	Explorer: ReplicatedStorage > Hearthscale > Content > Dialogue > SaffronStory

	Choice tags (used by tests' simulated players, never shown):
	kind, joke, curious, respect, honest, comfort, insight, push, rude,
	dismissive, leave, romance, friend, together, believe, family, mother.
	Emotes: neutral happy laugh flustered annoyed sad surprised thoughtful
	determined smug tender.
]]

return {
	-- CHAPTER 1 ---------------------------------------------------------------
	saffron_meet = {
		npc = "saffron",
		priority = 1000,
		when = { questStep = { "q_arrival", "meet" } },
		start = "a1",
		nodes = {
			a1 = { emote = "surprised", text = "Oh! It's awake. Good. Don't move — you're evidence.", next = "a2" },
			a2 = {
				emote = "smug",
				text = "You came through my roof at a speed I'd describe as 'excessive'. Under Section Four of the Kettlewick Lost & Found Charter, anything that arrives unannounced and unclaimed is lost property.",
				next = "a3",
			},
			a3 = {
				emote = "neutral",
				text = "Which makes you Item Number Four Thousand One Hundred and Twelve. Name, for the ledger?",
				choices = {
					{
						text = "I'm {player}. I'm so sorry about your roof — I'll help fix it.",
						tag = "kind",
						effects = { stat = { { "trust", 4 }, { "affinity", 2 } }, flag = "first_kind" },
						next = "b_kind",
					},
					{
						text = "Did you just call me an item?",
						tag = "joke",
						effects = { stat = { "affinity", 3 }, flag = "first_joke" },
						next = "b_joke",
					},
					{
						text = "Hold on — are those horns? Are you a DRAGON?",
						tag = "curious",
						effects = { flag = "first_horns" },
						next = "b_horns",
					},
					{
						text = "I don't have time for this. Where's the exit?",
						tag = "rude",
						effects = { stat = { "affinity", -2 }, flag = "first_rude" },
						next = "b_rude",
					},
				},
			},
			b_kind = { emote = "surprised", text = "An apology. Unprompted. With an offer of labour.", next = "b_kind2" },
			b_kind2 = {
				emote = "happy",
				text = "'Item #4112: polite.' That's going in the margin. With a little star.",
				next = "c1",
			},
			b_joke = { emote = "smug", text = "Item. Guest. Unexpected ceiling feature. I don't make the rules.", next = "b_joke2" },
			b_joke2 = {
				emote = "thoughtful",
				text = "...I do make the rules. I wrote all of them. But I wrote them very carefully.",
				next = "c1",
			},
			b_horns = { emote = "flustered", text = "I am a tall woman with an extensive hat collection.", next = "b_horns2" },
			b_horns2 = {
				speaker = "narrator",
				emote = "flustered",
				text = "A small puff of smoke escapes her nostrils. She waves it away and pretends it didn't happen.",
				next = "b_horns3",
			},
			b_horns3 = {
				emote = "annoyed",
				text = "...Fine. Yes. Dragon. Please don't make it a whole thing.",
				choices = {
					{
						text = "Okay. Not a whole thing.",
						tag = "respect",
						effects = { stat = { "trust", 5 }, flag = "respected_horns" },
						next = "b_horns_ok",
					},
					{
						text = "But it IS a whole thing! That's incredible!",
						tag = "joke",
						effects = { stat = { "affinity", 3 } },
						next = "b_horns_wow",
					},
				},
			},
			b_horns_ok = { emote = "surprised", text = "...Oh. Right. Good. Thank you.", next = "b_horns_ok2" },
			b_horns_ok2 = {
				emote = "happy",
				text = "Most people at least ask if I can breathe fire. It's refreshing to meet someone with restraint. Rare quality in a projectile.",
				next = "c1",
			},
			b_horns_wow = {
				emote = "flustered",
				text = "It is NOT incred— well. The horns are quite good. I polish them. Moving on!",
				next = "c1",
			},
			b_rude = { emote = "annoyed", text = "The exit is that way. Past the hole you made.", next = "b_rude2" },
			b_rude2 = {
				emote = "smug",
				text = "Your balloon, however, is in seven pieces, and my roof is in eleven. So unless you plan to walk over the mountains, you're staying a while.",
				next = "c1",
			},
			c1 = {
				emote = "neutral",
				text = "Introductions, then. I am Saffron Ignavarre, Keeper of Lost Things, Ninth Flame of the Hearth— never mind the rest. It's long and there's a goat in it.",
				next = "c2",
			},
			c2 = { emote = "smug", text = "You may call me Miss Ignavarre.", next = "c3" },
			c3 = {
				emote = "neutral",
				text = "Here's the arrangement. Lost things stay in the Keeping House until someone claims them. Nobody has claimed you, so you'll work off the roof: help me catalogue the hoard, return a few strays to their owners, and we'll call it even.",
				choices = {
					{ text = "Deal. Where do I start?", tag = "kind", effects = { stat = { "trust", 1 } }, next = "d_deal" },
					{ text = "Do I get paid?", tag = "joke", effects = { stat = { "affinity", 2 } }, next = "d_paid" },
					{ text = "And if I refuse?", tag = "rude", next = "d_refuse" },
				},
			},
			d_deal = {
				emote = "happy",
				text = "Enthusiasm! Wonderful. The sorting table is right beside my counter. Try not to fall through anything.",
			},
			d_paid = {
				emote = "smug",
				text = "In tea. And in not being reported to the Mayor for unlicensed aerial littering. Sorting table's beside my counter.",
			},
			d_refuse = {
				emote = "smug",
				text = "Then you'll be filed under 'Unhelpful' and shelved next to the umbrellas. Nobody visits the umbrellas. Sorting table's beside my counter.",
			},
		},
		onEnd = { flag = "met_saffron", event = "talk:saffron_meet" },
	},

	saffron_catalogue = {
		npc = "saffron",
		priority = 900,
		repeatable = true,
		when = { questStep = { "q_item_4112", "catalogue" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "determined",
				text = "The hoard. Eight items, four shelves: Wearables, Kitchenware, Curiosities, Paperwork. Read each tag, pick a shelf. Quickly — the umbrellas are watching.",
				choices = {
					{ text = "Let's sort.", tag = "kind", effects = { startActivity = "act_catalogue" } },
					{
						text = "Why do you keep all this?",
						once = "why_hoard",
						tag = "curious",
						effects = { stat = { "affinity", 1 }, flag = "learned_lost_things" },
						next = "b1",
					},
					{ text = "In a minute." },
				},
			},
			b1 = {
				emote = "thoughtful",
				text = "Because someone, somewhere, misses every one of these. If I keep them safe, then they're not lost-lost. Just... waiting.",
				next = "b2",
			},
			b2 = { emote = "smug", text = "Also, dragons hoard. It's very much a whole thing. Now: sorting!", next = "a1" },
		},
	},

	saffron_strays = {
		npc = "saffron",
		priority = 800,
		repeatable = true,
		when = { questStep = { "q_item_4112", "strays" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "neutral",
				text = "Three strays, three owners. The rolling pin is Mabel's — the bakery, north-west of the square. The spectacles are the Mayor's — the Hall, east. The hook is Wren's — the workshop, south-east.",
				choices = {
					{ text = "On it." },
					{
						text = "Why don't you return them yourself?",
						once = "why_not_return",
						tag = "curious",
						next = "b1",
					},
				},
			},
			b1 = {
				emote = "flustered",
				text = "I return things. I do. Very professionally. From a distance. With a form.",
				next = "b2",
			},
			b2 = {
				emote = "sad",
				text = "People ask questions when I go out. About the horns. About the Hearthflame. It's easier to stay behind the counter.",
				effects = { flag = "learned_shy" },
			},
		},
	},

	saffron_report_4112 = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_item_4112", "report" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "neutral",
				text = "Back already? Every stray returned? Nobody cried? Mabel didn't hit you with the rolling pin?",
				choices = {
					{ text = "Mabel says you haven't laughed properly in years.", tag = "kind", next = "m1" },
					{ text = "The Mayor says the Hearthflame looks 'a bit peaky'.", tag = "honest", next = "p1" },
					{ text = "Wren asked me if you can breathe fire.", tag = "curious", next = "w1" },
				},
			},
			m1 = {
				emote = "annoyed",
				text = "Mabel says a lot of things. Mabel once called a cloud 'shifty'.",
				choices = {
					{
						text = "She said it because she cares about you.",
						tag = "kind",
						effects = { stat = { "trust", 3 } },
						next = "m2",
					},
					{
						text = "So you DO laugh? Prove it. Knock knock.",
						tag = "joke",
						effects = { stat = { "affinity", 3 }, flag = "made_her_laugh" },
						next = "m3",
					},
				},
			},
			m2 = {
				emote = "sad",
				text = "...I know she does. I just — I'm fine. I'm a perfectly reasonable amount of happy.",
				next = "z1",
			},
			m3 = { emote = "smug", text = "I am not going to say 'who's there'.", next = "m4" },
			m4 = {
				emote = "laugh",
				text = "...Who's there? No — wait, don't, I already — ha! Oh no. Oh no, that's the laugh. Forget you heard that.",
				next = "z1",
			},
			p1 = { emote = "thoughtful", text = "It's guttering. Has been for weeks. Old magic gets tired.", next = "p2" },
			p2 = {
				emote = "annoyed",
				text = "And before you ask: no, I don't want to talk about it. Ask me something else. Ask me about spoons.",
				choices = {
					{
						text = "Okay. Tell me about spoons.",
						tag = "respect",
						effects = { stat = { "trust", 4 }, flag = "respected_flame" },
						next = "p3",
					},
					{
						text = "But you're a dragon. Couldn't you just—",
						tag = "push",
						effects = { stat = { "trust", -3 }, flag = "pushed_flame_early" },
						next = "p4",
					},
				},
			},
			p3 = {
				emote = "happy",
				text = "The Keeping House holds two hundred and six spoons. Forty are silver, one is haunted, and one is technically a very small shovel. Thank you for asking about spoons.",
				next = "z1",
			},
			p4 = { emote = "annoyed", text = "I said I don't want to talk about it.", next = "p5" },
			p5 = {
				speaker = "narrator",
				emote = "annoyed",
				text = "A thin curl of smoke rises from her nostrils. She turns back to the ledger.",
				next = "z1",
			},
			w1 = {
				emote = "flustered",
				text = "Of course Wren asked. Wren once asked me if my tail gets cold. In July.",
				next = "w2",
			},
			w2 = {
				emote = "sad",
				text = "I can breathe fire. Technically. Historically. It's... been a while.",
				choices = {
					{ text = "You don't have to explain.", tag = "respect", effects = { stat = { "trust", 3 } }, next = "z1" },
					{ text = "Does your tail get cold, though?", tag = "joke", effects = { stat = { "affinity", 2 } }, next = "w3" },
				},
			},
			w3 = { emote = "smug", text = "Never. It is a magnificent furnace. Thank you for your concern.", next = "z1" },
			z1 = { emote = "determined", text = "Right. Ledger business.", next = "z2" },
			z2 = {
				emote = "smug",
				text = "By the authority vested in me by myself: Item #4112 is hereby reclassified as... Assistant Keeper. Temporary. Probationary. Mostly decorative.",
				choices = {
					{ text = "I'm honoured, Miss Ignavarre.", tag = "kind", effects = { stat = { { "affinity", 2 }, { "trust", 1 } } }, next = "z3" },
					{ text = "Mostly decorative?!", tag = "joke", effects = { stat = { "affinity", 3 } }, next = "z4" },
					{ text = "Does that mean I can finally leave?", tag = "leave", effects = { flag = "asked_to_leave" }, next = "z5" },
				},
			},
			z3 = {
				emote = "happy",
				text = "As you should be. Assistant Keepers get a mug. It says WORLD'S OKAYEST. I found it.",
				next = "z6",
			},
			z4 = { emote = "laugh", text = "Decorative is a compliment here! The umbrellas would kill for decorative.", next = "z6" },
			z5 = {
				emote = "sad",
				text = "Oh. Well — yes. Technically. When your balloon is fixed. Wren could patch it, given time.",
				next = "z5b",
			},
			z5b = {
				emote = "neutral",
				text = "...Until then, you're still welcome behind the counter. Assistant Keepers get a mug.",
				next = "z6",
			},
			z6 = {
				emote = "neutral",
				text = "You can bring me things now, if you find something interesting out there. Gifts. Within reason. One per adventure — I'm a Keeper, not a landfill.",
			},
		},
		onEnd = { event = "talk:saffron_report_4112" },
	},

	-- CHAPTER 2 ---------------------------------------------------------------
	saffron_ask_flame = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_lanternfall", "ask" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "thoughtful",
				text = "You've got your 'the Mayor sent me' face on. It's the same face the Mayor makes, only less sweaty.",
				choices = {
					{
						text = "He's worried about the Hearthflame. So am I. Will you talk to me about it?",
						tag = "kind",
						next = "g1",
					},
					{
						text = "The village needs a Warden. You're a fire dragon. Do the maths.",
						tag = "push",
						effects = { stat = { "trust", -4 }, flag = "pushed_flame" },
						next = "p1",
					},
					{
						text = "Is it a 'no', or a 'very dramatic no'?",
						tag = "joke",
						effects = { stat = { "affinity", 3 } },
						next = "j1",
					},
				},
			},
			g1 = {
				emote = "sad",
				text = "I can't, {player}. It isn't that I won't. I can't.",
				choices = {
					{
						text = "You don't have to tell me why. But I'm here if you ever want to.",
						tag = "respect",
						effects = { stat = { "trust", 5 }, flag = "offered_ear" },
						next = "c1",
					},
					{
						text = "Can't, or won't? Those are different things.",
						tag = "honest",
						effects = { stat = { { "trust", 1 }, { "resolve", 1 } } },
						next = "g2",
					},
				},
			},
			g2 = {
				emote = "annoyed",
				text = "Can't. Definitely can't. ...Probably can't. It's complicated, and I'm not discussing it in front of the umbrellas.",
				next = "c1",
			},
			p1 = {
				emote = "annoyed",
				text = "Do the maths. Right. Thank you. Nobody has EVER suggested that.",
				next = "p2",
			},
			p2 = {
				speaker = "narrator",
				emote = "annoyed",
				text = "Smoke pours from her nostrils. She stares at the ledger until it's clear she isn't reading it.",
				next = "p3",
			},
			p3 = { emote = "sad", text = "The answer is no. Please don't ask me again.", next = "c1" },
			j1 = { emote = "smug", text = "Very dramatic. Operatic, even. There'd be a cape.", next = "j2" },
			j2 = { emote = "sad", text = "...It's a no, {player}. I'm sorry. Tell the Mayor I'm sorry, too.", next = "c1" },
			c1 = {
				emote = "neutral",
				text = "If you want to help the festival, help the lanterns. Wren needs glowcaps — the mushrooms in Glowcap Woods, east of the village. Five should do.",
				next = "c2",
			},
			c2 = {
				emote = "thoughtful",
				text = "And... when you're done being productive, meet me at Mirror Pond, south of the square. I fish there. For lost things, mostly. It's quiet.",
				choices = {
					{ text = "I'll be there.", tag = "kind", effects = { stat = { "affinity", 1 } } },
					{
						text = "Is this a date?",
						tag = "romance",
						romance = true,
						effects = { flag = "asked_date_early" },
						next = "d1",
					},
					{ text = "Fishing for lost things? Sure, why not." },
				},
			},
			d1 = {
				emote = "flustered",
				text = "It is FISHING. With a NET. For SOCKS. Nobody in history has been courted with socks.",
				next = "d2",
			},
			d2 = { emote = "smug", text = "...Bring a hat. The sun's bright on the water." },
		},
		onEnd = { event = "talk:saffron_ask_flame", startQuest = "q_pond" },
	},

	saffron_pond_wait = {
		npc = "saffron",
		priority = 900,
		repeatable = true,
		when = { questStep = { "q_pond", "fish" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "happy",
				text = "You came! The net's on the dock. Watch the marker — when it's in the glow, reel. Last week I caught a teapot, two boots and a very offended duck.",
				choices = {
					{ text = "Let's fish.", tag = "kind", effects = { startActivity = "act_fishing" } },
					{ text = "In a bit." },
				},
			},
		},
	},

	saffron_pond_talk = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_pond", "talk" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "happy",
				text = "Not bad, Assistant Keeper. Mirror Pond gives up its secrets to the patient. And the lucky. Mostly the lucky.",
				next = "a2",
			},
			a2 = {
				speaker = "narrator",
				emote = "sad",
				text = "She sets a kettle on a flat stone, cups her hands around it and breathes. A grey puff of smoke drifts out. Nothing else.",
				next = "a3",
			},
			a3 = {
				emote = "sad",
				text = "...Cold tea it is. Don't look at me like that.",
				choices = {
					{
						text = "That's been happening for a while, hasn't it?",
						tag = "kind",
						effects = { stat = { "trust", 4 } },
						next = "b1",
					},
					{
						text = "Smoke is very atmospheric. Very mysterious.",
						tag = "joke",
						effects = { stat = { "affinity", 3 } },
						next = "j1",
					},
					{
						text = "Have you tried... trying harder?",
						tag = "push",
						effects = { stat = { "trust", -3 } },
						next = "p1",
					},
				},
			},
			j1 = { emote = "laugh", text = "Mysterious! Yes. I'm a creature of mystery and lukewarm beverages.", next = "b1" },
			p1 = {
				emote = "annoyed",
				text = "Oh, TRYING HARDER. Why didn't I think of that? I'll just try harder, like a sneeze.",
				next = "b1",
			},
			b1 = {
				emote = "thoughtful",
				text = "Eight years. I used to light bonfires by sighing at them. Now: smoke. Every time I reach for the fire there's this... wall. Like my own flame doesn't trust me.",
				choices = {
					{
						text = "That sounds frightening. I'm sorry.",
						tag = "comfort",
						effects = { stat = { { "trust", 5 }, { "resolve", 1 } } },
						next = "c1",
					},
					{
						text = "I failed my pilot's exam three times. The third time I flew into a bell tower. I know that wall.",
						tag = "honest",
						effects = { stat = { { "trust", 4 }, { "affinity", 2 }, { "resolve", 1 } }, flag = "shared_failure" },
						next = "s1",
					},
					{
						text = "Fire comes back, though. Right? Like a cold.",
						tag = "joke",
						effects = { stat = { "affinity", 1 } },
						next = "k1",
					},
				},
			},
			c1 = {
				emote = "tender",
				text = "...Thank you. Most people go straight to fixing it. It's nice to just let it be frightening for a minute.",
				next = "d1",
			},
			s1 = {
				emote = "laugh",
				text = "A BELL TOWER? Oh, that's — I'm sorry, that's awful, I'm not laughing, I am completely laughing—",
				next = "s2",
			},
			s2 = {
				emote = "tender",
				text = "...Thank you for telling me. It helps, knowing walls happen to people who fall out of the sky, too.",
				next = "d1",
			},
			k1 = {
				emote = "thoughtful",
				text = "I hope so. I've been waiting eight years for it to pass like a cold. It's a very long cold.",
				next = "d1",
			},
			d1 = {
				effects = { flag = "pond_heart_to_heart" },
				branch = {
					{ when = { canReachMilestone = "friend" }, next = "f1" },
					{ next = "g1" },
				},
			},
			f1 = {
				emote = "tender",
				text = "You know what? Saffron. Just Saffron. 'Miss Ignavarre' is for people who owe me roof money.",
				next = "f2",
			},
			f2 = {
				emote = "smug",
				text = "You still owe me roof money. But you're also... a friend, I think. If that's alright.",
				choices = {
					{ text = "It's more than alright, Saffron.", tag = "kind", effects = { stat = { "affinity", 2 } }, next = "f3" },
					{ text = "Does this mean I get a better mug?", tag = "joke", effects = { stat = { "affinity", 2 } }, next = "f4" },
				},
			},
			f3 = { emote = "happy", text = "Good. Excellent. Very good. ...Your line's tangled." },
			f4 = { emote = "laugh", text = "The mug is non-negotiable. The friendship is a separate department." },
			g1 = { emote = "neutral", text = "Thank you for coming. Truly. Go on — I'll pack up the net." },
		},
		onEnd = { event = "talk:saffron_pond_talk" },
	},

	saffron_bridge_invite = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_old_bridge", "ask" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "neutral",
				text = "{player}. You've got your 'Wren told me something' face on. It's like the Mayor face, but with more eyebrows.",
				choices = {
					{ text = "Wren mentioned the Old Bridge. The night it burned.", tag = "honest", next = "b1" },
					{ text = "Nothing. I just wanted to see you.", tag = "kind", effects = { stat = { "affinity", 2 } }, next = "b2" },
				},
			},
			b1 = { emote = "sad", text = "Of course they did.", next = "b3" },
			b2 = { emote = "smug", text = "Suspicious. Lovely, but suspicious.", next = "b3" },
			b3 = {
				emote = "thoughtful",
				text = "I go out to the Old Bridge ruins once a year. Tomorrow would be... the day. North-east, past the woods, where the gorge is.",
				next = "b4",
			},
			b4 = {
				emote = "sad",
				text = "Would you — no. Never mind. It's silly.",
				choices = {
					{ text = "I'll come with you.", tag = "kind", effects = { stat = { "trust", 3 } }, next = "c1" },
					{ text = "Only if you want me there.", tag = "respect", effects = { stat = { "trust", 4 } }, next = "c2" },
				},
			},
			c1 = {
				emote = "happy",
				text = "...Okay. Okay! Good. Meet me there. Bring nothing. I mean it. No snacks — it's a solemn occasion.",
			},
			c2 = { emote = "tender", text = "I do. I think I do. Meet me there." },
		},
		onEnd = { event = "talk:saffron_bridge_invite" },
	},

	saffron_bridge_story = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_old_bridge", "talk" } },
		start = "a0",
		nodes = {
			a0 = {
				speaker = "narrator",
				emote = "sad",
				text = "The bridge is mostly gone: two blackened stumps of stone and a few charred beams reaching for each other across the gorge. Saffron stands at the edge, tail curled tight around her ankles.",
				next = "a1",
			},
			a1 = { branch = { { when = { stat = { "trust", 28 } }, next = "full1" }, { next = "part1" } } },
			part1 = {
				emote = "neutral",
				text = "It burned eight years ago. Long story. I come here to... remember it, I suppose. That's all.",
				next = "part2",
			},
			part2 = {
				emote = "sad",
				text = "Sorry. I thought I could tell you. I can't — not yet. Thank you for coming anyway.",
				choices = {
					{
						text = "Whenever you're ready. I'm not going anywhere.",
						tag = "kind",
						effects = { stat = { "trust", 4 }, flag = "bridge_patient" },
					},
					{
						text = "I walked all the way out here for 'long story'?",
						tag = "rude",
						effects = { stat = { "trust", -3 } },
						next = "part3",
					},
				},
			},
			part3 = {
				emote = "annoyed",
				text = "You did. And I'm grateful. But some stories don't come out while someone's tapping their foot.",
			},
			full1 = {
				emote = "sad",
				text = "Eight years ago, on Lanternfall, I was supposed to become the Warden. The Ninth Flame. My mother was the Eighth.",
				next = "full2",
			},
			full2 = {
				emote = "thoughtful",
				text = "The whole village came. Lanterns everywhere. My mother waiting on the summit. I walked onto this bridge to begin the climb and I thought: everyone is looking at me. Everyone.",
				next = "full3",
			},
			full3 = {
				emote = "sad",
				text = "And my fire just — came out. All of it. Not at anyone — nobody was hurt, gods know how — but the bridge went up like paper, the ceremony fell apart, and my mother had to climb up and light the Hearthflame herself.",
				next = "full4",
			},
			full4 = {
				emote = "sad",
				text = "She told me I wasn't ready. She was right. So I left the Roost, took over the Lost & Found because nobody else wanted it, and decided to be a tall woman with hats. Forever. Very sensible plan.",
				next = "full5",
			},
			full5 = {
				emote = "thoughtful",
				text = "That night I picked up everything people dropped when they ran. I think that's when I started keeping things. If I keep it all, then nothing else gets—",
				next = "full6",
			},
			full6 = {
				emote = "sad",
				text = "...Well. You understand.",
				effects = { flag = "heard_full_story" },
				choices = {
					{
						text = "It was an accident, Saffron. You were young and terrified, and nobody got hurt.",
						tag = "comfort",
						effects = { stat = { { "trust", 6 }, { "resolve", 1 } }, flag = "d1_comfort" },
						next = "dc",
					},
					{
						text = "Have you ever told the village what really happened?",
						tag = "honest",
						effects = { stat = { { "trust", 3 }, { "resolve", 2 } }, flag = "d1_honesty" },
						next = "dh",
					},
					{
						text = "So the hoard is how you make sure you never lose anything again.",
						tag = "insight",
						effects = { stat = { { "trust", 4 }, { "affinity", 2 }, { "resolve", 1 } }, flag = "d1_insight" },
						next = "di",
					},
					{
						text = "It's been eight years. Isn't it time you got over it?",
						tag = "dismissive",
						effects = { stat = { "trust", -6 }, flag = "d1_dismissive" },
						next = "dd",
					},
				},
			},
			dc = {
				emote = "tender",
				text = "Nobody got hurt. I know. I've told myself a thousand times. It sounds different when someone else says it.",
				next = "e1",
			},
			dh = { emote = "surprised", text = "Told them? They — they saw it. They know.", next = "dh2" },
			dh2 = {
				emote = "thoughtful",
				text = "...They saw the fire. They never heard me say sorry. I never stayed long enough to say it. Huh.",
				next = "e1",
			},
			di = { emote = "annoyed", text = "That is very rude.", next = "di2" },
			di2 = {
				emote = "thoughtful",
				text = "...And probably correct. Two hundred and six spoons, {player}. Nobody needs two hundred and six spoons.",
				next = "e1",
			},
			dd = { emote = "annoyed", text = "Right. Of course. 'Get over it.' I'll have it put on a mug.", next = "dd2" },
			dd2 = { emote = "sad", text = "I think I'd like to be alone for a bit. You can head back." },
			e1 = {
				emote = "determined",
				text = "The flame's guttering. If nobody lights it, my mother will come — she always does. And I keep thinking... what if I tried? Not tonight. But before Lanternfall.",
				next = "e2",
			},
			e2 = {
				emote = "sad",
				text = "I'd need someone there. In case I set something on fire. Again. Would you—",
				choices = {
					{
						text = "I'll be there. Every step.",
						tag = "kind",
						effects = { stat = { { "trust", 3 }, { "resolve", 1 } }, flag = "promised_summit" },
						next = "e3",
					},
					{
						text = "Only if you're doing it for you — not for your mother, or the village.",
						tag = "honest",
						effects = { stat = { { "trust", 2 }, { "resolve", 2 } }, flag = "promised_summit" },
						next = "e4",
					},
				},
			},
			e3 = {
				emote = "tender",
				text = "...Thank you. Let's go home. And bring snacks next time. I was lying about the snacks.",
			},
			e4 = { emote = "thoughtful", text = "For me. Okay. I don't know what that looks like yet. But okay." },
		},
		onEnd = { event = "talk:saffron_bridge_story" },
	},

	-- CHAPTER 3 ---------------------------------------------------------------
	saffron_letter = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_letter", "deliver" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "surprised",
				text = "That seal. That's — oh no. Oh, no no no.",
				effects = { take = "sealed_letter" },
				next = "a2",
			},
			a2 = {
				speaker = "narrator",
				emote = "sad",
				text = "She breaks the seal with one claw and reads. Her tail goes very still.",
				next = "a3",
			},
			a3 = {
				emote = "sad",
				text = "'Saffron. The Hearthflame fails. I will arrive on Lanternfall Eve to rekindle it myself, as I did before. You will then come home to the Roost, where you belong. — Cinderra Ignavarre, the Eighth Flame.'",
				effects = { flag = "read_letter" },
				next = "a4",
			},
			a4 = {
				emote = "annoyed",
				text = "'Where I belong.' Eight years without a word, and the first thing she sends is a — a SUMMONS.",
				choices = {
					{
						text = "You don't have to go anywhere you don't want to.",
						tag = "respect",
						effects = { stat = { "trust", 3 } },
						next = "b1",
					},
					{
						text = "Maybe this is a chance to finally talk to her.",
						tag = "honest",
						effects = { stat = { { "trust", 1 }, { "resolve", 1 } } },
						next = "b2",
					},
					{
						text = "Want me to tell her you moved? Very far. Possibly to the moon.",
						tag = "joke",
						effects = { stat = { "affinity", 3 } },
						next = "b3",
					},
				},
			},
			b1 = { emote = "tender", text = "...Thank you. I needed somebody to say that out loud.", next = "c1" },
			b2 = {
				emote = "thoughtful",
				text = "Talk. To my mother. Have you met a dragon matriarch? It's like talking to a cliff that's disappointed in you.",
				next = "c1",
			},
			b3 = {
				emote = "laugh",
				text = "The moon! She'd follow me, obviously, but she'd have to admit she was impressed by the commute.",
				next = "c1",
			},
			c1 = { emote = "thoughtful", text = "There's something else. Something I should've given back years ago.", next = "c2" },
			c2 = {
				emote = "sad",
				text = "Her lantern. The Warden's lantern. She dropped it on the bridge that night. I picked it up, and I... never returned it. It's somewhere in the hoard. I buried it. On purpose, I think.",
				next = "c3",
			},
			c3 = {
				emote = "determined",
				text = "Would you find it for me? I can't make myself look. There are notes on the back shelves — I leave myself clues when I hide things from myself. Which is a completely normal thing to do.",
			},
		},
		onEnd = { event = "talk:saffron_letter" },
	},

	saffron_hoard_hint = {
		npc = "saffron",
		priority = 800,
		repeatable = true,
		when = {
			any = {
				{ questStep = { "q_lantern_hoard", "search" } },
				{ questStep = { "q_lantern_hoard", "find" } },
			},
		},
		start = "a1",
		nodes = {
			a1 = {
				emote = "flustered",
				text = "Back shelves. Yellow tags. If a tag says 'not here', it's not there. I'm going to stand very still and alphabetise something.",
			},
		},
	},

	saffron_lantern = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_lantern_hoard", "decide" } },
		start = "a1",
		nodes = {
			a1 = {
				speaker = "narrator",
				emote = "sad",
				text = "You set the lantern on the counter. It's scorched along one side, but every inch of it has been polished. Saffron doesn't touch it.",
				effects = { take = "warden_lantern" },
				next = "a2",
			},
			a2 = {
				emote = "sad",
				text = "I polished it every year. On the anniversary. Isn't that strange? I couldn't give it back, but I couldn't let it get dusty, either.",
				next = "a3",
			},
			a3 = {
				emote = "thoughtful",
				text = "What do I do with it, {player}? I keep coming up with three answers, and they all sound right.",
				choices = {
					{
						text = "Give it back to your mother when she comes. Let it go.",
						tag = "honest",
						effects = { stat = { { "resolve", 2 }, { "trust", 2 } }, flag = "d2_return" },
						next = "b1",
					},
					{
						text = "Keep it. It's yours to decide — not hers, and not mine.",
						tag = "respect",
						effects = { stat = { "trust", 4 }, flag = "d2_keep" },
						next = "b2",
					},
					{
						text = "Carry it up the mountain. Light it yourself.",
						tag = "believe",
						effects = { stat = { "resolve", 3 }, flag = "d2_use" },
						next = "b3",
					},
				},
			},
			b1 = {
				emote = "tender",
				text = "Let it go. Gods. The Keeper of Lost Things, giving something back. ...Yes. I think I'm ready to try.",
				next = "c1",
			},
			b2 = {
				emote = "tender",
				text = "Mine to decide. Nobody has said that to me in a very long time. I'll keep it close until I know.",
				next = "c1",
			},
			b3 = {
				emote = "determined",
				text = "Light it MYSELF. With fire I can't make. ...That's either the bravest idea I've ever heard or the silliest. It's going on the shelf by the door. Just in case.",
				next = "c1",
			},
			c1 = {
				emote = "happy",
				text = "Thank you for finding it. Truly. Now, can I ask you something completely unrelated and much less heavy?",
				next = "c2",
			},
			c2 = {
				emote = "flustered",
				text = "There's a meteor shower tonight. The fireflies come out on Stargazer Hill, west of the village. I go every year. Alone, usually. ...Would you like to come?",
				choices = {
					{ text = "I'd love to.", tag = "kind", effects = { stat = { "affinity", 2 } }, next = "d2" },
					{
						text = "Is THIS a date?",
						tag = "romance",
						romance = true,
						when = { milestone = "confidant" },
						effects = { stat = { "romance", 3 }, flag = "asked_date_hill" },
						next = "d1",
					},
					{ text = "Sure. I like fireflies.", next = "d2" },
				},
			},
			d1 = {
				emote = "flustered",
				text = "It is FIREFLIES. Under STARS. Which is admittedly... a lot more date-shaped than socks. Bring a blanket. Not a cold one.",
			},
			d2 = { emote = "happy", text = "Wonderful. Top of the hill, after dusk. I'll bring the jar." },
		},
		onEnd = { event = "talk:saffron_lantern" },
	},

	saffron_hill_start = {
		npc = "saffron",
		priority = 900,
		repeatable = true,
		when = { questStep = { "q_stargazing", "catch" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "happy",
				text = "There you are! The fireflies are out. Help me catch some for the festival lanterns — gently. We let them go afterwards. They're employees, not prisoners.",
				choices = {
					{ text = "Let's catch some fireflies.", tag = "kind", effects = { startActivity = "act_fireflies" } },
					{ text = "Give me a moment." },
				},
			},
		},
	},

	saffron_stars = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_stargazing", "talk" } },
		start = "a1",
		nodes = {
			a1 = {
				speaker = "narrator",
				emote = "tender",
				text = "You lie back in the grass. Meteors streak across the sky, and the fireflies drift upward as if trying to join them.",
				next = "a2",
			},
			a2 = {
				emote = "tender",
				text = "That one's the Dragon's Tail. See? The long curve, from the bright star down to the hill. My mother used to trace it on the ceiling of the Roost with one claw.",
				effects = { flag = "learned_stars" },
				next = "a3",
			},
			a3 = {
				emote = "thoughtful",
				text = "{player}... do you ever think about staying? In Kettlewick, I mean. After Wren fixes your balloon.",
				choices = {
					{
						text = "I think about staying... because of you.",
						tag = "romance",
						romance = true,
						when = { milestone = "confidant", stat = { "trust", 40 } },
						lockedText = "(Tell her you'd stay because of her — you don't feel close enough to say that yet.)",
						effects = { stat = { "romance", 8 }, flag = "stars_confession" },
						next = "r1",
					},
					{
						text = "Kettlewick's growing on me. You especially.",
						tag = "friend",
						effects = { stat = { "affinity", 4 }, flag = "friend_lean" },
						next = "f1",
					},
					{
						text = "I don't know yet. I haven't let myself think about it.",
						tag = "honest",
						effects = { stat = { "trust", 3 } },
						next = "h1",
					},
					{
						text = "Not really. I've got places to be.",
						tag = "leave",
						effects = { flag = "leaning_leave" },
						next = "l1",
					},
				},
			},
			r1 = {
				emote = "flustered",
				text = "You — you can't just SAY that, the stars are RIGHT THERE, they can HEAR you—",
				next = "r2",
			},
			r2 = {
				emote = "tender",
				text = "...I think about it too. You staying. I've been trying very hard not to, because the last time I wanted something this much, I set a bridge on fire.",
				choices = {
					{
						text = "Then let's go slowly. No bridges.",
						tag = "romance",
						romance = true,
						effects = { stat = { { "romance", 4 }, { "trust", 2 } } },
						next = "r3",
					},
					{
						text = "I didn't mean to rush you.",
						tag = "respect",
						effects = { stat = { "trust", 3 } },
						next = "r4",
					},
				},
			},
			r3 = {
				emote = "laugh",
				text = "No bridges. Agreed. ...Ask me again after Lanternfall. If you still mean it, I'll have an answer.",
				effects = { flag = "romance_open" },
			},
			r4 = {
				emote = "tender",
				text = "You didn't. I just need to light one fire at a time. Ask me again after Lanternfall.",
				effects = { flag = "romance_open" },
			},
			f1 = {
				emote = "happy",
				text = "Me especially! Bold. Correct, but bold. I'm glad you're here, {player}. Whatever happens. Best fireflies in years.",
			},
			h1 = { emote = "thoughtful", text = "That's fair. Honest. I'll take honest over pretty any day." },
			l1 = { emote = "sad", text = "Oh. Right. Of course. ...The fireflies are nice, though. Stay for those, at least." },
		},
		onEnd = { event = "talk:saffron_stars" },
	},

	-- CHAPTER 4 ---------------------------------------------------------------
	saffron_after_mother = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_cinderra", "saffron" } },
		start = "a1",
		nodes = {
			a1 = {
				speaker = "narrator",
				emote = "flustered",
				text = "Saffron is behind the counter, half-buried under a pile of coats, holding very still in the manner of someone who believes coats are an effective disguise.",
				next = "a2",
			},
			a2 = {
				emote = "flustered",
				text = "I'm not here. I'm a coat.",
				choices = {
					{ text = "Nice coat.", tag = "joke", effects = { stat = { "affinity", 2 } }, next = "b0" },
					{
						text = "Your mother's in the square. She brought your favourite blanket.",
						tag = "honest",
						effects = { stat = { "trust", 1 } },
						next = "b1",
					},
				},
			},
			b0 = { emote = "laugh", text = "Thank you. It's a lot of coats. ...She's here, isn't she?", next = "b1" },
			b1 = {
				emote = "sad",
				text = "The blue one. With the moons. ...Of course she did. She always does the one thing that makes it impossible to stay angry.",
				next = "b2",
			},
			b2 = {
				branch = {
					{ when = { flag = "d2_return" }, next = "r1" },
					{ when = { flag = "d2_use" }, next = "u1" },
					{ next = "k1" },
				},
			},
			r1 = {
				emote = "determined",
				text = "I'm going to give it back. The lantern. Tomorrow, before the climb. I've been practising in the mirror: 'Here, Mother. Your lantern. Sorry it took eight years.' It sounds terrible every time.",
				choices = {
					{
						text = "It sounds honest. That's enough.",
						tag = "honest",
						effects = { stat = { { "trust", 2 }, { "resolve", 1 } }, flag = "ready_to_reconcile" },
						next = "z1",
					},
					{
						text = "Want me to stand next to you when you do it?",
						tag = "kind",
						effects = { stat = { "trust", 2 }, flag = "ready_to_reconcile" },
						next = "z1",
					},
				},
			},
			u1 = {
				emote = "determined",
				text = "I keep looking at the lantern. My lantern now, I suppose. If I'm going up that mountain, I'm going up with it lit — or I'm not going.",
				choices = {
					{
						text = "Then we'll light it together.",
						tag = "kind",
						effects = { stat = { { "trust", 2 }, { "resolve", 1 } } },
						next = "z1",
					},
					{ text = "You don't have to decide tonight.", tag = "respect", effects = { stat = { "trust", 2 } }, next = "z1" },
				},
			},
			k1 = {
				emote = "thoughtful",
				text = "The lantern's still on my shelf. Mine to decide, you said. I've decided... that I'm still deciding.",
				next = "z1",
			},
			z1 = {
				emote = "determined",
				text = "Tomorrow's Lanternfall. Wren's set up the lantern tables in the square. Paint runes with me tonight? I'd rather be doing something with my hands than thinking.",
			},
		},
		onEnd = { event = "talk:saffron_after_mother" },
	},

	saffron_lanterns_start = {
		npc = "saffron",
		priority = 900,
		repeatable = true,
		when = { questStep = { "q_lanterns", "craft" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "determined",
				text = "Four runes: Ember, Leaf, Star, Wave. I paint a pattern, you copy it. Get it wrong and the lantern says something rude in Old Draconic. Harmless. Mostly.",
				choices = {
					{ text = "Let's paint.", tag = "kind", effects = { startActivity = "act_lanterns" } },
					{ text = "Give me a minute." },
				},
			},
		},
	},

	saffron_eve = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_lanterns", "eve" } },
		start = "a0",
		nodes = {
			a0 = {
				speaker = "narrator",
				emote = "thoughtful",
				text = "The square glows with a hundred finished lanterns. Somewhere, Mabel is arguing with Pim about bunting. Saffron sits on the edge of the fountain, turning a paintbrush over and over in her claws.",
				next = "a1",
			},
			a1 = {
				emote = "thoughtful",
				text = "Before tomorrow, I want to ask you something, and I want you to be honest, because I'm terrible at guessing and I've already guessed six different ways.",
				next = "a2",
			},
			a2 = {
				emote = "flustered",
				text = "What are we? You and me.",
				choices = {
					{
						text = "I'd like us to be more than friends, Saffron.",
						tag = "romance",
						romance = true,
						when = { milestone = "confidant" },
						lockedText = "(Ask to be more than friends — you don't feel close enough to say it.)",
						next = "rc",
					},
					{ text = "You're my best friend. That's what we are.", tag = "friend", next = "fr" },
					{
						text = "I'm leaving after the festival. Wren fixed my balloon.",
						tag = "leave",
						effects = { stat = { "trust", -2 }, flag = "leaving" },
						next = "lv",
					},
				},
			},
			rc = {
				branch = {
					{ when = { stat = { "trust", 48 }, all = { { stat = { "romance", 12 } } } }, next = "yes1" },
					{ when = { stat = { "trust", 48 } }, next = "no1" },
					{ next = "nt1" },
				},
			},
			yes1 = {
				emote = "flustered",
				text = "Yes. I — yes. Gods. I'm smoking. Ignore the smoke. The smoke is unrelated.",
				effects = { path = "romance", stat = { { "romance", 10 }, { "trust", 3 } }, flag = "confessed" },
				next = "yes2",
			},
			yes2 = {
				emote = "tender",
				text = "I've wanted to say that since the pond. Maybe since the roof. Is it strange, falling for someone who arrived as lost property?",
				choices = {
					{ text = "Only a little strange.", tag = "joke", effects = { stat = { "affinity", 2 } }, next = "yes3" },
					{ text = "Not strange at all.", tag = "romance", romance = true, effects = { stat = { "romance", 2 } }, next = "yes3" },
				},
			},
			yes3 = {
				speaker = "narrator",
				emote = "tender",
				text = "She leans in until her forehead rests against yours, horns tilted carefully aside. Dragons do this, she tells you later. It means: I'm here. I'm staying.",
				next = "z1",
			},
			no1 = {
				emote = "tender",
				text = "{player}... I care about you so much. You're the best thing that's happened to me in eight years.",
				next = "no2",
			},
			no2 = {
				emote = "sad",
				text = "But I don't think I feel it that way. Not — not like that. And I'd rather tell you than pretend, because pretending is how I ended up hiding under coats.",
				effects = { path = "friendship", flag = "declined_romance" },
				choices = {
					{
						text = "Thank you for being honest. Best friends, then?",
						tag = "kind",
						effects = { stat = { "trust", 4 } },
						next = "no3",
					},
					{ text = "I understand.", effects = { stat = { "trust", 2 } }, next = "no3" },
				},
			},
			no3 = { emote = "happy", text = "Best friends. Absolutely. Unconditionally. With a mug.", next = "z1" },
			nt1 = {
				emote = "thoughtful",
				text = "I... don't think I know you well enough for that question yet. I'm sorry. I'm not saying never. I'm saying I need to trust where I'm putting my feet.",
				effects = { flag = "romance_too_soon" },
				next = "z1",
			},
			fr = {
				branch = {
					{ romance = true, when = { stat = { "romance", 15 } }, next = "fw1" },
					{ next = "fr1" },
				},
			},
			fr1 = {
				emote = "happy",
				text = "Best friend. Yes. Good. That's exactly what I hoped you'd say.",
				effects = { path = "friendship", stat = { { "trust", 3 }, { "affinity", 3 } } },
				next = "z1",
			},
			fw1 = {
				emote = "tender",
				text = "Best friend. Yes. That's... that's a good answer. A very good one.",
				effects = { path = "friendship", stat = { { "trust", 3 }, { "affinity", 3 } } },
				next = "fw2",
			},
			fw2 = {
				speaker = "narrator",
				emote = "happy",
				text = "Something wistful crosses her face, then settles into a smile that's entirely real.",
				next = "z1",
			},
			lv = { emote = "sad", text = "Oh. The balloon. Right.", next = "lv2" },
			lv2 = {
				emote = "thoughtful",
				text = "No — that's good. That's good for you. You were always going somewhere. I just got to borrow you for a while.",
				choices = {
					{ text = "I'll write. I promise.", tag = "kind", effects = { stat = { "trust", 2 } }, next = "z1" },
					{ text = "Maybe I'll come back someday.", next = "z1" },
				},
			},
			z1 = {
				emote = "determined",
				text = "Tomorrow, then. The mountain. Whatever happens up there... I'm glad it's you next to me.",
			},
		},
		onEnd = { event = "talk:saffron_eve" },
	},

	-- CHAPTER 5 ---------------------------------------------------------------
	saffron_summit = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_summit", "choose" } },
		start = "a0",
		nodes = {
			a0 = {
				speaker = "narrator",
				emote = "sad",
				text = "The summit of Hearthpeak is wind and stone and stars. In the great iron brazier, the Hearthflame has shrunk to one shivering ember. Cinderra stands beside it. Saffron stands beside you.",
				next = "a1",
			},
			a1 = { speaker = "cinderra", emote = "neutral", text = "You came. Both of you.", next = "a2" },
			a2 = {
				branch = {
					{ when = { flag = "ready_to_reconcile" }, next = "rec1" },
					{ next = "a3" },
				},
			},
			rec1 = {
				emote = "sad",
				text = "Mother. Before anything — this is yours.",
				next = "rec2",
			},
			rec2 = {
				speaker = "narrator",
				emote = "sad",
				text = "She holds out the Warden's lantern. Cinderra looks at it for a long moment.",
				next = "rec3",
			},
			rec3 = { speaker = "cinderra", emote = "tender", text = "You polished it.", next = "rec4" },
			rec4 = { emote = "sad", text = "Every year.", next = "rec5" },
			rec5 = {
				speaker = "cinderra",
				emote = "sad",
				text = "I told you that you were not ready, Saffron. I never told you that I was not ready either — to be the mother of a flame that bright. I am sorry.",
				effects = { flag = "reconciled", stat = { "resolve", 2 } },
				next = "a3",
			},
			a3 = {
				speaker = "cinderra",
				emote = "determined",
				text = "The ember is nearly out. If you will not light it, I will. There is no shame in that.",
				next = "a4",
			},
			a4 = { branch = { { when = { statBelow = { "trust", 40 } }, next = "low1" }, { next = "c1" } } },
			low1 = {
				emote = "sad",
				text = "I... I can't. I'm sorry. I thought I could, but I'm standing here and all I can hear is the bridge.",
				next = "low2",
			},
			low2 = {
				speaker = "narrator",
				emote = "sad",
				text = "She looks at you, just for a moment, as if hoping you'll say something. Then she steps back.",
				effects = { flag = { "finale_low_trust", "finale_no_rekindle" } },
				next = "low3",
			},
			low3 = { speaker = "cinderra", emote = "determined", text = "Then it is mine to do.", next = "low4" },
			low4 = {
				speaker = "narrator",
				emote = "sad",
				text = "Cinderra breathes, and the Hearthflame roars back to life, gold and enormous. It is beautiful. It is not Saffron's.",
			},
			c1 = { emote = "sad", text = "I want to. I want to so much. But my fire hasn't answered me in eight years.", next = "c2" },
			c2 = {
				emote = "thoughtful",
				text = "{player}... what should I do?",
				choices = {
					{
						text = "Together. Take my hand — we'll breathe through it, like at the pond.",
						tag = "together",
						romance = true,
						when = { path = "romance" },
						effects = { flag = "finale_together", stat = { "resolve", 1 } },
						next = "t1",
					},
					{
						text = "You can do this. I believe in you.",
						tag = "believe",
						effects = { flag = "finale_believe", stat = { "resolve", 1 } },
						next = "b1",
					},
					{
						text = "Do it with your mother. Two flames.",
						tag = "family",
						when = { flag = "reconciled" },
						effects = { flag = "finale_family" },
						next = "fam1",
					},
					{
						text = "You don't have to prove anything. Let your mother light it — go home with her, and heal.",
						tag = "mother",
						effects = { flag = { "finale_mother", "finale_no_rekindle" } },
						next = "m1",
					},
				},
			},
			t1 = {
				speaker = "narrator",
				emote = "tender",
				text = "Her hand is very warm. Her claws are careful. She laughs, shakily, and squeezes once.",
				next = "go",
			},
			b1 = { emote = "determined", text = "Believe in me. Right. Okay. Okay okay okay.", next = "go" },
			fam1 = { speaker = "cinderra", emote = "tender", text = "Together, then. As it should have been.", next = "go" },
			m1 = { emote = "sad", text = "...Go home.", next = "m2" },
			m2 = {
				emote = "thoughtful",
				text = "Maybe you're right. Maybe I need to learn the fire properly, where it started, before I can carry it here.",
				next = "m3",
			},
			m3 = { speaker = "cinderra", emote = "tender", text = "Then we will learn it together. Come, little flame.", next = "m4" },
			m4 = {
				speaker = "narrator",
				emote = "tender",
				text = "Cinderra breathes, and the Hearthflame roars back to life. Saffron watches it with her mother's arm around her shoulders.",
			},
			go = {
				emote = "determined",
				text = "Breathe with me. In... and out. When the ember glows, that's when I push.",
				effects = { startActivity = "act_rekindle" },
			},
		},
		onEnd = { event = "talk:saffron_summit" },
	},

	saffron_rekindle_retry = {
		npc = "saffron",
		priority = 900,
		repeatable = true,
		when = { questStep = { "q_summit", "rekindle" } },
		start = "a1",
		nodes = {
			a1 = {
				emote = "determined",
				text = "Okay. Again. Breathe with me — in, and out.",
				choices = {
					{ text = "Together. In, and out.", effects = { startActivity = "act_rekindle" } },
					{ text = "One moment." },
				},
			},
		},
	},

	saffron_finale_after = {
		npc = "saffron",
		priority = 900,
		when = { questStep = { "q_summit", "after" } },
		start = "a0",
		nodes = {
			a0 = {
				branch = {
					{ when = { flag = "finale_no_rekindle" }, next = "x1" },
					{ when = { flag = "rekindle_high" }, next = "h1" },
					{ when = { flag = "rekindle_mid" }, next = "m1" },
					{ next = "l1" },
				},
			},
			h1 = {
				speaker = "narrator",
				emote = "laugh",
				text = "Saffron breathes out, and fire answers — not the wild flood from the bridge, but a long, steady river of gold. The Hearthflame catches and climbs until it lights the whole valley.",
				next = "s1",
			},
			m1 = {
				speaker = "narrator",
				emote = "happy",
				text = "The ember flares, sputters, and catches. Saffron's fire is uneven, but it holds, and the Hearthflame grows bright and warm.",
				next = "s1",
			},
			l1 = {
				speaker = "narrator",
				emote = "happy",
				text = "Saffron's breath comes out ragged — smoke, sparks, smoke — and then, with Cinderra's hand on her shoulder, a thin thread of real flame. It's enough. The Hearthflame catches.",
				effects = { flag = "rekindle_assisted" },
				next = "s1",
			},
			s1 = { emote = "laugh", text = "I did it. I DID it. {player}, I did a fire!", next = "s2" },
			s2 = {
				speaker = "narrator",
				emote = "happy",
				text = "Far below, the lanterns of Kettlewick rise into the sky, one by one.",
				effects = { resolveEnding = true },
			},
			x1 = {
				speaker = "narrator",
				emote = "thoughtful",
				text = "Far below, the lanterns of Kettlewick rise into the sky, one by one.",
				effects = { resolveEnding = true },
			},
		},
		onEnd = { event = "talk:saffron_finale_after" },
	},
}
