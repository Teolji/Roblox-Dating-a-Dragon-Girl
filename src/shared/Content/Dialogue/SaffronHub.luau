--[[
	Saffron — hub menu (chats, gifts, outings, hints) and epilogue
	Explorer: ReplicatedStorage > Hearthscale > Content > Dialogue > SaffronHub

	Chat topics are `once` choices: each can be picked a single time, so
	small talk can't be farmed for stats. Some topics test boundaries.
]]

local function menuChoices()
	return {
		{ text = "Can we chat?", next = "topics" },
		{
			text = "I brought you something.",
			when = { giftReady = true },
			lockedText = "I brought you something. (She'd like to share another adventure first.)",
			effects = { action = { action = "openGift", npc = "saffron" } },
		},
		{
			text = "Let's do something together.",
			when = {
				any = {
					{ activity = "act_catalogue" },
					{ activity = "act_fishing" },
					{ activity = "act_lanterns" },
				},
			},
			next = "outings",
		},
		{ text = "Where should I go next?", next = "hint" },
		{ text = "Goodbye." },
	}
end

return {
	saffron_hub = {
		npc = "saffron",
		priority = 0,
		repeatable = true,
		when = { noEnding = true },
		start = "menu",
		nodes = {
			menu = {
				branch = {
					{ when = { milestone = "friend" }, next = "menu_f" },
					{ when = { milestone = "acquaintance" }, next = "menu_a" },
					{ next = "menu_s" },
				},
			},
			menu_s = {
				emote = "neutral",
				text = "Item #4112. Need something?",
				choices = {
					{ text = "Where should I go next?", next = "hint" },
					{ text = "Goodbye." },
				},
			},
			menu_a = { emote = "neutral", text = "Assistant Keeper. What can I do for you?", choices = menuChoices() },
			menu_f = { emote = "happy", text = "{player}! Hello. Hi. What's on your mind?", choices = menuChoices() },

			hint = { emote = "thoughtful", text = "{hint}", next = "menu" },

			outings = {
				emote = "happy",
				text = "Something together? I'd like that. What did you have in mind?",
				choices = {
					{
						text = "Catalogue the hoard.",
						when = { activity = "act_catalogue" },
						effects = { startActivity = "act_catalogue" },
					},
					{
						text = "Fishing — we'll pretend the counter is a dock.",
						when = { activity = "act_fishing" },
						effects = { startActivity = "act_fishing" },
					},
					{
						text = "Paint some spare lanterns.",
						when = { activity = "act_lanterns" },
						effects = { startActivity = "act_lanterns" },
					},
					{ text = "Actually, never mind.", next = "menu" },
				},
			},

			topics = {
				emote = "smug",
				text = "Chat! I love to chat. I'm extremely chatty. Ask me anything. Within reason. Within MY reason.",
				choices = {
					{ text = "How old are you, exactly?", once = "t_age", tag = "curious", next = "age1" },
					{ text = "Why run a Lost & Found?", once = "t_lostfound", tag = "curious", next = "lf1" },
					{ text = "What's the strangest thing in the hoard?", once = "t_strange", tag = "joke", next = "st1" },
					{ text = "What do you like to drink?", once = "t_tea", tag = "curious", next = "tea1" },
					{ text = "Can I touch your tail?", once = "t_tail", tag = "curious", next = "tail1" },
					{
						text = "What do dragons dream about?",
						once = "t_dreams",
						tag = "curious",
						when = { milestone = "friend" },
						next = "dr1",
					},
					{
						text = "Tell me about your mother.",
						once = "t_mother",
						tag = "curious",
						when = { milestone = "friend", notFlag = "read_letter" },
						next = "mo1",
					},
					{
						text = "Do you like the stars?",
						once = "t_stars",
						tag = "curious",
						when = { milestone = "friend" },
						next = "sk1",
					},
					{
						text = "Can you tell me about the bridge now?",
						once = "t_bridge_again",
						tag = "kind",
						when = {
							notFlag = "heard_full_story",
							quest = { "q_old_bridge", "complete" },
							stat = { "trust", 28 },
						},
						next = "br1",
					},
					{
						text = "What will you do after Lanternfall?",
						once = "t_after",
						tag = "curious",
						when = { milestone = "confidant" },
						next = "af1",
					},
					{
						text = "You look really nice today, Saffron.",
						once = "t_flirt1",
						tag = "romance",
						romance = true,
						when = { milestone = "friend" },
						next = "fl1",
					},
					{
						text = "Your laugh is my favourite sound in Kettlewick.",
						once = "t_flirt2",
						tag = "romance",
						romance = true,
						when = { flag = "flirt_welcomed", milestone = "confidant" },
						next = "fl2",
					},
					{
						text = "Are you sure it's just 'nice'?",
						once = "t_flirt_push",
						tag = "push",
						romance = true,
						when = { flag = "flirt_declined" },
						next = "fp1",
					},
					{ text = "Never mind.", next = "menu" },
				},
			},

			age1 = {
				emote = "smug",
				text = "Two hundred and nine. Which is twenty-six, in dragon. Please don't do the maths out loud — it's considered rude, and you'll get it wrong.",
				effects = { stat = { { "affinity", 1 }, { "trust", 1 } }, flag = "learned_age" },
				next = "topics",
			},
			lf1 = {
				emote = "thoughtful",
				text = "Nobody else wanted it. And there's something lovely about it — every object in here is a little story that hasn't finished yet. Someone lost it. Someone's going to find it. I just keep the middle bit safe.",
				effects = { stat = { "affinity", 2 }, flag = "learned_lost_things" },
				next = "topics",
			},
			st1 = {
				emote = "laugh",
				text = "A goat. A real one. Somebody 'lost' it outside in a storm. I logged it, fed it, and it ate four ledgers and a wizard's hat. It was claimed after a week. I still miss it, honestly.",
				effects = { stat = { "affinity", 2 } },
				next = "topics",
			},
			tea1 = {
				emote = "happy",
				text = "Smoked ember tea. Mabel blends it specially. It tastes like a campfire apologising. I drink it cold now, obviously, for... reasons.",
				effects = { stat = { "affinity", 1 }, flag = "learned_tea" },
				next = "topics",
			},
			tail1 = {
				emote = "annoyed",
				text = "No.",
				next = "tail2",
			},
			tail2 = {
				emote = "annoyed",
				text = "It's not a petting zoo, {player}. Do I ask to touch your... whatever you've got? Elbows?",
				choices = {
					{
						text = "Sorry — that was out of line. I shouldn't have asked like that.",
						tag = "respect",
						effects = { stat = { "trust", 2 }, flag = "learned_tail" },
						next = "tail3",
					},
					{
						text = "Come on. Just once?",
						tag = "push",
						effects = { stat = { "trust", -5 }, flag = { "pushed_tail", "learned_tail" } },
						next = "tail4",
					},
				},
			},
			tail3 = {
				emote = "smug",
				text = "Apology accepted. For the record, it's very nice that you asked instead of grabbing. Some people grab. Some people are now shelved with the umbrellas.",
				next = "topics",
			},
			tail4 = {
				emote = "annoyed",
				text = "No means no, {player}. Even for tails. Especially for tails.",
				next = "topics",
			},
			dr1 = {
				emote = "thoughtful",
				text = "Falling, mostly. Then flying. Then, embarrassingly, soup. A lake of it. I can't explain the soup.",
				effects = { stat = { "affinity", 2 } },
				next = "topics",
			},
			mo1 = { emote = "sad", text = "Not today.", next = "mo2" },
			mo2 = {
				emote = "neutral",
				text = "...Sorry. That came out sharp. It's just — not today.",
				choices = {
					{
						text = "Okay. Whenever you're ready.",
						tag = "respect",
						effects = { stat = { "trust", 3 } },
						next = "mo3",
					},
					{
						text = "Why not?",
						tag = "push",
						effects = { stat = { "trust", -1 } },
						next = "mo4",
					},
				},
			},
			mo3 = { emote = "tender", text = "Thank you. Really.", next = "topics" },
			mo4 = { emote = "annoyed", text = "Because I said 'not today'. That's a whole sentence.", next = "topics" },
			sk1 = {
				emote = "happy",
				text = "I love the stars. They're like lost things nobody's allowed to keep. You just get to look at them and know they're fine.",
				effects = { stat = { "affinity", 1 }, flag = "learned_stars" },
				next = "topics",
			},
			br1 = {
				emote = "sad",
				text = "...Alright. The night of my Warden trial, my fire got away from me on that bridge. Nobody was hurt, but it burned, and the ceremony fell apart, and my mother had to light the Hearthflame herself. She said I wasn't ready. I ran.",
				effects = { flag = "heard_full_story" },
				choices = {
					{
						text = "It was an accident. You were young and scared.",
						tag = "comfort",
						effects = { stat = { { "trust", 5 }, { "resolve", 1 } }, flag = "d1_comfort" },
						next = "br2",
					},
					{
						text = "Thank you for trusting me with it.",
						tag = "kind",
						effects = { stat = { "trust", 4 } },
						next = "br2",
					},
				},
			},
			br2 = { emote = "tender", text = "Thank you for waiting until I could.", next = "topics" },
			af1 = {
				emote = "thoughtful",
				text = "If the flame goes out, I suppose I go home with my mother and pretend I never left. If it doesn't... I don't know. I haven't let myself imagine a version where it doesn't.",
				choices = {
					{
						text = "Imagine it now. What does it look like?",
						tag = "kind",
						effects = { stat = { { "resolve", 1 }, { "trust", 1 } } },
						next = "af2",
					},
					{ text = "Whatever you choose, I'm on your side.", tag = "respect", effects = { stat = { "trust", 2 } }, next = "topics" },
				},
			},
			af2 = {
				emote = "happy",
				text = "...The Keeping House, but with the windows open. Me, going out. Returning things in person. People knowing my name and my horns and not minding either. Huh. That's nice.",
				next = "topics",
			},
			fl1 = {
				branch = {
					{ when = { stat = { "trust", 32 } }, next = "fl1y" },
					{ next = "fl1n" },
				},
			},
			fl1y = {
				emote = "flustered",
				text = "I — thank you. It's the same waistcoat as always. Is it the waistcoat? It's the waistcoat. ...Thank you.",
				effects = { stat = { "romance", 3 }, flag = "flirt_welcomed" },
				next = "topics",
			},
			fl1n = {
				emote = "neutral",
				text = "...Thank you. Let's keep it at 'nice' for now, if that's alright.",
				effects = { flag = "flirt_declined" },
				next = "topics",
			},
			fl2 = {
				emote = "flustered",
				text = "My laugh sounds like a kettle with hiccups. You're a terrible liar. ...Say it again sometime.",
				effects = { stat = { "romance", 3 } },
				next = "topics",
			},
			fp1 = {
				emote = "annoyed",
				text = "I said 'for now', {player}. I need you to hear that. When I'm ready to say something different, I'll say it.",
				effects = { stat = { "trust", -4 }, flag = "flirt_pushed" },
				next = "topics",
			},
		},
	},

	saffron_epilogue = {
		npc = "saffron",
		priority = 5,
		repeatable = true,
		when = { anyEnding = true },
		start = "a0",
		nodes = {
			a0 = {
				branch = {
					{ when = { ending = "two_flames" }, next = "tf" },
					{ when = { ending = "kindred_sparks" }, next = "ks" },
					{ next = "sl" },
				},
			},
			tf = {
				emote = "tender",
				text = "Co-Keeper {player}! The ledger has a new column. It's just your name. With a small heart. Don't look at it. ...You're looking at it.",
				next = "end",
			},
			ks = {
				emote = "happy",
				text = "Head Assistant Keeper {player}! I had the mug updated. It now says WORLD'S BEST. Just 'best'. Of everything. Don't argue.",
				next = "end",
			},
			sl = {
				emote = "neutral",
				text = "Thank you for your help with the festival, {player}. Safe travels, wherever you're going.",
				next = "end",
			},
			["end"] = {
				emote = "smug",
				text = "Want to start your story over? You'll find that in Settings. I'll pretend not to recognise you. Mostly.",
			},
		},
	},
}
