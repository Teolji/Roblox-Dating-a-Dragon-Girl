--[[
	Config
	Explorer: ReplicatedStorage > Hearthscale > Config (ModuleScript)

	Global tuning and build switches. Pure data: no Roblox API calls, so the
	Lune test suite can load it outside Studio.
]]

local Config = {
	GameTitle = "Hearthscale",
	Subtitle = "A Kettlewick Story",

	-- Content edition switch.
	--   true  = romance edition. Roblox rules require a Restricted maturity
	--           label (age-verified 18+) for any experience with romantic
	--           themes. See docs/01-Compliance.md before publishing.
	--   false = all-ages "friendship edition". Every choice, node, milestone
	--           and ending tagged `romance = true` is removed at runtime and
	--           the story still completes (covered by tests/specs/playthrough).
	RomanceEnabled = true,

	-- Persistence
	SaveVersion = 1,
	DataStoreName = "Hearthscale_Saves_v1",
	DataStoreKeyPrefix = "player_",
	AutosaveInterval = 90, -- seconds between saves of a changed profile
	SessionLockTimeout = 600, -- a lock older than this is considered abandoned
	LoadAttempts = 5,
	SaveAttempts = 4,
	-- Studio without "Enable Studio Access to API Services": fall back to an
	-- in-memory store so the game is still playable (progress is lost on stop).
	UseMemoryStoreWhenApiUnavailable = true,

	-- Server-side proximity validation (studs)
	TalkDistance = 18,
	CollectDistance = 14,
	ActivityDistance = 30,
	ReachDistanceDefault = 30,

	-- Relationship tuning
	StatMax = 100,
	ResolveMax = 10,
	-- Gift and repeat-activity affinity can never push affinity past this cap
	-- for the current milestone. Story choices are not capped.
	SoftAffinityCap = {
		stranger = 10,
		acquaintance = 30,
		friend = 50,
		confidant = 70,
		kindred = 90,
		sweetheart = 90,
	},
	ActivityRepeatRewardLimit = 3,

	-- Request throttling (token bucket per player)
	RequestBurst = 30,
	RequestRefillPerSecond = 12,

	-- World
	BuildPlaceholderWorld = true, -- builds a blockout map if Workspace.HearthscaleWorld is missing
	WorldFolderName = "HearthscaleWorld",
	AnchorsFolderName = "Anchors",

	-- Optional asset IDs. Empty string = not provided; the game falls back to
	-- procedural placeholders. See docs/05-Assets.md.
	Animations = {
		saffron = {
			idle = "",
			talk = "",
			happy = "",
			laugh = "",
			flustered = "",
			annoyed = "",
			sad = "",
			surprised = "",
			thoughtful = "",
			determined = "",
			tender = "",
			breatheFire = "",
		},
	},
	Audio = {
		Music = {
			village = "",
			night = "",
			tension = "",
			finale = "",
			ending = "",
		},
		Sfx = {
			click = "",
			toast = "",
			questComplete = "",
			milestone = "",
			pickup = "",
			smokePuff = "",
			success = "",
			fail = "",
			typewriter = "",
		},
	},
	Portraits = {
		-- rbxassetid://... per character; empty = initial-letter placeholder
		saffron = "",
		mabel = "",
		pim = "",
		wren = "",
		cinderra = "",
	},
}

return Config
