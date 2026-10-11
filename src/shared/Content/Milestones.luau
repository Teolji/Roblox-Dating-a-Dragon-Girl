--[[
	Milestones (relationship stages with Saffron)
	Explorer: ReplicatedStorage > Hearthscale > Content > Milestones (ModuleScript)

	Ordered by rank. A milestone is reached when the previous rank is held and
	`requires` passes; milestones never regress. Rank 4 branches into
	Kindred Spirits (friendship) or Sweethearts (romance) — the branch is set
	by a story decision in Chapter 4 that Saffron also gets a say in.
	callHer: how the {saffron} text token addresses her at this stage.
	romance = true entries are removed in the all-ages edition.
]]

return {
	{
		id = "stranger",
		rank = 0,
		title = "Unclaimed Item #4112",
		callHer = "Miss Ignavarre",
		blurb = "She logged you in her ledger, between the umbrellas and a goat-shaped candle.",
	},
	{
		id = "acquaintance",
		rank = 1,
		title = "Assistant Keeper",
		callHer = "Miss Ignavarre",
		blurb = "Temporary. Probationary. Mostly decorative. You have a mug.",
		unlocks = "Gifts (one per adventure) and chats about her day.",
		requires = { { quest = { "q_item_4112", "complete" } } },
	},
	{
		id = "friend",
		rank = 2,
		title = "Friend",
		callHer = "Saffron",
		blurb = "She asked you to call her Saffron. 'Miss Ignavarre' is for people who owe her roof money.",
		unlocks = "New chat topics and outings.",
		requires = {
			{ flag = "pond_heart_to_heart" },
			{ stat = { "trust", 22 } },
			{ stat = { "affinity", 22 } },
		},
	},
	{
		id = "confidant",
		rank = 3,
		title = "Confidant",
		callHer = "Saffron",
		blurb = "You know what happened on the Old Bridge. She trusted you with it.",
		unlocks = "Deeper conversations about her future.",
		requires = {
			{ flag = "heard_full_story" },
			{ stat = { "trust", 40 } },
			{ stat = { "affinity", 36 } },
		},
	},
	{
		id = "kindred",
		rank = 4,
		title = "Kindred Spirits",
		callHer = "Saffi",
		blurb = "Best friends. Unconditionally. With a mug.",
		requires = { { path = "friendship" }, { stat = { "trust", 52 } } },
	},
	{
		id = "sweetheart",
		rank = 4,
		romance = true,
		fallback = "confidant",
		title = "Sweethearts",
		callHer = "Saffi",
		blurb = "Her forehead to yours, horns tilted carefully aside. It means: I'm here. I'm staying.",
		requires = { { path = "romance" }, { stat = { "trust", 52 } }, { stat = { "romance", 25 } } },
	},
}
